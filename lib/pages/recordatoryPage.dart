import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/recordatoryController.dart';
import '../models/recordatoryModel.dart';

class RecordatoryPage extends StatefulWidget {
  const RecordatoryPage({super.key});

  @override
  State<RecordatoryPage> createState() => _RecordatoryPageState();
}

class _RecordatoryPageState extends State<RecordatoryPage> {
  int _selectedIndex = 2;
  // Map para almacenar actividades e íconos
  Map<String, IconData> _activityIcons = {};

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador aquí para asegurar que tenemos toda la información del usuario
    Future.delayed(Duration.zero, () {
      final controller = Provider.of<RecordatoryController>(
        context,
        listen: false,
      );
      // Refrescar la lista de usuarios para asegurar que estén filtrados correctamente
      controller.refreshUsers();
    });
  }

  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecordatoryController(), // Inicializa el controlador
      child: Consumer<RecordatoryController>(
        builder: (context, controller, _) {
          final bool isFamiliarUser = controller.currentUserRole == 'Familiar';

          return Scaffold(
            bottomNavigationBar:
                isFamiliarUser
                    ? null
                    : Container(
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
                              decoration: BoxDecoration(
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
                              child: const Icon(
                                Icons.person,
                                color: Colors.grey,
                              ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child:
                          controller.isLoading
                              ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF03d069),
                                ),
                              )
                              : Column(
                                children: [
                                  Expanded(
                                    child:
                                        controller.recordatories.isEmpty
                                            ? Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .notifications_off_outlined,
                                                    size: 64,
                                                    color: Colors.grey[400],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'No hay recordatorios',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.grey[600],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Agrega un nuevo recordatorio usando el botón inferior',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            : ListView.builder(
                                              itemCount:
                                                  controller
                                                      .recordatories
                                                      .length,
                                              itemBuilder: (context, index) {
                                                final recordatory =
                                                    controller
                                                        .recordatories[index];

                                                // Verificar si el recordatorio fue creado por un familiar
                                                bool isCreatedByFamiliar =
                                                    false;
                                                String creatorName = "Usuario";

                                                // Si el usuario actual es admin y el creatorId es diferente al usuario actual
                                                if (controller
                                                            .currentUserRole ==
                                                        'admin' &&
                                                    recordatory.creatorId !=
                                                        FirebaseAuth
                                                            .instance
                                                            .currentUser
                                                            ?.uid) {
                                                  isCreatedByFamiliar = true;

                                                  // Buscar el nombre del creador en la lista de usuarios
                                                  for (var user
                                                      in controller.users) {
                                                    if (user['id'] ==
                                                        recordatory.creatorId) {
                                                      creatorName =
                                                          user['nombre'] ??
                                                          user['displayName'] ??
                                                          "Familiar";
                                                      break;
                                                    }
                                                  }
                                                }

                                                return Dismissible(
                                                  key: Key(
                                                    recordatory.id.toString(),
                                                  ),
                                                  background: Container(
                                                    color: Colors.red,
                                                    alignment:
                                                        Alignment.centerRight,
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 20,
                                                        ),
                                                    child: const Icon(
                                                      Icons.delete,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  direction:
                                                      DismissDirection
                                                          .endToStart,
                                                  confirmDismiss: (
                                                    direction,
                                                  ) async {
                                                    return await showDialog(
                                                      context: context,
                                                      builder: (
                                                        BuildContext context,
                                                      ) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                            "Confirmar",
                                                          ),
                                                          content: const Text(
                                                            "¿Estás seguro de que quieres eliminar este recordatorio?",
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop(
                                                                        false,
                                                                      ),
                                                              child: const Text(
                                                                "Cancelar",
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop(
                                                                        true,
                                                                      ),
                                                              child: const Text(
                                                                "Eliminar",
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  },
                                                  onDismissed: (direction) {
                                                    controller
                                                        .deleteRecordatory(
                                                          recordatory.id,
                                                        );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          "Recordatorio eliminado",
                                                        ),
                                                        backgroundColor: Color(
                                                          0xFF03d069,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      _showRecordatoryDetails(
                                                        context,
                                                        recordatory,
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 12,
                                                          ),
                                                      child:
                                                          isCreatedByFamiliar
                                                              ? _buildReminderItemWithCreator(
                                                                icon: _getIconForActivity(
                                                                  recordatory
                                                                      .activityId,
                                                                ),
                                                                title:
                                                                    recordatory
                                                                        .title,
                                                                date:
                                                                    recordatory
                                                                        .date,
                                                                isNotificationEnabled:
                                                                    recordatory
                                                                        .isNotificationEnabled,
                                                                onNotificationToggle: () async {
                                                                  await controller
                                                                      .toggleNotification(
                                                                        recordatory
                                                                            .id,
                                                                      );
                                                                },
                                                                creatorName:
                                                                    creatorName,
                                                              )
                                                              : _buildReminderItem(
                                                                icon: _getIconForActivity(
                                                                  recordatory
                                                                      .activityId,
                                                                ),
                                                                title:
                                                                    recordatory
                                                                        .title,
                                                                date:
                                                                    recordatory
                                                                        .date,
                                                                isNotificationEnabled:
                                                                    recordatory
                                                                        .isNotificationEnabled,
                                                                onNotificationToggle: () async {
                                                                  await controller
                                                                      .toggleNotification(
                                                                        recordatory
                                                                            .id,
                                                                      );
                                                                },
                                                              ),
                                                    ),
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
                                      onPressed:
                                          () => _showAddRecordatoryDialog(
                                            context,
                                            controller,
                                          ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF03d069,
                                        ),
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
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
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReminderItem({
    required IconData icon,
    required String title,
    required String date,
    required bool isNotificationEnabled,
    required VoidCallback onNotificationToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              color: Colors.black87,
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
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isNotificationEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: isNotificationEnabled ? Colors.black : Colors.grey,
            ),
            onPressed: onNotificationToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItemWithCreator({
    required IconData icon,
    required String title,
    required String date,
    required bool isNotificationEnabled,
    required VoidCallback onNotificationToggle,
    required String creatorName,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF03d069).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black87,
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
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                // Mostrar quién creó el recordatorio
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Creado por: $creatorName',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isNotificationEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: isNotificationEnabled ? Colors.black : Colors.grey,
            ),
            onPressed: onNotificationToggle,
          ),
        ],
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

  // Función para obtener el ícono correspondiente a una actividad
  IconData _getIconForActivity(String activityId) {
    // Primero revisar si tenemos un ícono personalizado para esta actividad
    if (_activityIcons.containsKey(activityId)) {
      return _activityIcons[activityId]!;
    }

    // Si no, usar iconos por defecto según el ID
    // Podemos mantener algunos iconos predeterminados por si acaso
    switch (activityId) {
      case 'medicina':
        return Icons.medication_outlined;
      case 'actividad':
        return Icons.calendar_month_outlined;
      case 'terapia':
        return Icons.fitness_center_outlined;
      case 'consulta':
        return Icons.local_hospital_outlined;
      case 'ejercicio':
        return Icons.directions_run_outlined;
      case 'comida':
        return Icons.restaurant_outlined;
      default:
        return Icons.event_note;
    }
  }

  void _showRecordatoryDetails(BuildContext context, Recordatory recordatory) {
    // Obtener el controlador
    final controller = Provider.of<RecordatoryController>(
      context,
      listen: false,
    );

    // Obtener el rol del usuario actual
    String? currentUserRole = controller.currentUserRole;

    // Buscar el nombre del usuario destinatario
    String nombreUsuario = "Usuario";
    for (final user in controller.users) {
      if (user['id'] == recordatory.userId) {
        nombreUsuario = user['nombre'] ?? user['displayName'] ?? "Usuario";
        break;
      }
    }

    // Buscar el nombre del creador si es diferente al usuario actual
    String nombreCreador = "Yo";
    bool mostrarCreador = false;

    if (recordatory.creatorId != FirebaseAuth.instance.currentUser?.uid) {
      mostrarCreador = true;
      for (final user in controller.users) {
        if (user['id'] == recordatory.creatorId) {
          nombreCreador = user['nombre'] ?? user['displayName'] ?? "Familiar";
          break;
        }
      }
    }

    // Mostrar el diálogo con detalles del recordatorio
    showDialog(
      context: context,
      builder:
          (context) => FutureBuilder<List<Map<String, dynamic>>>(
            future: controller.getActivities(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AlertDialog(
                  content: Center(
                    child: CircularProgressIndicator(color: Color(0xFF03d069)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return AlertDialog(
                  title: Text(recordatory.title),
                  content: const Text(
                    'Error al cargar la información de la actividad',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                );
              }

              // Buscar la actividad por su ID
              final activities = snapshot.data ?? [];
              final activity = activities.firstWhere(
                (act) => act['id'] == recordatory.activityId,
                orElse: () => {'title': 'Actividad no encontrada'},
              );

              // Obtener el nombre de la actividad
              final activityName =
                  activity['title'] ?? 'Actividad no encontrada';

              return AlertDialog(
                title: Text(recordatory.title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fecha: ${recordatory.date}'),
                    Text('Hora: ${recordatory.time}'),
                    Text('Actividad: $activityName'),
                    Text(
                      'Notificación: ${recordatory.isNotificationEnabled ? "Activada" : "Desactivada"}',
                    ),
                    Text('Usuario: $nombreUsuario'),

                    // Mostrar información del creador si corresponde
                    if (mostrarCreador)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Creado por: $nombreCreador',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),
                    Text(
                      'Repetición: ${_getRepeatText(recordatory.repeat, recordatory.repeatInterval)}',
                    ),
                    if (recordatory.repeat != 'ninguno' &&
                        (recordatory.repeatEndDate != null &&
                            recordatory.repeatEndDate!.isNotEmpty))
                      Text('Repetir hasta: ${recordatory.repeatEndDate}'),

                    // Mostrar información adicional para usuarios
                    if (currentUserRole == 'admin' && mostrarCreador)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber[300]!),
                          ),
                          child: Text(
                            'Este recordatorio fue creado por un usuario Familiar.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[800],
                            ),
                          ),
                        ),
                      ),

                    if (currentUserRole == 'Familiar')
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue[300]!),
                          ),
                          child: Text(
                            'Como usuario Familiar, solo puedes crear y ver recordatorios para usuarios Adulto de tu familia.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Función auxiliar para obtener texto de repetición
  String _getRepeatText(String repeat, int? repeatInterval) {
    switch (repeat) {
      case 'diario':
        return 'Diario';
      case 'semanal':
        return 'Semanal';
      case 'mensual':
        return 'Mensual';
      case 'personalizado':
        return 'Cada $repeatInterval días';
      default:
        return 'Sin repetición';
    }
  }

  Future<void> _showAddRecordatoryDialog(
    BuildContext context,
    RecordatoryController controller,
  ) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _dateController = TextEditingController();
    final TextEditingController _timeController = TextEditingController();
    bool _isNotificationEnabled = true;
    String _selectedActivity = '';
    String _selectedUserId = '';
    String _selectedRepeat = 'ninguno';
    int _repeatInterval = 1;
    String _repeatEndDate = '';

    List<Map<String, dynamic>> activities = await controller.getActivities();

    // Obtener el rol del usuario actual
    final String? currentUserRole = controller.currentUserRole;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Obtener la lista de usuarios disponibles
            List<Map<String, dynamic>> usuarios = controller.getUsers();

            // Verificar si el usuario es Familiar y no hay usuarios adultos disponibles
            if (currentUserRole == 'Familiar' && usuarios.isEmpty) {
              // Mostrar mensaje en la interfaz
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "No hay usuarios adultos en tu familia disponibles para asignar recordatorios.",
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 5),
                  ),
                );
              });
            }

            // Si la lista de usuarios no está vacía, seleccionar el primer usuario por defecto
            if (usuarios.isNotEmpty && _selectedUserId.isEmpty) {
              _selectedUserId = usuarios[0]['id'];
            }

            // Si la lista de actividades no está vacía, seleccionar la primera actividad por defecto
            if (activities.isNotEmpty && _selectedActivity.isEmpty) {
              _selectedActivity = activities[0]['id'];
            }

            return AlertDialog(
              title: const Text('Nuevo Recordatorio'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Título'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa un título';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setState(() {
                              _dateController.text =
                                  "${picked.day}/${picked.month}/${picked.year}";
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona una fecha';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          labelText: 'Hora',
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _timeController.text =
                                  "${picked.hour}:${picked.minute.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona una hora';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value:
                            _selectedActivity.isNotEmpty
                                ? _selectedActivity
                                : null,
                        hint: const Text('Seleccionar actividad'),
                        decoration: const InputDecoration(
                          labelText: 'Actividad asociada',
                        ),
                        items:
                            activities.isNotEmpty
                                ? activities.map((activity) {
                                  return DropdownMenuItem<String>(
                                    value: activity['id'],
                                    child: Text(activity['title']),
                                  );
                                }).toList()
                                : [
                                  const DropdownMenuItem<String>(
                                    value: '',
                                    child: Text(
                                      'No hay actividades disponibles',
                                    ),
                                  ),
                                ],
                        onChanged: (value) {
                          setState(() {
                            _selectedActivity = value ?? '';
                          });
                        },
                        validator: (value) {
                          if (activities.isNotEmpty &&
                              (value == null || value.isEmpty)) {
                            return 'Por favor selecciona una actividad';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value:
                            _selectedUserId.isNotEmpty ? _selectedUserId : null,
                        hint: const Text('Seleccionar usuario'),
                        decoration: const InputDecoration(
                          labelText: 'Asignar a usuario',
                        ),
                        items:
                            usuarios.isNotEmpty
                                ? usuarios.map((user) {
                                  return DropdownMenuItem<String>(
                                    value: user['id'],
                                    child: Text(
                                      user['nombre'] ?? 'Usuario sin nombre',
                                    ),
                                  );
                                }).toList()
                                : [
                                  const DropdownMenuItem<String>(
                                    value: '',
                                    child: Text('No hay usuarios disponibles'),
                                  ),
                                ],
                        onChanged: (value) {
                          setState(() {
                            _selectedUserId = value ?? '';
                          });
                        },
                        validator: (value) {
                          if (usuarios.isNotEmpty &&
                              (value == null || value.isEmpty)) {
                            return 'Por favor selecciona un usuario';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedRepeat,
                        decoration: const InputDecoration(labelText: 'Repetir'),
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'ninguno',
                            child: Text('No repetir'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'diario',
                            child: Text('Diario'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'semanal',
                            child: Text('Semanal'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'mensual',
                            child: Text('Mensual'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRepeat = value ?? 'ninguno';
                          });
                        },
                      ),
                      if (_selectedRepeat != 'ninguno') ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Intervalo',
                                ),
                                keyboardType: TextInputType.number,
                                initialValue: _repeatInterval.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _repeatInterval = int.tryParse(value) ?? 1;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Hasta fecha',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                readOnly: true,
                                controller: TextEditingController(
                                  text: _repeatEndDate,
                                ),
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().add(
                                      const Duration(days: 30),
                                    ),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2101),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _repeatEndDate =
                                          "${picked.day}/${picked.month}/${picked.year}";
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 15),
                      SwitchListTile(
                        title: const Text('Notificar'),
                        value: _isNotificationEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            _isNotificationEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        // Generar un ID único basado en timestamp
                        final recordatoryId =
                            DateTime.now().millisecondsSinceEpoch;

                        await controller.addRecordatory(
                          Recordatory(
                            id: recordatoryId,
                            title: _titleController.text,
                            date: _dateController.text,
                            time: _timeController.text,
                            activityId: _selectedActivity,
                            userId: _selectedUserId,
                            creatorId: '', // Se asignará en el controlador
                            isNotificationEnabled: _isNotificationEnabled,
                            repeat: _selectedRepeat,
                            repeatInterval: _repeatInterval,
                            repeatEndDate: _repeatEndDate,
                          ),
                        );

                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recordatorio creado con éxito'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
