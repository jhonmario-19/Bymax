import 'dart:typed_data';
import 'dart:async';
import 'package:bymax/controllers/recordatoryController.dart';
import 'package:bymax/services/tts_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../models/recordatoryModel.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegúrate de inicializar Firebase antes de cualquier operación
  await Firebase.initializeApp();
  print("Mensaje FCM recibido en segundo plano: ${message.messageId}");
  print("Datos del mensaje en segundo plano: ${message.data}");

  // Inicializar el plugin de notificaciones locales
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Configurar para Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Configurar para iOS
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Mostrar la notificación recibida en segundo plano
  if (message.notification != null) {
    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification!.title ?? 'Nueva notificación',
      message.notification!.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Recordatorios',
          channelDescription: 'Notificaciones de recordatorios importantes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['route'],
    );
  } else if (message.data.isNotEmpty) {
    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.data['title'] ?? 'Nuevo recordatorio',
      message.data['body'] ?? 'Tienes un nuevo recordatorio pendiente',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Recordatorios',
          channelDescription: 'Notificaciones de recordatorios importantes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['route'],
    );
  }
}

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Mapa para almacenar las IDs programadas y sus correspondientes recordatorios
  final Map<int, int> _scheduledNotifications =
      {}; // <notificationId, recordatorioId>

  // Timer para verificación automática
  Timer? _checkTimer;
  late TTSService _ttsService;

  // Constantes para canales de notificación
  static const AndroidNotificationChannel _highImportanceChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'Recordatorios',
        description: 'Notificaciones de recordatorios importantes',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

  // Inicializar el servicio de notificaciones
  Future<void> init() async {
    // Inicializar zonas horarias
    tz_init.initializeTimeZones();

    // Registrar el handler global para mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canales de notificación para Android
    await _setupNotificationChannels();

    // Solicitar permisos para FCM y notificaciones locales
    await _requestNotificationPermissions();

    // Configurar manejadores de mensajes para FCM
    await _setupMessageHandlers();

    // Recuperar notificaciones programadas guardadas
    await _loadScheduledNotificationsFromPrefs();

    // Configurar FCM para recibir notificaciones en segundo plano
    await _setupFCMForBackgroundMessages();

    await _setupAlarmChannel();

    // Inicializar TTS Service
    _ttsService = TTSService();
    await _ttsService.initTTS();

    // Iniciar verification automática cada minuto
    _startAutomaticCheck();

    print(
      'Servicio de notificaciones inicializado con TTS y verificación automática',
    );
  }

  // Iniciar verificación automática
  void _startAutomaticCheck() {
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkExactTimeRecordatories();
    });
  }

  // Verificar recordatorios en tiempo exacto
  Future<void> _checkExactTimeRecordatories() async {
    try {
      final recordatoryController = Get.find<RecordatoryController>();
      final now = DateTime.now();

      for (final recordatory in recordatoryController.recordatories) {
        if (!recordatory.isRead && recordatory.isNotificationEnabled) {
          // Parsear fecha y hora
          final timeString = convertTo24HourFormat(recordatory.time);
          final dateTimeParts = recordatory.date.split('/');
          final timeParts = timeString.split(':');

          if (dateTimeParts.length == 3 && timeParts.length == 2) {
            final day = int.parse(dateTimeParts[0]);
            final month = int.parse(dateTimeParts[1]);
            final year = int.parse(dateTimeParts[2]);
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);

            final scheduledDate = DateTime(year, month, day, hour, minute);

            // Verificar si es exactamente la hora (con margen de 1 minuto)
            final difference = now.difference(scheduledDate).abs();

            if (difference.inMinutes == 0 ||
                (now.isAfter(scheduledDate) && difference.inMinutes <= 1)) {
              print(
                '¡Activando recordatorio en tiempo exacto: ${recordatory.title}',
              );

              // Mostrar notificación inmediatamente
              await showLocalNotification(
                recordatory.id,
                '🚨 RECORDATORIO ACTIVO',
                recordatory.title,
                recordatory.id.toString(),
              );

              // Activar alarma con TTS
              await _triggerRecordatoryAlarmImmediate(recordatory.id);
            }
          }
        }
      }
    } catch (e) {
      print('Error en verificación automática: $e');
    }
  }

  // Activar recordatorio inmediatamente con TTS
  Future<void> _triggerRecordatoryAlarmImmediate(int recordatoryId) async {
    try {
      final recordatoryController = Get.find<RecordatoryController>();
      final recordatory = recordatoryController.findRecordatoryById(
        recordatoryId,
      );

      if (recordatory != null) {
        // Marcar como leído
        recordatoryController.markRecordatoryAsRead(recordatoryId);

        // Texto para reproducir con más énfasis
        String textToSpeak = "¡ATENCIÓN! Recordatorio importante. ";
        textToSpeak += "${recordatory.title}. ";
        textToSpeak +=
            "Programado para hoy ${recordatory.date} a las ${recordatory.time}.";

        // Usar speakAsAlarm para reproducir con repeticiones
        await _ttsService.speakAsAlarm(textToSpeak);

        // Mostrar la pantalla automáticamente si la app está en primer plano
        if (Get.context != null) {
          Get.toNamed('/adultHomePage');
        }

        print('Recordatorio activado con alarma TTS: ${recordatory.title}');
      }
    } catch (e) {
      print('Error al activar recordatorio inmediato: $e');
    }
  }

  // NUEVO: Configurar FCM para mensajes en segundo plano
  Future<void> _setupFCMForBackgroundMessages() async {
    // Obtener el token de FCM y guardarlo si es necesario
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');

    // Puedes guardar este token en tu backend o Firestore para enviar
    // notificaciones específicas a este dispositivo

    // Configurar los tipos de notificaciones que queremos recibir
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // IMPORTANTE: Para iOS, configurar la capacidad de recibir notificaciones en segundo plano
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
  }

  Future<void> _setupNotificationChannels() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_highImportanceChannel);
  }

  // NUEVO: Programar recordatorio como alarma automática
  Future<void> scheduleRecordatoryAlarm(Recordatory recordatorio) async {
    try {
      // Convertir fecha y hora del recordatorio a DateTime
      final timeString = convertTo24HourFormat(recordatorio.time);
      final dateTimeParts = recordatorio.date.split('/');
      final timeParts = timeString.split(':');

      if (dateTimeParts.length != 3 || timeParts.length != 2) {
        print('Formato de fecha u hora inválido');
        return;
      }

      final day = int.parse(dateTimeParts[0]);
      final month = int.parse(dateTimeParts[1]);
      final year = int.parse(dateTimeParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final scheduledDate = DateTime(year, month, day, hour, minute);

      // Verificar si la fecha ya pasó
      if (scheduledDate.isBefore(DateTime.now())) {
        print(
          'La fecha del recordatorio ya pasó: ${recordatorio.date} ${recordatorio.time}',
        );
        return;
      }

      // Crear zona horaria local
      final scheduledTzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      // ID único para la alarma
      final alarmId =
          recordatorio.id + 10000; // Diferente de notificaciones normales

      // Configurar detalles de la alarma con máxima prioridad
      final AndroidNotificationDetails
      androidDetails = AndroidNotificationDetails(
        'alarm_channel', // Canal específico para alarmas
        'Alarmas de Recordatorios',
        channelDescription: 'Alarmas automáticas de recordatorios importantes',
        importance: Importance.max,
        priority: Priority.high,
        ticker: '🚨 RECORDATORIO ACTIVO',
        styleInformation: BigTextStyleInformation(
          '🚨 ${recordatorio.title}\n📅 ${recordatorio.date} ⏰ ${recordatorio.time}',
          contentTitle: '🚨 RECORDATORIO ACTIVO',
          summaryText: 'Toca para detener',
        ),
        fullScreenIntent: true, // Mostrar en pantalla completa
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        ongoing: true, // No se puede deslizar para cerrar
        autoCancel: false, // No se cierra automáticamente
        showWhen: true,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(
          'alarm_sound',
        ), // Sonido de alarma
        vibrationPattern: Int64List.fromList([
          0,
          1000,
          500,
          1000,
          500,
          1000,
          500,
          1000,
        ]),
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alarm_sound.aiff',
        ),
      );

      // Programar la alarma
      await flutterLocalNotificationsPlugin.zonedSchedule(
        alarmId,
        '🚨 RECORDATORIO ACTIVO',
        '${recordatorio.title}\n📅 ${recordatorio.date} ⏰ ${recordatorio.time}',
        scheduledTzDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'alarm_${recordatorio.id}',
      );

      print(
        'Alarma programada para: ${recordatorio.title} a las ${recordatorio.time} del ${recordatorio.date}',
      );
    } catch (e) {
      print('Error al programar alarma: $e');
    }
  }

  // NUEVO: Crear canal de alarmas
  Future<void> _setupAlarmChannel() async {
    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarmas de Recordatorios',
      description: 'Alarmas automáticas de recordatorios importantes',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(alarmChannel);
  }

  Future<void> _requestNotificationPermissions() async {
    // Permisos para notificaciones locales en iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Permisos para Firebase Cloud Messaging
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          announcement: true,
          carPlay: false,
          criticalAlert: true,
        );

    print(
      'Estado de autorización para notificaciones FCM: ${settings.authorizationStatus}',
    );
  }

  Future<void> _setupMessageHandlers() async {
    // Comprobar notificaciones pendientes que pueden haber abierto la app
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print(
        'La app se inició con una notificación: ${initialMessage.messageId}',
      );
      Future.delayed(const Duration(seconds: 1), () {
        _handleMessage(initialMessage);
      });
    }

    // Configurar manejador de mensajes en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Configurar manejador cuando se abre la app desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  // Manejador de notificaciones tocadas (locales)
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        print('Notificación local tocada: ID $payload');
        // Navegar a la pantalla de detalles del recordatorio
        Get.toNamed('/recordatorio/detalle', arguments: {'id': payload});
      } catch (e) {
        print('Error al procesar la notificación local: $e');
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Mensaje FCM recibido en primer plano!');
    print('Datos del mensaje: ${message.data}');

    // Extraer el ID del recordatorio
    final recordatoryId = int.tryParse(message.data['recordatoryId'] ?? '');

    if (message.notification != null) {
      await showLocalNotification(
        message.hashCode,
        message.notification!.title ?? 'Nueva notificación',
        message.notification!.body ?? '',
        message
            .data['recordatoryId'], // Usar el ID del recordatorio como payload
      );

      // Activar TTS automáticamente si está configurado
      if (recordatoryId != null) {
        _triggerRecordatoryAlarm(recordatoryId);
      }
    } else if (message.data.isNotEmpty) {
      await showLocalNotification(
        message.hashCode,
        message.data['title'] ?? 'Nuevo recordatorio',
        message.data['body'] ?? 'Tienes un nuevo recordatorio pendiente',
        message.data['recordatoryId'],
      );

      // Activar TTS automáticamente si está configurado
      if (recordatoryId != null) {
        _triggerRecordatoryAlarm(recordatoryId);
      }
    }
  }

  Future<void> checkUpcomingRecordatories() async {
    try {
      // Obtenemos el controlador de recordatorios
      final recordatoryController = Get.find<RecordatoryController>();
      final now = DateTime.now();

      // Verificar cada recordatorio
      for (final recordatory in recordatoryController.recordatories) {
        // Parsear fecha y hora
        final dateTimeParts = recordatory.date.split('/');
        final timeParts = recordatory.time.split(':');

        if (dateTimeParts.length == 3 && timeParts.length == 2) {
          final day = int.parse(dateTimeParts[0]);
          final month = int.parse(dateTimeParts[1]);
          final year = int.parse(dateTimeParts[2]);
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);

          final scheduledDate = DateTime(year, month, day, hour, minute);

          // Si está próximo (menos de 5 minutos) y no ha sido marcado como leído
          final difference = scheduledDate.difference(now);
          if (difference.inMinutes <= 5 &&
              difference.inMinutes >= 0 &&
              !recordatory.isRead) {
            // Programar la notificación inminente
            showLocalNotification(
              recordatory.id + 1000, // ID diferente para evitar conflictos
              '¡Recordatorio inminente!',
              '${recordatory.title} se activará en ${difference.inMinutes} minutos',
              recordatory.id.toString(),
            );
          }
        }
      }
    } catch (e) {
      print('Error al verificar recordatorios próximos: $e');
    }
  }

  void _triggerRecordatoryAlarm(int recordatoryId) {
    // Usar el método inmediato con TTS
    _triggerRecordatoryAlarmImmediate(recordatoryId);
  }

  // Manejador para cuando la app se abre desde una notificación FCM
  void _handleMessage(RemoteMessage message) {
    print(
      'La aplicación se abrió desde una notificación FCM: ${message.messageId}',
    );
    print('Datos: ${message.data}');
    print('Notificación: ${message.notification?.title}');

    // Navegación usando GetX
    final route = message.data['route'];
    if (route != null && route.isNotEmpty) {
      Get.toNamed(route);
    }
  }

  // Mostrar notificación local
  Future<void> showLocalNotification(
    int id,
    String title,
    String body,
    String? payload,
  ) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _highImportanceChannel.id,
          _highImportanceChannel.name,
          channelDescription: _highImportanceChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableLights: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> scheduleNotification(Recordatory recordatorio) async {
    if (!recordatorio.isNotificationEnabled) {
      print('Notificaciones desactivadas para este recordatorio');
      return;
    }

    try {
      // Convertir fecha y hora del recordatorio a DateTime
      final dateTimeParts = recordatorio.date.split('/');
      final timeString = convertTo24HourFormat(recordatorio.time);
      final timeParts = timeString.split(':');

      if (dateTimeParts.length != 3 || timeParts.length != 2) {
        print('Formato de fecha u hora inválido');
        return;
      }

      final day = int.parse(dateTimeParts[0]);
      final month = int.parse(dateTimeParts[1]);
      final year = int.parse(dateTimeParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final scheduledDate = DateTime(year, month, day, hour, minute);

      // Verificar si la fecha ya pasó
      if (scheduledDate.isBefore(DateTime.now())) {
        print(
          'La fecha del recordatorio ya pasó: ${recordatorio.date} ${recordatorio.time}',
        );

        // NUEVO: Si el recordatorio es de hoy pero ya pasó por poco tiempo (menos de 15 minutos),
        // mostrar inmediatamente como alarma
        final DateTime now = DateTime.now();
        final Duration difference = now.difference(scheduledDate).abs();
        if (scheduledDate.day == now.day &&
            scheduledDate.month == now.month &&
            scheduledDate.year == now.year &&
            difference.inMinutes < 2) {
          // Mostrar inmediatamente como una alarma con el TTS
          showLocalNotification(
            recordatorio.id,
            'Recordatorio: ${recordatorio.title}',
            'Este recordatorio estaba programado para hace poco tiempo: ${recordatorio.time}',
            recordatorio.id.toString(),
          );

          // Llamar al método para reproducir alarma
          _triggerRecordatoryAlarm(recordatorio.id);
        }
        return;
      }

      // Crear zona horaria local
      final scheduledTzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      // ID único para la notificación
      final notificationId = recordatorio.id;

      // Configurar detalles de la notificación con datos mejorados
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _highImportanceChannel.id,
            _highImportanceChannel.name,
            channelDescription: _highImportanceChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'Recordatorio importante',
            styleInformation: BigTextStyleInformation(
              recordatorio.title,
              contentTitle: 'Recordatorio: ${recordatorio.title}',
              summaryText: 'Hora: ${recordatorio.time}',
            ),
            fullScreenIntent:
                true, // NUEVO: Muestra como alerta de pantalla completa
            sound: const RawResourceAndroidNotificationSound(
              'notification_sound',
            ), // NUEVO: Sonido personalizado
            vibrationPattern: Int64List.fromList([
              0,
              500,
              200,
              500,
            ]), // NUEVO: Patrón de vibración
          );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound:
              'notification_sound.aiff', // NUEVO: Sonido personalizado para iOS
        ),
      );

      // Programar la notificación
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Recordatorio: ${recordatorio.title}',
        'Hora: ${recordatorio.time}',
        scheduledTzDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: recordatorio.id.toString(),
      );

      // Guardar referencia a la notificación programada
      _scheduledNotifications[notificationId] = recordatorio.id;
      await _saveScheduledNotificationsToPrefs();

      print(
        'Notificación programada para: ${recordatorio.title} a las ${recordatorio.time} del ${recordatorio.date}',
      );
    } catch (e) {
      print('Error al programar notificación: $e');
    }
  }

  String convertTo24HourFormat(String time12h) {
    final regExp = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AP]M)$',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(time12h.trim());
    if (match == null) return time12h; // Si ya está en 24h o formato inesperado

    int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    final String period = match.group(3)!.toUpperCase();

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // Programar notificaciones para una lista de recordatorios
  Future<void> scheduleAllNotifications(List<Recordatory> recordatorios) async {
    // Primero cancelar todas las notificaciones existentes
    await cancelAllNotifications();

    // Luego programar las nuevas
    for (final recordatorio in recordatorios) {
      if (recordatorio.isNotificationEnabled) {
        await scheduleNotification(recordatorio);
      }
    }
  }

  // Cancelar una notificación específica
  Future<void> cancelNotification(int recordatorioId) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(recordatorioId);
      _scheduledNotifications.removeWhere(
        (key, value) => value == recordatorioId,
      );
      await _saveScheduledNotificationsToPrefs();
      print('Notificación cancelada para recordatorio ID: $recordatorioId');
    } catch (e) {
      print('Error al cancelar notificación: $e');
    }
  }

  // Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      _scheduledNotifications.clear();
      await _saveScheduledNotificationsToPrefs();
      print('Todas las notificaciones canceladas');
    } catch (e) {
      print('Error al cancelar todas las notificaciones: $e');
    }
  }

  // Guardar las notificaciones programadas en las preferencias
  Future<void> _saveScheduledNotificationsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationIds = _scheduledNotifications.keys.toList();
      final recordatorioIds = _scheduledNotifications.values.toList();

      await prefs.setStringList(
        'notification_ids',
        notificationIds.map((id) => id.toString()).toList(),
      );
      await prefs.setStringList(
        'recordatorio_ids',
        recordatorioIds.map((id) => id.toString()).toList(),
      );
    } catch (e) {
      print('Error al guardar notificaciones programadas: $e');
    }
  }

  // Cargar las notificaciones programadas desde las preferencias
  Future<void> _loadScheduledNotificationsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationIds = prefs.getStringList('notification_ids') ?? [];
      final recordatorioIds = prefs.getStringList('recordatorio_ids') ?? [];

      if (notificationIds.length == recordatorioIds.length) {
        for (int i = 0; i < notificationIds.length; i++) {
          _scheduledNotifications[int.parse(notificationIds[i])] = int.parse(
            recordatorioIds[i],
          );
        }
      }
    } catch (e) {
      print('Error al cargar notificaciones programadas: $e');
    }
  }

  // Suscribirse a un tema para recibir notificaciones grupales
  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    print('Suscrito al tema: $topic');
  }

  // Obtener y mostrar el token de FCM (útil para pruebas)
  Future<String?> getFirebaseToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    print('Token FCM: $token');
    return token;
  }

  // Método para limpiar recursos
  void dispose() {
    _checkTimer?.cancel();
    _ttsService.dispose();
  }
}
