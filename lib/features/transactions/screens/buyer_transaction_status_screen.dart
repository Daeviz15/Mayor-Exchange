import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mayor_exchange/core/services/storage_service.dart';
import 'package:mayor_exchange/core/theme/app_colors.dart';
import 'package:mayor_exchange/core/utils/image_utils.dart';
import 'package:mayor_exchange/core/widgets/rocket_loader.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:mayor_exchange/features/transactions/models/transaction.dart';
import 'package:mayor_exchange/features/transactions/providers/transaction_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../giftcards/models/gift_card.dart';
import '../../giftcards/data/gift_cards_data.dart';
import '../../chat/screens/transaction_chat_screen.dart';
import '../../chat/providers/chat_provider.dart';

class BuyerTransactionStatusScreen extends ConsumerStatefulWidget {
  final String transactionId;
  final TransactionModel? initialTransaction;

  const BuyerTransactionStatusScreen({
    super.key,
    required this.transactionId,
    this.initialTransaction,
  });

  @override
  ConsumerState<BuyerTransactionStatusScreen> createState() =>
      _BuyerTransactionStatusScreenState();
}

class _BuyerTransactionStatusScreenState
    extends ConsumerState<BuyerTransactionStatusScreen> {
  File? _proofImage;
  bool _isUploading = false;
  bool _isSuccess = false;
  String? _fetchedNote;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _checkForMissingNote());
  }

  Future<void> _checkForMissingNote() async {
    final reason = await ref
        .read(transactionServiceProvider)
        .getRejectionReason(widget.transactionId);
    if (reason != null && mounted) {
      setState(() {
        _fetchedNote = reason;
      });
    }
  }

  Future<void> _pickAndSubmitProof() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // Compress image before uploading
    final compressed = await ImageUtils.compressProofImage(File(picked.path));

    setState(() {
      _proofImage = compressed;
      _isUploading = true;
      _isSuccess = false;
    });

    try {
      final user = ref.read(authControllerProvider).asData?.value;
      if (user == null) return;

      // 1. Upload Image (already compressed)
      final path = await ref.read(storageServiceProvider).uploadFile(
            file: _proofImage!,
            bucket: 'transaction-proofs',
            path: '${user.id}/${widget.transactionId}_proof.jpg',
          );

      // 2. Submit to Service
      await ref.read(transactionServiceProvider).userSubmitProof(
            transactionId: widget.transactionId,
            proofPath: path,
          );

      if (mounted) {
        setState(() {
          _isSuccess = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proof uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading proof: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch specific transaction
    final allTransactions = ref.watch(userTransactionsProvider);

    // 1. Try to use data from stream (Live)
    TransactionModel? transaction;
    // 2. Fallback to initial data (passed from previous screen)
    transaction = widget.initialTransaction;

    // Check Stream
    if (allTransactions.hasValue) {
      try {
        final found = allTransactions.value!
            .firstWhere((t) => t.id == widget.transactionId);
        transaction = found;
      } catch (_) {
        // Not found in stream yet, keep using initialTransaction if valid
      }
    }

    if (transaction != null) {
      // RENDERING DATA
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundCard,
          title: const Text('Transaction Details'),
          centerTitle: true,
          actions: [
            // Chat button with unread badge
            _buildChatButton(transaction),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildheader(transaction),
              const SizedBox(height: 24),
              _buildStatusSection(transaction),
              if (transaction.details['note'] != null &&
                  transaction.details['note'].toString().isNotEmpty &&
                  transaction.status != TransactionStatus.rejected &&
                  transaction.status != TransactionStatus.cancelled) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: transaction.status == TransactionStatus.rejected
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: transaction.status == TransactionStatus.rejected
                          ? Colors.red.withValues(alpha: 0.3)
                          : Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.status == TransactionStatus.rejected
                            ? 'REJECTION REASON'
                            : 'ADMIN REMARK',
                        style: TextStyle(
                          color:
                              transaction.status == TransactionStatus.rejected
                                  ? Colors.red
                                  : Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        transaction.details['note'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (transaction.details['admin_name'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.support_agent,
                            size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transaction Agent',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            transaction.details['admin_name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // IF NO DATA AT ALL (Loading Loop)
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Transaction Details'),
        centerTitle: true,
      ),
      body: allTransactions.when(
        data: (_) => const Center(
            child: Text('Transaction not found',
                style: TextStyle(color: Colors.white))),
        error: (e, s) => ErrorStateWidget(
          error: e,
          onRetry: () => ref.invalidate(userTransactionsProvider),
        ),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RocketLoader(),
              SizedBox(height: 16),
              Text('Syncing transaction...',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  /// Chat button with unread message badge
  Widget _buildChatButton(TransactionModel transaction) {
    final unreadAsync = ref.watch(unreadCountStreamProvider(transaction.id));

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline,
              color: AppColors.primaryOrange),
          tooltip: 'Chat with Support',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionChatScreen(
                  transactionId: transaction.id,
                  transactionTitle: 'Support Chat',
                  transactionDetails: transaction.details,
                ),
              ),
            );
          },
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

  Widget _buildheader(TransactionModel transaction) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                color: AppColors.primaryOrange, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.type.name.toUpperCase().replaceAll('_', ' '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900, // Extra bold
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${transaction.currencyPair} • ${transaction.details['currency_symbol'] ?? '₦'}${transaction.amountFiat}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto',
                      fontFamilyFallback: ['Noto Sans', 'Arial'],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(TransactionModel transaction) {
    switch (transaction.status) {
      case TransactionStatus.pending:
        // Case 1: Waiting for Admin
        return _buildStatusCard(
          icon: Icons.hourglass_top,
          color: Colors.amber,
          title: 'Waiting for Admin',
          description:
              'An agent will review your request shortly. Once accepted, you will see the payment details here.',
        );

      case TransactionStatus.paymentPending: // This matches our custom flow
        // Case 2: Admin Accepted -> Show Bank Details
        final bankDetails = transaction.details['admin_bank_details'];
        if (bankDetails == null) {
          return const Text('Error: Bank details missing');
        }
        return Column(
          children: [
            _buildStatusCard(
              icon: Icons.check_circle_outline,
              color: Colors.blue,
              title: 'Request Accepted',
              description:
                  'Please make a transfer to the account below to complete your purchase.',
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.backgroundCard,
                          AppColors.backgroundCard.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppColors.primaryOrange.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withOpacity(0.1),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24)),
                            border: Border(
                                bottom: BorderSide(
                                    color: AppColors.primaryOrange
                                        .withOpacity(0.2))),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance,
                                  color: AppColors.primaryOrange, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'PAYMENT DETAILS',
                                style: TextStyle(
                                  color: AppColors.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (bankDetails is String)
                                SelectableText(
                                  bankDetails,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.5,
                                      fontWeight: FontWeight.w500),
                                )
                              else if (bankDetails is Map) ...[
                                _buildDetailRow('Bank Name',
                                    bankDetails['bank_name'] ?? 'N/A'),
                                const Divider(color: Colors.white10),
                                _buildDetailRow('Account Number',
                                    bankDetails['account_number'] ?? 'N/A',
                                    isCopyable: true, isHighlighted: true),
                                const Divider(color: Colors.white10),
                                _buildDetailRow('Account Name',
                                    bankDetails['account_name'] ?? 'N/A'),
                              ] else
                                const Text('No details provided',
                                    style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_fileName != null) ...[
              Text('Proof Selected: $_fileName',
                  style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed:
                    (_isUploading || _isSuccess) ? null : _pickAndSubmitProof,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : (_isSuccess
                        ? const Icon(Icons.check_circle, color: Colors.white)
                        : const Icon(Icons.upload_file)),
                label: Text(_isUploading
                    ? 'Uploading...'
                    : (_isSuccess
                        ? 'Payment Submitted'
                        : 'I Have Made Payment')),
              ),
            ),
          ],
        );

      case TransactionStatus.verificationPending:
        // Case 3: Waiting for Admin Verification
        // Different messages for buy vs sell transactions
        final isSellTransaction =
            transaction.type == TransactionType.sellGiftCard ||
                transaction.type == TransactionType.sellCrypto;

        return _buildStatusCard(
          icon: Icons.safety_check,
          color: Colors.purple,
          title:
              isSellTransaction ? 'Verifying Your Card' : 'Verifying Payment',
          description: isSellTransaction
              ? 'We are reviewing your gift card details. An agent is verifying it right now. Your payment will be processed shortly.'
              : 'We have received your proof of payment. An agent is verifying it right now. Your asset will be released shortly.',
        );

      case TransactionStatus.completed:
        final isBuyGiftCard = transaction.type == TransactionType.buyGiftCard ||
            transaction.type == TransactionType.buyCrypto;
        final giftCardInfo = transaction.details['gift_card_info'];
        final cardId = transaction.details['card_id'] as String?;
        final cardName = transaction.details['card_name'] as String? ??
            transaction.currencyPair.split('/').first;

        if (isBuyGiftCard && giftCardInfo != null) {
          // Get the gift card data for branding
          GiftCard? giftCard;
          if (cardId != null) {
            try {
              giftCard = GiftCardsData.getAllGiftCards().firstWhere(
                (gc) => gc.id.toLowerCase() == cardId.toLowerCase(),
              );
            } catch (_) {}
          }

          final redemptionUrl =
              cardId != null ? GiftCardsData.getRedemptionUrl(cardId) : null;

          return Column(
            children: [
              _buildStatusCard(
                icon: Icons.check_circle,
                color: Colors.green,
                title: 'Transaction Completed',
                description: 'Your purchase is complete!',
              ),
              const SizedBox(height: 24),

              // Brand header with logo
              if (giftCard != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        giftCard.cardColor.withOpacity(0.9),
                        giftCard.cardColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: giftCard.cardColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(
                          Icons.card_giftcard,
                          size: 150,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: giftCard.icon != null
                                        ? Icon(giftCard.icon,
                                            color: Colors.white, size: 24)
                                        : Text(
                                            giftCard.logoText
                                                    ?.substring(0, 1)
                                                    .toUpperCase() ??
                                                '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cardName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        'Official Gift Card',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Text(
                              '\$${transaction.amountCrypto?.toStringAsFixed(0) ?? '0'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                            const Text(
                              'CARD VALUE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Gift Card Code Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primaryOrange.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YOUR CODE',
                        style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              giftCardInfo,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily:
                                      'Courier', // Monospace for code feeling
                                  fontSize: 22,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy,
                                color: AppColors.primaryOrange),
                            onPressed: () => _copyToClipboard(giftCardInfo),
                            tooltip: 'Copy code',
                          ),
                        ],
                      ),
                    ),

                    // Redemption Instructions
                    if (redemptionUrl != null) ...[
                      const SizedBox(height: 16),
                      Text('REDEEM AT',
                          style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _copyToClipboard(redemptionUrl),
                        child: Row(
                          children: [
                            const Icon(Icons.link,
                                size: 16, color: AppColors.primaryOrange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                redemptionUrl,
                                style: const TextStyle(
                                  color: AppColors.primaryOrange,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }

        return _buildStatusCard(
          icon: Icons.check_circle,
          color: Colors.green,
          title: 'Completed',
          description: 'Transaction successful! Check your wallet or email.',
        );

      case TransactionStatus.cancelled:
        return _buildStatusCard(
          icon: Icons.cancel,
          color: Colors.red,
          title: 'Transaction Cancelled',
          description: (transaction.details['note'] as String?) ??
              _fetchedNote ??
              'This transaction was cancelled. Please verify your details or contact support.',
        );

      case TransactionStatus.rejected:
        return _buildStatusCard(
          icon: Icons.error_outline,
          color: Colors.red,
          title: 'Transaction Rejected',
          description: (transaction.details['note'] as String?) ??
              _fetchedNote ??
              'Your transaction was rejected. Please check the notification or contact support for reasons.',
        );

      default:
        return _buildStatusCard(
          icon: Icons.info,
          color: Colors.grey,
          title: 'Status: ${transaction.status.name}',
          description: 'Check back later.',
        );
    }
  }

  String? get _fileName => _proofImage?.path.split('/').last;

  Widget _buildDetailRow(String label, String value,
      {bool isCopyable = false, bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Row(
            children: [
              Text(value,
                  style: TextStyle(
                      color: isHighlighted
                          ? AppColors.primaryOrange
                          : Colors.white,
                      fontWeight:
                          isHighlighted ? FontWeight.w900 : FontWeight.bold,
                      fontSize: isHighlighted ? 18 : 14)),
              if (isCopyable) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _copyToClipboard(value),
                  child: const Icon(Icons.copy,
                      size: 16, color: AppColors.primaryOrange),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textSecondary, height: 1.5, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
