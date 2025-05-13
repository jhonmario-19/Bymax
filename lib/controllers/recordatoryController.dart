import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recordatoryModel.dart';
import '../controllers/UserController.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class RecordatoryController extends ChangeNotifier {
  List<Recordatory> _recordatories = [];
  List<Map<String, dynamic>> _users = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'recordatorios';
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  String? _fcmToken;

  // Getters
  List<Recordatory> get recordatories => _recordatories;
  List<Map<String, dynamic>> get users => _users;
  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;

  // Constructor que carga los recordatorios desde Firebase
  RecordatoryController() {
    _fetchRecordatories();
    _fetchUsers(); // Cargamos usuarios al inicializar
    _initializeFCM();
  }

  // Configurar FCM
  Future<void> _initializeFCM() async {
    // Obtener el token FCM
    _fcmToken = await FirebaseMessaging.instance.getToken();

    // Actualizar el token en Firestore
    _updateFCMToken();

    // Escuchar cambios del token
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _updateFCMToken();
    });

    // Configurar manejo de mensajes
    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  // Actualizar el token FCM en Firestore
  Future<void> _updateFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _fcmToken != null) {
      await _firestore.collection('usuarios').doc(user.uid).update({
        'fcmToken': _fcmToken,
      });
    }
  }

  // Manejar mensaje recibido
  void _handleMessage(RemoteMessage message) {
    // Refrescar recordatorios cuando se recibe una notificación
    _fetchRecordatories();
    notifyListeners();
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

  Future<void> _fetchUsers() async {
    try {
      _isLoadingUsers = true;
      notifyListeners();

      final currentUser = UserController.auth.currentUser;
      if (currentUser == null) {
        _users = [];
        _isLoadingUsers = false;
        notifyListeners();
        return;
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('usuarios').doc(currentUser.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userData['id'] = currentUser.uid;

        // Función auxiliar para normalizar la comparación de roles
        bool isAdultUser(Map<String, dynamic> user) {
          final role = user['rol']?.toString().toLowerCase() ?? '';
          return role == 'adulto'; // Ahora compara en minúsculas
        }

        // Solo agregar al usuario actual si es adulto (sin importar mayúsculas)
        if (isAdultUser(userData)) {
          _users = [userData];
        } else {
          _users = [];
        }

        bool isAdmin = userData['rol']?.toString().toLowerCase() == 'admin';
        print('Usuario actual: ${userData['nombre']} - Es admin: $isAdmin');

        if (isAdmin) {
          try {
            QuerySnapshot usersCreatedQuery =
                await _firestore
                    .collection('usuarios')
                    .where('createdBy', isEqualTo: currentUser.uid)
                    .get();

            for (var doc in usersCreatedQuery.docs) {
              Map<String, dynamic> userCreatedData =
                  doc.data() as Map<String, dynamic>;
              userCreatedData['id'] = doc.id;

              if (doc.id != currentUser.uid && isAdultUser(userCreatedData)) {
                _users.add(userCreatedData);
              }
            }
          } catch (e) {
            print('Error al buscar usuarios creados por admin: $e');
          }
        } else {
          try {
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

                  for (String memberId in memberIds) {
                    if (memberId != currentUser.uid) {
                      DocumentSnapshot memberDoc =
                          await _firestore
                              .collection('usuarios')
                              .doc(memberId)
                              .get();
                      if (memberDoc.exists) {
                        Map<String, dynamic> memberData =
                            memberDoc.data() as Map<String, dynamic>;
                        memberData['id'] = memberId;

                        if (isAdultUser(memberData)) {
                          _users.add(memberData);
                        }
                      }
                    }
                  }
                }
              }
            }
          } catch (e) {
            print('Error al buscar miembros de familia: $e');
          }

          try {
            QuerySnapshot responsableQuery =
                await _firestore
                    .collection('usuarios')
                    .where('responsableId', isEqualTo: currentUser.uid)
                    .get();

            for (var doc in responsableQuery.docs) {
              Map<String, dynamic> userAssignedData =
                  doc.data() as Map<String, dynamic>;
              userAssignedData['id'] = doc.id;

              if (doc.id != currentUser.uid &&
                  !_users.any((u) => u['id'] == doc.id) &&
                  isAdultUser(userAssignedData)) {
                _users.add(userAssignedData);
              }
            }
          } catch (e) {
            print('Error al buscar usuarios asignados: $e');
          }
        }
      }

      print('Total de usuarios adultos cargados: ${_users.length}');
      _isLoadingUsers = false;
      notifyListeners();
    } catch (e) {
      print('Error al cargar usuarios: $e');
      _isLoadingUsers = false;
      _users = [];
      notifyListeners();
    }
  }

  // Método modificado para obtener solo las actividades del usuario actual
  Future<List<Map<String, dynamic>>> getActivities() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      final querySnapshot =
          await _firestore
              .collection('actividades')
              .where('userId', isEqualTo: currentUser.uid)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'date': data['date'] ?? '',
          'time': data['time'] ?? '',
          'userId': data['userId'] ?? currentUser.uid,
        };
      }).toList();
    } catch (e) {
      print('Error al obtener actividades del usuario: $e');
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

      // Verificar si el usuario destinatario es diferente del creador
      if (recordatory.userId != currentUser.uid) {
        // Obtener token FCM del usuario destinatario
        final userDoc =
            await _firestore
                .collection('usuarios')
                .doc(recordatory.userId)
                .get();
        final userData = userDoc.data();
        final userToken = userData?['fcmToken'];

        if (userToken != null) {
          // Enviar notificación a través de tu backend o servicio de terceros
          await _sendNotificationToUser(
            token: userToken,
            title: 'Nuevo recordatorio',
            body: recordatory.title,
            data: {'recordatoryId': recordatory.id.toString()},
          );
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error al agregar recordatorio: $e');
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Método para marcar un recordatorio como leído
  Future<void> markRecordatoryAsRead(int id) async {
    try {
      final index = _recordatories.indexWhere((r) => r.id == id);
      if (index != -1) {
        // Actualizar en Firestore
        await _firestore.collection(_collectionName).doc(id.toString()).update({
          'isRead': true,
        });

        // Actualizar localmente
        final recordatory = _recordatories[index];
        _recordatories[index] = Recordatory(
          id: recordatory.id,
          title: recordatory.title,
          date: recordatory.date,
          time: recordatory.time,
          activityId: recordatory.activityId,
          userId: recordatory.userId,
          creatorId: recordatory.creatorId,
          isNotificationEnabled: recordatory.isNotificationEnabled,
          repeat: recordatory.repeat,
          repeatInterval: recordatory.repeatInterval,
          repeatEndDate: recordatory.repeatEndDate,
          isRead: true,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error al marcar recordatorio como leído: $e');
    }
  }

  // Método para enviar notificación (usando REST API de FCM)
  Future<void> _sendNotificationToUser({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Aquí utilizaremos una solución alternativa a Cloud Functions
    // Puedes implementar un servicio de terceros como OneSignal o un backend simple

    // Nota: Esta clave no es segura en producción, usa un backend intermedio
    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'key=TU_CLAVE_DE_SERVIDOR', // Reemplazar con tu clave real de Firebase
      },
      body: jsonEncode({
        'to': token,
        'notification': {'title': title, 'body': body},
        'data': data ?? {},
      }),
    );

    if (response.statusCode != 200) {
      print('Error enviando notificación: ${response.body}');
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
          creatorId: recordatory.creatorId,
          repeat: recordatory.repeat,
          repeatInterval: recordatory.repeatInterval,
          repeatEndDate: recordatory.repeatEndDate,
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
              'id': data['id'] ?? int.tryParse(doc.id) ?? 0,
              'title': data['title'] ?? '',
              'date': data['date'] ?? '',
              'activityId': data['activityId'] ?? '',
              'time': data['time'] ?? '',
              'userId': data['userId'] ?? '',
              'creatorId': data['creatorId'] ?? '',
              'isNotificationEnabled': data['isNotificationEnabled'] ?? false,
              'repeat': data['repeat'] ?? 'ninguno',
              'repeatInterval': data['repeatInterval'] ?? 0,
              'repeatEndDate': data['repeatEndDate'] ?? '',
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

  // Método para refrescar la lista de usuarios explícitamente
  Future<void> refreshUsers() async {
    await _fetchUsers();
  }
}
