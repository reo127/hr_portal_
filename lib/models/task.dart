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

  factory Task.fromJson(Map<String, dynamic> json) {
    // Handle hours as either int or double
    int hoursValue = 0;
    if (json['hours'] != null) {
      if (json['hours'] is int) {
        hoursValue = json['hours'];
      } else if (json['hours'] is double) {
        hoursValue = (json['hours'] as double).toInt();
      } else {
        hoursValue = int.tryParse(json['hours'].toString()) ?? 0;
      }
    }

    return Task(
      id: json['_id'] ?? '',
      title: json['task'] ?? '',
      description: json['summary'] ?? '',
      hours: hoursValue,
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'hours': hours,
      'status': status,
    };
  }

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
