class LeaveBalance {
  final String id;
  final String userId;
  final int year;
  final int earnedLeave;
  final int sickLeave;
  final int casualLeave;
  final int compensatoryLeave;
  final int currentMonthLOP;
  final int bereavementLeave;
  final CompLeaveDetails compLeaveDetails;

  LeaveBalance({
    required this.id,
    required this.userId,
    required this.year,
    required this.earnedLeave,
    required this.sickLeave,
    required this.casualLeave,
    required this.compensatoryLeave,
    required this.currentMonthLOP,
    required this.bereavementLeave,
    required this.compLeaveDetails,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      year: json['year'] ?? 0,
      earnedLeave: json['earnedLeave'] ?? 0,
      sickLeave: json['sickLeave'] ?? 0,
      casualLeave: json['casualLeave'] ?? 0,
      compensatoryLeave: json['compensatoryLeave'] ?? 0,
      currentMonthLOP: json['currentMonthLOP'] ?? 0,
      bereavementLeave: json['bereavementLeave'] ?? 0,
      compLeaveDetails: json['compLeaveDetails'] != null
          ? CompLeaveDetails.fromJson(json['compLeaveDetails'])
          : CompLeaveDetails(total: 0, activeEntries: [], expiredEntries: [], usedEntries: []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'year': year,
      'earnedLeave': earnedLeave,
      'sickLeave': sickLeave,
      'casualLeave': casualLeave,
      'compensatoryLeave': compensatoryLeave,
      'currentMonthLOP': currentMonthLOP,
      'bereavementLeave': bereavementLeave,
      'compLeaveDetails': compLeaveDetails.toJson(),
    };
  }
}

class CompLeaveDetails {
  final int total;
  final List<dynamic> activeEntries;
  final List<dynamic> expiredEntries;
  final List<dynamic> usedEntries;

  CompLeaveDetails({
    required this.total,
    required this.activeEntries,
    required this.expiredEntries,
    required this.usedEntries,
  });

  factory CompLeaveDetails.fromJson(Map<String, dynamic> json) {
    return CompLeaveDetails(
      total: json['total'] ?? 0,
      activeEntries: json['activeEntries'] ?? [],
      expiredEntries: json['expiredEntries'] ?? [],
      usedEntries: json['usedEntries'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'activeEntries': activeEntries,
      'expiredEntries': expiredEntries,
      'usedEntries': usedEntries,
    };
  }
}
