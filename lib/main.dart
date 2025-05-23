import 'package:bymax/services/authService.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:timezone/timezone.dart' as tz;
import 'firebase_options.dart';
import 'package:bymax/pages/loginPage.dart';
import 'package:bymax/pages/homePage.dart';
import 'package:bymax/pages/addUserPage.dart';
import 'package:bymax/pages/user_list_page.dart';
import 'package:bymax/pages/activitiesPage.dart';
import 'package:bymax/pages/AdultHomePage.dart';
import 'package:bymax/controllers/recordatoryController.dart';
import 'package:bymax/controllers/authStateController.dart';
import 'package:bymax/services/notification_service.dart';
import 'package:bymax/pages/familiarHomePage.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Mensaje en segundo plano recibido: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar zonas horarias para notificaciones programadas
  tz_init.initializeTimeZones();

  // Registrar el handler para mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Configurar notificaciones
  final notificationService = NotificationService();
  await notificationService.init();

  // Inicializar controladores
  Get.put(AuthStateController());

  // Crear el RecordatoryController como singleton para evitar recrearlo
  final recordatoryController = RecordatoryController();
  Get.put(recordatoryController, permanent: true);

  runApp(
    MultiProvider(
      providers: [
        // Proporcionar el RecordatoryController a nivel de aplicación
        ChangeNotifierProvider.value(value: Get.find<RecordatoryController>()),
      ],
      child: const MyApp(),
    ),
  );
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
        '/familiarHome': (context) => const FamiliarHomePage(),
        '/adultHome': (context) => const AdultHomePages(),
      },
    );
  }
}
