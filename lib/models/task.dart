class Task {
  final String id;
  final String title;
  final String description;
  final int hours;
  final String status;
  final String? date;
  final String? userId;
  final String? employeeName;
  final String? reason;
  final String? details;
  final bool? isHoliday;
  final String? holidayName;
  final bool? onLeave;
  final String? leaveType;
  final String? resourceStatus;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.hours,
    this.status = 'pending',
    this.date,
    this.userId,
    this.employeeName,
    this.reason,
    this.details,
    this.isHoliday,
    this.holidayName,
    this.onLeave,
    this.leaveType,
    this.resourceStatus,
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
      date: json['date'],
      userId: json['userId'],
      employeeName: json['employeeName'],
      reason: json['reason'] ?? '',
      details: json['details'] ?? '',
      isHoliday: json['isHoliday'] ?? false,
      holidayName: json['holidayName'] ?? '',
      onLeave: json['onLeave'] ?? false,
      leaveType: json['LeaveType'] ?? '',
      resourceStatus: json['resourceStatus'] ?? 'benchresource',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task': title,
      'summary': description,
      'hours': hours,
      'status': status,
      'date': date ?? '',
      'userId': userId ?? '',
      'employeeName': employeeName ?? '',
      'reason': reason ?? '',
      'details': details ?? '',
      'isHoliday': isHoliday ?? false,
      'holidayName': holidayName ?? '',
      'onLeave': onLeave ?? false,
      'LeaveType': leaveType ?? '',
      'resourceStatus': resourceStatus ?? 'benchresource',
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    int? hours,
    String? status,
    String? date,
    String? userId,
    String? employeeName,
    String? reason,
    String? details,
    bool? isHoliday,
    String? holidayName,
    bool? onLeave,
    String? leaveType,
    String? resourceStatus,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hours: hours ?? this.hours,
      status: status ?? this.status,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      employeeName: employeeName ?? this.employeeName,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      isHoliday: isHoliday ?? this.isHoliday,
      holidayName: holidayName ?? this.holidayName,
      onLeave: onLeave ?? this.onLeave,
      leaveType: leaveType ?? this.leaveType,
      resourceStatus: resourceStatus ?? this.resourceStatus,
    );
  }
}
