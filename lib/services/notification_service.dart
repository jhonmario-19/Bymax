import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recordatoryModel.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Mapa para almacenar las IDs programadas y sus correspondientes recordatorios
  final Map<int, int> _scheduledNotifications =
      {}; // <notificationId, recordatorioId>

  // Inicializar el servicio de notificaciones
  Future<void> init() async {
    tz_init.initializeTimeZones();

    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permisos en iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Configurar canales para Android
    await _setupNotificationChannels();

    // Recuperar notificaciones guardadas
    await _loadScheduledNotificationsFromPrefs();
  }

  Future<void> _setupNotificationChannels() async {
    // Canal para notificaciones de recordatorios
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Recordatorios',
      description: 'Notificaciones de recordatorios importantes',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Manejar cuando el usuario toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    // Extraer el ID del recordatorio de la carga útil
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        // Aquí podrías navegar a una pantalla específica o realizar una acción
        print('Notificación tocada: recordatorio ID $payload');
        // Implementa la navegación según tus necesidades
      } catch (e) {
        print('Error al procesar la notificación: $e');
      }
    }
  }

  // Programar una notificación para un recordatorio
  Future<void> scheduleNotification(Recordatory recordatorio) async {
    if (!recordatorio.isNotificationEnabled) {
      print('Notificaciones desactivadas para este recordatorio');
      return;
    }

    try {
      // Convertir fecha y hora del recordatorio a DateTime
      final dateTimeParts = recordatorio.date.split('/');
      final timeParts = recordatorio.time.split(':');

      if (dateTimeParts.length != 3 || timeParts.length != 2) {
        print('Formato de fecha u hora inválido');
        return;
      }

      final day = int.parse(dateTimeParts[0]);
      final month = int.parse(dateTimeParts[1]);
      final year = int.parse(dateTimeParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final scheduledDate = DateTime(year, month, day, hour, minute);

      // Verificar si la fecha ya pasó
      if (scheduledDate.isBefore(DateTime.now())) {
        print(
          'La fecha del recordatorio ya pasó: ${recordatorio.date} ${recordatorio.time}',
        );
        return;
      }

      // Crear zona horaria local
      final scheduledTzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      // ID único para la notificación
      final notificationId = recordatorio.id;

      // Configurar detalles de la notificación
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'high_importance_channel',
            'Recordatorios',
            channelDescription: 'Notificaciones de recordatorios importantes',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'Nuevo recordatorio',
            styleInformation: BigTextStyleInformation(
              recordatorio.title,
              contentTitle: 'Recordatorio: ${recordatorio.title}',
              summaryText: 'Hora: ${recordatorio.time}',
            ),
          );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Programar la notificación
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Recordatorio: ${recordatorio.title}',
        'Hora: ${recordatorio.time}',
        scheduledTzDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: recordatorio.id.toString(),
      );

      // Guardar referencia a la notificación programada
      _scheduledNotifications[notificationId] = recordatorio.id;
      await _saveScheduledNotificationsToPrefs();

      print(
        'Notificación programada para: ${recordatorio.title} a las ${recordatorio.time} del ${recordatorio.date}',
      );
    } catch (e) {
      print('Error al programar notificación: $e');
    }
  }

  // Programar notificaciones para una lista de recordatorios
  Future<void> scheduleAllNotifications(List<Recordatory> recordatorios) async {
    // Primero cancelar todas las notificaciones existentes
    await cancelAllNotifications();

    // Luego programar las nuevas
    for (final recordatorio in recordatorios) {
      if (recordatorio.isNotificationEnabled) {
        await scheduleNotification(recordatorio);
      }
    }
  }

  // Cancelar una notificación específica
  Future<void> cancelNotification(int recordatorioId) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(recordatorioId);
      _scheduledNotifications.removeWhere(
        (key, value) => value == recordatorioId,
      );
      await _saveScheduledNotificationsToPrefs();
      print('Notificación cancelada para recordatorio ID: $recordatorioId');
    } catch (e) {
      print('Error al cancelar notificación: $e');
    }
  }

  // Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      _scheduledNotifications.clear();
      await _saveScheduledNotificationsToPrefs();
      print('Todas las notificaciones canceladas');
    } catch (e) {
      print('Error al cancelar todas las notificaciones: $e');
    }
  }

  // Guardar las notificaciones programadas en las preferencias
  Future<void> _saveScheduledNotificationsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationIds = _scheduledNotifications.keys.toList();
      final recordatorioIds = _scheduledNotifications.values.toList();

      await prefs.setStringList(
        'notification_ids',
        notificationIds.map((id) => id.toString()).toList(),
      );
      await prefs.setStringList(
        'recordatorio_ids',
        recordatorioIds.map((id) => id.toString()).toList(),
      );
    } catch (e) {
      print('Error al guardar notificaciones programadas: $e');
    }
  }

  // Cargar las notificaciones programadas desde las preferencias
  Future<void> _loadScheduledNotificationsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationIds = prefs.getStringList('notification_ids') ?? [];
      final recordatorioIds = prefs.getStringList('recordatorio_ids') ?? [];

      if (notificationIds.length == recordatorioIds.length) {
        for (int i = 0; i < notificationIds.length; i++) {
          _scheduledNotifications[int.parse(notificationIds[i])] = int.parse(
            recordatorioIds[i],
          );
        }
      }
    } catch (e) {
      print('Error al cargar notificaciones programadas: $e');
    }
  }
}
