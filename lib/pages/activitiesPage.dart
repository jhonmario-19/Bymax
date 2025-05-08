import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/activityController.dart';
import '../models/activitiesModel.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActivityController(),
      child: Scaffold(
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
          color: const Color(0xFF03d069),
          child: Column(
            children: [
              // Header
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
                          children: const [
                            Text(
                              'Hola Usuario,',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
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
              // Contenido principal
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                      bottom: Radius.zero,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Consumer<ActivityController>(
                    builder: (context, controller, child) {
                      if (controller.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Column(
                        children: [
                          const Text(
                            'Actividades',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child:
                                controller.activities.isEmpty
                                    ? const Center(
                                      child: Text(
                                        'No hay actividades registradas',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                    : ListView.builder(
                                      itemCount: controller.activities.length,
                                      itemBuilder: (context, index) {
                                        final activity =
                                            controller.activities[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _buildActivityItem(
                                            icon: Icons.event_note,
                                            title: activity.title,
                                            description: activity.description,
                                            duration: activity.date,
                                            time: activity.time,
                                            onDelete: () async {
                                              await controller.deleteActivity(
                                                activity.id,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                          ),
                          Container(
                            width: 240,
                            height: 45,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: ElevatedButton(
                              onPressed: () => _showAddActivityDialog(context),
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
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para cada elemento de actividad
  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String description,
    required String duration,
    required String time,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFAA33CC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
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
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.schedule, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  void _showAddActivityDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Nueva Actividad'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Fecha'),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: dialogContext,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        dateController.text =
                            "${date.day}/${date.month}/${date.year}";
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(labelText: 'Hora'),
                    readOnly: true,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        timeController.text = time.format(dialogContext);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty &&
                      dateController.text.isNotEmpty &&
                      timeController.text.isNotEmpty) {
                    try {
                      final activity = Activity(
                        id: '', // Se asigna en Firestore
                        title: titleController.text,
                        description: descriptionController.text,
                        date: dateController.text,
                        time: timeController.text,
                        userId: '', // Se asigna en el controlador
                      );

                      // Usar el Provider.of del contexto original, no del diálogo
                      final controller = Provider.of<ActivityController>(
                        context,
                        listen: false,
                      );

                      await controller.addActivity(activity);

                      // Cerrar el diálogo después de la operación exitosa
                      Navigator.of(dialogContext).pop();

                      // Mostrar mensaje de éxito
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Actividad agregada correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      // Mostrar mensaje de error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error al guardar la actividad: ${e.toString()}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      print('Error al guardar actividad: $e');
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Completa todos los campos obligatorios'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  // Barra de navegación
  Widget _buildNavBarItem(IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
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
