import 'package:flutter/material.dart';
import '../controllers/firebaseController.dart'; // Importa tu controlador de Firebase

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  int _selectedIndex =
      1; // Por defecto seleccionamos la opción de agregar (índice 1)

  // Controladores para los campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _idNumberController = TextEditingController();

  // Variable para el tipo de usuario
  String _userType = "Adulto"; // Por defecto es Paciente

  // Añadimos el controlador para el scrollbar
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    // Limpiamos los controladores cuando se destruye el widget
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    _idNumberController.dispose();
    _scrollController.dispose(); // Importante liberar el controlador del scroll
    super.dispose();
  }

  // Método para registrar usuario en Firebase
  Future<void> _saveUserToFirebase() async {
    try {
      // Generamos una contraseña temporal o solicitamos al usuario que la establezca
      // Esto es solo un ejemplo, puedes adaptarlo según tus necesidades
      String tempPassword =
          "Temporal123!"; // En un caso real, podría ser generada aleatoriamente

      // Crea un mapa con los datos del usuario
      Map<String, dynamic> userData = {
        'nombre': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'direccion': _addressController.text.trim(),
        'fechaNacimiento': _birthDateController.text.trim(),
        'numeroIdentificacion': _idNumberController.text.trim(),
        'tipoUsuario': _userType,
        'fechaRegistro': DateTime.now().toString(),
      };

      // Registra el usuario usando Firebase Authentication y guarda los datos adicionales
      final user = await FirebaseController.registerUser(
        email: _emailController.text.trim(),
        password: tempPassword,
        userData: userData,
      );

      if (user != null) {
        _showSuccessDialog(context);
        // Limpiar los campos después de guardar exitosamente
        _clearFields();
      }
    } catch (e) {
      // Mostrar mensaje de error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  // Método para mostrar el selector de fecha
  Future<void> _selectBirthDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Fecha inicial del calendario
      firstDate: DateTime(1900), // Fecha mínima seleccionable
      lastDate: DateTime.now(), // Fecha máxima seleccionable
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF03d069), // Color del encabezado del calendario
              onPrimary: Colors.white, // Color del texto en el encabezado
              onSurface: Colors.black, // Color del texto en el calendario
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(
                  0xFF03d069,
                ), // Color del botón "OK"
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _birthDateController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Método para limpiar los campos del formulario
  void _clearFields() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _birthDateController.clear();
    _idNumberController.clear();
    setState(() {
      _userType = "Adulto";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra de navegación inferior fuera del SafeArea
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFF03d069)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavBarItem(Icons.home, 0),
            _buildNavBarItem(Icons.add, 1),
            _buildNavBarItem(Icons.settings, 2),
            _buildNavBarItem(Icons.logout, 3),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        color: const Color(0xFF03d069), // Color verde de fondo
        child: Column(
          children: [
            // Header verde con saludo
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
                  const SizedBox(height: 16),

                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/homePage');
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
                        decoration: const BoxDecoration(
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
                    ],
                  ),

                  // Saludo con texto blanco
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hola Usuario,',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'Hoy es un día maravilloso',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Contenido principal con fondo blanco
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.zero,
                  ),
                ),
                // Implementamos el Scrollbar aquí
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility:
                      true, // Hace que la barra sea siempre visible
                  thickness: 6, // Grosor del scrollbar
                  radius: const Radius.circular(
                    10,
                  ), // Bordes redondeados para el scrollbar
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título de la sección
                        const Center(
                          child: Text(
                            'Agregar Usuario',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Formulario para agregar usuario
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nombre completo',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _phoneController,
                          label: 'Teléfono',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // Selector de tipo de usuario
                        const Text(
                          'Tipo de usuario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Opciones de tipo de usuario
                        Row(
                          children: [
                            _buildUserTypeOption(
                              icon: Icons.person,
                              label: 'Adulto',
                              isSelected: _userType == "Adulto",
                              onTap: () {
                                setState(() {
                                  _userType = "Adulto";
                                });
                              },
                            ),

                            const SizedBox(width: 12),
                            _buildUserTypeOption(
                              icon: Icons.family_restroom,
                              label: 'Familiar',
                              isSelected: _userType == "Familiar",
                              onTap: () {
                                setState(() {
                                  _userType = "Familiar";
                                });
                              },
                            ),
                          ],
                        ),

                        // Agregamos más campos para probar el scrollbar
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _addressController,
                          label: 'Dirección',
                          icon: Icons.home,
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _birthDateController,
                          label: 'Fecha de nacimiento',
                          icon: Icons.calendar_today,
                          keyboardType:
                              TextInputType.none, // Deshabilita el teclado
                          onTap:
                              () => _selectBirthDate(
                                context,
                              ), // Abre el selector de fecha
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _idNumberController,
                          label: 'Número de identificación',
                          icon: Icons.badge,
                        ),

                        // Espacio para asegurar que el botón no se corte
                        const SizedBox(height: 40),

                        // Botón "GUARDAR USUARIO"
                        Center(
                          child: Container(
                            width: 240,
                            height: 45,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: ElevatedButton(
                              onPressed:
                                  _saveUserToFirebase, // Llamamos al método para guardar en Firebase
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF03d069),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'GUARDAR USUARIO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap, // Nuevo parámetro opcional
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly:
            onTap !=
            null, // Hace que el campo sea de solo lectura si `onTap` está definido
        onTap: onTap, // Llama a la función `onTap` si se proporciona
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF03d069)),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  // Widget para las opciones de tipo de usuario
  Widget _buildUserTypeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, // Ahora podemos manejar la selección
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? const Color(0xFF03d069).withOpacity(0.2)
                    : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected
                    ? Border.all(color: const Color(0xFF03d069), width: 2)
                    : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF03d069) : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected ? const Color(0xFF03d069) : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para cada icono de la barra de navegación
  Widget _buildNavBarItem(IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        // Navegación según el índice seleccionado
        if (_selectedIndex == index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/homePage');
              break;
            case 1:
              // Ya estamos en la página de agregar usuario
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/settings');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/loginPage');
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

  // Diálogo de éxito al guardar
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Usuario guardado'),
          content: const Text('El usuario ha sido registrado exitosamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Opcionalmente, navegar de vuelta a la página principal
                // Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF03d069)),
              ),
            ),
          ],
        );
      },
    );
  }
}
