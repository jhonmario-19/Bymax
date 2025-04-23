import 'package:bymax/pages/activitiesPage.dart';
import 'package:bymax/pages/recordatoryPage.dart';
import 'package:flutter/material.dart';

class homePage extends StatefulWidget {
  const homePage({super.key});

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  int _selectedIndex = 2;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Color(0xFF03d069),
          //borderRadius: BorderRadius.circular(12),
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
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            // Corregir la ruta de la imagen - quitar la barra inicial
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
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start, // Alinea los textos a la izquierda
                        children: [
                          const Text(
                            'Hola Usuario',
                            style: TextStyle(
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
                  ), // Bordes redondeados
                  image: const DecorationImage(
                    image: AssetImage('lib/pages/images/patron_homePage.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color.fromARGB(
                        211,
                        200,
                        193,
                        193,
                      ), // Opacidad (ajustable)
                      BlendMode.darken, // Modo de mezcla
                    ),
                  ),
                ),

                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // Asistente IA - botón vertical
                    _buildMenuItemVertical(
                      icon: Icons.mic,
                      label: 'Asistente IA',
                      color: Colors.blue,
                      textColor: Colors.black,
                    ),
                    const SizedBox(height: 15),

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

                    // Espacio para el resto del contenido
                    Expanded(child: Container()),

                    // Removido la barra de navegación de aquí ya que ahora está en bottomNavigationBar
                  ],
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
    VoidCallback? onTap, // ← nuevo parámetro
  }) {
    return GestureDetector(
      onTap: onTap, // ← ejecuta la función al tocar
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
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        // Evitamos navegación si ya estamos en la pantalla actual
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
}
