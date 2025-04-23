import 'package:bymax/pages/recordatoryPage.dart';
import 'package:flutter/material.dart';

class homePage extends StatelessWidget {
  const homePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: const Color(0xFF03d069),
        child: Column(
          children: [
            // Barra de estado personalizada + Encabezado verde
            Container(
              padding: const EdgeInsets.only(top: 30, left: 16, right: 16, bottom: 8),
              color: const Color(0xFF03d069),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const SizedBox(height: 25),
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
                      const Spacer(),
                      
                    ],
                  ),
                  
                  // Saludo con texto blanco subrayado
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      const SizedBox(width: 10), // Espacio entre avatar y texto
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Alinea los textos a la izquierda
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
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
                ),// Bordes redondeados
                  image: const DecorationImage(
                    image: AssetImage('lib/pages/images/patron_homePage.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color.fromARGB(211, 200, 193, 193), // Opacidad (ajustable)
                      BlendMode.darken, // Modo de mezcla
                    ),
                  ),
                ),

                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    // Asistente IA - botón vertical
                    _buildMenuItemVertical(
                      icon: Icons.mic,
                      label: 'Asistente IA',
                      color: Colors.blue,
                      textColor: Colors.black,
                      
                    ),
                    const SizedBox(height: 20),
                    
                    // Recordatorios - botón vertical
                    _buildMenuItemVertical(
                      icon: Icons.notifications_active,
                      label: 'Recordatorios',
                      color: Colors.amber,
                      textColor: Colors.black,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RecordatoryPage()),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    
                    // Actividades - botón vertical
                    _buildMenuItemVertical(
                      icon: Icons.access_time_filled,
                      label: 'Actividades',
                      color: Colors.purple,
                      textColor: Colors.black,
                      
                      
                    ),
                    
                    // Espacio para el resto del contenido
                    Expanded(child: Container()),
                    
                    //Barra de navegación inferior simplificada
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavBarItem(Icons.home, isSelected: true),
                          _buildNavBarItem(Icons.chat_bubble_outline),
                          _buildNavBarItem(Icons.settings),
                          _buildNavBarItem(Icons.menu),
                        ],
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
            child: Icon(
              icon,
              color: Colors.white,
              size: 60,
            ),
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


  Widget _buildNavBarItem(IconData icon, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: isSelected ? const Color(0xFF00A86B) : Colors.grey,
        size: 24,
      ),
    );
  }
}