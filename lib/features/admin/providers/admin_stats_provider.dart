import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../models/admin_stats.dart';

/// Provider to fetch admin performance stats (super-admin only)
final adminStatsProvider = FutureProvider<List<AdminStats>>((ref) async {
  final client = ref.read(supabaseClientProvider);

  // Query to get admin stats aggregated from transactions
  final result = await client.rpc('get_admin_stats').select();

  return (result as List).map((json) => AdminStats.fromJson(json)).toList();
});

/// Provider to fetch stats for a specific admin - OPTIMIZED
/// Should ideally reuse the data from leaderboard if already fetched
final singleAdminStatsProvider =
    FutureProvider.family<AdminStats?, String>((ref, adminId) async {
  // First try to find in the already loaded leaderboard to save network
  final leaderboard = ref.read(adminLeaderboardProvider).asData?.value;
  if (leaderboard != null) {
    try {
      return leaderboard.firstWhere((s) => s.adminId == adminId);
    } catch (_) {
      // Not found in leaderboard, fetch fresh
    }
  }

  // If not found, fetch fresh using the same RPC but filtered
  try {
    final client = ref.read(supabaseClientProvider);
    // Note: We fetch all and filter in memory since we don't have a single-admin RPC yet.
    // This is still cleaner than the previous manual transaction aggregation.
    final List<dynamic> result = await client
        .rpc('get_admin_leaderboard_v2')
        .timeout(const Duration(seconds: 15));

    final adminJson = result.firstWhere(
      (json) => json['admin_id'] == adminId,
      orElse: () => null,
    );

    if (adminJson == null) return null;

    return AdminStats(
      adminId: adminJson['admin_id'] as String,
      adminName: adminJson['display_name'] as String? ?? 'Unknown Admin',
      totalProcessed: (adminJson['total_processed'] as num).toInt(),
      totalCompleted: (adminJson['total_completed'] as num).toInt(),
      totalRejected: (adminJson['total_rejected'] as num).toInt(),
      totalPending: (adminJson['total_pending'] as num).toInt(),
      completionRate: (adminJson['completion_rate'] as num).toDouble(),
      todayCount: (adminJson['today_count'] as num).toInt(),
      weekCount: (adminJson['week_count'] as num).toInt(),
      monthCount: (adminJson['month_count'] as num).toInt(),
    );
  } catch (e) {
    debugPrint('📊 Admin Stats: Error fetching single stats for $adminId: $e');
    return null;
  }
});

/// Provider to fetch all admins with their stats for leaderboard - OPTIMIZED
final adminLeaderboardProvider = FutureProvider<List<AdminStats>>((ref) async {
  final client = ref.read(supabaseClientProvider);

  try {
    // Call the optimized RPC function that aggregates everything on the server
    final List<dynamic> result = await client
        .rpc('get_admin_leaderboard_v2')
        .timeout(const Duration(seconds: 15));

    debugPrint('📊 Admin Stats: Fetched ${result.length} rows from RPC');

    final stats = result.map((json) {
      return AdminStats(
        adminId: json['admin_id'] as String,
        adminName: json['display_name'] as String? ?? 'Unknown Admin',
        totalProcessed: (json['total_processed'] as num).toInt(),
        totalCompleted: (json['total_completed'] as num).toInt(),
        totalRejected: (json['total_rejected'] as num).toInt(),
        totalPending: (json['total_pending'] as num).toInt(),
        completionRate: (json['completion_rate'] as num).toDouble(),
        todayCount: (json['today_count'] as num).toInt(),
        weekCount: (json['week_count'] as num).toInt(),
        monthCount: (json['month_count'] as num).toInt(),
      );
    }).toList();

    // Sort by total completed (descending)
    stats.sort((a, b) => b.totalCompleted.compareTo(a.totalCompleted));

    return stats;
  } catch (e) {
    debugPrint('📊 Admin Stats: Error fetching leaderboard: $e');
    // Return empty list on error to prevent UI crash
    return [];
  }
});
