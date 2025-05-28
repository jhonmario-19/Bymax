import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recordatoryModel.dart';
import '../controllers/UserController.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';

class RecordatoryController extends ChangeNotifier {
  List<Recordatory> _recordatories = [];
  List<Map<String, dynamic>> _users = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'recordatorios';
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  bool _initialLoadComplete = false;
  String? _fcmToken;
  String? _currentUserRole;
  String? _currentUserCreator;
  String? _currentUserFamilyId;
  String? get currentUserRole => _currentUserRole;
  final NotificationService _notificationService = NotificationService();
  // Getters
  List<Recordatory> get recordatories => _recordatories;
  List<Map<String, dynamic>> get users => _users;
  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;

  // Constructor que carga los recordatorios desde Firebase
  RecordatoryController() {
    _initCurrentUserInfo().then((_) {
      _fetchRecordatories();
      _fetchUsers();
      _initializeFCM();
      _initNotifications();
    });
  }

  // Nuevo método para inicializar notificaciones
  Future<void> _initNotifications() async {
    await _notificationService.init();
    Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredRecordatories();
    });

    // Programar notificaciones para recordatorios existentes
    if (_recordatories.isNotEmpty) {
      await _notificationService.scheduleAllNotifications(_recordatories);
    }
  }

  // Reemplaza este método completo
  Future<void> _initializeFCM() async {
    try {
      // Solicitar permisos explícitamente
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('Estado de permisos FCM: ${settings.authorizationStatus}');

      // Obtener el token FCM
      _fcmToken = await FirebaseMessaging.instance.getToken();

      if (_fcmToken != null) {
        print('Token FCM obtenido: ${_fcmToken!.substring(0, 20)}...');
        await _updateFCMToken();
      } else {
        print('No se pudo obtener el token FCM');
      }

      // Verificar notificaciones pendientes al iniciar sesión
      await checkPendingNotifications();

      // Configurar verificación periódica de notificaciones (cada 60 segundos)
      Timer.periodic(const Duration(seconds: 60), (_) {
        checkPendingNotifications();
      });

      // Escuchar cambios del token
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        print('Token FCM actualizado');
        _fcmToken = token;
        _updateFCMToken();
      });
    } catch (e) {
      print('Error al inicializar FCM: $e');
    }
  }

  Future<void> _initCurrentUserInfo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('usuarios').doc(currentUser.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _currentUserRole = userData['rol']?.toString() ?? 'Usuario';
        _currentUserCreator = userData['createdBy'];
        _currentUserFamilyId = userData['familiaId'];
        print(
          'Usuario actual rol: $_currentUserRole, creador: $_currentUserCreator, familia: $_currentUserFamilyId',
        );
      }
    } catch (e) {
      print('Error al obtener información del usuario actual: $e');
    }
  }

  Future<void> _updateFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _fcmToken == null) return;

    try {
      // Verificar si el token ha cambiado
      final userRef = _firestore.collection('usuarios').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists || userDoc.data()?['fcmToken'] != _fcmToken) {
        await userRef.update({
          'fcmToken': _fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'plataforma': Theme.of(Get.context!).platform.toString(),
        });
        print('Token FCM actualizado en Firestore');
      }
    } catch (e) {
      print('Error al actualizar token FCM: $e');
    }
  }

  // Manejar mensaje recibido
  void _handleMessage(RemoteMessage message) {
    // Refrescar recordatorios cuando se recibe una notificación
    _fetchRecordatories();
    notifyListeners();
  }

  Future<void> _loadRecordatoryCreators() async {
    try {
      if (_recordatories.isEmpty) return;

      // Recopilar todos los IDs de creadores que no son el usuario actual
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      Set<String> creatorIds = {};
      for (var recordatory in _recordatories) {
        if (recordatory.creatorId != currentUserId &&
            !_users.any((user) => user['id'] == recordatory.creatorId)) {
          creatorIds.add(recordatory.creatorId);
        }
      }

      // Si no hay creadores externos, terminar
      if (creatorIds.isEmpty) return;

      // Cargar información de estos usuarios
      for (String creatorId in creatorIds) {
        try {
          DocumentSnapshot creatorDoc =
              await _firestore.collection('usuarios').doc(creatorId).get();

          if (creatorDoc.exists) {
            Map<String, dynamic> creatorData =
                creatorDoc.data() as Map<String, dynamic>;
            creatorData['id'] = creatorId;

            // Añadir a la lista si no existe ya
            if (!_users.any((user) => user['id'] == creatorId)) {
              _users.add(creatorData);
            }
          }
        } catch (e) {
          print('Error al cargar información del creador $creatorId: $e');
        }
      }

      // Notificar cambios
      notifyListeners();
    } catch (e) {
      print('Error al cargar creadores de recordatorios: $e');
    }
  }

  Future<void> _fetchRecordatories() async {
    try {
      // Si ya hay una carga en progreso, no continuar
      if (_isLoading) return;

      _isLoading = true;
      notifyListeners();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _recordatories = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Lista para almacenar todos los recordatorios
      List<Recordatory> allRecordatories = [];

      // 1. Obtener recordatorios donde el usuario actual es el creador
      final querySnapshot =
          await _firestore
              .collection(_collectionName)
              .where('creatorId', isEqualTo: currentUser.uid)
              .get();

      allRecordatories =
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

      // 2. Si el usuario es admin, también obtener recordatorios creados por usuarios
      // que él creó (familiares)
      if (_currentUserRole == 'admin') {
        try {
          // Primero obtenemos los IDs de los usuarios creados por el admin
          final usersCreatedQuery =
              await _firestore
                  .collection('usuarios')
                  .where('createdBy', isEqualTo: currentUser.uid)
                  .get();

          List<String> familiarIds = [];

          // Filtramos para obtener solo los usuarios con rol 'Familiar'
          for (var userDoc in usersCreatedQuery.docs) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            if (userData['rol']?.toString() == 'Familiar') {
              familiarIds.add(userDoc.id);
            }
          }

          // Si hay familiares, buscar recordatorios creados por ellos
          if (familiarIds.isNotEmpty) {
            // No podemos usar 'whereIn' si la lista tiene más de 10 elementos
            if (familiarIds.length <= 10) {
              final familiarRecordatoriesQuery =
                  await _firestore
                      .collection(_collectionName)
                      .where('creatorId', whereIn: familiarIds)
                      .get();

              // Agregar estos recordatorios a la lista
              final familiarRecordatories =
                  familiarRecordatoriesQuery.docs.map((doc) {
                    final data = doc.data();
                    return Recordatory.fromMap({
                      'id': int.parse(doc.id),
                      'title': data['title'],
                      'date': data['date'],
                      'activityId': data['activityId'],
                      'time': data['time'] ?? '',
                      'userId': data['userId'],
                      'creatorId': data['creatorId'],
                      'isNotificationEnabled':
                          data['isNotificationEnabled'] ?? false,
                      'repeat': data['repeat'] ?? 'ninguno',
                      'repeatInterval': data['repeatInterval'],
                      'repeatEndDate': data['repeatEndDate'],
                    });
                  }).toList();

              allRecordatories.addAll(familiarRecordatories);
            } else {
              // Si hay más de 10 familiares, hacemos consultas individuales
              for (String familiarId in familiarIds) {
                final familiarRecordatoriesQuery =
                    await _firestore
                        .collection(_collectionName)
                        .where('creatorId', isEqualTo: familiarId)
                        .get();

                // Agregar estos recordatorios a la lista
                final familiarRecordatories =
                    familiarRecordatoriesQuery.docs.map((doc) {
                      final data = doc.data();
                      return Recordatory.fromMap({
                        'id': int.parse(doc.id),
                        'title': data['title'],
                        'date': data['date'],
                        'activityId': data['activityId'],
                        'time': data['time'] ?? '',
                        'userId': data['userId'],
                        'creatorId': data['creatorId'],
                        'isNotificationEnabled':
                            data['isNotificationEnabled'] ?? false,
                        'repeat': data['repeat'] ?? 'ninguno',
                        'repeatInterval': data['repeatInterval'],
                        'repeatEndDate': data['repeatEndDate'],
                      });
                    }).toList();

                allRecordatories.addAll(familiarRecordatories);
              }
            }
          }
        } catch (e) {
          print('Error al cargar recordatorios de familiares: $e');
        }
      }

      // Ordenar todos los recordatorios por fecha (más recientes primero)
      allRecordatories.sort((a, b) {
        // Convertir las fechas (formato dd/mm/yyyy) para comparación
        List<String> partsA = a.date.split('/');
        List<String> partsB = b.date.split('/');

        if (partsA.length == 3 && partsB.length == 3) {
          DateTime dateA = DateTime(
            int.parse(partsA[2]),
            int.parse(partsA[1]),
            int.parse(partsA[0]),
          );
          DateTime dateB = DateTime(
            int.parse(partsB[2]),
            int.parse(partsB[1]),
            int.parse(partsB[0]),
          );
          return dateB.compareTo(dateA); // Orden descendente
        }
        return 0;
      });

      _recordatories = allRecordatories;
      await _loadRecordatoryCreators();
      _initialLoadComplete = true;
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

        bool isAdultUser(Map<String, dynamic> user) {
          final role = user['rol']?.toString().toLowerCase() ?? '';
          return role == 'adulto';
        }

        // Solo agregar al usuario actual si es adulto
        if (isAdultUser(userData)) {
          _users = [userData];
        } else {
          _users = [];
        }

        // Lógica para Admin
        if (_currentUserRole == 'admin') {
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
        }
        // Lógica modificada para Familiar
        else if (_currentUserRole == 'Familiar') {
          try {
            // Verificar si el familiar tiene una familia asignada
            if (_currentUserFamilyId != null &&
                _currentUserFamilyId!.isNotEmpty) {
              // Buscar todos los miembros de la familia
              DocumentSnapshot familyDoc =
                  await _firestore
                      .collection('familias')
                      .doc(_currentUserFamilyId)
                      .get();

              if (familyDoc.exists) {
                Map<String, dynamic> familyData =
                    familyDoc.data() as Map<String, dynamic>;
                if (familyData.containsKey('miembros') &&
                    familyData['miembros'] is List) {
                  List<dynamic> memberIds = familyData['miembros'];
                  print(
                    'Miembros de la familia encontrados: ${memberIds.length}',
                  );

                  // Para cada miembro de la familia, obtener su información
                  for (String memberId in memberIds) {
                    if (memberId != currentUser.uid) {
                      // Excluir al usuario actual
                      DocumentSnapshot memberDoc =
                          await _firestore
                              .collection('usuarios')
                              .doc(memberId)
                              .get();

                      if (memberDoc.exists) {
                        Map<String, dynamic> memberData =
                            memberDoc.data() as Map<String, dynamic>;
                        memberData['id'] = memberId;

                        // Solo agregar usuarios Adulto
                        if (memberData['rol']?.toString().toLowerCase() ==
                            'adulto') {
                          _users.add(memberData);
                          print(
                            'Usuario Adulto añadido: ${memberData['nombre']}',
                          );
                        }
                      }
                    }
                  }
                }
              }
            } else {
              print('El usuario Familiar no tiene asignada una familia.');
            }
          } catch (e) {
            print('Error al buscar usuarios para familiar: $e');
          }
        }
        // Lógica para otros roles (Adulto, etc.)
        else {
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
      if (_initialLoadComplete) {
        _cleanupExpiredRecordatories();
      }
    }
  }

  Future<List<Map<String, dynamic>>> getActivities() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      QuerySnapshot querySnapshot;

      // Si es Familiar, cargar actividades de su creador
      if (_currentUserRole == 'Familiar' && _currentUserCreator != null) {
        querySnapshot =
            await _firestore
                .collection('actividades')
                .where('userId', isEqualTo: _currentUserCreator)
                .get();
      } else {
        // Para otros roles, cargar sus propias actividades
        querySnapshot =
            await _firestore
                .collection('actividades')
                .where('userId', isEqualTo: currentUser.uid)
                .get();
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
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
    return _users;
  }

  Future<void> addRecordatory(Recordatory recordatory) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Obtener el usuario actual (creador)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No hay usuario autenticado');

      // Validación para Familiar
      if (_currentUserRole == 'Familiar') {
        // Verificar que el usuario seleccionado está en la lista permitida
        if (!_users.any((user) => user['id'] == recordatory.userId)) {
          throw Exception(
            'No tienes permisos para asignar recordatorios a este usuario',
          );
        }
      }

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
          .set({
            ...recordatoryWithCreator.toMap(),
            'enviado': false, 
          });
      await notificarRecordatorioCreado(
        recordatory.userId,
        recordatory.title,
        recordatory.id,
      );

      // Actualizar lista local
      _recordatories.add(recordatoryWithCreator);
      if (recordatoryWithCreator.isNotificationEnabled) {
        await _notificationService.scheduleNotification(recordatoryWithCreator);
      }

      // Verificar si el usuario destinatario es diferente del creador
      if (recordatory.userId != currentUser.uid) {
        try {
          // Obtener información del usuario destino
          final userDoc =
              await _firestore
                  .collection('usuarios')
                  .doc(recordatory.userId)
                  .get();
          if (!userDoc.exists) return;

          final userData = userDoc.data()!;
          final userToken = userData['fcmToken'];
          final userName = userData['nombre'] ?? 'Usuario';

          // Obtener información del creador para personalizar el mensaje
          final creatorDoc =
              await _firestore
                  .collection('usuarios')
                  .doc(currentUser.uid)
                  .get();
          final creatorName =
              creatorDoc.exists
                  ? (creatorDoc.data()?['nombre'] ?? 'Alguien')
                  : 'Alguien';

          if (userToken != null) {
            // Crear datos adicionales útiles
            final notificationData = {
              'recordatoryId': recordatory.id.toString(),
              'creatorId': currentUser.uid,
              'userId': recordatory.userId,
              'route': '/recordatorio/detalle',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };

            // Enviar notificación
            await _sendNotificationToUser(
              token: userToken,
              title: '$creatorName te ha enviado un recordatorio',
              body: 'Nuevo recordatorio: ${recordatory.title}',
              data: notificationData,
            );

            print('Notificación enviada a $userName');
          }
        } catch (e) {
          print('Error al notificar al usuario destino: $e');
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

  Future<void> _sendNotificationToUser({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // En lugar de llamar directamente a FCM, almacena la notificación en una colección de Firestore
      final notificationData = {
        'token': token,
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'recipientId': data?['userId'] ?? '',
      };

      await _firestore.collection('pendingNotifications').add(notificationData);

      print('Notificación añadida a la cola: $title');
    } catch (e) {
      print('Error al agregar notificación a la cola: $e');
    }
  }

  Future<void> checkPendingNotifications() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final pendingNotifications =
          await _firestore
              .collection('pendingNotifications')
              .where('recipientId', isEqualTo: currentUser.uid)
              .where('status', isEqualTo: 'pending')
              .get();

      for (var doc in pendingNotifications.docs) {
        final notification = doc.data();
        // Mostrar como notificación local
        await _notificationService.showLocalNotification(
          doc.hashCode,
          notification['title'] ?? 'Nuevo recordatorio',
          notification['body'] ?? '',
          notification['data']?['recordatoryId']?.toString(),
        );

        // Actualizar estado
        await doc.reference.update({'status': 'delivered'});
      }
    } catch (e) {
      print('Error al verificar notificaciones pendientes: $e');
    }
  }

  // Eliminar un recordatorio
  Future<void> deleteRecordatory(int id) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _notificationService.cancelNotification(id);
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

        // Programar o cancelar notificación local
        final updatedRecordatory = _recordatories[index];
        if (updatedNotificationStatus) {
          await _notificationService.scheduleNotification(updatedRecordatory);
        } else {
          await _notificationService.cancelNotification(id);
        }
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

  Future<void> rescheduleAllNotifications() async {
    try {
      // Primero cancelar todas las notificaciones existentes
      await _notificationService.cancelAllNotifications();

      // Luego programar las que tienen notificaciones habilitadas
      final enabledRecordatories =
          _recordatories.where((r) => r.isNotificationEnabled).toList();

      await _notificationService.scheduleAllNotifications(enabledRecordatories);

      print(
        'Todas las notificaciones reprogramadas: ${enabledRecordatories.length}',
      );
    } catch (e) {
      print('Error al reprogramar notificaciones: $e');
    }
  }

  Future<void> fetchRecordatoriesForUser(String userId) async {
    // Evitar múltiples cargas simultáneas
    if (_isLoading) return;

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

      try {
        await rescheduleAllNotifications();
      } catch (e) {
        print('Error al programar notificaciones después de cargar: $e');
      }

      _initialLoadComplete = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error al cargar recordatorios para el usuario: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método nuevo para llamar desde la pantalla de inicio
  Future<void> checkForMissedNotifications() async {
    try {
      await checkPendingNotifications();

      // También reprogramar notificaciones locales
      if (_recordatories.isNotEmpty) {
        final now = DateTime.now();

        // Filtrar recordatorios futuros
        final futureRecordatories =
            _recordatories.where((r) {
              if (!r.isNotificationEnabled) return false;

              final dateParts = r.date.split('/');
              final timeParts = r.time.split(':');

              if (dateParts.length != 3 || timeParts.length != 2) return false;

              try {
                final day = int.parse(dateParts[0]);
                final month = int.parse(dateParts[1]);
                final year = int.parse(dateParts[2]);
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);

                final recordatoryDate = DateTime(
                  year,
                  month,
                  day,
                  hour,
                  minute,
                );
                return recordatoryDate.isAfter(now);
              } catch (e) {
                return false;
              }
            }).toList();

        await _notificationService.scheduleAllNotifications(
          futureRecordatories,
        );
        print(
          '${futureRecordatories.length} notificaciones reprogramadas al iniciar sesión',
        );
      }
      await _cleanupExpiredRecordatories();
    } catch (e) {
      print('Error al verificar notificaciones perdidas: $e');
    }
  }

  Recordatory? findRecordatoryById(int recordatoryId) {
    try {
      final recordatory = _recordatories.firstWhere(
        (recordatory) => recordatory.id == recordatoryId,
      );

      return recordatory;
    } on StateError catch (_) {
      print(
        'Recordatorio con ID $recordatoryId no encontrado en la lista local',
      );
      return null;
    } catch (e) {
      print(
        'Error inesperado al buscar recordatorio con ID $recordatoryId: $e',
      );
      return null;
    }
  }

  Future<void> scheduleAllAlarmsForUser(String userId) async {
    try {
      final notificationService = NotificationService();

      // Programar alarmas para todos los recordatorios no leídos
      for (final recordatorio in _recordatories) {
        if (!recordatorio.isRead) {
          await notificationService.scheduleRecordatoryAlarm(recordatorio);
        }
      }

      print(
        '${_recordatories.length} alarmas programadas para el usuario $userId',
      );
    } catch (e) {
      print('Error al programar alarmas: $e');
    }
  }

  Future<void> _cleanupExpiredRecordatories() async {
    try {
      final now = DateTime.now();
      final recordatoriesToRemove = <Recordatory>[];
      final recordatoriesToUpdate = <Recordatory>[];

      for (final recordatory in _recordatories) {
        final timeString = NotificationService().convertTo24HourFormat(
          recordatory.time,
        );
        final dateParts = recordatory.date.split('/');
        final timeParts = timeString.split(':');

        if (dateParts.length != 3 || timeParts.length != 2) continue;

        try {
          final day = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final year = int.parse(dateParts[2]);
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);

          final recordatoryDateTime = DateTime(year, month, day, hour, minute);
          final fiveMinutesAfter = recordatoryDateTime.add(
            Duration(minutes: 5),
          );

          // Si han pasado 5 minutos
          if (now.isAfter(fiveMinutesAfter)) {
            if (recordatory.repeat == 'ninguno') {
              // No se repite, eliminar
              recordatoriesToRemove.add(recordatory);
            } else {
              // Se repite, calcular siguiente fecha
              DateTime? nextDate = _calculateNextRepeatDate(
                recordatoryDateTime,
                recordatory.repeat,
                recordatory.repeatInterval,
              );

              if (nextDate != null) {
                // Verificar si no ha pasado la fecha final
                if (recordatory.repeatEndDate.isNotEmpty) {
                  final endDateParts = recordatory.repeatEndDate.split('/');
                  if (endDateParts.length == 3) {
                    final endDate = DateTime(
                      int.parse(endDateParts[2]),
                      int.parse(endDateParts[1]),
                      int.parse(endDateParts[0]),
                    );

                    if (nextDate.isAfter(endDate)) {
                      recordatoriesToRemove.add(recordatory);
                      continue;
                    }
                  }
                }

                // Actualizar fecha
                final updatedRecordatory = Recordatory(
                  id: recordatory.id,
                  title: recordatory.title,
                  date:
                      "${nextDate.day.toString().padLeft(2, '0')}/${nextDate.month.toString().padLeft(2, '0')}/${nextDate.year}",
                  time: recordatory.time,
                  activityId: recordatory.activityId,
                  userId: recordatory.userId,
                  creatorId: recordatory.creatorId,
                  isNotificationEnabled: recordatory.isNotificationEnabled,
                  repeat: recordatory.repeat,
                  repeatInterval: recordatory.repeatInterval,
                  repeatEndDate: recordatory.repeatEndDate,
                );
                recordatoriesToUpdate.add(updatedRecordatory);
              } else {
                recordatoriesToRemove.add(recordatory);
              }
            }
          }
        } catch (e) {
          print('Error procesando recordatorio ${recordatory.id}: $e');
        }
      }

      // Eliminar recordatorios expirados
      for (final recordatory in recordatoriesToRemove) {
        await _firestore
            .collection(_collectionName)
            .doc(recordatory.id.toString())
            .delete();
        _recordatories.removeWhere((r) => r.id == recordatory.id);
        await _notificationService.cancelNotification(recordatory.id);
      }

      // Actualizar recordatorios repetitivos
      for (final recordatory in recordatoriesToUpdate) {
        await _firestore
            .collection(_collectionName)
            .doc(recordatory.id.toString())
            .set(recordatory.toMap());
        final index = _recordatories.indexWhere((r) => r.id == recordatory.id);
        if (index != -1) {
          _recordatories[index] = recordatory;
          if (recordatory.isNotificationEnabled) {
            await _notificationService.scheduleNotification(recordatory);
          }
        }
      }

      if (recordatoriesToRemove.isNotEmpty ||
          recordatoriesToUpdate.isNotEmpty) {
        notifyListeners();
        print(
          'Limpieza completada: ${recordatoriesToRemove.length} eliminados, ${recordatoriesToUpdate.length} actualizados',
        );
      }
    } catch (e) {
      print('Error en limpieza de recordatorios: $e');
    }
  }

  DateTime? _calculateNextRepeatDate(
    DateTime currentDate,
    String repeat,
    int? interval,
  ) {
    try {
      switch (repeat.toLowerCase()) {
        case 'diario':
          return currentDate.add(Duration(days: interval ?? 1));
        case 'semanal':
          return currentDate.add(Duration(days: (interval ?? 1) * 7));
        case 'mensual':
          final nextMonth = DateTime(
            currentDate.year,
            currentDate.month + (interval ?? 1),
            currentDate.day,
            currentDate.hour,
            currentDate.minute,
          );
          return nextMonth;
        default:
          return null;
      }
    } catch (e) {
      print('Error calculando siguiente fecha: $e');
      return null;
    }
  }

  // Método para refrescar la lista de usuarios explícitamente
  Future<void> refreshUsers() async {
    await _fetchUsers();
  }

  Future<void> notificarRecordatorioCreado(
    String userId,
    String title,
    int recordatoryId,
  ) async {
    final url = Uri.parse(
      'https://backend-bymax.onrender.com/recordatory-created',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'title': title,
        'recordatoryId': recordatoryId,
      }),
    );
    print('Respuesta notificación inmediata: ${response.body}');
  }
}