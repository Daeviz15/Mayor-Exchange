import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/transaction.dart';
import '../providers/transaction_service.dart';

import '../../../core/widgets/rocket_loader.dart';
import '../../../core/widgets/error_state_widget.dart';

import 'buyer_transaction_status_screen.dart'; // Added import
import '../../chat/providers/chat_provider.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
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
      ref.read(userHistoryProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(userHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: null,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('History', style: AppTextStyles.titleLarge(context)),
      ),
      body: stateAsync.when(
        loading: () => const Center(child: RocketLoader()),
        error: (err, stack) => ErrorStateWidget(
          error: err,
          onRetry: () => ref.read(userHistoryProvider.notifier).refresh(),
        ),
        data: (state) {
          final transactions = state.transactions;

          return RefreshIndicator(
            color: AppColors.primaryOrange,
            backgroundColor: AppColors.backgroundCard,
            onRefresh: () async {
              await ref.read(userHistoryProvider.notifier).refresh();
            },
            child: transactions.isEmpty && !state.hasMore
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.35),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history,
                                size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions yet.',
                              style: AppTextStyles.bodyMedium(context)
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: transactions.length + (state.hasMore ? 1 : 0),
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
                      return GestureDetector(
                        onTap: () {
                          if (transaction.type == TransactionType.buyGiftCard ||
                              transaction.type == TransactionType.buyCrypto) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BuyerTransactionStatusScreen(
                                  transactionId: transaction.id,
                                  initialTransaction: transaction,
                                ),
                              ),
                            );
                          }
                        },
                        child: _HistoryCard(transaction: transaction),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final TransactionModel transaction;

  const _HistoryCard({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountStreamProvider(transaction.id));
    final isBuy = transaction.type == TransactionType.buyCrypto ||
        transaction.type == TransactionType.buyGiftCard ||
        transaction.type == TransactionType.deposit;

    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isBuy
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                color: isBuy ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTitle(transaction),
                    style: AppTextStyles.titleSmall(context)
                        .copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.createdAt.toString().split('.')[0],
                    style: AppTextStyles.bodySmall(context)
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),

            // Unread Badge
            unreadAsync.when(
              data: (count) => count > 0
                  ? Container(
                      margin: const EdgeInsets.only(right: 12),
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

            // Amount & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isBuy ? '+' : '-'}${transaction.details['currency_symbol'] ?? '₦'}${transaction.amountFiat}',
                  style: AppTextStyles.bodyMedium(context)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.status.name.toUpperCase(),
                  style: AppTextStyles.labelMedium(context).copyWith(
                    color: _getStatusColor(transaction.status),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(TransactionModel t) {
    switch (t.type) {
      case TransactionType.buyCrypto:
        return 'Buy ${t.details['asset'] ?? 'Crypto'}';
      case TransactionType.sellCrypto:
        return 'Sell ${t.details['asset'] ?? 'Crypto'}';
      case TransactionType.buyGiftCard:
        return 'Buy Gift Card';
      case TransactionType.sellGiftCard:
        return 'Sell Gift Card';
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.withdrawal:
        return 'Withdrawal';
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.rejected:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
