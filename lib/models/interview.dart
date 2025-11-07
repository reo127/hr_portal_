class Interview {
  final String id;
  final int serialNumber;
  final String clientName;
  final String date;
  final String jobRole;
  final String questions;
  final String employeeName;
  final String userId;
  final String status;
  final String createdAt;
  final String updatedAt;

  Interview({
    required this.id,
    required this.serialNumber,
    required this.clientName,
    required this.date,
    required this.jobRole,
    required this.questions,
    required this.employeeName,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Interview.fromJson(Map<String, dynamic> json) {
    return Interview(
      id: json['_id'] ?? '',
      serialNumber: json['serialNumber'] ?? 0,
      clientName: json['clientName'] ?? '',
      date: json['date'] ?? '',
      jobRole: json['jobRole'] ?? '',
      questions: json['questions'] ?? '',
      employeeName: json['employeeName'] ?? '',
      userId: json['userId'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'serialNumber': serialNumber,
      'clientName': clientName,
      'date': date,
      'jobRole': jobRole,
      'questions': questions,
      'employeeName': employeeName,
      'userId': userId,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class InterviewPagination {
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final int recordsPerPage;

  InterviewPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.recordsPerPage,
  });

  factory InterviewPagination.fromJson(Map<String, dynamic> json) {
    return InterviewPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalRecords: json['totalRecords'] ?? 0,
      recordsPerPage: json['recordsPerPage'] ?? 10,
    );
  }
}
