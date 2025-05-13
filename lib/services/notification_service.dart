import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar la respuesta a la notificación
        print("Notification clicked: ${response.payload}");
      },
    );

    // Configurar manejo de mensajes en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Si hay notificación y es para Android, mostrar una notificación local
      if (notification != null && android != null) {
        _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Canal de alta importancia',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data['route'],
        );
      }
    });

    // Configurar notificaciones en segundo plano
    configureBackgroundMessaging();
  }

  // Método para obtener el token FCM actual
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Método para recibir mensajes en segundo plano
  void configureBackgroundMessaging() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

// Función para manejar mensajes en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");

  // Asegúrate de tener configurado el canal para Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // ID del canal
    'Canal de alta importancia', // Nombre del canal
    description: 'Este canal es usado para mostrar notificaciones importantes',
    importance: Importance.max,
  );

  // Registra el canal con FlutterLocalNotificationsPlugin
  await FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Mostrar la notificación en segundo plano
  if (message.notification != null) {
    // Mostrar la notificación con FlutterLocalNotificationsPlugin
    await FlutterLocalNotificationsPlugin().show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Canal de alta importancia',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload:
          message.data['route'], // Puedes usar datos extras si es necesario
    );
  }
}
