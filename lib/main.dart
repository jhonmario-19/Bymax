import 'package:flutter/material.dart';
import 'package:bymax/pages/loginPage.dart';
import 'package:bymax/pages/homePage.dart';
import 'package:bymax/pages/addUserPage.dart';
//import 'package:bymax/pages/recordatoryPage.dart'; // Página de configuraciones (temporal)
import 'package:bymax/pages/activitiesPage.dart'; // Si deseas también usarla

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bymax App',
      initialRoute: '/loginPage',
      routes: {
        '/loginPage': (context) => const LoginPage(),
        '/homePage': (context) => const homePage(),
        '/addUser': (context) => const AddUserPage(),
        //'/settings': (context) => const RecordatoryPage(), // Usada como "ajustes"
        '/activities': (context) => const ActivitiesPage(), 
      },
    );
  }
}
