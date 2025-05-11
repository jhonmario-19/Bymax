import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

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
    });
  }

  // Método para hablar texto
  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
      return;
    }

    _isSpeaking = true;
    await _flutterTts.speak(text);
  }

  // Método para detener el habla
  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  // Método para liberar recursos al cerrar la app
  Future<void> dispose() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  // Getter para saber si está hablando
  bool get isSpeaking => _isSpeaking;
}
