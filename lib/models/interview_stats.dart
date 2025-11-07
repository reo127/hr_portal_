class InterviewStats {
  final int total;
  final int accepted;
  final int rejected;
  final int notAvailable;

  InterviewStats({
    required this.total,
    required this.accepted,
    required this.rejected,
    required this.notAvailable,
  });

  factory InterviewStats.fromJson(Map<String, dynamic> json) {
    return InterviewStats(
      total: json['total'] ?? 0,
      accepted: json['accepted'] ?? 0,
      rejected: json['rejected'] ?? 0,
      notAvailable: json['notAvailable'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'accepted': accepted,
      'rejected': rejected,
      'notAvailable': notAvailable,
    };
  }
}
