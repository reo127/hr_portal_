class CompOff {
  final String id;
  final String employeeId;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String reason;
  final String? proof;
  final String status;
  final String appliedDate;
  final int usedDays;
  final String createdAt;
  final String updatedAt;

  CompOff({
    required this.id,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    this.proof,
    required this.status,
    required this.appliedDate,
    required this.usedDays,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompOff.fromJson(Map<String, dynamic> json) {
    return CompOff(
      id: json['_id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      totalDays: json['totalDays'] ?? 0,
      reason: json['reason'] ?? '',
      proof: json['proof'],
      status: json['status'] ?? '',
      appliedDate: json['appliedDate'] ?? '',
      usedDays: json['usedDays'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'employeeId': employeeId,
      'startDate': startDate,
      'endDate': endDate,
      'totalDays': totalDays,
      'reason': reason,
      'proof': proof,
      'status': status,
      'appliedDate': appliedDate,
      'usedDays': usedDays,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String getStatusDisplay() {
    switch (status.toLowerCase()) {
      case 'applied':
        return 'Applied';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}
