import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../controllers/recordatoryController.dart';
import '../controllers/loginController.dart';
import '../models/recordatoryModel.dart';
import '../services/tts_service.dart';
import '../services/notification_service.dart';

class AdultHomePages extends StatefulWidget {
  const AdultHomePages({Key? key}) : super(key: key);

  @override
  State<AdultHomePages> createState() => _AdultHomePageState();
}

class _AdultHomePageState extends State<AdultHomePages> {
  String? userName;
  bool _loadingUser = true;
  final ScrollController _scrollController = ScrollController();
  final TTSService _ttsService = TTSService();
  int? _speakingRecordatoryId;
  bool _isInitialized = false; // Bandera para controlar la inicialización
  String? _debugUserId; // Para depuración
  Timer? _periodicCheckTimer;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _initLocalNotifications();
    _configureNotifications();
    _startPeriodicCheck();
    _checkForMissedNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadUserInfo();
      _isInitialized = true;
    }
  }

  Future<void> _initLocalNotifications() async {
    await _notificationService.init();
  }

  void _startPeriodicCheck() {
    // Verificar cada minuto si hay recordatorios que deban activarse
    _periodicCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkCurrentTimeRecordatories();
    });
  }

  Future<void> _initializeApp() async {
    await _loadUserInfo();
    _setupForegroundNotificationHandling();
  }

  void _checkCurrentTimeRecordatories() async {
    if (!mounted) return;

    final recordatoryController = Provider.of<RecordatoryController>(
      context,
      listen: false,
    );

    final now = DateTime.now();
    final currentTimeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final currentDateString =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    // Filtrar recordatorios no leídos que coincidan con la fecha/hora actual
    final activeRecordatories =
        recordatoryController.recordatories
            .where(
              (r) =>
                  !r.isRead &&
                  r.date == currentDateString &&
                  r.time == currentTimeString,
            )
            .toList();

    if (activeRecordatories.isNotEmpty) {
      // Ordenar por ID (asumimos que IDs mayores son más recientes)
      activeRecordatories.sort((a, b) => b.id.compareTo(a.id));

      final mostRecent = activeRecordatories.first;
      _speakRecordatoryAsAlarm(mostRecent);

      // Marcar como leído
      recordatoryController.markRecordatoryAsRead(mostRecent.id);
    }
  }

  void _speakRecordatoryAsAlarm(Recordatory recordatory) async {
    // Construir el texto para hablar
    String textToSpeak =
        "¡Atención! Recordatorio importante: ${recordatory.title}. ";
    textToSpeak += "Fecha: ${recordatory.date}. ";
    textToSpeak += "Hora: ${recordatory.time}.";

    // Actualizar el estado y hablar en modo alarma
    setState(() {
      _speakingRecordatoryId = recordatory.id;
    });

    // Usar el nuevo método de TTS para reproducir como alarma
    await _ttsService.speakAsAlarm(textToSpeak);

    // Cuando termina, actualizar estado
    if (!_ttsService.isSpeaking && mounted) {
      setState(() {
        _speakingRecordatoryId = null;
      });
    }
  }

  void _scrollToRecordatory(Recordatory recordatory) {
    final recordatoryController = Provider.of<RecordatoryController>(
      context,
      listen: false,
    );

    // Encontrar índice del recordatorio
    final index = recordatoryController.recordatories.indexOf(recordatory);
    if (index != -1) {
      // Calcular posición aproximada
      final itemHeight = 120.0; // Altura estimada del elemento de recordatorio
      final offset = index * itemHeight;

      // Desplazar con animación
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // Configurar permisos de notificaciones
  Future<void> _configureNotifications() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      setState(() {});
    });
  }

  Future<void> _checkForMissedNotifications() async {
    try {
      final recordatoryController = Provider.of<RecordatoryController>(
        context,
        listen: false,
      );

      // Verificar notificaciones pendientes de Firebase
      await recordatoryController.checkPendingNotifications();

      // Reprogramar notificaciones locales si es necesario
      if (recordatoryController.recordatories.isNotEmpty) {
        await recordatoryController.rescheduleAllNotifications();
      }
    } catch (e) {
      print('Error al verificar notificaciones perdidas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar notificaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Inicializar el servicio TTS
  Future<void> _initializeTTS() async {
    await _ttsService.initTTS();
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    _scrollController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      setState(() {
        _loadingUser = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _debugUserId = user.uid;
        print('ID del usuario actual: ${user.uid}');

        final userDoc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .get();

        if (mounted) {
          setState(() {
            userName = userDoc.data()?['nombre'] ?? 'Usuario';
          });

          final recordatoryController = Provider.of<RecordatoryController>(
            context,
            listen: false,
          );

          // Cargar recordatorios y verificar notificaciones
          await Future.wait([
            recordatoryController.fetchRecordatoriesForUser(user.uid),
            _checkForMissedNotifications(), // Verificación añadida aquí
          ]);

          print(
            'Recordatorios cargados: ${recordatoryController.recordatories.length}',
          );

          setState(() {
            _loadingUser = false;
          });
        }
      } else {
        setState(() {
          _loadingUser = false;
        });
      }
    } catch (e) {
      print('Error al cargar datos: $e');
      if (mounted) {
        setState(() {
          _loadingUser = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método para forzar recarga de recordatorios (útil para depuración)
  Future<void> _refreshRecordatorios() async {
    try {
      setState(() {
        _loadingUser = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final recordatoryController = Provider.of<RecordatoryController>(
          context,
          listen: false,
        );

        // Intentar ambos métodos para encontrar recordatorios
        await recordatoryController.fetchRecordatoriesForUser(user.uid);
        await recordatoryController.rescheduleAllNotifications();
      }

      setState(() {
        _loadingUser = false;
      });
    } catch (e) {
      print('Error al recargar recordatorios: $e');
      setState(() {
        _loadingUser = false;
      });
    }
  }

  void _setupForegroundNotificationHandling() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Verificar notificaciones pendientes cuando llega una nueva
      await _checkForMissedNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nuevo recordatorio: ${message.notification?.title ?? ""}',
            ),
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () {
                final recordatoryId = int.tryParse(
                  message.data['recordatoryId'] ?? '',
                );
                if (recordatoryId != null) {
                  _handleNotificationTap(recordatoryId);
                }
              },
            ),
          ),
        );
      }
    });
  }

  void _speakRecordatory(Recordatory recordatory) async {
    // Si ya estamos hablando, detener primero
    if (_ttsService.isSpeaking) {
      await _ttsService.stop();

      // Si es el mismo recordatorio, solo detener
      if (_speakingRecordatoryId == recordatory.id) {
        setState(() {
          _speakingRecordatoryId = null;
        });
        return;
      }
    }

    // Construir el texto para hablar
    String textToSpeak = "Recordatorio: ${recordatory.title}. ";
    textToSpeak += "Fecha: ${recordatory.date}. ";
    textToSpeak += "Hora: ${recordatory.time}.";

    // Actualizar el estado y hablar
    setState(() {
      _speakingRecordatoryId = recordatory.id;
    });

    // Marcar como leído si no lo está
    final recordatoryController = Provider.of<RecordatoryController>(
      context,
      listen: false,
    );
    if (!recordatory.isRead) {
      recordatoryController.markRecordatoryAsRead(recordatory.id);
    }

    await _ttsService.speak(textToSpeak);

    // Cuando termina de hablar, actualizar el estado
    if (!_ttsService.isSpeaking && mounted) {
      setState(() {
        _speakingRecordatoryId = null;
      });
    }
  }

  void _handleNotificationTap(int recordatoryId) {
    // Buscar el recordatorio en la lista
    final recordatoryController = Provider.of<RecordatoryController>(
      context,
      listen: false,
    );

    final recordatory = recordatoryController.recordatories.firstWhere(
      (r) => r.id == recordatoryId,
      orElse:
          () => Recordatory(
            id: -1,
            title: '',
            date: '',
            time: '',
            activityId: '',
            userId: '',
            creatorId: '',
          ),
    );

    if (recordatory.id != -1) {
      // Marcar como leído y reproducir audio
      recordatoryController.markRecordatoryAsRead(recordatory.id);
      _speakRecordatory(recordatory);

      // Opcional: desplazar hasta el recordatorio en la lista
      final index = recordatoryController.recordatories.indexOf(recordatory);
      if (index != -1) {
        // Calcular la posición aproximada
        final scrollOffset =
            index * 100.0; // Ajusta según la altura del elemento

        // Desplazar con animación
        _scrollController.animateTo(
          scrollOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prevenir cambios no deseados al RecordatoryController dentro de build
    final recordatoryController = Provider.of<RecordatoryController>(
      context,
      listen: true,
    );

    return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(color: Color(0xFF03d069)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
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
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Color(0xFF03d069)),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 24),
              ),
            ),
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
                      const Spacer(),
                    ],
                  ),

                  // Saludo con texto blanco
                  const SizedBox(height: 15),
                  _loadingUser
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: Color(0xFF03d069)),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola $userName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                'Bienvenido a tus recordatorios',
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

            // Contenido principal con fondo blanco
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.zero,
                  ),
                  image: DecorationImage(
                    image: AssetImage('lib/pages/images/patron_homePage.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color.fromARGB(211, 200, 193, 193),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(10),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mis Recordatorios',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                // Botón de actualizar
                                IconButton(
                                  icon: Icon(
                                    Icons.refresh,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: _refreshRecordatorios,
                                  tooltip: 'Actualizar recordatorios',
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message:
                                      'Pulsa en un recordatorio para escucharlo',
                                  child: Icon(
                                    Icons.volume_up,
                                    color: Colors.grey[600],
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Lista de recordatorios con un contenedor que evite reconstrucción innecesaria
                        recordatoryController.isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF03d069),
                              ),
                            )
                            : recordatoryController.recordatories.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No tienes recordatorios asignados',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Mostrar información de depuración en modo desarrollo
                                  if (_debugUserId != null)
                                    Text(
                                      'ID usuario: $_debugUserId',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  recordatoryController.recordatories.length,
                              itemBuilder: (context, index) {
                                final rec =
                                    recordatoryController.recordatories[index];
                                final isSpeaking =
                                    _speakingRecordatoryId == rec.id;
                                final isUnread = !rec.isRead;

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  color:
                                      isUnread
                                          ? const Color(0xFFFFF9C4)
                                          : (isSpeaking
                                              ? const Color(0xFFE1F5FE)
                                              : Colors.white),
                                  child: InkWell(
                                    onTap: () {
                                      // Si no está leído, marcarlo como leído
                                      if (isUnread) {
                                        recordatoryController
                                            .markRecordatoryAsRead(rec.id);
                                      }
                                      _speakRecordatory(rec);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      children: [
                                        ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 15,
                                                vertical: 10,
                                              ),
                                          leading: CircleAvatar(
                                            backgroundColor: const Color(
                                              0xFF03d069,
                                            ),
                                            child:
                                                isSpeaking
                                                    ? const Icon(
                                                      Icons.volume_up,
                                                      color: Colors.white,
                                                    )
                                                    : const Icon(
                                                      Icons
                                                          .notifications_active,
                                                      color: Colors.white,
                                                    ),
                                          ),
                                          title: Text(
                                            rec.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.calendar_today,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    rec.date,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  const Icon(
                                                    Icons.access_time,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    rec.time,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing:
                                              isSpeaking
                                                  ? const Icon(
                                                    Icons.pause,
                                                    color: Color(0xFF03d069),
                                                  )
                                                  : const Icon(
                                                    Icons.volume_up_outlined,
                                                  ),
                                        ),
                                        if (!isSpeaking)
                                          Positioned(
                                            right: 12,
                                            bottom: 12,
                                            child: Text(
                                              'Tocar para escuchar',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        if (isUnread)
                                          Positioned(
                                            right: 10,
                                            top: 10,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
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
}
