import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bymax/controllers/loginController.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Inicializar la persistencia de sesión
  static Future<void> initializeAuth() async {
    // Configurar la persistencia para mantener la sesión activa incluso cuando la app se cierra
    await _auth.setPersistence(Persistence.LOCAL);
  }

  // Verificar si hay un usuario ya autenticado y redirigir según corresponda
  static Future<String?> checkAuthState(BuildContext context) async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      // Usuario ya autenticado, obtener su rol
      final role = await LoginController.getCurrentUserRole();

      // Guardar información del usuario
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      await prefs.setBool('is_admin', LoginController.isAdmin(role));

      // Devolver la ruta a la que debe redirigirse
      return LoginController.getRouteByRole(role);
    }

    return null; // No hay usuario autenticado
  }
}
