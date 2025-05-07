import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class UserController {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static FirebaseAuth get auth => _auth;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variable estática para almacenar el rol del usuario actual
  static String? _currentUserRole;
  static String? get currentUserRole => _currentUserRole;

  // Constantes para los roles
  static const String ROLE_ADMIN = 'admin';
  static const String ROLE_USER = 'user';
  static const String ROLE_FAMILIAR = 'familiar';
  static const String ROLE_ADULTO = 'adulto';

  // Método para verificar si un nombre de usuario es único
  static Future<bool> isUsernameUnique(String username) async {
    try {
      final query =
          await _firestore
              .collection('usuarios')
              .where('username', isEqualTo: username)
              .get();
      return query.docs.isEmpty;
    } catch (e) {
      print("Error al verificar nombre de usuario: $e");
      throw Exception("Error al verificar nombre de usuario");
    }
  }

  // Método mejorado para registrar usuarios sin afectar la sesión actual del admin
  static Future<Map<String, dynamic>> registerNewUser({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
    required String adminPassword, // Nuevo parámetro
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No se encontró al usuario administrador actual.");
      }
      final adminEmail = currentUser.email;

      // Crear el usuario (esto cambia la sesión)
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final Map<String, dynamic> finalUserData = {
        ...userData,
        'uid': userCredential.user!.uid,
        'createdBy': currentUser.uid,
        'isAdmin': false,
        'rol': userData['rol'] ?? ROLE_USER,
      };

      await _firestore
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set(finalUserData);

      // Volver a loguear al admin
      if (adminEmail != null && adminPassword.isNotEmpty) {
        await _auth.signOut();
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      }

      return {
        'success': true,
        'usuario': finalUserData,
      };
    } catch (e) {
      print("Error al registrar nuevo usuario: $e");
      return {'success': false, 'message': 'Error al registrar usuario: $e'};
    }
  }

  // Método para refrescar el usuario actual
  static Future<User?> refreshCurrentUser() async {
    try {
      await _auth.currentUser?.reload();
      return _auth.currentUser;
    } catch (e) {
      print("Error al refrescar el usuario actual: $e");
      return null;
    }
  }

  // Método para agregar un usuario a una familia existente
  static Future<void> addUserToFamily(String familyId, String userId) async {
    try {
      await _firestore.collection('familias').doc(familyId).update({
        'miembros': FieldValue.arrayUnion([
          userId,
        ]), // Agrega el UID del usuario
      });
    } catch (e) {
      print("Error al agregar usuario a la familia: $e");
      throw Exception("Error al agregar usuario a la familia");
    }
  }

  // Método para crear una nueva familia
  static Future<String> createFamily(String familyName) async {
    try {
      DocumentReference familyRef = await _firestore.collection('familias').add(
        {
          'nombre': familyName,
          'fechaCreacion': DateTime.now().toString(),
          'miembros': [], // Inicializa la familia sin miembros
        },
      );
      return familyRef.id;
    } catch (e) {
      print("Error al crear familia: $e");
      throw Exception("Error al crear familia");
    }
  }

  // Método para generar una contraseña segura
  static String generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        12, // Longitud de la contraseña
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Método para obtener el rol de un usuario
  static Future<String> getUserRole(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('usuarios').doc(userId).get();
      return userDoc['rol'] ?? ROLE_USER; // Valor predeterminado si no existe
    } catch (e) {
      print("Error al obtener el rol del usuario: $e");
      throw Exception("Error al obtener el rol del usuario");
    }
  }

  // Método para obtener todos los usuarios
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot usuariosSnapshot =
          await _firestore.collection('usuarios').get();

      List<Map<String, dynamic>> usuariosList = [];
      for (var doc in usuariosSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id;
        usuariosList.add(userData);
      }

      return usuariosList;
    } catch (e) {
      print("Error al obtener usuarios: $e");
      throw Exception("Error al obtener usuarios");
    }
  }

  // Método para verificar si el usuario actual es administrador
  static Future<bool> isCurrentUserAdmin() async {
    try {
      // Si ya tenemos el rol cargado, usarlo
      if (_currentUserRole != null) {
        return _currentUserRole == ROLE_ADMIN;
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Refrescar el usuario antes de verificar el rol
      await currentUser.reload();

      final userDoc =
          await _firestore.collection('usuarios').doc(currentUser.uid).get();

      // Almacenar el rol para futuras verificaciones
      _currentUserRole = userDoc.exists ? userDoc['rol'] : null;

      return userDoc.exists && userDoc['rol'] == ROLE_ADMIN;
    } catch (e) {
      print("Error al verificar si el usuario es administrador: $e");
      return false;
    }
  }

  // Método para obtener usuarios creados por el administrador actual
  static Future<List<Map<String, dynamic>>> getUsersCreatedByAdmin(
    String adminId,
  ) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('usuarios')
              .where('createdBy', isEqualTo: adminId)
              .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id; // Agregar el ID del documento
        return userData;
      }).toList();
    } catch (e) {
      print("Error al obtener usuarios creados por el administrador: $e");
      throw Exception("Error al obtener usuarios creados por el administrador");
    }
  }

  // Método para obtener todas las familias
  static Future<Map<String, String>> getFamilies() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('familias').get();

      Map<String, String> families = {};
      for (var doc in querySnapshot.docs) {
        families[doc.id] = doc['nombre'] ?? 'Sin nombre';
      }

      return families;
    } catch (e) {
      print("Error al obtener familias: $e");
      throw Exception("Error al obtener familias");
    }
  }

  static Future<String> reloadCurrentUserRole() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No se encontró al usuario actual.");
      }

      // Refrescar el usuario actual para asegurar que tenemos la información más reciente
      await currentUser.reload();

      final userDoc =
          await _firestore.collection('usuarios').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        throw Exception(
          "El usuario actual no tiene un documento en Firestore.",
        );
      }

      // Guardar el rol en nuestra variable estática
      _currentUserRole = userDoc['rol'] ?? ROLE_USER;

      return _currentUserRole!; // Devuelve el rol
    } catch (e) {
      print("Error al recargar el rol del usuario: $e");
      throw Exception("Error al recargar el rol del usuario.");
    }
  }

  // Método para eliminar un usuario
  static Future<void> deleteUser(String userId) async {
    try {
      // Obtener el documento del usuario
      DocumentSnapshot userDoc =
          await _firestore.collection('usuarios').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Eliminar al usuario de la familia si pertenece a una
        if (userData['familiaId'] != null) {
          await _firestore
              .collection('familias')
              .doc(userData['familiaId'])
              .update({
                'miembros': FieldValue.arrayRemove([userId]),
              });
        }

        // Eliminar el documento del usuario en Firestore
        await _firestore.collection('usuarios').doc(userId).delete();
      } else {
        print("El usuario no existe en Firestore.");
      }
    } catch (e) {
      print("Error al eliminar usuario: $e");
      throw Exception("Error al eliminar usuario: $e");
    }
  }

  // Método para iniciar sesión y cargar el rol del usuario
  static Future<Map<String, dynamic>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cargar inmediatamente el rol del usuario
      if (userCredential.user != null) {
        _currentUserRole = await getUserRole(userCredential.user!.uid);
      }

      return {
        'success': true,
        'user': userCredential.user,
        'role': _currentUserRole,
      };
    } catch (e) {
      print("Error al iniciar sesión: $e");
      return {'success': false, 'message': 'Error al iniciar sesión: $e'};
    }
  }

  // Método para cerrar sesión
  static Future<void> signOut() async {
    await _auth.signOut();
    _currentUserRole = null; // Limpiar el rol al cerrar sesión
  }
}