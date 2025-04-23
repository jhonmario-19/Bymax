import 'package:flutter/material.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  int _selectedIndex = 1; // Por defecto seleccionamos la opción de agregar (índice 1)
  
  // Controladores para los campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  @override
  void dispose() {
    // Limpiamos los controladores cuando se destruye el widget
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra de navegación inferior fuera del SafeArea
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF03d069),
          
        ),
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
              padding: const EdgeInsets.only(top: 30, left: 16, right: 16, bottom: 8),
              color: const Color(0xFF03d069),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () {
                      Navigator.of(context).pop();
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
                        )
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                          label: 'Paciente',
                          isSelected: true,
                        ),
                        
                        const SizedBox(width: 12),
                        _buildUserTypeOption(
                          icon: Icons.family_restroom,
                          label: 'Familiar',
                          isSelected: false,
                        ),
                      ],
                    ),
                    
                    // Espaciador
                    Expanded(child: Container()),
                    
                    // Botón "GUARDAR USUARIO"
                    Center(
                      child: Container(
                        width: 240,
                        height: 45,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: ElevatedButton(
                          onPressed: () {
                            // Aquí iría la lógica para guardar el usuario
                            // Por ejemplo, mostrar un diálogo de confirmación
                            _showSuccessDialog(context);
                          },
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
          ],
        ),
      ),
    );
  }

  // Widget para crear campos de texto personalizados
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
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
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF03d069)),
          labelStyle: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  // Widget para las opciones de tipo de usuario
  Widget _buildUserTypeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Aquí se manejaría la selección del tipo de usuario
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF03d069).withOpacity(0.2) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: isSelected
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
                  color: isSelected ? const Color(0xFF03d069) : Colors.grey[600],
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

      // Evitamos navegación si ya estamos en la pantalla actual
      if (_selectedIndex == index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/homePage');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '');
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
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
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
          content: const Text('El usuario ha sido guardado exitosamente.'),
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