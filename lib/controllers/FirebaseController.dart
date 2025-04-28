import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseController {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método existente para registro de cuentas
  static Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String nombre,
    required String username,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Guardar información adicional en Firestore
      await _firestore.collection('adultos').doc(userCredential.user!.uid).set({
        'nombre': nombre,
        'email': email,
        'username': username,
        'fechaRegistro': DateTime.now(),
        'rol': 'usuario', // Por defecto es usuario regular
      });

      return userCredential.user;
    } catch (e) {
      rethrow; // Lanzamos el error para manejarlo en la UI
    }
  }

  // Nuevo método para registrar usuarios desde la página AddUserPage
  static Future<User?> registerUser({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Primero creamos el usuario en Firebase Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Luego guardamos la información adicional en Firestore
      await _firestore
          .collection('adultos')
          .doc(userCredential.user!.uid)
          .set(userData);

      // Opcionalmente, podrías enviar un correo para restablecer la contraseña
      // await _auth.sendPasswordResetEmail(email: email);

      return userCredential.user;
    } catch (e) {
      print("Error al registrar usuario: $e");
      rethrow;
    }
  }

  // Método para obtener todos los usuarios
  static Stream<QuerySnapshot> getUsers() {
    return _firestore.collection('adultos').snapshots();
  }

  // Método para obtener un usuario específico por ID
  static Future<DocumentSnapshot> getUserById(String userId) {
    return _firestore.collection('adultos').doc(userId).get();
  }

  // Método para actualizar datos de un usuario
  static Future<void> updateUserData(String userId, Map<String, dynamic> data) {
    return _firestore.collection('adultos').doc(userId).update(data);
  }

  // Método para eliminar un usuario
  static Future<void> deleteUser(String userId) async {
    // Eliminar de Firestore
    await _firestore.collection('adultos').doc(userId).delete();

    // Para eliminar de Authentication, se necesitaría que el usuario esté autenticado
    // y llamar a _auth.currentUser!.delete();
  }
}
