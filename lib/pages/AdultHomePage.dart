import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vibration/vibration.dart';
import '../controllers/recordatoryController.dart';
import '../controllers/loginController.dart';
import '../models/recordatoryModel.dart';
import '../services/tts_service.dart';
import '../services/notification_service.dart';
import 'package:bymax/main.dart';

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
  bool _isInitialized = false;
  String? _debugUserId;
  Timer? _periodicCheckTimer;
  final NotificationService _notificationService = NotificationService();
  Map<int, int> _recordatoryRepeatCount = {};
  Map<int, Timer?> _repeatTimers = {};
  bool _manualRefreshExecuted = false;

  Set<String> _processedRecordatoriesKeys = {};

  bool _isRepeatingStopped = false;
  bool _manualStopRequested = false;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _initLocalNotifications();
    _configureNotifications();
    _startPeriodicCheck();
    //_checkForMissedNotifications();
    _registrarTokenSiEsNecesario();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App abierta desde notificación: ${message.data}');
      _forceRefreshAndCheck();
    });
  }

  void _registrarTokenSiEsNecesario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await registrarTokenFCM(user.uid, token);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await registrarTokenFCM(user.uid, newToken);
      });
    }
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
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      print('⏰ Verificación periódica ejecutándose...');
      _checkCurrentTimeRecordatories();
    });
  }

  Future<void> _initializeApp() async {
    await _loadUserInfo();
    _setupForegroundNotificationHandling();
  }

  Future<void> _forceRefreshAndCheck() async {
    print('🔄 Forzando actualización y verificación...');
    await _refreshRecordatorios();
    _checkCurrentTimeRecordatories();
  }

  String _generateRecordatoryKey(Recordatory recordatory) {
    return '${recordatory.id}_${recordatory.date}_${recordatory.time}';
  }

  bool _shouldProcessRecordatory(Recordatory recordatory, DateTime now) {
    // Generar clave única
    final key = _generateRecordatoryKey(recordatory);

    // Si ya fue procesado, no procesarlo de nuevo
    if (_processedRecordatoriesKeys.contains(key)) {
      return false;
    }

    // Parsear la fecha y hora del recordatorio
    try {
      final dateParts = recordatory.date.split('/');
      final timeParts = recordatory.time.split(':');

      if (dateParts.length != 3 || timeParts.length != 2) {
        return false;
      }

      final recordatoryDateTime = DateTime(
        int.parse(dateParts[2]), // año
        int.parse(dateParts[1]), // mes
        int.parse(dateParts[0]), // día
        int.parse(timeParts[0]), // hora
        int.parse(timeParts[1]), // minuto
      );

      // Si el recordatorio es de una fecha/hora pasada (más de 2 minutos), no procesarlo
      final timeDifference = now.difference(recordatoryDateTime);
      if (timeDifference.inMinutes > 2) {
        print(
          '⚠️ Recordatorio demasiado antiguo: ${recordatory.title} - ${timeDifference.inMinutes} minutos de diferencia',
        );
        return false;
      }

      return true;
    } catch (e) {
      print('Error al parsear fecha/hora del recordatorio: $e');
      return false;
    }
  }

  void _checkCurrentTimeRecordatories() async {
    if (!mounted) return;

    final recordatoryController = Provider.of<RecordatoryController>(
      context,
      listen: false,
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await recordatoryController.fetchRecordatoriesForUser(user.uid);
    }

    final now = DateTime.now();
    final currentTimeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final currentDateString =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    print(
      'Verificando recordatorios para: $currentDateString $currentTimeString',
    );

    // CAMBIO CRÍTICO: Marcar como leídos los recordatorios vencidos PRIMERO
    await _markPastRecordatoriesAsRead(recordatoryController);

    // Limpiar recordatorios antiguos procesados
    _cleanOldProcessedRecordatories(now);

    // AHORA sí buscar recordatorios activos (después de marcar vencidos)
    final activeRecordatories =
        recordatoryController.recordatories.where((r) {
          // Solo recordatorios no leídos
          if (r.isRead) return false;

          // Solo recordatorios de hoy y hora actual
          if (r.date != currentDateString || r.time != currentTimeString)
            return false;

          // Verificación más estricta del tiempo
          if (!_isRecordatoryActiveNow(r, now)) return false;

          // Verificar que no haya sido procesado
          final key = _generateRecordatoryKey(r);
          if (_processedRecordatoriesKeys.contains(key)) return false;

          // No debe estar ya en repetición
          if (_recordatoryRepeatCount.containsKey(r.id)) return false;

          return true;
        }).toList();

    print('Recordatorios activos encontrados: ${activeRecordatories.length}');

    if (activeRecordatories.isNotEmpty && !_manualStopRequested) {
      activeRecordatories.sort((a, b) => b.id.compareTo(a.id));
      final mostRecent = activeRecordatories.first;

      print('Activando recordatorio: ${mostRecent.title}');

      // Marcar como procesado
      final key = _generateRecordatoryKey(mostRecent);
      _processedRecordatoriesKeys.add(key);

      _recordatoryRepeatCount[mostRecent.id] = 0;

      await _notificationService.showLocalNotification(
        mostRecent.id + 9999,
        '🚨 RECORDATORIO ACTIVO',
        mostRecent.title,
        mostRecent.id.toString(),
      );

      _startRecordatoryRepetition(mostRecent);
      recordatoryController.markRecordatoryAsRead(mostRecent.id);

      try {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(pattern: [0, 1000, 500, 1000, 500, 1000]);
        }
      } catch (e) {
        print('Error al vibrar: $e');
      }
    }
  }

  bool _isRecordatoryActiveNow(Recordatory recordatory, DateTime now) {
    try {
      final dateParts = recordatory.date.split('/');
      final timeParts = recordatory.time.split(':');

      if (dateParts.length != 3 || timeParts.length != 2) {
        return false;
      }

      final recordatoryDateTime = DateTime(
        int.parse(dateParts[2]), // año
        int.parse(dateParts[1]), // mes
        int.parse(dateParts[0]), // día
        int.parse(timeParts[0]), // hora
        int.parse(timeParts[1]), // minuto
      );

      final timeDifference = now.difference(recordatoryDateTime);

      // CAMBIO CRÍTICO: Ventana más estricta - solo 60 segundos después
      if (timeDifference.inSeconds < 0 || timeDifference.inSeconds > 60) {
        if (timeDifference.inSeconds > 60) {
          print(
            '⚠️ Recordatorio fuera de ventana (${timeDifference.inSeconds}s): ${recordatory.title}',
          );
        }
        return false;
      }

      print(
        '✅ Recordatorio activo (${timeDifference.inSeconds}s): ${recordatory.title}',
      );
      return true;
    } catch (e) {
      print('Error al verificar tiempo del recordatorio: $e');
      return false;
    }
  }

  void _cleanOldProcessedRecordatories(DateTime now) {
    final keysToRemove = <String>[];

    for (String key in _processedRecordatoriesKeys) {
      try {
        // Extraer información de la clave (formato: id_dd/mm/yyyy_hh:mm)
        final parts = key.split('_');
        if (parts.length >= 3) {
          final datePart = parts[1]; // dd/mm/yyyy
          final timePart = parts[2]; // hh:mm

          final dateParts = datePart.split('/');
          final timeParts = timePart.split(':');

          if (dateParts.length == 3 && timeParts.length == 2) {
            final recordatoryDateTime = DateTime(
              int.parse(dateParts[2]), // año
              int.parse(dateParts[1]), // mes
              int.parse(dateParts[0]), // día
              int.parse(timeParts[0]), // hora
              int.parse(timeParts[1]), // minuto
            );

            // Si han pasado más de 5 minutos, remover de la lista
            if (now.difference(recordatoryDateTime).inMinutes >= 5) {
              keysToRemove.add(key);
            }
          }
        }
      } catch (e) {
        // Si hay error al parsear, remover la clave
        keysToRemove.add(key);
      }
    }

    for (String key in keysToRemove) {
      _processedRecordatoriesKeys.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      print(
        'Limpiados ${keysToRemove.length} recordatorios procesados antiguos',
      );
    }
  }

  void _startRecordatoryRepetition(Recordatory recordatory) {
    _manualStopRequested = false;

    _speakRecordatoryAsAlarm(recordatory);
    _recordatoryRepeatCount[recordatory.id] = 1;

    _repeatTimers[recordatory
        .id] = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (!mounted || _manualStopRequested) {
        timer.cancel();
        _repeatTimers.remove(recordatory.id);
        _recordatoryRepeatCount.remove(recordatory.id);
        _manualStopRequested = false;
        return;
      }

      final currentCount = _recordatoryRepeatCount[recordatory.id] ?? 0;

      if (currentCount < 1) {
        print(
          'Repetición ${currentCount + 1} del recordatorio: ${recordatory.title}',
        );
        _speakRecordatoryAsAlarm(recordatory);
        _recordatoryRepeatCount[recordatory.id] = currentCount + 1;
        _vibrateDevice();
      } else {
        print(
          'Recordatorio completado después de 1 repeticion: ${recordatory.title}',
        );
        timer.cancel();
        _repeatTimers.remove(recordatory.id);
        _recordatoryRepeatCount.remove(recordatory.id);
      }
    });
  }

  void _stopAllActiveRecordatories() {
    if (_recordatoryRepeatCount.isEmpty && _speakingRecordatoryId == null) {
      // Mostrar mensaje si no hay alarmas activas
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay recordatorios activos para detener'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    print('🛑 Parando todos los recordatorios activos');
    
    _ttsService.stop();
    
    for (final timer in _repeatTimers.values) {
      timer?.cancel();
    }
    
    _repeatTimers.clear();
    _recordatoryRepeatCount.clear();
    _manualStopRequested = true;
    
    setState(() {
      _speakingRecordatoryId = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recordatorios detenidos'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _vibrateDevice() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 500, 200, 500]);
      }
    } catch (e) {
      print('Error al vibrar: $e');
    }
  }

  void _speakRecordatoryAsAlarm(Recordatory recordatory) async {
    String textToSpeak =
        "¡Atención! Recordatorio importante: ${recordatory.title}. ";
    textToSpeak += "Fecha: ${recordatory.date}. ";
    textToSpeak += "Hora: ${recordatory.time}.";

    setState(() {
      _speakingRecordatoryId = recordatory.id;
    });

    await _ttsService.speakAsAlarm(textToSpeak);

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

    final index = recordatoryController.recordatories.indexOf(recordatory);
    if (index != -1) {
      final itemHeight = 120.0;
      final offset = index * itemHeight;

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

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

  

  Future<void> _initializeTTS() async {
    await _ttsService.initTTS();
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();

    for (final timer in _repeatTimers.values) {
      timer?.cancel();
    }
    _repeatTimers.clear();
    _recordatoryRepeatCount.clear();
    _processedRecordatoriesKeys.clear(); // CAMBIO 8: Limpiar el nuevo Set

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

          // Cargar recordatorios
          await recordatoryController.fetchRecordatoriesForUser(user.uid);

          // CAMBIO 8: Marcar como leídos los vencidos inmediatamente después de cargar
          await _markPastRecordatoriesAsRead(recordatoryController);

          // Verificar notificaciones perdidas
          //await _checkForMissedNotifications();

          // Programar alarmas solo para recordatorios válidos
          await recordatoryController.scheduleAllAlarmsForUser(user.uid);

          print(
            'Recordatorios cargados: ${recordatoryController.recordatories.length}',
          );

          // Verificar recordatorios actuales
          _checkCurrentTimeRecordatories();

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

        // Primero obtener los recordatorios
        await recordatoryController.fetchRecordatoriesForUser(user.uid);

        // CAMBIO 6: Inmediatamente marcar como leídos los recordatorios vencidos
        await _markPastRecordatoriesAsRead(recordatoryController);

        // Luego reprogramar notificaciones solo para recordatorios válidos
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

  Future<void> _markPastRecordatoriesAsRead(
    RecordatoryController recordatoryController,
  ) async {
    final now = DateTime.now();
    final recordatoriesToMarkAsRead = <Recordatory>[];

    for (final recordatory in recordatoryController.recordatories) {
      // Solo procesar recordatorios no leídos
      if (!recordatory.isRead) {
        // NUEVO: Verificar si ya fue procesado (ya sonó y posiblemente fue detenido)
        final key = _generateRecordatoryKey(recordatory);
        if (_processedRecordatoriesKeys.contains(key)) {
          recordatoriesToMarkAsRead.add(recordatory);
          print(
            '🔄 Marcando como leído recordatorio ya procesado: ${recordatory.title}',
          );
          continue;
        }

        try {
          final dateParts = recordatory.date.split('/');
          final timeParts = recordatory.time.split(':');

          if (dateParts.length == 3 && timeParts.length == 2) {
            final recordatoryDateTime = DateTime(
              int.parse(dateParts[2]), // año
              int.parse(dateParts[1]), // mes
              int.parse(dateParts[0]), // día
              int.parse(timeParts[0]), // hora
              int.parse(timeParts[1]), // minuto
            );

            final timeDifference = now.difference(recordatoryDateTime);

            // Marcar como leído si han pasado más de 2 minutos O si es de un día anterior
            bool shouldMarkAsRead = false;

            if (timeDifference.inMinutes > 2) {
              shouldMarkAsRead = true;
              print(
                '⏰ Recordatorio vencido por tiempo: ${recordatory.title} - ${timeDifference.inMinutes} min',
              );
            } else if (recordatoryDateTime.day < now.day ||
                recordatoryDateTime.month < now.month ||
                recordatoryDateTime.year < now.year) {
              shouldMarkAsRead = true;
              print('⏰ Recordatorio de día anterior: ${recordatory.title}');
            }

            if (shouldMarkAsRead) {
              recordatoriesToMarkAsRead.add(recordatory);
            }
          }
        } catch (e) {
          print(
            'Error al parsear fecha/hora del recordatorio ${recordatory.id}: $e',
          );
          // En caso de error, marcarlo como leído para evitar problemas
          recordatoriesToMarkAsRead.add(recordatory);
        }
      }
    }

    // Marcar todos los recordatorios vencidos como leídos
    for (final recordatory in recordatoriesToMarkAsRead) {
      try {
        await recordatoryController.markRecordatoryAsRead(recordatory.id);
        print('✅ Marcado como leído: ${recordatory.title}');
      } catch (e) {
        print('Error al marcar recordatorio ${recordatory.id} como leído: $e');
      }
    }

    if (recordatoriesToMarkAsRead.isNotEmpty) {
      print(
        '✅ Se marcaron ${recordatoriesToMarkAsRead.length} recordatorios vencidos como leídos',
      );
    }
  }

  void _setupForegroundNotificationHandling() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📱 Notificación recibida en primer plano: ${message.data}');

      await _refreshRecordatorios();
      _checkCurrentTimeRecordatories();

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
    if (_ttsService.isSpeaking) {
      await _ttsService.stop();

      if (_speakingRecordatoryId == recordatory.id) {
        setState(() {
          _speakingRecordatoryId = null;
        });
        return;
      }
    }

    String textToSpeak = "Recordatorio: ${recordatory.title}. ";
    textToSpeak += "Fecha: ${recordatory.date}. ";
    textToSpeak += "Hora: ${recordatory.time}.";

    setState(() {
      _speakingRecordatoryId = recordatory.id;
    });

    final recordatoryController = Provider.of<RecordatoryController>(
      context,
      listen: false,
    );
    if (!recordatory.isRead) {
      recordatoryController.markRecordatoryAsRead(recordatory.id);
    }

    await _ttsService.speak(textToSpeak);

    if (!_ttsService.isSpeaking && mounted) {
      setState(() {
        _speakingRecordatoryId = null;
      });
    }
  }

  void _handleNotificationTap(int recordatoryId) {
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
      recordatoryController.markRecordatoryAsRead(recordatory.id);
      _speakRecordatory(recordatory);

      final index = recordatoryController.recordatories.indexOf(recordatory);
      if (index != -1) {
        final scrollOffset = index * 100.0;

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

                  // Logo Bymax con botón de parar
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
                      // NUEVO: Botón para parar recordatorios activos
                      GestureDetector(
                      onTap: _stopAllActiveRecordatories,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_recordatoryRepeatCount.isNotEmpty || _speakingRecordatoryId != null)
                              ? Colors.red.withOpacity(0.8)
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stop, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'PARAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
