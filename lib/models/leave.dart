class Leave {
  final String id;
  final LeaveUser userId;
  final LeaveManager manager;
  final String leaveType;
  final bool isLOP;
  final String startDate;
  final String endDate;
  final String session;
  final String reason;
  final String status;
  final int totalDays;
  final int lopDays;
  final int nonLopDays;
  final String appliedDate;
  final String month;
  final String? balanceHistoryId;
  final LeaveManager? approvedBy;
  final String? approvedByName;
  final String? approvedDate;
  final String? rejectionReason;
  final String createdAt;
  final String updatedAt;

  Leave({
    required this.id,
    required this.userId,
    required this.manager,
    required this.leaveType,
    required this.isLOP,
    required this.startDate,
    required this.endDate,
    required this.session,
    required this.reason,
    required this.status,
    required this.totalDays,
    required this.lopDays,
    required this.nonLopDays,
    required this.appliedDate,
    required this.month,
    this.balanceHistoryId,
    this.approvedBy,
    this.approvedByName,
    this.approvedDate,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    // Helper function to parse int from dynamic (handles int and double)
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return Leave(
      id: json['_id'] ?? '',
      userId: LeaveUser.fromJson(json['userId'] ?? {}),
      manager: LeaveManager.fromJson(json['manager'] ?? {}),
      leaveType: json['leaveType'] ?? '',
      isLOP: json['isLOP'] ?? false,
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      session: json['session'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? '',
      totalDays: parseInt(json['totalDays']),
      lopDays: parseInt(json['lopDays']),
      nonLopDays: parseInt(json['nonLopDays']),
      appliedDate: json['appliedDate'] ?? '',
      month: json['month'] ?? '',
      balanceHistoryId: json['balanceHistoryId'],
      approvedBy: json['approvedBy'] != null
          ? LeaveManager.fromJson(json['approvedBy'])
          : null,
      approvedByName: json['approvedByName'],
      approvedDate: json['approvedDate'],
      rejectionReason: json['rejectionReason'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  String getLeaveTypeDisplay() {
    switch (leaveType.toLowerCase()) {
      case 'sickleave':
        return 'Sick Leave';
      case 'casualleave':
        return 'Casual Leave';
      case 'earnedleave':
        return 'Earned Leave';
      case 'compensatoryleave':
      case 'compleave':
        return 'Comp-Off';
      case 'bereavementleave':
        return 'Bereavement Leave';
      case 'lop':
        return 'Loss of Pay';
      default:
        return leaveType;
    }
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

class LeaveUser {
  final String id;
  final String employeeName;
  final String email;

  LeaveUser({
    required this.id,
    required this.employeeName,
    required this.email,
  });

  factory LeaveUser.fromJson(Map<String, dynamic> json) {
    return LeaveUser(
      id: json['_id'] ?? '',
      employeeName: json['employeeName'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class LeaveManager {
  final String id;
  final String employeeName;

  LeaveManager({
    required this.id,
    required this.employeeName,
  });

  factory LeaveManager.fromJson(Map<String, dynamic> json) {
    return LeaveManager(
      id: json['_id'] ?? '',
      employeeName: json['employeeName'] ?? '',
    );
  }
}
