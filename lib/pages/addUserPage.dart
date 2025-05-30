import 'dart:math';

import 'package:flutter/material.dart';
import '../controllers/userController.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final _usernameController =
      TextEditingController(); // Para mostrar el username generado
  final _passwordController =
      TextEditingController(); // Para mostrar la contraseña generada

  // Variables para la familia
  bool _createNewFamily = false; // Por defecto, no crear nueva familia
  String? _selectedFamilyId;
  String _newFamilyName = "";
  final _newFamilyNameController = TextEditingController();

  // Variables para el formulario
  String _userType = "Adulto";
  Map<String, String> _families = {};
  bool _isLoadingFamilies = true;
  bool _isSaving = false;

  // Scroll controller for the Scrollbar
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFamilies();
    _generateCredentials();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    _idNumberController.dispose();
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
    _passwordController.dispose();
    _newFamilyNameController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilies() async {
    setState(() {
      _isLoadingFamilies = true;
    });

    try {
      // Obtener el ID del administrador actual
      final currentUser = UserController.auth.currentUser;
      if (currentUser == null) {
        throw Exception("No se encontró al usuario actual.");
      }

      // Obtener las familias creadas por el administrador actual
      final families = await UserController.getFamiliesCreatedByAdmin(
        currentUser.uid,
      );

      setState(() {
        _families = families;
        _isLoadingFamilies = false;
        if (_families.isNotEmpty) {
          _selectedFamilyId = _families.keys.first;
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

  void _generateCredentials() {
    String name = _nameController.text.trim().toLowerCase();
    name = name.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (name.isEmpty) {
      name = 'usuario${DateTime.now().millisecondsSinceEpoch % 1000}';
    } else {
      name = name.length > 10 ? name.substring(0, 10) : name;
    }
    _usernameController.text = name;
    _passwordController.text = name;
  }

  Future<void> _saveUserToFirebase() async {
    // Validar campos obligatorios
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre y correo electrónico son obligatorios'),
        ),
      );
      return;
    }

    // Iniciar estado de carga
    setState(() {
      _isSaving = true;
    });

    // Pide la contraseña del admin antes de crear el usuario
    final adminPassword = await _askAdminPassword(context);
    if (adminPassword == null || adminPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes ingresar tu contraseña para continuar'),
        ),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      String familyId;

      // Maneja la creación o selección de familia
      if (_createNewFamily && _newFamilyNameController.text.isNotEmpty) {
        DocumentReference familyRef = await FirebaseFirestore.instance
            .collection('familias')
            .add({
              'nombre': _newFamilyNameController.text.trim(),
              'fechaCreacion': DateTime.now().toString(),
              'createdBy': UserController.auth.currentUser!.uid,
            });
        familyId = familyRef.id;
      } else if (!_createNewFamily && _selectedFamilyId != null) {
        familyId = _selectedFamilyId!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Es necesario seleccionar o crear una familia'),
          ),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Captura las credenciales actuales antes del registro
      final currentUsername = _usernameController.text.trim();
      final currentPassword = _passwordController.text.trim();

      // Verificar si el nombre de usuario es único
      bool isUnique = await UserController.isUsernameUnique(currentUsername);
      String finalUsername = currentUsername;
      if (!isUnique) {
        finalUsername = 'user${DateTime.now().millisecondsSinceEpoch}';
      }

      // Preparar datos del usuario
      Map<String, dynamic> userData = {
        'nombre': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'direccion': _addressController.text.trim(),
        'fechaNacimiento': _birthDateController.text.trim(),
        'numeroIdentificacion': _idNumberController.text.trim(),
        'username': finalUsername,
        'rol': _userType,
        'familiaId': familyId,
        'fechaRegistro': DateTime.now().toString(),
        'isAdmin': false,
      };

      // Registrar nuevo usuario
      final result = await UserController.registerNewUser(
        email: _emailController.text.trim(),
        password: currentPassword,
        userData: userData,
        adminPassword: adminPassword,
      );

      if (result['success']) {
        String newUserId = result['usuario']['uid'];
        await UserController.addUserToFamily(familyId, newUserId);

        // Mostrar diálogo con las credenciales capturadas
        _showSuccessDialog(
          context,
          username: finalUsername,
          password: currentPassword,
        );

        _clearFields();
        _loadFamilies();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<String?> _askAdminPassword(BuildContext context) async {
    final TextEditingController _passwordDialogController =
        TextEditingController();
    String? password;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirma tu contraseña'),
          content: TextField(
            controller: _passwordDialogController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña de administrador',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                password = _passwordDialogController.text;
                Navigator.of(context).pop();
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    return password;
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
      // Formatea la fecha como DD/MM/YYYY
      String formattedDate =
          "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
      setState(() {
        _birthDateController.text = formattedDate;
      });
    }
  }

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
        _selectedFamilyId = _families.keys.first;
      } else {
        _selectedFamilyId = null;
      }
    });
    _generateCredentials();
  }

  void _showSuccessDialog(
    BuildContext context, {
    required String username,
    required String password,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Usuario registrado exitosamente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('El usuario ha sido registrado con éxito.'),
                const SizedBox(height: 16),
                const Text(
                  'Credenciales de acceso:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Usuario: $username',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                SelectableText(
                  'Contraseña: $password',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                const SizedBox(height: 16),
                const Text(
                  '⚠️ IMPORTANTE:',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Guarde o comparta estas credenciales de forma segura. '
                  'No podrá verlas nuevamente.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ENTENDIDO',
                style: TextStyle(color: Color(0xFF03d069)),
              ),
            ),
          ],
        );
      },
    );
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
          children: [_buildNavBarItem(Icons.home, 0)],
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
                                      _families.entries.map((family) {
                                        return DropdownMenuItem<String>(
                                          value: family.key,
                                          child: Text(family.value),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
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
