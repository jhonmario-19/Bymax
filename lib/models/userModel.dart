class UserModel {
  final String uid;
  final String nombre;
  final String email;
  final String username;
  final DateTime fechaRegistro;
  final String rol;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.username,
    required this.fechaRegistro,
    required this.rol,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'username': username,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'rol': rol, // Incluimos el rol en el mapa
    };
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      nombre: map['nombre'],
      email: map['email'],
      username: map['username'],
      fechaRegistro: DateTime.parse(map['fechaRegistro']),
      rol: map['rol'] ?? 'user', // Valor predeterminado si no existe
    );
  }
}
