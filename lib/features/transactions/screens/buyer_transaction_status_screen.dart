import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mayor_exchange/core/services/storage_service.dart';
import 'package:mayor_exchange/core/theme/app_colors.dart';
import 'package:mayor_exchange/core/theme/app_text_styles.dart';
import 'package:mayor_exchange/core/widgets/rocket_loader.dart';
import 'package:mayor_exchange/features/transactions/models/transaction.dart';
import 'package:mayor_exchange/features/transactions/providers/transaction_service.dart';
import '../../auth/providers/auth_providers.dart';

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

  Future<void> _pickAndSubmitProof() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _proofImage = File(picked.path);
      _isUploading = true;
      _isSuccess = false;
    });

    try {
      final user = ref.read(authControllerProvider).asData?.value;
      if (user == null) return;

      // 1. Upload Image
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildheader(transaction),
              const SizedBox(height: 24),
              _buildStatusSection(transaction),
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
        error: (e, s) => Center(child: Text('Error: $e')),
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

  Widget _buildheader(TransactionModel transaction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                color: AppColors.primaryOrange, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${transaction.type.name.toUpperCase().replaceAll('_', ' ')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${transaction.currencyPair} • ${transaction.details['currency_symbol'] ?? '₦'}${transaction.amountFiat}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryOrange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Instructions',
                      style: AppTextStyles.titleMedium(context)),
                  const SizedBox(height: 16),
                  if (bankDetails is String)
                    SelectableText(
                      bankDetails,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    )
                  else if (bankDetails is Map) ...[
                    _buildDetailRow(
                        'Bank Name', bankDetails['bank_name'] ?? 'N/A'),
                    _buildDetailRow('Account Number',
                        bankDetails['account_number'] ?? 'N/A',
                        isCopyable: true),
                    _buildDetailRow(
                        'Account Name', bankDetails['account_name'] ?? 'N/A'),
                  ] else
                    const Text('No details provided',
                        style: TextStyle(color: Colors.white)),
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
        // Case 3: Proof Uploaded -> Waiting for Admin
        return _buildStatusCard(
          icon: Icons.safety_check,
          color: Colors.purple,
          title: 'Verifying Payment',
          description:
              'We have received your proof of payment. An agent is verifying it right now. Your asset will be released shortly.',
        );

      case TransactionStatus.completed:
        final isBuyGiftCard = transaction.type == TransactionType.buyGiftCard ||
            transaction.type == TransactionType.buyCrypto;
        final giftCardInfo = transaction.details['gift_card_info'];

        if (isBuyGiftCard && giftCardInfo != null) {
          return Column(
            children: [
              _buildStatusCard(
                icon: Icons.check_circle,
                color: Colors.green,
                title: 'Transaction Completed',
                description: 'Your purchase is complete!',
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Gift Card Code:',
                        style: AppTextStyles.titleMedium(context)
                            .copyWith(color: Colors.green)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        giftCardInfo,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
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
      {bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Row(
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
