import 'package:bymax/controllers/authStateController.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:bymax/pages/loginPage.dart';
import 'package:bymax/pages/homePage.dart';
import 'package:bymax/pages/addUserPage.dart';
import 'package:bymax/pages/user_list_page.dart';
import 'package:bymax/pages/activitiesPage.dart';
import 'package:bymax/pages/AdultHomePage.dart';
import 'package:bymax/controllers/recordatoryController.dart';
import 'package:bymax/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Mensaje recibido en segundo plano: ${message.messageId}");

  // Mostrar notificación local si se recibe un mensaje en segundo plano
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'Canal de alta importancia',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
  );

  if (message.notification != null) {
    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      platformDetails,
      payload: message.data['route'], // Datos adicionales si los hay
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Registrar el manejador de mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Configurar permisos para notificaciones
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false, // Solicitud de permiso no provisional
  );
  print('Permiso de notificaciones: ${settings.authorizationStatus}');

  // Inicializar el servicio de notificaciones
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Configurar manejador de mensajes en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('Mensaje recibido en primer plano!');
    print('Datos del mensaje: ${message.data}');

    if (message.notification != null) {
      print(
        'El mensaje también contiene una notificación: ${message.notification?.title}',
      );

      // Mostrar la notificación local en primer plano
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'high_importance_channel',
            'Canal de alta importancia',
            importance: Importance.max,
            priority: Priority.high,
          );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        platformDetails,
        payload: message.data['route'], // Datos adicionales si los hay
      );
    }
  });

  // Configurar manejador cuando se abre la app desde una notificación
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('La aplicación se abrió desde una notificación');
    // Aquí puedes manejar la navegación, por ejemplo:
    // Get.toNamed('/recordatoryDetails', arguments: message.data['recordatoryId']);
  });

  // Inicializar el controlador de autenticación
  Get.put(AuthStateController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bymax App',
      theme: ThemeData(
        primaryColor: const Color(0xFF03d069),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF03d069),
          primary: const Color(0xFF03d069),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/loginPage',
      routes: {
        '/loginPage': (context) => const LoginPage(),
        '/homePage': (context) => const homePage(),
        '/addUser': (context) => const AddUserPage(),
        '/activities': (context) => const ActivitiesPage(),
        '/userList': (context) => const UserListPage(),
        '/adultHome':
            (context) => ChangeNotifierProvider(
              create: (_) => RecordatoryController(),
              child: const AdultHomePages(),
            ),
      },
    );
  }
}
