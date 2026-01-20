import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transaction_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../chat/screens/transaction_chat_screen.dart';
import '../../chat/providers/chat_provider.dart';
import '../../../core/widgets/currency_text.dart';

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

  Future<String?> _showReasonDialog(
      {required String actionLabel, bool isMandatory = false}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text('$actionLabel Transaction',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMandatory
                  ? 'Please provide a reason for this action.'
                  : 'Add an optional remark (or leave empty).',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter note here...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (isMandatory && text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reason is required')),
                );
                return;
              }
              Navigator.pop(context, text);
            },
            child:
                Text(actionLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
        actions: [
          _buildAdminChatButton(widget.transaction),
          const SizedBox(width: 8),
        ],
      ),
      body: transactionAsync.when(
        loading: () => _buildContent(widget.transaction, isLoading: true),
        error: (err, stack) => ErrorStateWidget(
          error: err,
          onRetry: () => ref.refresh(singleTransactionProvider(transactionId)),
        ),
        data: (liveTransaction) {
          final transaction = liveTransaction ?? widget.transaction;
          return _buildContent(transaction);
        },
      ),
    );
  }

  /// Admin chat button with unread badge
  Widget _buildAdminChatButton(TransactionModel transaction) {
    final unreadAsync = ref.watch(unreadCountStreamProvider(transaction.id));

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.chat, color: AppColors.primaryOrange),
          tooltip: 'Open Chat',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionChatScreen(
                transactionId: transaction.id,
                transactionTitle: 'Chat: ${transaction.type.name}',
                transactionDetails: transaction.details,
              ),
            ),
          ),
        ),
        // Unread badge
        unreadAsync.when(
          data: (count) => count > 0
              ? Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
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
          const SizedBox(height: 10),

          // Lock Status Indicator
          _buildLockStatusIndicator(transaction),

          const SizedBox(height: 20),

          // Key Details
          _buildDetailRow('Transaction ID', transaction.id.substring(0, 8)),
          _buildDetailRow('Type', transaction.type.name.toUpperCase()),
          _buildCurrencyRow(
              'Amount (Fiat)',
              transaction.details['currency_symbol'] ?? '\u20A6',
              transaction.amountFiat.toStringAsFixed(2)),
          if (transaction.details.containsKey('usd_input'))
            _buildDetailRow(
                'USD Input', '\$${transaction.details['usd_input']}'),
          if (transaction.details.containsKey('admin_name'))
            _buildDetailRow(
                'Assigned Agent', transaction.details['admin_name']),

          // User Info Section
          Column(
            children: [
              _buildDetailRow('User Country',
                  transaction.details['user_country'] ?? 'Unknown/Old'),
              _buildDetailRow('User Currency',
                  transaction.details['user_currency'] ?? 'NGN'),
              if (transaction.details.containsKey('user_full_name'))
                _buildDetailRow(
                    'Full Name', transaction.details['user_full_name']),
            ],
          ),
          if (transaction.amountCrypto != null)
            _buildDetailRow('Amount (Crypto)',
                '${transaction.amountCrypto} ${transaction.currencyPair.split('/').first}'),
          _buildDetailRow('Currency Pair', transaction.currencyPair),
          if (transaction.details.containsKey('fx_rate_applied'))
            _buildCurrencyRow('FX Rate', '\u20A6',
                '${transaction.details['fx_rate_applied']}/USD'),
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
            _TransactionImage(
              path: transaction.proofImagePath!,
              type: transaction.type,
            ),
          ],

          const SizedBox(height: 20),

          // Admin Proof Images Section
          _buildAdminProofImagesSection(transaction),

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Build row with currency symbol using CurrencyText widget for proper rendering
  Widget _buildCurrencyRow(String label, String symbol, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: CurrencyText(
                symbol: symbol,
                amount: amount,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build lock status indicator with claim/unclaim actions
  Widget _buildLockStatusIndicator(TransactionModel transaction) {
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (currentUserId == null) return const SizedBox.shrink();

    final isClaimedByMe =
        transaction.adminId == currentUserId && transaction.claimedAt != null;
    final isClaimedByOther = transaction.isClaimedByOther(currentUserId);

    if (!transaction.status.isActive) {
      return const SizedBox
          .shrink(); // No lock status for completed transactions
    }

    if (isClaimedByOther) {
      // Claimed by another admin - show warning
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Locked by another admin. You cannot modify this transaction.',
                style: TextStyle(color: Colors.red[300], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (isClaimedByMe) {
      // Claimed by current admin - show unclaim option
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_open, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You have claimed this order',
                style: TextStyle(color: Colors.green[300], fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () => _unclaimTransaction(transaction),
              child:
                  const Text('Release', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
    }

    // Not claimed - show claim button
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryOrange),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline,
              color: AppColors.primaryOrange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Claim this order to start processing',
              style: TextStyle(color: Colors.orange[300], fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: () => _claimTransaction(transaction),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Claim', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Claim a transaction for this admin
  Future<void> _claimTransaction(TransactionModel transaction) async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final adminId = client.auth.currentUser!.id;

      await client.from('transactions').update({
        'admin_id': adminId,
        'claimed_at': DateTime.now().toIso8601String(),
        'status': 'claimed',
      }).eq('id', transaction.id);

      // Log the activity
      await client.from('admin_activity_log').insert({
        'admin_id': adminId,
        'transaction_id': transaction.id,
        'action': 'claim',
      });

      // Send notification to user
      await client.from('notifications').insert({
        'user_id': transaction.userId,
        'title': 'Transaction Update',
        'message':
            'Your transaction has been claimed by an admin and is being processed.',
        'type': 'transaction',
        'related_id': transaction.id,
        'is_read': false,
      });

      ref.invalidate(singleTransactionProvider(transaction.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Order claimed!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Release/unclaim a transaction
  Future<void> _unclaimTransaction(TransactionModel transaction) async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final adminId = client.auth.currentUser!.id;

      await client.from('transactions').update({
        'admin_id': null,
        'claimed_at': null,
        'status': 'pending',
      }).eq('id', transaction.id);

      // Log the activity
      await client.from('admin_activity_log').insert({
        'admin_id': adminId,
        'transaction_id': transaction.id,
        'action': 'unclaim',
      });

      ref.invalidate(singleTransactionProvider(transaction.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Order released'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Section for displaying and uploading admin proof images
  Widget _buildAdminProofImagesSection(TransactionModel transaction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Admin Proof Images',
                style: AppTextStyles.titleMedium(context)),
            // Upload button (only for active transactions)
            if (transaction.status.isActive)
              IconButton(
                onPressed: () => _uploadAdminProof(transaction),
                icon: const Icon(Icons.add_photo_alternate,
                    color: AppColors.primaryOrange),
                tooltip: 'Add Proof Image',
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (transaction.adminProofImages.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Text(
                'No admin proof images yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: transaction.adminProofImages.length,
              itemBuilder: (context, index) {
                final imageUrl = transaction.adminProofImages[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => _showFullImage(imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 120,
                          height: 120,
                          color: AppColors.backgroundCard,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 120,
                          height: 120,
                          color: AppColors.backgroundCard,
                          child: const Icon(Icons.error, color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// Show full image in dialog
  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  /// Upload admin proof image
  Future<void> _uploadAdminProof(TransactionModel transaction) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isLoading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final file = File(picked.path);
      final fileExt = picked.path.split('.').last;
      final fileName =
          'admin_${transaction.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload to storage
      await client.storage
          .from('transaction-proofs')
          .upload('admin/$fileName', file);

      // Get signed URL (works for private buckets - valid for 1 year)
      final imageUrl = await client.storage
          .from('transaction-proofs')
          .createSignedUrl('admin/$fileName', 60 * 60 * 24 * 365);

      // Update transaction with new image
      final updatedImages = [...transaction.adminProofImages, imageUrl];
      await client.from('transactions').update({
        'admin_proof_images': updatedImages,
      }).eq('id', transaction.id);

      // Refresh data
      ref.invalidate(singleTransactionProvider(transaction.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proof image uploaded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveTransaction(
      TransactionModel transaction, WidgetRef ref, String? note) async {
    final service = ref.read(transactionServiceProvider);
    final isBuyGiftCard = transaction.type == TransactionType.buyGiftCard;

    // Merge details
    final newDetails = Map<String, dynamic>.from(transaction.details);

    if (isBuyGiftCard) {
      if (_giftCardInfoController.text.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter Gift Card details')));
        return;
      }
      newDetails['gift_card_info'] = _giftCardInfoController.text.trim();
    }

    // MANUAL PAYOUT LOGIC
    // Check if we need to set payout amount (Sell Flows)
    bool needsPayoutAmount = transaction.type == TransactionType.sellCrypto ||
        transaction.type == TransactionType.sellGiftCard;

    double? finalPayout;

    if (needsPayoutAmount) {
      // Show Dialog to get Amount
      if (!mounted) return;
      final amountStr = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            _PayoutDialog(estimatedAmount: transaction.amountFiat),
      );

      if (amountStr == null) return; // Cancelled
      finalPayout = double.tryParse(amountStr);
      if (finalPayout == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid Amount Entered')));
        return;
      }
    }

    // Build notification message based on transaction type
    String notificationMessage;
    if (transaction.type == TransactionType.buyCrypto) {
      // Buy Crypto: Crypto sent to user's external wallet (NO wallet credit)
      final asset = transaction.details['asset'] ?? 'Crypto';
      final targetAddress =
          transaction.details['target_address'] ?? 'your wallet';
      final cryptoAmount = transaction.amountCrypto?.toStringAsFixed(6) ?? '0';
      notificationMessage =
          'Transaction Completed! Your $cryptoAmount $asset has been sent to $targetAddress.';
    } else if (transaction.type == TransactionType.buyGiftCard) {
      // Buy Gift Card: Code provided
      notificationMessage =
          'Transaction Completed! View details for your code.';
    } else if (transaction.type == TransactionType.withdrawal) {
      // Withdrawal: Money sent to user's bank
      final bankName = transaction.details['bank_name'] ?? 'Bank';
      final accountNum = transaction.details['account_number'] ?? '****';
      notificationMessage =
          'Withdrawal successful, your funds has been credited to your designated bank account ($bankName - $accountNum).';
    } else {
      // Sell Crypto / Sell GiftCard: Wallet credited
      notificationMessage =
          'Transaction Completed! Your wallet has been credited with ${finalPayout ?? transaction.amountFiat}.';
    }

    await service.updateStatus(
      transactionId: transaction.id,
      targetUserId: transaction.userId,
      newStatus: TransactionStatus.completed,
      previousStatus: transaction.status,
      note: note ?? 'Admin approved and completed transaction',
      details: newDetails,
      finalPayoutAmount: finalPayout,
      notificationMessage: notificationMessage,
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
            // Non-Buy Requests (Withdrawal / Sell)
            // Admin can approve directly after checking details
            _buildActionButton(
              transaction.type == TransactionType.withdrawal
                  ? 'Approve & Mark Sent'
                  : 'Approve & Credit Wallet',
              Colors.green,
              () async {
                final note = await _showReasonDialog(
                    actionLabel: 'Approve', isMandatory: false);
                if (note == null) return;
                await _approveTransaction(transaction, ref, note);
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Reject',
              Colors.red,
              () async {
                final reason = await _showReasonDialog(
                    actionLabel: 'Reject', isMandatory: true);
                if (reason == null) return;

                await service.updateStatus(
                  transactionId: transaction.id,
                  targetUserId: transaction.userId,
                  newStatus: TransactionStatus.rejected,
                  previousStatus: transaction.status,
                  note: reason,
                );
              },
            ),
          ],

          const SizedBox(height: 12),

          // 'Pending Verification' allows moving to a holding state if needed
          // Mostly useful for Buy requests waiting for user, or complex verifications
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
      final isBuyCrypto = transaction.type == TransactionType.buyCrypto;
      final isBuyRequest = isBuyGiftCard || isBuyCrypto;
      final hasProof = transaction.proofImagePath != null;
      final userName = transaction.details['user_full_name'] ?? 'User';

      // For BUY requests in payment_pending without proof - show waiting message
      if (isBuyRequest &&
          transaction.status == TransactionStatus.paymentPending &&
          !hasProof) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Waiting for payment message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top,
                      color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Waiting for Payment',
                          style: AppTextStyles.titleSmall(context).copyWith(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Waiting for $userName to make payment and upload proof.',
                          style:
                              TextStyle(color: Colors.amber[200], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Show payment details sent
            if (transaction.details['admin_bank_details'] != null) ...[
              Text('Payment Details Sent:',
                  style: AppTextStyles.bodySmall(context)
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transaction.details['admin_bank_details'].toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildActionButton(
              'Cancel Transaction',
              Colors.red,
              () async {
                final reason = await _showReasonDialog(
                    actionLabel: 'Cancel', isMandatory: true);
                if (reason == null) return;

                await service.updateStatus(
                  transactionId: transaction.id,
                  targetUserId: transaction.userId,
                  newStatus: TransactionStatus.rejected,
                  previousStatus: transaction.status,
                  note: reason,
                );
              },
            ),
          ],
        );
      }

      // Has proof or verification_pending - show approve/reject buttons
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proof received indicator for buy requests
          if (isBuyRequest && hasProof) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Payment proof received from $userName. Review and approve.',
                      style: TextStyle(color: Colors.green[300], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              final note = await _showReasonDialog(
                  actionLabel: 'Approve', isMandatory: false);
              if (note == null) return;
              await _approveTransaction(transaction, ref, note);
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Reject',
            Colors.red,
            () async {
              final reason = await _showReasonDialog(
                  actionLabel: 'Reject', isMandatory: true);
              if (reason == null) return;

              await service.updateStatus(
                transactionId: transaction.id,
                targetUserId: transaction.userId,
                newStatus: TransactionStatus.rejected,
                previousStatus: transaction.status,
                note: reason,
              );
            },
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

// Payout Dialog Widget
class _PayoutDialog extends StatefulWidget {
  final double estimatedAmount;

  const _PayoutDialog({required this.estimatedAmount});

  @override
  State<_PayoutDialog> createState() => _PayoutDialogState();
}

class _PayoutDialogState extends State<_PayoutDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with estimated amount
    _controller.text = widget.estimatedAmount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: const Text('Confirm Payout Amount',
          style: TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter the final amount to credit to the user\'s wallet.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              prefixText: '₦ ',
              prefixStyle: const TextStyle(
                color: AppColors.primaryOrange,
                fontFamily: 'Roboto',
                fontFamilyFallback: ['Noto Sans'],
              ),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Confirm & Pay',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _TransactionImage extends ConsumerWidget {
  final String path;
  final TransactionType type;

  const _TransactionImage({required this.path, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // All transaction images are uploaded to 'transaction-proofs' bucket
    const bucket = 'transaction-proofs';

    final imageAsync =
        ref.watch(signedUrlProvider((bucket: bucket, path: path)));

    return imageAsync.when(
      loading: () =>
          const Center(child: RocketLoader(color: AppColors.primaryOrange)),
      error: (_, __) => const Text('Error loading image',
          style: TextStyle(color: Colors.red)),
      data: (url) => GestureDetector(
        onTap: () {
          // Show full screen on tap
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              child: CachedNetworkImage(imageUrl: url),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: url,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 300,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 300,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, size: 50),
            ),
          ),
        ),
      ),
    );
  }
}
