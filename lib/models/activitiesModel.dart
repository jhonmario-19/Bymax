class Activity {
  final String id;
  final String title;
  final String description;
  final String userId;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'userId': userId,
    };
  }

  Activity copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
    );
  }
}
