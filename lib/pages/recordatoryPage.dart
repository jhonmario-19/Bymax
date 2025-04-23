import 'package:flutter/material.dart';

class RecordatoryPage extends StatelessWidget {
  const RecordatoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: const Color(0xFF03d069), // Color verde de fondo
        child: Column(
          children: [
            // Header verde con saludo
            Container(
              padding: const EdgeInsets.only(top: 30, left: 16, right: 16, bottom: 8),
              color: const Color(0xFF03d069),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
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
                    // Recordatorio 1: Medicamento
                    _buildReminderItem(
                      icon: Icons.medication_outlined,
                      title: 'Medicamento',
                      date: '2 de marzo 2025',
                    ),
                    const SizedBox(height: 12),
                    
                    // Recordatorio 2: Cita médica
                    _buildReminderItem(
                      icon: Icons.calendar_month_outlined,
                      title: 'cita medica',
                      date: '2 de marzo 2025',
                    ),
                    const SizedBox(height: 12),
                    
                    // Recordatorio 3: Terapia
                    _buildReminderItem(
                      icon: Icons.fitness_center_outlined,
                      title: 'Terapia',
                      date: '3 de marzo 2025',
                    ),
                    
                    // Espaciador
                    Expanded(child: Container()),
                    
                    // Botón "AGREGAR RECORDATORIO"
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
                          'AGREGAR RECORDATORIO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    
                    // Barra de navegación
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF03d069),
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavBarItem(Icons.home),
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

  // Widget para cada elemento de recordatorio
  Widget _buildReminderItem({
    required IconData icon,
    required String title,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icono en cuadrado negro
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Título y fecha
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
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Icono de notificación
          Icon(
            Icons.notifications,
            color: Colors.black,
            size: 24,
          ),
        ],
      ),
    );
  }

  // Widget para cada icono de la barra de navegación
  Widget _buildNavBarItem(IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}