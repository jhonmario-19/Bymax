import 'package:bymax/controllers/userController.dart';
import 'package:flutter/material.dart';
import '../controllers/userListController.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  int _selectedIndex = 1;
  final ScrollController _scrollController = ScrollController();
  final UserListController _controller = UserListController();

  List<Map<String, dynamic>> _usuarios = [];
  Map<String, String> _familias = {};
  bool _isLoading = true;
  String _errorMessage = '';
  String _filterRole = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadUsuariosYFamilias();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsuariosYFamilias() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      bool isAdmin = await _controller.verifyAdminAccess();
      if (!isAdmin && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No tienes permisos de administrador';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes permisos de administrador'),
            backgroundColor: Colors.red,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/homePage');
        });
        return;
      }

      final result = await _controller.loadUsersAndFamilies();

      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _usuarios = List<Map<String, dynamic>>.from(result['usuarios']);
          _familias = Map<String, String>.from(result['familias']);
          _isLoading = false;

          print("Usuarios cargados: ${_usuarios.length}");
          if (_usuarios.isEmpty) {
            _errorMessage =
                'No se encontraron usuarios creados por este administrador';
          }
        });
      } else {
        setState(() {
          _errorMessage = result['error'].toString();
          _isLoading = false;
        });
        throw Exception(result['error']);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar usuarios: $e'),
          backgroundColor: Colors.red,
        ),
      );

      if (e.toString().contains("No tienes permisos")) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/homePage');
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredUsers() {
    if (_filterRole == 'Todos') {
      return _usuarios;
    }

    final lowerCaseFilter = _filterRole.toLowerCase();
    return _usuarios.where((usuario) {
      final userRole = usuario['rol']?.toString().toLowerCase() ?? '';
      return userRole == lowerCaseFilter;
    }).toList();
  }

  void _showUserDetails(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con avatar y nombre (fuera del scroll)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(
                            0xFF03d069,
                          ).withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: const Color(0xFF03d069),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                usuario['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(usuario['rol']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  usuario['rol'] ?? 'No definido',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Contenido desplazable
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      physics: const BouncingScrollPhysics(),
                      child: Column(children: _buildUserInfoItems(usuario)),
                    ),
                  ),

                  // Botón de cerrar (fuera del scroll)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF03d069),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  List<Widget> _buildUserInfoItems(Map<String, dynamic> usuario) {
    // Lista de campos que quieres mostrar en orden
    final fieldsList = [
      {'key': 'email', 'label': 'Email', 'icon': Icons.email},
      {'key': 'rol', 'label': 'Rol', 'icon': Icons.badge},
      {'key': 'familiaId', 'label': 'Familia', 'icon': Icons.family_restroom},
      {
        'key': 'fechaNacimiento',
        'label': 'Fecha de nacimiento',
        'icon': Icons.cake,
      },
      {'key': 'direccion', 'label': 'Dirección', 'icon': Icons.home},
      {
        'key': 'numeroIdentificacion',
        'label': 'Número de identificación',
        'icon': Icons.credit_card,
      },
      {'key': 'telefono', 'label': 'Teléfono', 'icon': Icons.phone},
      {'key': 'username', 'label': 'Nombre de usuario', 'icon': Icons.person},
    ];

    return fieldsList.map((field) {
      String value;
      if (field['key'] == 'familiaId') {
        value = _controller.getFamilyName(_familias, usuario['familiaId']);
      } else {
        value = usuario[field['key']]?.toString() ?? 'No disponible';
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              field['icon'] as IconData,
              size: 20,
              color: const Color(0xFF03d069),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getRoleColor(String? role) {
    if (role == null) return Colors.grey;

    switch (role.toLowerCase()) {
      case 'adulto':
        return Colors.blue;
      case 'familiar':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsuariosYFamilias,
        backgroundColor: const Color(0xFF03d069),
        elevation: 4,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF03d069),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
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
        color: const Color(0xFF03d069),
        child: Column(
          children: [
            // Header verde con saludo
            Container(
              padding: const EdgeInsets.only(
                top: 40,
                left: 20,
                right: 20,
                bottom: 15,
              ),
              color: const Color(0xFF03d069),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/homePage');
                        },
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      // Logo más prominente
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                    'lib/pages/images/logo.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Bymax',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hola, Administrador',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Administra tus usuarios',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                    top: Radius.circular(25),
                    bottom: Radius.zero,
                  ),
                ),
                child: Column(
                  children: [
                    // Cabecera con título y filtros
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_alt,
                                color: const Color(0xFF03d069),
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Lista de Usuarios',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          // Filtros por rol
                          const Text(
                            'Filtrar por rol:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildFilterChip('Todos'),
                              const SizedBox(width: 10),
                              _buildFilterChip('Adulto'),
                              const SizedBox(width: 10),
                              _buildFilterChip('Familiar'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Lista de usuarios
                    Expanded(
                      child:
                          _isLoading
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Color(0xFF03d069),
                                      strokeWidth: 3,
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      'Cargando usuarios...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : filteredUsers.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_off,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay usuarios para mostrar',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    if (_errorMessage.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          _errorMessage,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.red[400],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                ),
                              )
                              : Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                thickness: 6,
                                radius: const Radius.circular(10),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    5,
                                    16,
                                    80,
                                  ),
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final usuario = filteredUsers[index];
                                    return _buildUsuarioCard(usuario);
                                  },
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

  // Widget para las tarjetas de usuario
  Widget _buildUsuarioCard(Map<String, dynamic> usuario) {
    final familyName = _controller.getFamilyName(
      _familias,
      usuario['familiaId'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUserDetails(usuario),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                // Avatar circular con icono o primera letra del nombre
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _getRoleColor(
                    usuario['rol'],
                  ).withOpacity(0.2),
                  child: Text(
                    (usuario['nombre'] ?? 'U').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(usuario['rol']),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Información del usuario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        usuario['email'] ?? 'No disponible',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.family_restroom,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            familyName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(
                                usuario['rol'],
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              usuario['rol'] ?? 'Desconocido',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getRoleColor(usuario['rol']),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Icono de chevron para indicar que se puede tocar
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para los chips de filtro
  Widget _buildFilterChip(String label) {
    final isSelected = _filterRole == label;

    return InkWell(
      onTap: () {
        setState(() {
          _filterRole = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF03d069) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: const Color(0xFF03d069).withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(
                  label == 'Todos'
                      ? Icons.people
                      : label == 'Adulto'
                      ? Icons.person
                      : Icons.family_restroom,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para cada icono de la barra de navegación
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
              Navigator.pushReplacementNamed(context, '/homePage');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/addUser');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/settings');
              break;
            case 3:
              try {
                final result = await _controller.signOut();
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor:
                        result['success'] ? Colors.green : Colors.red,
                  ),
                );

                if (result['success']) {
                  Navigator.pushReplacementNamed(context, '/loginPage');
                }
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              size: 24,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
