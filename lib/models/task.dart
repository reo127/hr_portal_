class Task {
  final String id;
  final String title;
  final String description;
  final int hours;
  final String status; // 'pending' or 'completed'

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.hours,
    this.status = 'pending',
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    int? hours,
    String? status,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hours: hours ?? this.hours,
      status: status ?? this.status,
    );
  }
}
