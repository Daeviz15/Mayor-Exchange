import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/repositories/transaction_repository.dart';
import 'admin_transaction_detail_screen.dart';
import 'admin_rates_screen.dart';
import 'admin_bank_details_screen.dart';
import 'admin_wallet_settings_screen.dart';
import 'admin_kyc_list_screen.dart';

import '../../../core/widgets/rocket_loader.dart';

import '../providers/admin_notification_provider.dart';

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
            tooltip: 'Exchange Rates',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminRatesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance,
                color: AppColors.primaryOrange),
            tooltip: 'Bank Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminBankDetailsScreen()),
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
            icon: const Icon(Icons.account_balance_wallet,
                color: AppColors.primaryOrange),
            tooltip: 'Wallet Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminWalletSettingsScreen()),
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
          _TransactionList(filterStatuses: null), // Full history
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
    // Fetch ALL transactions to ensure we have the full history and can filter locally.
    // This solves the issue of implicit Supabase stream limitations and provides flexibility.
    final transactionsStream =
        ref.watch(transactionRepositoryProvider).watchAllTransactions();

    return StreamBuilder<List<TransactionModel>>(
      stream: transactionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: RocketLoader());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));
        }

        final allTransactions = snapshot.data ?? [];

        // Filter locally
        final transactions = filterStatuses == null
            ? allTransactions // Show all if filter is null (History Tab)
            : allTransactions
                .where((t) => filterStatuses!.contains(t.status))
                .toList();

        return RefreshIndicator(
          color: AppColors.primaryOrange,
          backgroundColor: AppColors.backgroundCard,
          onRefresh: () async {
            // Trigger a refresh of the stream provider
            await ref
                .refresh(transactionRepositoryProvider)
                .watchAllTransactions()
                .first;
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

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          '${transaction.type.name.toUpperCase()} - ${transaction.details['currency_symbol'] ?? '₦'}${transaction.amountFiat}',
          style: AppTextStyles.titleSmall(context),
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
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: AppColors.textSecondary),
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
