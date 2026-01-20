/// Admin Stats Model
/// Represents performance statistics for an admin user
class AdminStats {
  final String adminId;
  final String? adminName;
  final int totalProcessed;
  final int totalCompleted;
  final int totalRejected;
  final int totalPending;
  final double avgResponseMinutes;
  final double completionRate;
  final int todayCount;
  final int weekCount;
  final int monthCount;

  AdminStats({
    required this.adminId,
    this.adminName,
    this.totalProcessed = 0,
    this.totalCompleted = 0,
    this.totalRejected = 0,
    this.totalPending = 0,
    this.avgResponseMinutes = 0,
    this.completionRate = 0,
    this.todayCount = 0,
    this.weekCount = 0,
    this.monthCount = 0,
  });

  /// Create from database query result
  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final completed = (json['completed_count'] as num?)?.toInt() ?? 0;
    final rejected = (json['rejected_count'] as num?)?.toInt() ?? 0;
    final total = (json['total_count'] as num?)?.toInt() ?? 0;

    return AdminStats(
      adminId: json['admin_id'] as String,
      adminName: json['admin_name'] as String?,
      totalProcessed: total,
      totalCompleted: completed,
      totalRejected: rejected,
      totalPending: (json['pending_count'] as num?)?.toInt() ?? 0,
      avgResponseMinutes:
          (json['avg_response_seconds'] as num?)?.toDouble() ?? 0 / 60,
      completionRate: total > 0 ? (completed / total * 100) : 0,
      todayCount: (json['today_count'] as num?)?.toInt() ?? 0,
      weekCount: (json['week_count'] as num?)?.toInt() ?? 0,
      monthCount: (json['month_count'] as num?)?.toInt() ?? 0,
    );
  }
}
