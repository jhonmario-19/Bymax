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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) =>
              RecordatoryController(), // Inicializa el controlador con Firebase
      child: Scaffold(
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
                  child: Consumer<RecordatoryController>(
                    builder: (context, controller, child) {
                      // Mostrar indicador de carga si está cargando datos
                      if (controller.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF03d069),
                          ),
                        );
                      }

                      return Column(
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
                                            Icons.notifications_off_outlined,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No hay recordatorios',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
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
                                          controller.recordatories.length,
                                      itemBuilder: (context, index) {
                                        final recordatory =
                                            controller.recordatories[index];
                                        return Dismissible(
                                          key: Key(recordatory.id.toString()),
                                          background: Container(
                                            color: Colors.red,
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                              right: 20,
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                            ),
                                          ),
                                          direction:
                                              DismissDirection.endToStart,
                                          confirmDismiss: (direction) async {
                                            return await showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
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
                                                          () => Navigator.of(
                                                            context,
                                                          ).pop(false),
                                                      child: const Text(
                                                        "Cancelar",
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.of(
                                                            context,
                                                          ).pop(true),
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
                                            controller.deleteRecordatory(
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
                                              padding: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: _buildReminderItem(
                                                icon: _getIconForActivity(
                                                  recordatory.activityId,
                                                ),
                                                title: recordatory.title,
                                                date: recordatory.date,
                                                isNotificationEnabled:
                                                    recordatory
                                                        .isNotificationEnabled,
                                                onNotificationToggle: () async {
                                                  await controller
                                                      .toggleNotification(
                                                        recordatory.id,
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

    // Buscar el nombre del usuario
    String nombreUsuario = "Usuario";
    for (final user in controller.users) {
      if (user['id'] == recordatory.userId) {
        nombreUsuario = user['nombre'] ?? user['displayName'] ?? "Usuario";
        break;
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
                    const SizedBox(height: 8),
                    Text(
                      'Repetición: ${_getRepeatText(recordatory.repeat, recordatory.repeatInterval)}',
                    ),
                    if (recordatory.repeat != 'ninguno' &&
                        (recordatory.repeatEndDate != null &&
                            recordatory.repeatEndDate!.isNotEmpty))
                      Text('Repetir hasta: ${recordatory.repeatEndDate}'),
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

  // Modifica el método _showAddRecordatoryDialog para solucionar el desbordamiento
  void _showAddRecordatoryDialog(
    BuildContext context,
    RecordatoryController controller,
  ) {
    final titleController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    String? selectedActivityId;
    String? selectedUserId;
    TimeOfDay? selectedTime;
    List<Map<String, dynamic>> activities = [];
    bool isLoadingActivities = true;

    // Cargar actividades desde Firebase
    controller
        .getActivities()
        .then((fetchedActivities) {
          activities = fetchedActivities;
          isLoadingActivities = false;
          // Actualizar estado si el diálogo está abierto
          if (Navigator.of(context).canPop()) {
            (context as Element).markNeedsBuild();
          }
        })
        .catchError((error) {
          print('Error al cargar actividades: $error');
          isLoadingActivities = false;
        });

    // Campos para repetición
    String selectedRepeat = 'ninguno';
    int? repeatInterval;
    final repeatEndDateController = TextEditingController();

    // Obtenemos la lista de usuarios del controlador
    List<Map<String, dynamic>> usuarios = controller.getUsers();

    // Si no hay usuarios cargados, mostrar un mensaje
    if (usuarios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cargando lista de usuarios..."),
          backgroundColor: Colors.orange,
        ),
      );
      // Intentar cargar los usuarios
      controller.refreshUsers().then((_) {
        // Si ya está abierto el diálogo, actualizamos la lista
        usuarios = controller.getUsers();
      });
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              // Actualizamos la lista de usuarios dentro del StatefulBuilder
              usuarios = controller.getUsers();

              return Dialog(
                // Usar Dialog en lugar de AlertDialog para tener más control
                insetPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width:
                      MediaQuery.of(context).size.width *
                      0.9, // Ancho controlado
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context).size.height *
                        0.8, // Altura máxima
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título del diálogo
                        const Text(
                          'Nuevo Recordatorio',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contenido con scroll
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Título',
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Dropdown para seleccionar usuario - Corregido para evitar desbordamiento
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Usuario',
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  hint: const Text('Selecciona un usuario'),
                                  value: selectedUserId,
                                  isExpanded:
                                      true, // Importante: evita desbordamiento
                                  items:
                                      usuarios.map<DropdownMenuItem<String>>((
                                        usuario,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: usuario['id']?.toString(),
                                          child: Text(
                                            (usuario['nombre'] ??
                                                usuario['username'] ??
                                                'Usuario sin nombre'),
                                            overflow:
                                                TextOverflow
                                                    .ellipsis, // Trunca texto largo
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedUserId = value;
                                    });
                                  },
                                ),

                                const SizedBox(height: 16),
                                TextField(
                                  controller: dateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Fecha',
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  readOnly: true,
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2025, 12, 31),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        dateController.text =
                                            "${date.day}/${date.month}/${date.year}";
                                      });
                                    }
                                  },
                                ),

                                const SizedBox(height: 16),
                                TextField(
                                  controller: timeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Hora',
                                    prefixIcon: Icon(Icons.access_time),
                                  ),
                                  readOnly: true,
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setState(() {
                                        timeController.text = time.format(
                                          context,
                                        );
                                        selectedTime = time;
                                      });
                                    }
                                  },
                                ),

                                const SizedBox(height: 16),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: controller.getActivities(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF03d069),
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return const Text(
                                        'Error al cargar actividades',
                                      );
                                    }

                                    final activities = snapshot.data ?? [];

                                    return DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Actividad',
                                        prefixIcon: Icon(Icons.category),
                                      ),
                                      hint: const Text(
                                        'Selecciona una actividad',
                                      ),
                                      value: selectedActivityId,
                                      isExpanded:
                                          true, // Importante: evita desbordamiento
                                      items:
                                          activities.map((activity) {
                                            return DropdownMenuItem<String>(
                                              value: activity['id'],
                                              child: Text(
                                                activity['title'] ??
                                                    'Sin título',
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis, // Trunca texto largo
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedActivityId = value;
                                        });
                                      },
                                    );
                                  },
                                ),

                                // --- Campos de repetición ---
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Repetir',
                                    prefixIcon: Icon(Icons.repeat),
                                  ),
                                  value: selectedRepeat,
                                  isExpanded:
                                      true, // Importante: evita desbordamiento
                                  items: [
                                    DropdownMenuItem(
                                      value: 'ninguno',
                                      child: Text('No repetir'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'diario',
                                      child: Text('Todos los días'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'semanal',
                                      child: Text('Cada semana'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'personalizado',
                                      child: Text('Personalizado'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedRepeat = value!;
                                    });
                                  },
                                ),

                                if (selectedRepeat == 'personalizado')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Cada cuántos días',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        repeatInterval = int.tryParse(value);
                                      },
                                    ),
                                  ),

                                const SizedBox(height: 16),
                                TextField(
                                  controller: repeatEndDateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Repetir hasta (opcional)',
                                    prefixIcon: Icon(Icons.event_available),
                                  ),
                                  readOnly: true,
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2100),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        repeatEndDateController.text =
                                            "${date.day}/${date.month}/${date.year}";
                                      });
                                    }
                                  },
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),

                        // Botones
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF03d069),
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () async {
                                if (titleController.text.isNotEmpty &&
                                    dateController.text.isNotEmpty &&
                                    timeController.text.isNotEmpty &&
                                    selectedUserId != null &&
                                    selectedActivityId != null) {
                                  // Mostrar indicador de carga mientras se agrega
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF03d069),
                                        ),
                                      );
                                    },
                                  );

                                  try {
                                    // Usar await para la operación asíncrona
                                    await controller.addRecordatory(
                                      Recordatory(
                                        id:
                                            DateTime.now()
                                                .millisecondsSinceEpoch,
                                        title: titleController.text,
                                        date: dateController.text,
                                        activityId: selectedActivityId!,
                                        time: timeController.text,
                                        userId: selectedUserId!,
                                        creatorId: '',
                                        isNotificationEnabled: true,
                                        repeat: selectedRepeat,
                                        repeatInterval: repeatInterval ?? 0,
                                        repeatEndDate:
                                            repeatEndDateController
                                                    .text
                                                    .isNotEmpty
                                                ? repeatEndDateController.text
                                                : '',
                                      ),
                                    );

                                    // Cerrar el diálogo de carga
                                    Navigator.pop(context);

                                    // Cerrar el diálogo de agregar recordatorio
                                    Navigator.pop(context);

                                    // Mostrar mensaje de éxito
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Recordatorio guardado correctamente",
                                        ),
                                        backgroundColor: Color(0xFF03d069),
                                      ),
                                    );
                                  } catch (e) {
                                    // Cerrar el diálogo de carga
                                    Navigator.pop(context);

                                    // Mostrar mensaje de error
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Error al guardar: $e"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Por favor completa todos los campos",
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}
