import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthStateController extends GetxController {
  // Usuario administrador actual
  final Rx<User?> _adminUser = Rx<User?>(null);
  final RxString _adminRole = ''.obs;

  // Getters para acceder al usuario y rol
  User? get adminUser => _adminUser.value;
  String get adminRole => _adminRole.value;

  // Establecer el usuario administrador
  void setAdminUser(User user) {
    _adminUser.value = user;
  }

  // Establecer el rol del administrador
  void setAdminRole(String role) {
    _adminRole.value = role;
  }

  // Inicializar el usuario administrador y su rol
  Future<void> initializeAdmin() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _adminUser.value = currentUser;

        // Obtener el documento del usuario desde Firestore
        final userDoc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(currentUser.uid)
                .get();

        // Verificar si el documento existe y establecer el rol
        if (userDoc.exists) {
          _adminRole.value = userDoc['rol'] ?? '';
        } else {
          _adminRole.value = '';
          print("El documento del usuario no existe en Firestore.");
        }
      } else {
        print("No hay un usuario autenticado.");
      }
    } catch (e) {
      print("Error al inicializar el administrador: $e");
      _adminRole.value = '';
    }
  }

  // Limpiar los datos del administrador
  void clearAdmin() {
    _adminUser.value = null;
    _adminRole.value = '';
  }
}
