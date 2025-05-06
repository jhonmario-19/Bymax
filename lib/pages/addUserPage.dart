import 'package:flutter/material.dart';
import '../controllers/userController.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/authStateController.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  int _selectedIndex = 1;
  final AuthStateController authController = Get.find<AuthStateController>();

  // Controladores para los campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _usernameController = TextEditingController(); // Para mostrar el username generado
  final _passwordController = TextEditingController(); // Para mostrar la contraseña generada

  // Variable para el tipo de usuario
  String _userType = "Adulto"; // Por defecto es Adulto

  // Variables para la familia
  bool _createNewFamily = false; // Por defecto, no crear nueva familia
  String? _selectedFamilyId;
  String _newFamilyName = "";
  final _newFamilyNameController = TextEditingController();
  List<Map<String, dynamic>> _families = [];
  bool _isLoadingFamilies = true;

  // Añadimos el controlador para el scrollbar
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    authController.initializeAdmin();
    _loadFamilies();
    // Generar nombre de usuario y contraseña inicial
    _generateCredentials();

  }

  @override
  void dispose() {
    // Limpiamos los controladores cuando se destruye el widget
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    _idNumberController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _newFamilyNameController.dispose();
    _scrollController.dispose(); // Importante liberar el controlador del scroll
    super.dispose();
  }

  // Método para cargar las familias desde Firestore
  Future<void> _loadFamilies() async {
    setState(() {
      _isLoadingFamilies = true;
    });

    try {
      QuerySnapshot familiesSnapshot =
          await FirebaseFirestore.instance.collection('familias').get();

      List<Map<String, dynamic>> loadedFamilies = [];
      for (var doc in familiesSnapshot.docs) {
        loadedFamilies.add({
          'id': doc.id,
          'nombre': doc['nombre'] ?? 'Sin nombre',
        });
      }

      setState(() {
        _families = loadedFamilies;
        _isLoadingFamilies = false;
        // Si hay familias, seleccionamos la primera por defecto
        if (_families.isNotEmpty) {
          _selectedFamilyId = _families[0]['id'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingFamilies = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar familias: $e')));
    }
  }

  // Método para generar nombre de usuario y contraseña
  void _generateCredentials() {
    // Generar un nombre de usuario basado en el nombre completo si está disponible
    if (_nameController.text.isNotEmpty) {
      String fullName = _nameController.text.trim();
      List<String> nameParts = fullName.split(' ');

      // Tomar primera letra del nombre y apellido completo
      String username = '';
      if (nameParts.isNotEmpty) {
        username = nameParts[0].toLowerCase();
        if (nameParts.length > 1) {
          // Añadir primera letra del apellido
          username += nameParts.last[0].toLowerCase();
        }
        // Añadir números aleatorios para hacerlo único
        username += '${DateTime.now().millisecondsSinceEpoch % 1000}';
      } else {
        username = 'user${DateTime.now().millisecondsSinceEpoch % 10000}';
      }

      _usernameController.text = username;
    } else {
      // Si no hay nombre, generar uno aleatorio
      _usernameController.text =
          'user${DateTime.now().millisecondsSinceEpoch % 10000}';
    }

    // Generar una contraseña aleatoria
    String password = 'Pass${DateTime.now().millisecondsSinceEpoch % 10000}!';
    _passwordController.text = password;
  }

  // Método para registrar usuario en Firebase
  Future<void> _saveUserToFirebase() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre y correo electrónico son obligatorios')),
      );
      return;
    }

    try {
      // Envolver la operación de guardado en Obx para mantener estado del admin
      Obx(() {
        if (authController.adminUser == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Container(); // Widget vacío cuando el admin está disponible
      });

      String familyId;
      if (_createNewFamily && _newFamilyNameController.text.isNotEmpty) {
        DocumentReference familyRef = await FirebaseFirestore.instance
            .collection('familias')
            .add({
          'nombre': _newFamilyNameController.text.trim(),
          'fechaCreacion': DateTime.now().toString(),
        });
        familyId = familyRef.id;
      } else if (!_createNewFamily && _selectedFamilyId != null) {
        familyId = _selectedFamilyId!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Es necesario seleccionar o crear una familia')),
        );
        return;
      }

      Map<String, dynamic> userData = {
        'nombre': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'direccion': _addressController.text.trim(),
        'fechaNacimiento': _birthDateController.text.trim(),
        'numeroIdentificacion': _idNumberController.text.trim(),
        'username': _usernameController.text.trim(),
        'rol': _userType,
        'familiaId': familyId,
        'fechaRegistro': DateTime.now().toString(),
      };

      // Registrar usuario usando FirebaseController
      final result = await UserController.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        userData: userData,
      );

      if (result['success']) {
        // Actualizar el estado del admin después de la operación
        await authController.initializeAdmin();
        
        _showSuccessDialog(context);
        _clearFields();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
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
    _usernameController.clear();
    _passwordController.clear();
    _newFamilyNameController.clear();
    setState(() {
      _userType = "Adulto";
      _createNewFamily = false;
      if (_families.isNotEmpty) {
        _selectedFamilyId = _families[0]['id'];
      } else {
        _selectedFamilyId = null;
      }
    });

    // Generar nuevas credenciales
    _generateCredentials();
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
                          onChanged: (value) => _generateCredentials(),
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

                        // Selector de tipo de usuario (rol)
                        const Text(
                          'Rol del usuario',
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

                        const SizedBox(height: 24),

                        // Sección de asignación a familia
                        const Text(
                          'Asignación a Familia',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Opciones para la familia
                        Row(
                          children: [
                            _buildFamilyOption(
                              icon: Icons.group,
                              label: 'Asignar a familia existente',
                              isSelected: !_createNewFamily,
                              onTap: () {
                                setState(() {
                                  _createNewFamily = false;
                                });
                              },
                            ),

                            const SizedBox(width: 12),
                            _buildFamilyOption(
                              icon: Icons.group_add,
                              label: 'Crear nueva familia',
                              isSelected: _createNewFamily,
                              onTap: () {
                                setState(() {
                                  _createNewFamily = true;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Mostrar el selector de familia o campo para crear una nueva
                        if (_createNewFamily)
                          _buildTextField(
                            controller: _newFamilyNameController,
                            label: 'Nombre de la nueva familia',
                            icon: Icons.add_home,
                          )
                        else
                          _isLoadingFamilies
                              ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF03d069),
                                ),
                              )
                              : _families.isEmpty
                              ? const Center(
                                child: Text(
                                  'No hay familias disponibles. Cree una nueva.',
                                ),
                              )
                              : Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedFamilyId,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    labelText: 'Seleccionar familia',
                                    prefixIcon: Icon(
                                      Icons.family_restroom,
                                      color: Color(0xFF03d069),
                                    ),
                                  ),
                                  items:
                                      _families.map((family) {
                                        return DropdownMenuItem<String>(
                                          value: family['id'],
                                          child: Text(family['nombre']),
                                        );
                                      }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedFamilyId = newValue;
                                    });
                                  },
                                ),
                              ),

                        const SizedBox(height: 24),

                        // Sección de credenciales generadas
                        const Text(
                          'Credenciales autogeneradas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildTextField(
                                controller: _usernameController,
                                label: 'Nombre de usuario',
                                icon: Icons.person_outline,
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Color(0xFF03d069),
                              ),
                              onPressed: _generateCredentials,
                              tooltip: 'Regenerar credenciales',
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          icon: Icons.lock_outline,
                          readOnly: true,
                        ),

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
    VoidCallback? onTap,
    Function(String)? onChanged,
    bool readOnly = false,
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
        readOnly: readOnly || onTap != null,
        onTap: onTap,
        onChanged: onChanged,
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

  // Widget para las opciones de familia
  Widget _buildFamilyOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
                textAlign: TextAlign.center,
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('El usuario ha sido registrado exitosamente.'),
              const SizedBox(height: 12),
              Text('Nombre de usuario: ${_usernameController.text}'),
              Text('Contraseña: ${_passwordController.text}'),
              const SizedBox(height: 8),
              const Text(
                'Recuerde compartir estas credenciales con el usuario.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
