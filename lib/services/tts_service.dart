// En tts_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:vibration/vibration.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier(false);

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  Timer? _repeatTimer;
  Timer? _scheduledAlarmTimer; // Timer para alarmas pospuestas
  int _repeatCount = 0;
  final int _maxRepeats = 3; // Número máximo de repeticiones

  // Estado para controlar si está en modo alarma
  bool _isAlarmMode = false;

  // Inicializa el servicio TTS con configuraciones
  Future<void> initTTS() async {
    // Configurar idioma español
    await _flutterTts.setLanguage("es-ES");

    // Configurar velocidad y tono (valores entre 0.0 y 1.0)
    await _flutterTts.setSpeechRate(
      0.5,
    ); // Velocidad más lenta para mayor claridad
    await _flutterTts.setPitch(1.0);

    // Volumen (entre 0.0 y 1.0)
    await _flutterTts.setVolume(1.0);

    // Escuchar cuando termina de hablar
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      isSpeakingNotifier.value = false;

      // Si está en modo alarma, repetir automáticamente
      if (_isAlarmMode && _repeatCount < _maxRepeats) {
        _repeatTimer = Timer(const Duration(seconds: 3), () {
          if (_lastSpokenText.isNotEmpty) {
            _repeatCount++;
            _speak(_lastSpokenText);
          }
        });
      } else if (_isAlarmMode) {
        // Si ya se repitió el máximo de veces, cancelar el modo alarma
        _isAlarmMode = false;
        _repeatCount = 0;
      }
    });
  }

  String _lastSpokenText = '';

  // Método interno para hablar sin cambiar el modo
  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    // CORRECCIÓN: Establecer estado correcto ANTES de hablar
    _isSpeaking = true;
    isSpeakingNotifier.value = true;
    _lastSpokenText = text;
    
    await _flutterTts.speak(text);
  }

  // Método para hablar texto
  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
      isSpeakingNotifier.value = false; // ACTUALIZAR NOTIFIER
      _isAlarmMode = false;
      _cancelRepeating();
      return;
    }

    _lastSpokenText = text;
    
    // CORRECCIÓN: Actualizar estado antes de hablar
    _isSpeaking = true;
    isSpeakingNotifier.value = true;
    
    await _flutterTts.speak(text);
  }

  // Método específico para reproducir como alarma (con repeticiones)
  Future<void> speakAsAlarm(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      // CORRECCIÓN: Actualizar estado al detener
      _isSpeaking = false;
      isSpeakingNotifier.value = false;
    }
    // Cancelar cualquier repetición anterior
    _cancelRepeating();

    // Activar modo alarma
    _isAlarmMode = true;
    _repeatCount = 0;

    // Uso de vibración si está disponible
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000, 500]);
    }

    // Reproducir con volumen alto
    await _flutterTts.setVolume(1.0);
    await _speak(text);

    // Mostrar diálogo en pantalla si la app está en primer plano
    if (Get.context != null) {
      // Usar GetX para mostrar diálogo
      Get.dialog(
        AlertDialog(
          title: Text('Recordatorio Importante'),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () {
                stop();
                Get.back();
              },
              child: Text('Detener'),
            ),
            TextButton(
              onPressed: () {
                // Posponer por 5 minutos
                stop();
                _scheduleRepeatLater(text, Duration(minutes: 5));
                Get.back();
              },
              child: Text('Posponer 5 min'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }
  }

  // Programar repetición posterior
  void _scheduleRepeatLater(String text, Duration delay) {
    _scheduledAlarmTimer = Timer(delay, () {
      speakAsAlarm('Recordatorio pospuesto: $text');
    });
  }

  // Cancelar repeticiones
  void _cancelRepeating() {
    _repeatTimer?.cancel();
    _scheduledAlarmTimer?.cancel(); // Cancela el timer de posposición
    _repeatTimer = null;
    _scheduledAlarmTimer = null; // Limpia la referencia
    _repeatCount = 0;
  }

  // Método para detener el habla
  Future<void> stop() async {
    _isAlarmMode = false;
    _cancelRepeating(); // Esto ahora cancela ambos timers
    await _flutterTts.stop();
    _isSpeaking = false;

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.cancel();
    }
  }

  // Método para liberar recursos al cerrar la app
  Future<void> dispose() async {
    _cancelRepeating();
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  // Getter para saber si está hablando
  bool get isSpeaking => _isSpeaking;
}
