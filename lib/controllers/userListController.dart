import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/userController.dart';

class UserListController {
  // Singleton pattern
  static final UserListController _instance = UserListController._internal();

  factory UserListController() {
    return _instance;
  }

  UserListController._internal();

  // Método para verificar el acceso del administrador
  Future<bool> verifyAdminAccess() async {
    try {
      // Obtener el usuario actual
      final currentUser = UserController.auth.currentUser;
      if (currentUser == null) {
        print("No hay usuario actual logueado");
        return false;
      }

      // Obtener los datos del usuario desde Firestore
      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(currentUser.uid)
              .get();

      // Verificar si el usuario existe y es admin
      final isAdmin =
          userDoc.exists &&
          (userDoc.data()?['isAdmin'] == true ||
              userDoc.data()?['rol'] == UserController.ROLE_ADMIN);
      print("Usuario ${currentUser.uid} es admin: $isAdmin");
      return isAdmin;
    } catch (e) {
      print("Error al verificar acceso de administrador: $e");
      return false;
    }
  }

  // Método para cargar usuarios y familias
  Future<Map<String, dynamic>> loadUsersAndFamilies() async {
    try {
      // Obtener el usuario actual
      final currentUser = UserController.auth.currentUser;
      if (currentUser == null) {
        print("No se encontró al usuario actual.");
        throw Exception("No se encontró al usuario actual.");
      }

      print("Cargando usuarios para el admin: ${currentUser.uid}");

      // Primero verificamos el rol de admin directamente en Firestore
      final adminDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(currentUser.uid)
              .get();

      if (!adminDoc.exists ||
          !(adminDoc.data()?['isAdmin'] == true ||
              adminDoc.data()?['rol'] == UserController.ROLE_ADMIN)) {
        print("Usuario no tiene permisos de administrador");
        throw Exception("No tienes permisos de administrador.");
      }

      // Obtener usuarios creados por este admin
      final usersSnapshot =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .where('createdBy', isEqualTo: currentUser.uid)
              .get();

      print("Cantidad de usuarios encontrados: ${usersSnapshot.docs.length}");

      // Si no hay usuarios, intentamos verificar si hay algún problema
      if (usersSnapshot.docs.isEmpty) {
        print(
          "No se encontraron usuarios creados por este admin. Verificando si existen usuarios:",
        );
        // Verificar si hay usuarios en general (para depuración)
        final allUsersSnapshot =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .limit(5)
                .get();

        print(
          "Total de usuarios en la colección: ${allUsersSnapshot.docs.length}",
        );

        if (allUsersSnapshot.docs.isNotEmpty) {
          print("Ejemplos de usuarios existentes:");
          for (var doc in allUsersSnapshot.docs) {
            print("Usuario ID: ${doc.id}");
            print("  createdBy: ${doc.data()['createdBy'] ?? 'No definido'}");
            print("  nombre: ${doc.data()['nombre'] ?? 'Sin nombre'}");
          }
        }
      }

      List<Map<String, dynamic>> usuarios =
          usersSnapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList();

      // Obtener todas las familias
      final familiasSnapshot =
          await FirebaseFirestore.instance.collection('familias').get();

      print(
        "Cantidad de familias encontradas: ${familiasSnapshot.docs.length}",
      );

      Map<String, String> familias = {};
      for (var doc in familiasSnapshot.docs) {
        familias[doc.id] = doc.data()['nombre'] ?? 'Sin nombre';
      }

      return {'success': true, 'usuarios': usuarios, 'familias': familias};
    } catch (e) {
      print("Error al cargar usuarios y familias: $e");
      return {
        'success': false,
        'error': e.toString(),
        'usuarios': [],
        'familias': {},
      };
    }
  }

  // Método para filtrar usuarios por rol
  List<Map<String, dynamic>> filterUsersByRole(
    List<Map<String, dynamic>> usuarios,
    String rol,
  ) {
    if (rol == 'Todos') {
      return usuarios;
    }
    return usuarios.where((user) => user['rol'] == rol).toList();
  }

  // Método para obtener el nombre de la familia
  String getFamilyName(Map<String, String> familias, String? familiaId) {
    if (familiaId == null) return 'Sin familia';
    return familias[familiaId] ?? 'Familia desconocida';
  }

  // Método para cerrar sesión
  Future<Map<String, dynamic>> signOut() async {
    try {
      await UserController.signOut();
      return {'success': true, 'message': 'Sesión cerrada correctamente'};
    } catch (e) {
      return {'success': false, 'message': 'Error al cerrar sesión: $e'};
    }
  }
}
