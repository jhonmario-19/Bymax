import 'package:flutter/material.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  // Índice para controlar qué botón está seleccionado
  int _selectedIndex = 2; // Por defecto seleccionamos Actividades (índice 2)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Agregamos la barra de navegación como propiedad bottomNavigationBar del Scaffold
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
            // Header verde con saludo y botón de regreso
            Container(
              padding: const EdgeInsets.only(top: 30, left: 16, right: 16, bottom: 8),
              color: const Color(0xFF03d069),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón de regreso
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
                  children: [
                    // Título de la sección
                    const Text(
                      'Actividades',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Actividad 1: Caminar
                    _buildActivityItem(
                      icon: Icons.directions_walk,
                      title: 'Caminar',
                      duration: '30 minutos',
                      time: '8:00 AM',
                    ),
                    const SizedBox(height: 12),
                    
                    // Actividad 2: Ejercicios
                    _buildActivityItem(
                      icon: Icons.fitness_center,
                      title: 'Ejercicios',
                      duration: '45 minutos',
                      time: '10:30 AM',
                    ),
                    const SizedBox(height: 12),
                    
                    // Actividad 3: Meditación
                    _buildActivityItem(
                      icon: Icons.self_improvement,
                      title: 'Meditación',
                      duration: '15 minutos',
                      time: '6:00 PM',
                    ),
                    const SizedBox(height: 12),
                    
                    // Actividad 4: Lectura
                    _buildActivityItem(
                      icon: Icons.menu_book,
                      title: 'Lectura',
                      duration: '20 minutos',
                      time: '9:00 PM',
                    ),
                    
                    // Espaciador
                    Expanded(child: Container()),
                    
                    // Botón "AGREGAR ACTIVIDAD"
                    Container(
                      width: 240,
                      height: 45,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF03d069),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'AGREGAR ACTIVIDAD',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    
                    // Eliminamos la barra de navegación de aquí ya que ahora está en bottomNavigationBar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para cada elemento de actividad
  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String duration,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icono en cuadrado púrpura (color similar al de la imagen de actividades)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFAA33CC), // Color púrpura
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Título y detalles de la actividad
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Icono de completado
          Icon(
            Icons.check_circle_outline,
            color: Colors.grey[600],
            size: 24,
          ),
        ],
      ),
    );
  }

  // Widget actualizado para la barra de navegación con selección
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

}