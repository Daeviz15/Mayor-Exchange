import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/currency_text.dart';
import '../../transactions/models/transaction.dart';
import 'admin_transaction_detail_screen.dart';
import 'admin_rates_screen.dart';
import '../../transactions/providers/transaction_service.dart';
import '../../chat/providers/chat_provider.dart';

import 'admin_giftcards_management_screen.dart';
import 'admin_wallet_settings_screen.dart';
import 'admin_kyc_list_screen.dart';
import 'admin_list_screen.dart';
import 'admin_performance_screen.dart';

import '../../../core/widgets/rocket_loader.dart';

import '../providers/admin_notification_provider.dart';
import '../providers/admin_history_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for notifications
    ref.listen<AdminNotification?>(adminNotificationProvider,
        (_, notification) {
      if (notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                Text(notification.message,
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: AppColors.primaryOrange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title:
            Text('Admin Dashboard', style: AppTextStyles.titleLarge(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.currency_exchange,
                color: AppColors.primaryOrange),
            tooltip: 'Crypto Rates',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminRatesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_card, color: AppColors.primaryOrange),
            tooltip: 'Manage Gift Cards',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminGiftCardsManagementScreen()),
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.verified_user, color: AppColors.primaryOrange),
            tooltip: 'KYC Requests',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminKycListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people, color: AppColors.primaryOrange),
            tooltip: 'Admin Team',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet,
                color: AppColors.primaryOrange),
            tooltip: 'Wallet Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminWalletSettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.analytics, color: AppColors.primaryOrange),
            tooltip: 'Performance Stats',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPerformanceScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryOrange,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryOrange,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'My Tasks'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TransactionList(filterStatuses: const [TransactionStatus.pending]),
          _TransactionList(
            filterStatuses: const [
              TransactionStatus.claimed,
              TransactionStatus.paymentPending,
              TransactionStatus.verificationPending
            ],
          ),
          const _PaginatedTransactionList(), // Full history (Paginated)
        ],
      ),
    );
  }
}

class _TransactionList extends ConsumerWidget {
  final List<TransactionStatus>? filterStatuses;

  const _TransactionList({this.filterStatuses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine which statuses to watch. If filterStatuses is null, watch all.
    final adminTransactionsAsync = filterStatuses == null
        ? ref.watch(adminTransactionsProvider)
        : ref.watch(adminTransactionsByStatusProvider(filterStatuses!));

    return adminTransactionsAsync.when(
      loading: () => const Center(child: RocketLoader()),
      error: (error, stack) => Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
      data: (transactions) {
        return RefreshIndicator(
          color: AppColors.primaryOrange,
          backgroundColor: AppColors.backgroundCard,
          onRefresh: () async {
            // Invalidate the provider to trigger a fresh fetch
            ref.invalidate(adminTransactionsProvider);
          },
          child: transactions.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                        height:
                            MediaQuery.of(context).size.height * 0.3), // Center
                    Center(
                      child: Text(
                        'No transactions found',
                        style: AppTextStyles.bodyMedium(context)
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _TransactionCard(transaction: transaction);
                  },
                ),
        );
      },
    );
  }
}

class _TransactionCard extends ConsumerWidget {
  final TransactionModel transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountStreamProvider(transaction.id));

    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Text(
              '${transaction.type.name.toUpperCase()} – ',
              style: AppTextStyles.titleSmall(context),
            ),
            CurrencyText(
              symbol: transaction.details['currency_symbol'] ?? '₦',
              amount: transaction.amountFiat.toString(),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Created: ${transaction.createdAt.toString().split('.')[0]}',
              style: AppTextStyles.bodySmall(context)
                  .copyWith(color: AppColors.textTertiary),
            ),
            Text(
              'Status: ${transaction.status.name}',
              style: AppTextStyles.bodySmall(context).copyWith(
                  color: transaction.status == TransactionStatus.pending
                      ? Colors.orange
                      : AppColors.textSecondary),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            unreadAsync.when(
              data: (count) => count > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AdminTransactionDetailScreen(transaction: transaction),
            ),
          );
        },
      ),
    );
  }
}

class _PaginatedTransactionList extends ConsumerStatefulWidget {
  const _PaginatedTransactionList();

  @override
  ConsumerState<_PaginatedTransactionList> createState() =>
      _PaginatedTransactionListState();
}

class _PaginatedTransactionListState
    extends ConsumerState<_PaginatedTransactionList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminHistoryProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(adminHistoryProvider);

    return stateAsync.when(
      loading: () => const Center(child: RocketLoader()),
      error: (error, stack) => Center(
          child:
              Text('Error: $error', style: const TextStyle(color: Colors.red))),
      data: (state) {
        final transactions = state.transactions;
        return RefreshIndicator(
          color: AppColors.primaryOrange,
          backgroundColor: AppColors.backgroundCard,
          onRefresh: () async {
            await ref.read(adminHistoryProvider.notifier).refresh();
          },
          child: transactions.isEmpty && !state.hasMore
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    Center(
                      child: Text(
                        'No transaction history',
                        style: AppTextStyles.bodyMedium(context)
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: transactions.length + (state.hasMore ? 1 : 0),
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == transactions.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryOrange,
                              )),
                        ),
                      );
                    }
                    final transaction = transactions[index];
                    return _TransactionCard(transaction: transaction);
                  },
                ),
        );
      },
    );
  }
}
