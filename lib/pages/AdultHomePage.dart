import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Añadida importación para notificaciones
import '../controllers/recordatoryController.dart';
import '../controllers/loginController.dart';
import '../models/recordatoryModel.dart'; // Asegúrate de que esta importación sea correcta para tu Recordatory
import '../services/tts_service.dart'; // Importación del servicio TTS

class AdultHomePages extends StatefulWidget {
  const AdultHomePages({Key? key}) : super(key: key);

  @override
  State<AdultHomePages> createState() => _AdultHomePageState();
}

class _AdultHomePageState extends State<AdultHomePages> {
  String? userName;
  bool _loadingUser = true;
  final ScrollController _scrollController = ScrollController();
  final TTSService _ttsService = TTSService(); // Instancia del servicio TTS
  int?
  _speakingRecordatoryId; // Para saber cuál recordatorio se está reproduciendo

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _initializeTTS(); // Inicializar el servicio TTS
    _configureNotifications(); // Añadido para configurar las notificaciones
  }

  // Configurar permisos de notificaciones
  Future<void> _configureNotifications() async {
    // Solicitar permiso para notificaciones
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configurar manejo de notificaciones cuando la app está en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Actualizar la interfaz cuando se abre la app desde una notificación
      setState(() {});
    });
  }

  // Inicializar el servicio TTS
  Future<void> _initializeTTS() async {
    await _ttsService.initTTS();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _ttsService.dispose(); // Liberar recursos del TTS al cerrar
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Trae el nombre desde Firestore
      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();
      setState(() {
        userName = userDoc.data()?['nombre'] ?? 'Usuario';
        _loadingUser = false;
      });
      // Carga los recordatorios asignados a este usuario
      await Provider.of<RecordatoryController>(
        context,
        listen: false,
      ).fetchRecordatoriesForUser(user.uid);
    }
  }

  // Método para leer un recordatorio en voz alta
  void _speakRecordatory(Recordatory recordatory) async {
    // Si ya estamos hablando, detener primero
    if (_ttsService.isSpeaking) {
      await _ttsService.stop();

      // Si es el mismo recordatorio, solo detener
      if (_speakingRecordatoryId == recordatory.id) {
        setState(() {
          _speakingRecordatoryId = null;
        });
        return;
      }
    }

    // Construir el texto para hablar
    String textToSpeak = "Recordatorio: ${recordatory.title}. ";
    textToSpeak += "Fecha: ${recordatory.date}. ";
    textToSpeak += "Hora: ${recordatory.time}.";

    // Actualizar el estado y hablar
    setState(() {
      _speakingRecordatoryId = recordatory.id;
    });

    await _ttsService.speak(textToSpeak);

    // Cuando termina de hablar, actualizar el estado
    if (!_ttsService.isSpeaking) {
      setState(() {
        _speakingRecordatoryId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(color: Color(0xFF03d069)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                // Mostrar diálogo de confirmación
                final shouldExit = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('¿Estás seguro?'),
                        content: const Text(
                          '¿Deseas cerrar sesión y salir de la aplicación?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Color(0xFF03d069)),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Salir',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                );

                // Si el usuario confirma, cerrar sesión y regresar al login
                if (shouldExit == true) {
                  try {
                    await LoginController.signOut();
                    if (!mounted) return;

                    Navigator.pushReplacementNamed(context, '/loginPage');
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cerrar sesión: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        color: const Color(0xFF03d069),
        child: Column(
          children: [
            // Barra de estado personalizada + Encabezado verde
            Container(
              padding: const EdgeInsets.only(
                top: 30,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              color: const Color(0xFF03d069),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Logo Bymax
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('lib/pages/images/logo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Bymax',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),

                  // Saludo con texto blanco
                  const SizedBox(height: 15),
                  _loadingUser
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: Color(0xFF03d069)),
                          ),
                          const SizedBox(
                            width: 10,
                          ), // Espacio entre avatar y texto
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola $userName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                'Bienvenido a tus recordatorios',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                ],
              ),
            ),

            // Contenido principal con fondo blanco
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.zero, // Sin bordes redondeados abajo
                  ),
                  image: DecorationImage(
                    image: AssetImage('lib/pages/images/patron_homePage.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color.fromARGB(211, 200, 193, 193),
                      BlendMode.darken, // Modo de mezcla
                    ),
                  ),
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(10),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mis Recordatorios',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            // Agregar un tooltip para indicar que se puede pulsar para escuchar
                            Tooltip(
                              message:
                                  'Pulsa en un recordatorio para escucharlo',
                              child: Icon(
                                Icons.volume_up,
                                color: Colors.grey[600],
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Lista de recordatorios
                        Consumer<RecordatoryController>(
                          builder: (context, controller, child) {
                            if (controller.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF03d069),
                                ),
                              );
                            }
                            final recordatories = controller.recordatories;
                            if (recordatories.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No tienes recordatorios asignados',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: recordatories.length,
                              itemBuilder: (context, index) {
                                final rec = recordatories[index];
                                // Verificar si este recordatorio se está reproduciendo
                                final isSpeaking =
                                    _speakingRecordatoryId == rec.id;
                                final isUnread = !rec.isRead;

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  // Destacar el card según estado de lectura/reproducción
                                  color:
                                      isUnread
                                          ? const Color(
                                            0xFFFFF9C4,
                                          ) // Amarillo claro para no leídos
                                          : (isSpeaking
                                              ? const Color(0xFFE1F5FE)
                                              : Colors.white),
                                  child: InkWell(
                                    onTap: () {
                                      // Si no está leído, marcarlo como leído
                                      if (isUnread) {
                                        Provider.of<RecordatoryController>(
                                          context,
                                          listen: false,
                                        ).markRecordatoryAsRead(rec.id);
                                      }
                                      _speakRecordatory(rec);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      children: [
                                        ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 15,
                                                vertical: 10,
                                              ),
                                          leading: CircleAvatar(
                                            backgroundColor: const Color(
                                              0xFF03d069,
                                            ),
                                            child:
                                                isSpeaking
                                                    ? const Icon(
                                                      Icons.volume_up,
                                                      color: Colors.white,
                                                    )
                                                    : const Icon(
                                                      Icons
                                                          .notifications_active,
                                                      color: Colors.white,
                                                    ),
                                          ),
                                          title: Text(
                                            rec.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.calendar_today,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    rec.date,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  const Icon(
                                                    Icons.access_time,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    rec.time,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing:
                                              isSpeaking
                                                  ? const Icon(
                                                    Icons.pause,
                                                    color: Color(0xFF03d069),
                                                  )
                                                  : const Icon(
                                                    Icons.volume_up_outlined,
                                                  ),
                                        ),
                                        // Mostrar una indicación visual de que se puede tocar
                                        if (!isSpeaking)
                                          Positioned(
                                            right: 12,
                                            bottom: 12,
                                            child: Text(
                                              'Tocar para escuchar',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        // Añadir indicador de no leído
                                        if (isUnread)
                                          Positioned(
                                            right: 10,
                                            top: 10,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
