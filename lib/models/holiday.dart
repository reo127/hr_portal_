class Holiday {
  final String id;
  final String name;
  final String date;

  Holiday({
    required this.id,
    required this.name,
    required this.date,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'date': date,
    };
  }
}
