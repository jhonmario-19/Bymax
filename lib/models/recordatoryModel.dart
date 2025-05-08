class Recordatory {
  final int id;
  final String title;
  final String date;
  final String time;
  final String activityId;
  final String userId; // ID del usuario para quien es el recordatorio
  final String creatorId; // ID del usuario que crea el recordatorio
  final bool isNotificationEnabled;
  final String repeat;
  final int repeatInterval;
  final String repeatEndDate;

  Recordatory({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.activityId,
    required this.userId,
    required this.creatorId,
    this.isNotificationEnabled = true,
    this.repeat = 'ninguno',
    this.repeatInterval = 0,
    this.repeatEndDate = '',
  });

  factory Recordatory.fromMap(Map<String, dynamic> map) {
    return Recordatory(
      id: map['id'],
      title: map['title'],
      date: map['date'],
      time: map['time'] ?? '',
      activityId: map['activityId'],
      userId: map['userId'],
      creatorId: map['creatorId'] ?? '',
      isNotificationEnabled: map['isNotificationEnabled'] ?? true,
      repeat: map['repeat'] ?? 'ninguno',
      repeatInterval: map['repeatInterval'] ?? 0,
      repeatEndDate: map['repeatEndDate'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'time': time,
      'activityId': activityId,
      'userId': userId,
      'creatorId': creatorId,
      'isNotificationEnabled': isNotificationEnabled,
      'repeat': repeat,
      'repeatInterval': repeatInterval,
      'repeatEndDate': repeatEndDate,
    };
  }
}
