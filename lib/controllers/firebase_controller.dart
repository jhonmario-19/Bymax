import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/userModel.dart';

class FirebaseController {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String nombre,
    required String username,
  }) async {
    try {
      // 1. Crear usuario en Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Si el registro en Auth es exitoso, guardar en Firestore
      if (userCredential.user != null) {
        await _saveUserToFirestore(
          UserModel(
            uid: userCredential.user!.uid,
            nombre: nombre,
            email: email,
            username: username,
            fechaRegistro: DateTime.now(),
          ),
        );
      }

      return userCredential.user;
    } catch (e) {
      print('Error en el registro: $e');
      return null;
    }
  }

  static Future<void> _saveUserToFirestore(UserModel user) async {
    try {
      await _db.collection('usuarios').doc(user.uid).set(user.toMap());
    } catch (e) {
      print('Error al guardar en Firestore: $e');
      throw e;
    }
  }

  static Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Obtener datos adicionales del usuario desde Firestore
        final userData = await FirebaseFirestore.instance
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
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado: $e',
      };
    }
  }
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }
}