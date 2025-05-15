import 'package:bymax/controllers/loginController.dart';
import 'package:bymax/pages/activitiesPage.dart';
import 'package:bymax/pages/recordatoryPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class homePage extends StatefulWidget {
  const homePage({super.key});

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  int _selectedIndex = 0;
  // Controlador para el scrollbar
  final ScrollController _scrollController = ScrollController();
  // Variable para almacenar el nombre del usuario
  String _userName = "Usuario";

  @override
  void initState() {
    super.initState();
    // Cargar el nombre del usuario cuando se inicia la pantalla
    _loadUserName();
  }

  // Método para cargar el nombre del usuario desde SharedPreferences
  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('user_name');

      setState(() {
        _userName = savedName ?? "Usuario";
      });
    } catch (e) {
      print('Error al cargar el nombre del usuario: $e');
    }
  }

  @override
  void dispose() {
    // Importante liberar el controlador cuando se destruye el widget
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

                  // Saludo con texto blanco subrayado
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
                          const Text(
                            'Hoy es un día maravilloso',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menú de opciones con fondo blanco
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
                        // Recordatorios - botón vertical
                        _buildMenuItemVertical(
                          icon: Icons.notifications_active,
                          label: 'Recordatorios',
                          color: Colors.amber,
                          textColor: Colors.black,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecordatoryPage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 15),

                        // Actividades - botón vertical
                        _buildMenuItemVertical(
                          icon: Icons.access_time_filled,
                          label: 'Actividades',
                          color: Colors.purple,
                          textColor: Colors.black,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActivitiesPage(),
                              ),
                            );
                          },
                        ),

                        // Puedes añadir más elementos aquí para probar el scroll
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

                        _buildMenuItemVertical(
                          icon: Icons.settings,
                          label: 'Configuración',
                          color: Colors.orange,
                          textColor: Colors.black,
                        ),

                        // Añadir espacio al final para mejor experiencia de desplazamiento
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

  // Nuevo método para crear botones verticales con texto debajo
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
              Navigator.pushReplacementNamed(context, '');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/addUser');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/settings');
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
