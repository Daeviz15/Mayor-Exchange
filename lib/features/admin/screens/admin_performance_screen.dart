import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../providers/admin_role_provider.dart';
import '../providers/admin_stats_provider.dart';
import '../models/admin_stats.dart';
import 'admin_transactions_screen.dart';
import 'admin_management_screen.dart';

/// Admin Performance Dashboard Screen
/// Only accessible by super-admins
class AdminPerformanceScreen extends ConsumerWidget {
  const AdminPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperAdminAsync = ref.watch(isSuperAdminProvider);

    return isSuperAdminAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundCard,
          title: const Text('Admin Performance',
              style: TextStyle(color: AppColors.textPrimary)),
        ),
        body: const Center(child: RocketLoader()),
      ),
      error: (_, __) => _buildAccessDenied(context),
      data: (isSuperAdmin) {
        if (!isSuperAdmin) {
          return _buildAccessDenied(context);
        }
        return _buildMainScreen(context, ref);
      },
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Admin Performance',
            style: TextStyle(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Access Denied',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Only Super Admins can view this page',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainScreen(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(adminLeaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Admin Performance',
            style: TextStyle(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group, color: AppColors.textPrimary),
            tooltip: 'Manage Admins',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminManagementScreen()),
              );
            },
          ),
        ],
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(child: RocketLoader()),
        error: (err, stack) => ErrorStateWidget(
          error: err,
          onRetry: () => ref.invalidate(adminLeaderboardProvider),
        ),
        data: (stats) => _buildContent(context, stats, ref),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, List<AdminStats> stats, WidgetRef ref) {
    if (stats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('No performance data yet',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminLeaderboardProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards
          _buildSummaryRow(stats),
          const SizedBox(height: 24),

          // Leaderboard
          Text('Admin Leaderboard', style: AppTextStyles.titleMedium(context)),
          const SizedBox(height: 12),
          ...stats.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;
            return _buildLeaderboardCard(context, stat, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(List<AdminStats> stats) {
    final totalCompleted =
        stats.fold<int>(0, (sum, s) => sum + s.totalCompleted);
    final totalPending = stats.fold<int>(0, (sum, s) => sum + s.totalPending);
    final avgCompletionRate = stats.isNotEmpty
        ? stats.fold<double>(0, (sum, s) => sum + s.completionRate) /
            stats.length
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Completed',
            totalCompleted.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Pending',
            totalPending.toString(),
            Icons.pending,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Avg Rate',
            '${avgCompletionRate.toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(title,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(
      BuildContext context, AdminStats stat, int rank) {
    final Color rankColor;
    final IconData? rankIcon;

    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey[400]!;
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown[300]!;
      rankIcon = Icons.emoji_events;
    } else {
      rankColor = AppColors.textSecondary;
      rankIcon = null;
    }

    // Display name with proper fallback
    final displayName = stat.adminName ?? 'Admin';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminTransactionsScreen(
              adminId: stat.adminId,
              adminName: displayName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: rank <= 3
              ? Border.all(color: rankColor.withAlpha(100), width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Rank
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rankColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: rankIcon != null
                    ? Icon(rankIcon, color: rankColor, size: 20)
                    : Text('#$rank',
                        style: TextStyle(
                            color: rankColor, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),

            // Admin Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                  Text(
                    'Today: ${stat.todayCount} | Week: ${stat.weekCount} | Month: ${stat.monthCount}',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stat.totalCompleted}',
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '${stat.completionRate.toStringAsFixed(0)}% rate',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
