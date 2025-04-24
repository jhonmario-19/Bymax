import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Método para iniciar sesión
  static Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userData = await _db
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .get();

        return {
          'success': true,
          'user': userCredential.user,
          'userData': userData.data(),
        };
      } else {
        return {
          'success': false,
          'message': 'No se pudo iniciar sesión',
        };
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No existe una cuenta con este correo electrónico.';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta.';
          break;
        case 'invalid-email':
          message = 'El correo electrónico no es válido.';
          break;
        case 'user-disabled':
          message = 'Esta cuenta ha sido deshabilitada.';
          break;
        default:
          message = 'Error al iniciar sesión: ${e.message}';
      }
      return {
        'success': false,
        'message': message,
      };
    }
  }

  // Método para cerrar sesión
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // Método para verificar si hay un usuario autenticado
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Método para obtener el estado de autenticación
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}