import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recordatoryModel.dart';

class RecordatoryController extends ChangeNotifier {
  List<Recordatory> _recordatories = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'recordatorios';
  bool _isLoading = false;
  
  // Getters
  List<Recordatory> get recordatories => _recordatories;
  bool get isLoading => _isLoading;

  // Constructor que carga los recordatorios desde Firebase
  RecordatoryController() {
    _fetchRecordatories();
  }

  // Cargar recordatorios desde Firebase
  Future<void> _fetchRecordatories() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final querySnapshot = await _firestore.collection(_collectionName).get();
      _recordatories = querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Asegúrate de que el id sea un int (Firebase lo guarda como String)
        return Recordatory.fromMap({
          'id': int.parse(doc.id),
          'title': data['title'],
          'date': data['date'],
          'type': data['type'],
          'isNotificationEnabled': data['isNotificationEnabled'],
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

  // Agregar un nuevo recordatorio
  Future<void> addRecordatory(Recordatory recordatory) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Primero añadir a Firestore
      await _firestore.collection(_collectionName).doc(recordatory.id.toString()).set({
        'title': recordatory.title,
        'date': recordatory.date,
        'type': recordatory.type,
        'isNotificationEnabled': recordatory.isNotificationEnabled,
      });
      
      // Luego añadir a la lista local
      _recordatories.add(recordatory);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error al agregar recordatorio: $e');
      _isLoading = false;
      notifyListeners();
      throw e; // Relanzar la excepción para que se pueda manejar en la UI
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
      
      final index = _recordatories.indexWhere((recordatory) => recordatory.id == id);
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
          type: recordatory.type,
          isNotificationEnabled: updatedNotificationStatus,
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
}