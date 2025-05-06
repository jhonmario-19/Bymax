import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/authStateController.dart';
import '../controllers/userController.dart'; // Add this import
import 'widgets/family_options.dart';
import 'widgets/custom_navigation_bar.dart';
import 'widgets/user_form.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final AuthStateController authController = Get.find<AuthStateController>();

  // Controladores para los campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newFamilyNameController = TextEditingController();

  // Variables para el formulario
  String _userType = "Adulto";
  bool _createNewFamily = false;
  String? _selectedFamilyId;
  Map<String, String> _families = {};
  bool _isLoadingFamilies = true;
  bool _isSaving = false;

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
    _usernameController.dispose();
    _passwordController.dispose();
    _newFamilyNameController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilies() async {
    setState(() {
      _isLoadingFamilies = true;
    });

    try {
      // Use the actual method from UserController
      final families = await UserController.getFamilies();

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
    // Generate unique username
    _usernameController.text =
        'user${DateTime.now().millisecondsSinceEpoch % 10000}';

    // Use the password generator from UserController
    _passwordController.text = UserController.generatePassword();
  }

  Future<void> _saveUserToFirebase() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre y correo electrónico son obligatorios'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? familyId;

      // Handle family creation or selection
      if (_createNewFamily && _newFamilyNameController.text.isNotEmpty) {
        // Create a new family and get its ID
        familyId = await UserController.createFamily(
          _newFamilyNameController.text,
        );
      } else if (!_createNewFamily && _selectedFamilyId != null) {
        familyId = _selectedFamilyId;
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

      // Verify username uniqueness
      bool isUnique = await UserController.isUsernameUnique(
        _usernameController.text,
      );
      if (!isUnique) {
        // Generate a new username if the current one is not unique
        _usernameController.text =
            'user${DateTime.now().millisecondsSinceEpoch}';
      }

      // Prepare user data
      Map<String, dynamic> userData = {
        'nombre': _nameController.text,
        'email': _emailController.text,
        'telefono': _phoneController.text,
        'direccion': _addressController.text,
        'fechaNacimiento': _birthDateController.text,
        'numeroIdentificacion': _idNumberController.text,
        'username': _usernameController.text,
        'familiaId': familyId,
        'rol': _userType.toLowerCase(), // Convert to lowercase for consistency
        'fechaCreacion': DateTime.now().toString(),
      };

      // Register the user using UserController
      final result = await UserController.registerUser(
        email: _emailController.text,
        password: _passwordController.text,
        userData: userData,
      );

      setState(() {
        _isSaving = false;
      });

      if (result['success']) {
        _showSuccessDialog(context);
        _clearFields();
        // Refresh the families list
        _loadFamilies();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${result['message']}')));
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: 1,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/homePage');
              break;
            case 1:
              break; // Ya estamos en esta página
            case 2:
              Navigator.pushReplacementNamed(context, '/settings');
              break;
            case 3:
              // Log out and navigate to login page
              UserController.signOut().then((_) {
                Navigator.pushReplacementNamed(context, '/loginPage');
              });
              break;
          }
        },
      ),
      body:
          _isSaving
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF03d069)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agregar Usuario',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildUserTypeOption(
                          label: 'Adulto',
                          isSelected: _userType == 'Adulto',
                          onTap: () => setState(() => _userType = 'Adulto'),
                        ),
                        const SizedBox(width: 12),
                        _buildUserTypeOption(
                          label: 'Familiar',
                          isSelected: _userType == 'Familiar',
                          onTap: () => setState(() => _userType = 'Familiar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    UserForm(
                      nameController: _nameController,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      addressController: _addressController,
                      birthDateController: _birthDateController,
                      idNumberController: _idNumberController,
                      usernameController: _usernameController,
                      passwordController: _passwordController,
                      onNameChanged: (value) => _generateCredentials(),
                      onGenerateCredentials: _generateCredentials,
                      onSelectBirthDate: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          _birthDateController.text =
                              "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    FamilyOptions(
                      createNewFamily: _createNewFamily,
                      newFamilyNameController: _newFamilyNameController,
                      families:
                          _families.entries
                              .map((e) => {'id': e.key, 'nombre': e.value})
                              .toList(),
                      selectedFamilyId: _selectedFamilyId,
                      isLoadingFamilies: _isLoadingFamilies,
                      onCreateNewFamily: () {
                        setState(() {
                          _createNewFamily = true;
                        });
                      },
                      onAssignExistingFamily: () {
                        setState(() {
                          _createNewFamily = false;
                        });
                      },
                      onFamilySelected: (String? newValue) {
                        setState(() {
                          _selectedFamilyId = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveUserToFirebase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF03d069),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'GUARDAR USUARIO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildUserTypeOption({
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
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF03d069) : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
