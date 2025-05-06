class Recordatory {
  final int id;
  final String title;
  final String date;
  final String type; // medication, appointment, therapy
  final bool isNotificationEnabled;

  Recordatory({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.isNotificationEnabled = true,
  });

  // Convertir de Map a Objeto
  factory Recordatory.fromMap(Map<String, dynamic> map) {
    return Recordatory(
      id: map['id'],
      title: map['title'],
      date: map['date'],
      type: map['type'],
      isNotificationEnabled: map['isNotificationEnabled'],
    );
  }

  // Convertir de Objeto a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'type': type,
      'isNotificationEnabled': isNotificationEnabled,
    };
  }
}