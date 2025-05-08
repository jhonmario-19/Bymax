class Activity {
  final String id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String userId;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.userId,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'userId': userId,
    };
  }

  Activity copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? time,
    String? userId,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      userId: userId ?? this.userId,
    );
  }
}
