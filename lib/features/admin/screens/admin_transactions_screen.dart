import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../transactions/models/transaction.dart';
import 'admin_transaction_detail_screen.dart';

/// Provider to fetch transactions by a specific admin
final adminSpecificTransactionsProvider =
    FutureProvider.family<List<TransactionModel>, String>((ref, adminId) async {
  final client = ref.read(supabaseClientProvider);

  final result = await client
      .from('transactions')
      .select()
      .eq('admin_id', adminId)
      .order('updated_at', ascending: false);

  return (result as List)
      .map((json) => TransactionModel.fromJson(json))
      .toList();
}); 

/// Screen to display all transactions handled by a specific admin
class AdminTransactionsScreen extends ConsumerWidget {
  final String adminId;
  final String adminName;

  const AdminTransactionsScreen({
    super.key,
    required this.adminId,
    required this.adminName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync =
        ref.watch(adminSpecificTransactionsProvider(adminId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          '$adminName\'s Transactions',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: RocketLoader()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error: $err', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(adminSpecificTransactionsProvider(adminId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions found',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(adminSpecificTransactionsProvider(adminId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return _buildTransactionCard(context, tx);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel tx) {
    final statusColor = _getStatusColor(tx.status);
    final details = tx.details;
    final productName = details['product_name'] ??
        details['card_name'] ??
        details['crypto_symbol'] ??
        'Transaction';
    final amount = details['card_value_usd'] ??
        details['amount_usd'] ??
        details['amount'] ??
        tx.amountFiat;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminTransactionDetailScreen(
              transaction: tx,
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
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 8,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),

            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tx.type.name.replaceAll('_', ' ').toUpperCase()} • ${_formatDate(tx.updatedAt)}',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Amount and status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$$amount',
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tx.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.rejected:
      case TransactionStatus.cancelled:
        return Colors.red;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.claimed:
      case TransactionStatus.paymentPending:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
