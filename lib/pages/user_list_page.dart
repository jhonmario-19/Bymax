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

  // Lista para almacenar los usuarios
  List<Map<String, dynamic>> _usuarios = [];
  // Mapa para almacenar familias por id
  Map<String, String> _familias = {};
  bool _isLoading = true;
  String _errorMessage = '';
  String _filterRole = 'Todos'; // Filtro por defecto

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
      // Primero verificamos si el usuario tiene acceso de administrador
      bool isAdmin = await _controller.verifyAdminAccess();
      if (!isAdmin && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No tienes permisos de administrador';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes permisos de administrador'))
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/homePage');
        });
        return;
      }
      
      // Usamos directamente el método del controlador
      final result = await _controller.loadUsersAndFamilies();
      
      if (!mounted) return;
      
      if (result['success']) {
        setState(() {
          _usuarios = List<Map<String, dynamic>>.from(result['usuarios']);
          _familias = Map<String, String>.from(result['familias']);
          _isLoading = false;
          
          // Mostrar información de depuración
          print("Usuarios cargados: ${_usuarios.length}");
          if (_usuarios.isEmpty) {
            _errorMessage = 'No se encontraron usuarios creados por este administrador';
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
        SnackBar(content: Text('Error al cargar usuarios: $e')),
      );
      // Redirigir al home si no hay permisos
      if (e.toString().contains("No tienes permisos")) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/homePage');
        });
      }
    }
  }

  // Método para filtrar usuarios por rol
  List<Map<String, dynamic>> _getFilteredUsers() {
    return _controller.filterUsersByRole(_usuarios, _filterRole);
  }

  // Función para mostrar información del usuario en una tarjeta más detallada
  void _showUserDetails(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(usuario['nombre'] ?? 'Sin nombre'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${usuario['id']}'),
              Text('Email: ${usuario['email'] ?? 'No disponible'}'),
              Text('Rol: ${usuario['rol'] ?? 'No definido'}'),
              Text('Familia: ${_controller.getFamilyName(_familias, usuario['familiaId'])}'),
              Text('Creado por: ${usuario['createdBy'] ?? 'No definido'}'),
              // Mostrar todos los campos disponibles
              const SizedBox(height: 16),
              const Text('Información adicional:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...usuario.entries
                  .where((entry) => !['id', 'email', 'rol', 'familiaId', 'createdBy', 'nombre'].contains(entry.key))
                  .map((entry) => Text('${entry.key}: ${entry.value}')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar usuarios según el rol seleccionado
    final filteredUsers = _getFilteredUsers();

    return Scaffold(
      // Botón para recargar
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsuariosYFamilias,
        backgroundColor: const Color(0xFF03d069),
        child: const Icon(Icons.refresh),
      ),
      // Barra de navegación inferior
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(color: Color(0xFF03d069)),
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
                            'Hola Administrador,',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'Administra tus usuarios',
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
                child: Column(
                  children: [
                    // Cabecera con título y filtros
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título de la sección
                          const Center(
                            child: Text(
                              'Lista de Usuarios',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Filtros por rol
                          Row(
                            children: [
                              const Text(
                                'Filtrar por: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip('Todos'),
                              const SizedBox(width: 4),
                              _buildFilterChip('Adulto'),
                              const SizedBox(width: 4),
                              _buildFilterChip('Familiar'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Lista de usuarios
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF03d069),
                              ),
                            )
                          : filteredUsers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'No hay usuarios para mostrar',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      if (_errorMessage.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            'Detalle: $_errorMessage',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.red,
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
                                    padding: const EdgeInsets.all(16),
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
    final familyName = _controller.getFamilyName(_familias, usuario['familiaId']);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showUserDetails(usuario),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario['nombre'] ?? 'Sin nombre',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Email: ${usuario['email'] ?? 'No disponible'}'),
              Text('Familia: $familyName'),
              Text('Rol: ${usuario['rol'] ?? 'Desconocido'}'),
              // Añadir indicador de creador
              Text(
                'Creado por: ${usuario['createdBy'] != null ? (usuario['createdBy'] == UserController.auth.currentUser?.uid ? 'Tí' : 'Otro admin') : 'Desconocido'}',
                style: TextStyle(
                  fontSize: 12,
                  color: usuario['createdBy'] == UserController.auth.currentUser?.uid 
                      ? Colors.green 
                      : Colors.grey,
                ),
              ),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF03d069) : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
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
                    backgroundColor: result['success'] ? Colors.green : Colors.red,
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