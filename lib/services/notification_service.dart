import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../models/recordatoryModel.dart';

// Manejador global para mensajes en segundo plano
// IMPORTANTE: Debe estar fuera de cualquier clase para ser accesible globalmente
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

    print('Servicio de notificaciones inicializado');
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

  // Manejador para mensajes en primer plano (FCM)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Mensaje FCM recibido en primer plano!');
    print('Datos del mensaje: ${message.data}');

    if (message.notification != null) {
      await showLocalNotification(
        message.hashCode,
        message.notification!.title ?? 'Nueva notificación',
        message.notification!.body ?? '',
        message.data['route'],
      );
    } else if (message.data.isNotEmpty) {
      await showLocalNotification(
        message.hashCode,
        message.data['title'] ?? 'Nuevo recordatorio',
        message.data['body'] ?? 'Tienes un nuevo recordatorio pendiente',
        message.data['route'],
      );
    }
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

  // Programar una notificación para un recordatorio
  Future<void> scheduleNotification(Recordatory recordatorio) async {
    if (!recordatorio.isNotificationEnabled) {
      print('Notificaciones desactivadas para este recordatorio');
      return;
    }

    try {
      // Convertir fecha y hora del recordatorio a DateTime
      final dateTimeParts = recordatorio.date.split('/');
      final timeParts = recordatorio.time.split(':');

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

      // ID único para la notificación
      final notificationId = recordatorio.id;

      // Configurar detalles de la notificación
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _highImportanceChannel.id,
            _highImportanceChannel.name,
            channelDescription: _highImportanceChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'Nuevo recordatorio',
            styleInformation: BigTextStyleInformation(
              recordatorio.title,
              contentTitle: 'Recordatorio: ${recordatorio.title}',
              summaryText: 'Hora: ${recordatorio.time}',
            ),
          );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
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

  // Enviar notificación de prueba (útil para depuración)
  Future<void> sendTestNotification() async {
    await showLocalNotification(
      0,
      'Prueba de notificación',
      'Esta es una notificación de prueba',
      null,
    );
    print('Notificación de prueba enviada');
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
}
