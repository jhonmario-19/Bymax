import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginController {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Roles disponibles en la aplicación (como aparecen en Firebase)
  static const String ROLE_ADMIN = 'admin'; // en firebase: "admin"
  static const String ROLE_ADULTO = 'Adulto'; // en firebase: "Adulto"
  static const String ROLE_FAMILIAR = 'Familiar'; // en firebase: "Familiar"

  // Método para iniciar sesión
  static Future<Map<String, dynamic>> signIn(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Obtener datos del usuario de Firestore
        final userDoc =
            await _db
                .collection('usuarios')
                .doc(userCredential.user!.uid)
                .get();

        if (!userDoc.exists) {
          return {
            'success': false,
            'message': 'No se encontró información del usuario',
          };
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final userRole = userData['rol'] ?? ROLE_ADULTO; // Rol por defecto

        return {
          'success': true,
          'user': userCredential.user,
          'userData': userData,
          'role': userRole,
        };
      } else {
        return {'success': false, 'message': 'No se pudo iniciar sesión'};
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
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
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

  // Método para verificar el rol del usuario actual
  static Future<String> getCurrentUserRole() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return '';

      DocumentSnapshot userDoc =
          await _db.collection('usuarios').doc(currentUser.uid).get();

      if (!userDoc.exists) return '';

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['rol'] ?? ROLE_ADULTO;
    } catch (e) {
      print('Error al obtener el rol del usuario: $e');
      return '';
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

  // Método para verificar si un rol coincide con otro (insensible a mayúsculas/minúsculas)
  static bool matchesRole(String userRole, String expectedRole) {
    return userRole.toLowerCase() == expectedRole.toLowerCase();
  }

  // Método para verificar si el usuario es administrador
  static bool isAdmin(String role) {
    return matchesRole(role, ROLE_ADMIN);
  }

  // Método para verificar si el usuario es adulto
  static bool isAdulto(String role) {
    return matchesRole(role, ROLE_ADULTO);
  }

  // Método para verificar si el usuario es familiar
  static bool isFamiliar(String role) {
    return matchesRole(role, ROLE_FAMILIAR);
  }

  // Método para obtener la ruta correspondiente según el rol
  static String getRouteByRole(String role) {
    // Normalizamos el rol para hacer la comparación insensible a mayúsculas/minúsculas
    String normalizedRole = role.toLowerCase();

    if (normalizedRole == ROLE_ADMIN.toLowerCase()) {
      return '/homePage';
    } else if (normalizedRole == ROLE_FAMILIAR.toLowerCase()) {
      return '/familiarHome';
    } else if (normalizedRole == ROLE_ADULTO.toLowerCase()) {
      return '/adultHome';
    } else {
      return '/adultHome'; // Ruta por defecto
    }
  }
}
