import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Configuración del canal de notificación
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Canal de alta importancia',
    description: 'Este canal es utilizado para notificaciones importantes',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  // Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    // Configurar el handler de segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Configurar notificaciones locales
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response);
      },
    );

    // Crear canal de notificaciones
    await _createNotificationChannel();

    // Configurar permisos
    await _requestNotificationPermissions();

    // Configurar manejadores de mensajes
    await _setupMessageHandlers();

    // Opcional: Enviar notificación de prueba
    // await _sendTestNotification();
  }

  static Future<void> _createNotificationChannel() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> _requestNotificationPermissions() async {
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
      'Estado de autorización para notificaciones: ${settings.authorizationStatus}',
    );
  }

  static Future<void> _setupMessageHandlers() async {
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

  // Manejador para mensajes en primer plano
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Mensaje recibido en primer plano!');
    print('Datos del mensaje: ${message.data}');

    if (message.notification != null) {
      await _showNotification(
        message.hashCode,
        message.notification!.title ?? 'Nueva notificación',
        message.notification!.body ?? '',
        message.data['route'],
      );
    } else if (message.data.isNotEmpty) {
      await _showNotification(
        message.hashCode,
        message.data['title'] ?? 'Nuevo recordatorio',
        message.data['body'] ?? 'Tienes un nuevo recordatorio pendiente',
        message.data['route'],
      );
    }
  }

  // Manejador para cuando la app se abre desde una notificación
  static void _handleMessage(RemoteMessage message) {
    print(
      'La aplicación se abrió desde una notificación: ${message.messageId}',
    );
    print('Datos: ${message.data}');
    print('Notificación: ${message.notification?.title}');

    // Aquí puedes manejar la navegación según el payload
    // Ejemplo: Get.toNamed(message.data['route'] ?? '/');
  }

  // Manejador para cuando se toca una notificación
  static void _handleNotificationTap(NotificationResponse response) {
    print('Notificación pulsada: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      // Get.toNamed(response.payload!);
    }
  }

  // Mostrar notificación local
  static Future<void> _showNotification(
    int id,
    String title,
    String body,
    String? payload,
  ) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableLights: true,
          playSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // Manejador de mensajes en segundo plano
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();
    print("Mensaje recibido en segundo plano: ${message.messageId}");

    if (message.notification != null) {
      await _showNotification(
        message.hashCode,
        message.notification!.title ?? 'Nueva notificación',
        message.notification!.body ?? '',
        message.data['route'],
      );
    } else if (message.data.isNotEmpty) {
      await _showNotification(
        message.hashCode,
        message.data['title'] ?? 'Nuevo recordatorio',
        message.data['body'] ?? 'Tienes un nuevo recordatorio pendiente',
        message.data['route'],
      );
    }
  }

  // Método para enviar notificaciones de prueba (opcional)
  static Future<void> sendTestNotification() async {
    await _showNotification(
      0,
      'Prueba de notificación',
      'Esta es una notificación de prueba',
      null,
    );
    print('Notificación de prueba enviada');
  }
}
