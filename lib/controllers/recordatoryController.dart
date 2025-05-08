import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recordatoryModel.dart';
import '../controllers/UserController.dart'; // Asegúrate de que la ruta sea correcta

class RecordatoryController extends ChangeNotifier {
  List<Recordatory> _recordatories = [];
  List<Map<String, dynamic>> _users = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'recordatorios';
  bool _isLoading = false;
  bool _isLoadingUsers = false;

  // Getters
  List<Recordatory> get recordatories => _recordatories;
  List<Map<String, dynamic>> get users => _users;
  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;

  // Constructor que carga los recordatorios desde Firebase
  RecordatoryController() {
    _fetchRecordatories();
    _fetchUsers(); // Cargamos usuarios al inicializar
  }

  Future<void> _fetchRecordatories() async {
    try {
      _isLoading = true;
      notifyListeners();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _recordatories = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Obtener recordatorios donde el usuario actual es el creador
      final querySnapshot =
          await _firestore
              .collection(_collectionName)
              .where('creatorId', isEqualTo: currentUser.uid)
              .get();

      _recordatories =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            return Recordatory.fromMap({
              'id': int.parse(doc.id),
              'title': data['title'],
              'date': data['date'],
              'activityId': data['activityId'],
              'time': data['time'] ?? '',
              'userId': data['userId'],
              'creatorId': data['creatorId'],
              'isNotificationEnabled': data['isNotificationEnabled'] ?? false,
              'repeat': data['repeat'] ?? 'ninguno',
              'repeatInterval': data['repeatInterval'],
              'repeatEndDate': data['repeatEndDate'],
            });
          }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error al cargar recordatorios: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para obtener usuarios creados por el usuario actual
  Future<void> _fetchUsers() async {
    try {
      _isLoadingUsers = true;
      notifyListeners();

      // Obtener el ID del usuario actual
      final currentUser = UserController.auth.currentUser;
      if (currentUser == null) {
        _users = [];
        _isLoadingUsers = false;
        notifyListeners();
        return;
      }

      // Verificar si el usuario actual es admin para determinar qué usuarios mostrar
      bool isAdmin = await UserController.isCurrentUserAdmin();

      if (isAdmin) {
        // Si es admin, obtener los usuarios que ha creado
        _users = await UserController.getUsersCreatedByAdmin(currentUser.uid);
      } else {
        // Si no es admin, obtener solo su propio usuario y los usuarios relacionados
        // Esto dependerá de tu lógica de negocio

        // Primero agregamos al usuario actual
        DocumentSnapshot userDoc =
            await _firestore.collection('usuarios').doc(currentUser.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          userData['id'] = currentUser.uid;
          _users = [userData];

          // Si el usuario tiene una familia, obtener los miembros de la familia
          if (userData.containsKey('familiaId') &&
              userData['familiaId'] != null) {
            DocumentSnapshot familyDoc =
                await _firestore
                    .collection('familias')
                    .doc(userData['familiaId'])
                    .get();
            if (familyDoc.exists) {
              Map<String, dynamic> familyData =
                  familyDoc.data() as Map<String, dynamic>;
              if (familyData.containsKey('miembros') &&
                  familyData['miembros'] is List) {
                List<dynamic> memberIds = familyData['miembros'];

                // Obtener detalles de cada miembro
                for (String memberId in memberIds) {
                  if (memberId != currentUser.uid) {
                    // Evitar duplicar el usuario actual
                    DocumentSnapshot memberDoc =
                        await _firestore
                            .collection('usuarios')
                            .doc(memberId)
                            .get();
                    if (memberDoc.exists) {
                      Map<String, dynamic> memberData =
                          memberDoc.data() as Map<String, dynamic>;
                      memberData['id'] = memberId;
                      _users.add(memberData);
                    }
                  }
                }
              }
            }
          }
        } else {
          _users = [];
        }
      }

      _isLoadingUsers = false;
      notifyListeners();
    } catch (e) {
      print('Error al cargar usuarios: $e');
      _isLoadingUsers = false;
      _users = [];
      notifyListeners();
    }
  }

  // Agregar método para obtener actividades
  Future<List<Map<String, dynamic>>> getActivities() async {
    try {
      final querySnapshot = await _firestore.collection('actividades').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'title': data['title'], ...data};
      }).toList();
    } catch (e) {
      print('Error al obtener actividades: $e');
      return [];
    }
  }

  // Método público para obtener usuarios (puede ser llamado desde la UI)
  Future<List<Map<String, dynamic>>> fetchUsersForCurrentUser() async {
    await _fetchUsers();
    return _users;
  }

  // Método de conveniencia para obtener la lista de usuarios actual
  List<Map<String, dynamic>> getUsers() {
    // Si los usuarios ya están cargados, devolver la lista
    // Si no, devolver una lista vacía (la carga está en proceso)
    return _users;
  }

  Future<void> addRecordatory(Recordatory recordatory) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Obtener el usuario actual (creador)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No hay usuario autenticado');

      // Crear el recordatorio con el ID del creador
      final recordatoryWithCreator = Recordatory(
        id: recordatory.id,
        title: recordatory.title,
        date: recordatory.date,
        time: recordatory.time,
        activityId: recordatory.activityId,
        userId:
            recordatory.userId, // ID del usuario para quien es el recordatorio
        creatorId: currentUser.uid, // ID del usuario que lo está creando
        isNotificationEnabled: recordatory.isNotificationEnabled,
        repeat: recordatory.repeat,
        repeatInterval: recordatory.repeatInterval,
        repeatEndDate: recordatory.repeatEndDate,
      );

      // Guardar en Firestore
      await _firestore
          .collection(_collectionName)
          .doc(recordatory.id.toString())
          .set(recordatoryWithCreator.toMap());

      // Actualizar lista local
      _recordatories.add(recordatoryWithCreator);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error al agregar recordatorio: $e');
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Eliminar un recordatorio
  Future<void> deleteRecordatory(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Primero eliminar de Firestore
      await _firestore.collection(_collectionName).doc(id.toString()).delete();

      // Luego eliminar de la lista local
      _recordatories.removeWhere((recordatory) => recordatory.id == id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error al eliminar recordatorio: $e');
      _isLoading = false;
      notifyListeners();
      throw e; // Relanzar la excepción para que se pueda manejar en la UI
    }
  }

  // Actualizar el estado de la notificación
  Future<void> toggleNotification(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      final index = _recordatories.indexWhere(
        (recordatory) => recordatory.id == id,
      );
      if (index != -1) {
        final recordatory = _recordatories[index];
        final updatedNotificationStatus = !recordatory.isNotificationEnabled;

        // Primero actualizar en Firestore
        await _firestore.collection(_collectionName).doc(id.toString()).update({
          'isNotificationEnabled': updatedNotificationStatus,
        });

        // Luego actualizar en la lista local
        _recordatories[index] = Recordatory(
          id: recordatory.id,
          title: recordatory.title,
          date: recordatory.date,
          activityId: recordatory.activityId,
          isNotificationEnabled: updatedNotificationStatus,
          time: recordatory.time,
          userId: recordatory.userId,
          creatorId: recordatory.creatorId, // Added missing parameter
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error al actualizar notificación: $e');
      _isLoading = false;
      notifyListeners();
      throw e; // Relanzar la excepción para que se pueda manejar en la UI
    }
  }

  // Al cargar recordatorios para un usuario específico
  Future<void> fetchRecordatoriesForUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot =
          await _firestore
              .collection(_collectionName)
              .where('userId', isEqualTo: userId)
              .get();

      _recordatories =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            return Recordatory.fromMap({
              'id': int.parse(doc.id),
              'title': data['title'],
              'date': data['date'],
              'type': data['type'],
              'time': data['time'] ?? '',
              'userId': data['userId'],
              'isNotificationEnabled': data['isNotificationEnabled'] ?? false,
            });
          }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error al cargar recordatorios para el usuario: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para refrescar la lista de usuarios
  Future<void> refreshUsers() async {
    await _fetchUsers();
  }
}
