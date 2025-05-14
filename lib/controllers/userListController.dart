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

  // Método para obtener el rol y la familia del usuario actual
  Future<Map<String, dynamic>> getCurrentUserInfo() async {
    try {
      final currentUser = UserController.auth.currentUser;
      if (currentUser == null) {
        print("No hay usuario actual logueado");
        return {'success': false, 'error': 'No hay usuario logueado'};
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(currentUser.uid)
              .get();

      if (!userDoc.exists) {
        print("No se encontró información del usuario en Firestore");
        return {'success': false, 'error': 'Usuario no encontrado'};
      }

      final userData = userDoc.data() ?? {};
      return {
        'success': true,
        'uid': currentUser.uid,
        'rol': userData['rol'] ?? 'desconocido',
        'familiaId': userData['familiaId'],
        'nombre': userData['nombre'] ?? 'Sin nombre',
        'isAdmin':
            userData['isAdmin'] == true ||
            userData['rol'] == UserController.ROLE_ADMIN,
      };
    } catch (e) {
      print("Error al obtener información del usuario: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> loadUsersAndFamilies() async {
    try {
      // Obtener información del usuario actual (rol, familia, etc.)
      final userInfo = await getCurrentUserInfo();

      if (!userInfo['success']) {
        print("Error al obtener información del usuario: ${userInfo['error']}");
        throw Exception(userInfo['error']);
      }

      final currentUserId = userInfo['uid'];
      final userRol = userInfo['rol'];
      final userFamiliaId = userInfo['familiaId'];
      final isAdmin = userInfo['isAdmin'] == true;

      print("Cargando usuarios para: ${userInfo['nombre']} (${userRol})");
      print("ID de familia del usuario: $userFamiliaId");
      print("¿Es administrador? $isAdmin");

      List<Map<String, dynamic>> usuarios = [];

      if (isAdmin) {
        // Si es administrador, mostrar los usuarios creados por él
        final usersSnapshot =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .where('createdBy', isEqualTo: currentUserId)
                .get();

        print(
          "Cantidad de usuarios encontrados para admin: ${usersSnapshot.docs.length}",
        );
        usuarios =
            usersSnapshot.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList();
      } else if (userRol == 'Familiar' && userFamiliaId != null) {
        // Si es familiar, mostrar solo los adultos de su familia
        final usersSnapshot =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .where('familiaId', isEqualTo: userFamiliaId)
                .where('rol', isEqualTo: 'Adulto') // Solo mostrar Adultos
                .get();

        print(
          "Cantidad de adultos encontrados para familiar: ${usersSnapshot.docs.length}",
        );
        usuarios =
            usersSnapshot.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList();
      } else {
        // Para otros roles, no mostrar usuarios o implementar lógica específica
        print("Rol no tiene permisos específicos para ver usuarios: $userRol");
      }

      // Obtener todas las familias (o solo la familia relevante para no-admin)
      Map<String, String> familias = {};

      if (isAdmin) {
        // Si es admin, cargar todas las familias
        final familiasSnapshot =
            await FirebaseFirestore.instance.collection('familias').get();

        for (var doc in familiasSnapshot.docs) {
          familias[doc.id] = doc.data()['nombre'] ?? 'Sin nombre';
        }
      } else if (userFamiliaId != null) {
        // Si no es admin, solo cargar su familia
        final familiaDoc =
            await FirebaseFirestore.instance
                .collection('familias')
                .doc(userFamiliaId)
                .get();

        if (familiaDoc.exists) {
          familias[userFamiliaId] =
              familiaDoc.data()?['nombre'] ?? 'Sin nombre';
        }
      }

      return {
        'success': true,
        'usuarios': usuarios,
        'familias': familias,
        'userInfo': {
          'rol': userRol,
          'familiaId': userFamiliaId,
          'isAdmin': isAdmin,
        },
      };
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
