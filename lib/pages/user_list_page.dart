import 'package:flutter/material.dart';
import '../controllers/FirebaseController.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final ScrollController _scrollController = ScrollController();

  // Lista para almacenar los usuarios
  List<Map<String, dynamic>> _usuarios = [];
  // Mapa para almacenar familias por id
  Map<String, String> _familias = {};
  bool _isLoading = true;
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
    setState(() {
      _isLoading = true;
    });

    try {
      // Recargar el rol del usuario actual
      String currentRole = await FirebaseController.reloadCurrentUserRole();
      if (currentRole != FirebaseController.ROLE_ADMIN) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solo los administradores pueden ver esta información',
            ),
          ),
        );
        Navigator.pushReplacementNamed(context, '/homePage');
        return;
      }

      // Obtener el usuario actual
      final currentUser = FirebaseController.auth.currentUser;
      if (currentUser == null) {
        throw Exception("No se encontró al usuario actual.");
      }

      // Obtener usuarios creados por el administrador actual
      List<Map<String, dynamic>> usuarios =
          await FirebaseController.getUsersCreatedByAdmin(currentUser.uid);

      // Obtener todas las familias
      Map<String, String> familias = await FirebaseController.getFamilies();

      setState(() {
        _usuarios = usuarios;
        _familias = familias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar usuarios y familias: $e')),
      );
    }
  }

  // Método para filtrar usuarios por rol
  List<Map<String, dynamic>> _getFilteredUsers() {
    if (_filterRole == 'Todos') {
      return _usuarios;
    } else {
      return _usuarios.where((user) => user['rol'] == _filterRole).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar usuarios según el rol seleccionado
    final filteredUsers = _getFilteredUsers();

    return Scaffold(
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
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(10),
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
                        child:
                            _isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF03d069),
                                  ),
                                )
                                : filteredUsers.isEmpty
                                ? const Center(
                                  child: Text('No hay usuarios para mostrar'),
                                )
                                : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final usuario = filteredUsers[index];
                                    // Obtener nombre de familia o usar placeholder
                                    final familyName =
                                        usuario['familiaId'] != null
                                            ? _familias[usuario['familiaId']] ??
                                                'Familia desconocida'
                                            : 'Sin familia';

                                    return _buildUsuarioCard(
                                      usuario,
                                      familyName,
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para las tarjetas de usuario
  Widget _buildUsuarioCard(Map<String, dynamic> usuario, String familyName) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Text('Familia: $familyName'),
            Text('Rol: ${usuario['rol'] ?? 'Desconocido'}'),
          ],
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
    return GestureDetector(
      onTap: () {
        // Implementar navegación según el índice
      },
      child: Icon(icon),
    );
  }
}
