import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bymax/controllers/loginController.dart';
// Importamos la página de recordatorios
import 'package:bymax/pages/recordatoryPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:bymax/main.dart';

class FamiliarHomePage extends StatefulWidget {
  const FamiliarHomePage({super.key});

  @override
  State<FamiliarHomePage> createState() => _FamiliarHomePageState();
}

class _FamiliarHomePageState extends State<FamiliarHomePage> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  String _userName = "Familiar";
  String _adultName = "Adulto asignado";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _registrarTokenSiEsNecesario();
  }

  // Método para cargar el nombre del usuario desde SharedPreferences
  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('user_name');
      final adultAssigned = prefs.getString('adult_assigned');

      setState(() {
        _userName = savedName ?? "Familiar";
        _adultName = adultAssigned ?? "Adulto asignado";
      });
    } catch (e) {
      print('Error al cargar la información del usuario: $e');
    }
  }
  void _registrarTokenSiEsNecesario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await registrarTokenFCM(user.uid, token);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await registrarTokenFCM(user.uid, newToken);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Color(0xFF03d069)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavBarItem(Icons.home, 0),
            _buildNavBarItem(Icons.notifications_active, 1),
            _buildNavBarItem(Icons.person, 2),
            _buildNavBarItem(Icons.logout, 3),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        color: const Color(0xFF03d069),
        child: Column(
          children: [
            // Barra de estado personalizada + Encabezado verde
            Container(
              padding: const EdgeInsets.only(
                top: 30,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              color: const Color(0xFF03d069),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () async {
                      // Mostrar diálogo de confirmación
                      final shouldExit = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('¿Estás seguro?'),
                              content: const Text(
                                '¿Deseas cerrar sesión y salir de la aplicación?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(color: Color(0xFF03d069)),
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Salir',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                      );

                      // Si el usuario confirma, cerrar sesión y regresar al login
                      if (shouldExit == true) {
                        try {
                          await LoginController.signOut();
                          if (!mounted) return;

                          Navigator.pushReplacementNamed(context, '/loginPage');
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al cerrar sesión: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  // Logo Bymax
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('lib/pages/images/logo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Bymax',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),

                  // Saludo con texto blanco
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      const SizedBox(width: 10), // Espacio entre avatar y texto
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola $_userName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Cuidando de $_adultName',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menú de opciones con fondo
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.zero, // Sin bordes redondeados abajo
                  ),
                  image: const DecorationImage(
                    image: AssetImage('lib/pages/images/patron_homePage.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color.fromARGB(211, 200, 193, 193),
                      BlendMode.darken, // Modo de mezcla
                    ),
                  ),
                ),
                // Aquí viene la implementación del Scrollbar
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility:
                      true, // Hace que el scrollbar sea siempre visible
                  thickness: 6, // Grosor del scrollbar
                  radius: Radius.circular(
                    10,
                  ), // Bordes redondeados del scrollbar
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        // Crear recordatorio - botón vertical
                        _buildMenuItemVertical(
                          icon: Icons.add_alert,
                          label: 'Crear Recordatorio',
                          color: Colors.amber,
                          textColor: Colors.black,
                          onTap: () {
                            // Cambiamos esta parte para usar MaterialPageRoute igual que en el homePage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecordatoryPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 15),

                        // Opcional: Añadir más elementos para probar el scrollbar
                        _buildMenuItemVertical(
                          icon: Icons.people,
                          label: 'Usuarios',
                          color: Colors.green,
                          textColor: Colors.black,
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/userList',
                            ); // Navegar a la ruta '/userList'
                          },
                        ),

                        const SizedBox(height: 15),

                        // Agregar espacio al final para mejor experiencia de desplazamiento
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para crear botones verticales con texto debajo
  Widget _buildMenuItemVertical({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedIndex = index;
        });

        if (_selectedIndex == index) {
          switch (index) {
            case 0:
              // Ya estamos en la página principal
              break;
            case 1:
              // Ir a la página de recordatorios - modificado para usar MaterialPageRoute
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecordatoryPage()),
              );
              break;
            case 2:
              // Ir al perfil
              Navigator.pushNamed(context, '/userList');
              break;
            case 3:
              try {
                await LoginController.signOut();
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesión cerrada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );

                Navigator.pushReplacementNamed(context, '/loginPage');
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al cerrar sesión: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              break;
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          size: 24,
        ),
      ),
    );
  }
}
