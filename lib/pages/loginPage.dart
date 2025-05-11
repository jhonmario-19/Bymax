import 'package:bymax/controllers/loginController.dart';
import 'package:flutter/material.dart';
import 'package:bymax/pages/registerPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isResetLoading = false;
  bool _passwordvisible = false;

  @override
  void initState() {
    super.initState();
    // Cargar credenciales guardadas cuando se inicia la pantalla
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Función para cargar credenciales guardadas
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final savedRememberMe = prefs.getBool('remember_me');

    if (savedEmail != null &&
        savedPassword != null &&
        savedRememberMe == true) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });

      // Opcionalmente, puedes intentar iniciar sesión automáticamente
      // await _handleLogin();
    }
  }

  // Función para guardar credenciales
  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    if (_rememberMe) {
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      await prefs.setBool('remember_me', true);
    } else {
      // Si no se marca "recordarme", eliminar las credenciales guardadas
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  // Función para manejar el reseteo de contraseña
  Future<void> _handlePasswordReset() async {
    // Verificar si el email está vacío
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, ingresa tu correo electrónico para recuperar la contraseña',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar un diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Recuperar contraseña'),
            content: Text(
              '¿Enviar un correo de recuperación a ${_emailController.text}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Enviar',
                  style: TextStyle(color: Color(0xFF03d069)),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isResetLoading = true;
    });

    try {
      // Llamar al método de Firebase para resetear la contraseña
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isResetLoading = false;
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se ha enviado un correo para recuperar tu contraseña'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isResetLoading = false;
      });

      // Mostrar mensaje de error
      String errorMessage;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No existe una cuenta con este correo electrónico';
            break;
          case 'invalid-email':
            errorMessage = 'El correo electrónico no es válido';
            break;
          default:
            errorMessage = 'Error al enviar el correo: ${e.message}';
            break;
        }
      } else {
        errorMessage = 'Error inesperado: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  // Función para verificar el rol del usuario después de iniciar sesión
  Future<Map<String, dynamic>> _checkUserRole(User user) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null && userData['rol'] == 'admin') {
        return {'isAdmin': true, 'userData': userData};
      } else {
        return {'isAdmin': false, 'userData': userData};
      }
    } catch (e) {
      print('Error al verificar el rol del usuario: $e');
      return {'isAdmin': false, 'error': 'Error al verificar el rol: $e'};
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final result = await LoginController.signIn(email, password);

      if (!mounted) return;

      if (result['success'] == true) {
        // Verificar el rol del usuario
        final User? user = result['user'];
        if (user != null) {
          final roleInfo = await _checkUserRole(user);

          // Guardar las credenciales si se seleccionó "Recordarme"
          await _saveCredentials(email, password);

          // Guardar información del rol en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_admin', roleInfo['isAdmin'] ?? false);

          // Guardar el nombre del usuario
          if (roleInfo['userData'] != null) {
            // Guardar el nombre del usuario en SharedPreferences
            final String userName = roleInfo['userData']['nombre'] ?? 'Usuario';
            await prefs.setString('user_name', userName);
          }

          setState(() {
            _isLoading = false;
          });

          // Redirigir según el rol
          final userData = roleInfo['userData'];
          final String rol = userData?['rol'] ?? 'adulto';
          // Redirigir a homePage para todos los usuarios
          if (rol == 'adulto') {
            Navigator.pushReplacementNamed(context, '/adultHome');
          } else if (rol == 'admin') {
            Navigator.pushReplacementNamed(context, '/homePage');
          } else {
            // Otros roles o página por defecto
            Navigator.pushReplacementNamed(context, '/adultHome');
          }
        } else {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al obtener información del usuario'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al iniciar sesión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función para limpiar las credenciales guardadas
  Future<void> _clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
    await prefs.setBool('remember_me', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/pages/images/backGround.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo y nombre
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 40.0),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('lib/pages/images/logo.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Bymax',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenedor verde para el formulario de login
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 20.0,
                    ),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF03d069),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        // Campo de email
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Campo de contraseña
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: !_passwordvisible,
                            decoration: InputDecoration(
                              hintText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordvisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _passwordvisible = !_passwordvisible;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Opciones adicionales
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? true;
                                  });
                                },
                                fillColor: MaterialStateProperty.all(
                                  Colors.white,
                                ),
                                checkColor: const Color(0xFF00C853),
                                shape: const CircleBorder(),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Recordarme',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            // Botón para recuperar contraseña con indicador de carga
                            _isResetLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                                : TextButton(
                                  onPressed: _handlePasswordReset,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Botón de iniciar sesión
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF00C853),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF00C853),
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'INICIAR SESIÓN',
                                    style: TextStyle(
                                      color: Color(0xFF00C853),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),

                        const SizedBox(height: 20),

                        // Opción para crear cuenta
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¿No tienes una cuenta?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Crea una',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
