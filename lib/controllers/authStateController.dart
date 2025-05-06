import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthStateController extends GetxController {
  final Rx<User?> _adminUser = Rx<User?>(null);
  final RxString _adminRole = ''.obs;

  User? get adminUser => _adminUser.value;
  String get adminRole => _adminRole.value;

  void setAdminUser(User user) {
    _adminUser.value = user;
  }

  void setAdminRole(String role) {
    _adminRole.value = role;
  }

  Future<void> initializeAdmin() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _adminUser.value = currentUser;
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .get();
      _adminRole.value = userDoc['rol'] ?? '';
    }
  }

  void clearAdmin() {
    _adminUser.value = null;
    _adminRole.value = '';
  }
}