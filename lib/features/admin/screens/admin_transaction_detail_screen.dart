import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transaction_service.dart';
import '../../../core/providers/supabase_provider.dart';

import '../../../core/widgets/rocket_loader.dart';

class AdminTransactionDetailScreen extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const AdminTransactionDetailScreen({super.key, required this.transaction});

  @override
  ConsumerState<AdminTransactionDetailScreen> createState() =>
      _AdminTransactionDetailScreenState();
}

class _AdminTransactionDetailScreenState
    extends ConsumerState<AdminTransactionDetailScreen> {
  bool _isLoading = false;
  final _noteController = TextEditingController();
  final _bankDetailsController = TextEditingController();
  final _giftCardInfoController = TextEditingController();

  Future<void> _handleAction(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Action completed successfully'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Go back to dashboard on success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionId = widget.transaction.id;
    final transactionAsync =
        ref.watch(singleTransactionProvider(transactionId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: Text('Transaction Details',
            style: AppTextStyles.titleLarge(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: transactionAsync.when(
        loading: () => _buildContent(widget.transaction, isLoading: true),
        error: (err, stack) => Center(
            child:
                Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (liveTransaction) {
          final transaction = liveTransaction ?? widget.transaction;
          return _buildContent(transaction);
        },
      ),
    );
  }

  Widget _buildContent(TransactionModel transaction, {bool isLoading = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading) const LinearProgressIndicator(),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(transaction.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getStatusColor(transaction.status)),
            ),
            child: Text(
              transaction.status.name.toUpperCase(),
              style: AppTextStyles.labelMedium(context).copyWith(
                color: _getStatusColor(transaction.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Key Details
          _buildDetailRow('Transaction ID', transaction.id.substring(0, 8)),
          _buildDetailRow('Type', transaction.type.name.toUpperCase()),
          _buildDetailRow('Amount (Fiat)',
              '${transaction.details['currency_symbol'] ?? '₦'}${transaction.amountFiat.toStringAsFixed(2)}'),
          if (transaction.details.containsKey('usd_input'))
            _buildDetailRow(
                'USD Input', '\$${transaction.details['usd_input']}'),
          if (transaction.amountCrypto != null)
            _buildDetailRow('Amount (Crypto)',
                '${transaction.amountCrypto} ${transaction.currencyPair.split('/').first}'),
          _buildDetailRow('Currency Pair', transaction.currencyPair),
          if (transaction.details.containsKey('fx_rate_applied'))
            _buildDetailRow(
                'FX Rate', '₦${transaction.details['fx_rate_applied']}/USD'),
          _buildDetailRow('User ID', transaction.userId),
          _buildDetailRow('Created At', transaction.createdAt.toString()),

          const SizedBox(height: 20),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 20),

          // JSON Details (Bank info, wallet address, etc.)
          Text('Technical Details', style: AppTextStyles.titleMedium(context)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: transaction.details.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.key}: ',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary)),
                      Expanded(
                          child: Text('${e.value}',
                              style: AppTextStyles.bodyMedium(context))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Proof Image (if any)
          if (transaction.proofImagePath != null) ...[
            Text(
                transaction.type == TransactionType.sellGiftCard
                    ? 'Card Image'
                    : 'Proof of Payment',
                style: AppTextStyles.titleMedium(context)),
            const SizedBox(height: 10),
            FutureBuilder<String>(
              future: _getSignedUrl(
                ref,
                transaction.proofImagePath!,
                bucket: transaction.type == TransactionType.sellGiftCard
                    ? 'gift-cards'
                    : 'transaction-proofs',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: RocketLoader(color: AppColors.primaryOrange));
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Error loading image',
                      style: TextStyle(color: Colors.red));
                }
                return GestureDetector(
                  onTap: () {
                    // Optionally show full screen
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      snapshot.data!,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 40),

          // Actions Area
          if (transaction.status != TransactionStatus.completed &&
              transaction.status != TransactionStatus.rejected)
            _buildActionButtons(context, ref, transaction),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          SelectableText(value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, TransactionModel transaction) {
    if (_isLoading) {
      return const Center(child: RocketLoader(color: AppColors.primaryOrange));
    }

    final service = ref.read(transactionServiceProvider);

    // 1. Pending -> Claim
    if (transaction.status == TransactionStatus.pending) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          onPressed: () => _handleAction(
              () => service.claimRequest(transaction.id, transaction.userId)),
          child: const Text('Claim Request',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
    }

    // 2. Claimed -> Process (Depends on type)
    // 2. Claimed -> Process (Depends on type)
    if (transaction.status == TransactionStatus.claimed) {
      final isBuyRequest = transaction.type == TransactionType.buyGiftCard ||
          transaction.type == TransactionType.buyCrypto;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBuyRequest) ...[
            Text('Payment Instructions / Bank Details:',
                style: AppTextStyles.bodySmall(context)
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _bankDetailsController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Enter bank details or wallet address for user to pay...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Send Payment Details',
              Colors.purple,
              () async {
                if (_bankDetailsController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter payment details')));
                  return;
                }

                // Merge with existing details
                final newDetails =
                    Map<String, dynamic>.from(transaction.details);
                newDetails['admin_bank_details'] =
                    _bankDetailsController.text.trim();

                await service.updateStatus(
                  transactionId: transaction.id,
                  targetUserId: transaction.userId,
                  newStatus: TransactionStatus.paymentPending,
                  previousStatus: transaction.status,
                  note: 'Admin sent payment details',
                  details: newDetails,
                  notificationMessage:
                      'Order Accepted. Please view order history to view payment details.',
                );
              },
            ),
          ] else ...[
            // For Sell requests, we might just mark as payment sent if we paid them externally
            // Or if we need to send them money first (unlikely for sell, usually they send assets first)
            _buildActionButton(
              'Mark Payment Sent',
              Colors.purple,
              () => service.updateStatus(
                transactionId: transaction.id,
                targetUserId: transaction.userId,
                newStatus: TransactionStatus.completed,
                previousStatus: transaction.status,
                note: 'Admin sent payment to user bank',
                notificationMessage:
                    'Payment sent to your bank! Transaction Completed.',
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildActionButton(
            'Pending Verification',
            Colors.orange,
            () => service.updateStatus(
              transactionId: transaction.id,
              targetUserId: transaction.userId,
              newStatus: TransactionStatus.verificationPending,
              previousStatus: transaction.status,
              note: 'Admin marked as pending verification',
            ),
          ),
        ],
      );
    }

    // 3. Verification/Payment Pending -> Approve/Reject
    if (transaction.status == TransactionStatus.verificationPending ||
        transaction.status == TransactionStatus.paymentPending) {
      final isBuyGiftCard = transaction.type == TransactionType.buyGiftCard;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBuyGiftCard) ...[
            Text('Gift Card Code / Details:',
                style: AppTextStyles.bodySmall(context)
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _giftCardInfoController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter code or details for user...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildActionButton(
            'Approve & Complete',
            Colors.green,
            () async {
              // Merge details
              final newDetails = Map<String, dynamic>.from(transaction.details);

              if (isBuyGiftCard) {
                if (_giftCardInfoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please enter Gift Card details')));
                  return;
                }
                newDetails['gift_card_info'] =
                    _giftCardInfoController.text.trim();
              }

              await service.updateStatus(
                transactionId: transaction.id,
                targetUserId: transaction.userId,
                newStatus: TransactionStatus.completed,
                previousStatus: transaction.status,
                note: 'Admin approved and completed transaction',
                details: newDetails,
                notificationMessage: isBuyGiftCard
                    ? 'Transaction Completed! View details for your code.'
                    : null,
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Reject',
            Colors.red,
            () => service.updateStatus(
              transactionId: transaction.id,
              targetUserId: transaction.userId,
              newStatus: TransactionStatus.rejected,
              previousStatus: transaction.status,
              note: _noteController.text.isEmpty
                  ? 'Rejected by admin'
                  : _noteController.text,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add note for rejection...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: AppColors.backgroundCard,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButton(
      String label, Color color, Future<void> Function() onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        onPressed: () => _handleAction(onPressed),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<String> _getSignedUrl(WidgetRef ref, String path,
      {String bucket = 'transaction-proofs'}) async {
    final client = ref.read(supabaseClientProvider);

    // Fix: Remove bucket name if present in the path
    String cleanPath = path;
    if (cleanPath.startsWith('$bucket/')) {
      cleanPath = cleanPath.replaceFirst('$bucket/', '');
    }

    // Generate signed URL valid for 60 seconds (or more)
    final url = await client.storage
        .from(bucket)
        .createSignedUrl(cleanPath, 3600); // 1 hour
    return url;
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.claimed:
        return Colors.blue;
      case TransactionStatus.paymentPending:
      case TransactionStatus.verificationPending:
        return Colors.purple;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.rejected:
      case TransactionStatus.cancelled:
        return Colors.red;
    }
  }
}
