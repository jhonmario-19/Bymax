import 'package:bymax/models/activitiesModel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityController extends ChangeNotifier {
  List<Activity> _activities = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'actividades';
  bool _isLoading = false;

  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;

  ActivityController() {
    fetchActivitiesForCurrentUser();
  }

  // Cargar solo actividades del usuario en sesión
  Future<void> fetchActivitiesForCurrentUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _activities = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final querySnapshot =
          await _firestore
              .collection(_collectionName)
              .where('userId', isEqualTo: currentUser.uid)
              .get();

      _activities =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            return Activity.fromMap({
              'id': doc.id,
              'title': data['title'],
              'description': data['description'] ?? '',
              'date': data['date'] ?? '',
              'time': data['time'] ?? '',
              'userId': data['userId'] ?? '',
            });
          }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error al cargar actividades: $e');
      _isLoading = false;
      notifyListeners();
      rethrow; // Re-lanzar la excepción para que se maneje en la UI
    }
  }

  // Crear una nueva actividad con el userId del usuario en sesión
  Future<void> addActivity(Activity activity) async {
    try {
      _isLoading = true;
      notifyListeners();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Crear el documento en Firestore
      final activityData = {
        'title': activity.title,
        'description': activity.description,
        'date': activity.date,
        'time': activity.time,
        'userId': currentUser.uid,
      };

      final docRef = await _firestore
          .collection(_collectionName)
          .add(activityData);

      // Añadir la actividad a la lista local con su ID asignado
      final newActivity = activity.copyWith(
        id: docRef.id,
        userId: currentUser.uid,
      );
      _activities.add(newActivity);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error al agregar actividad: $e');
      _isLoading = false;
      notifyListeners();
      rethrow; // Re-lanzar la excepción para que se maneje en la UI
    }
  }

  // Modificar una actividad existente
  Future<void> updateActivity(Activity activity) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection(_collectionName)
          .doc(activity.id)
          .update(activity.toMap());

      final index = _activities.indexWhere((a) => a.id == activity.id);
      if (index != -1) {
        _activities[index] = activity;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error al actualizar actividad: $e');
      _isLoading = false;
      notifyListeners();
      rethrow; // Re-lanzar la excepción para que se maneje en la UI
    }
  }

  // Eliminar una actividad
  Future<void> deleteActivity(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection(_collectionName).doc(id).delete();
      _activities.removeWhere((activity) => activity.id == id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error al eliminar actividad: $e');
      _isLoading = false;
      notifyListeners();
      rethrow; // Re-lanzar la excepción para que se maneje en la UI
    }
  }
}
