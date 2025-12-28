import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_handler_utils.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/transaction.dart';
import '../providers/transaction_service.dart';
import 'buyer_transaction_status_screen.dart';

class BuySellGiftCardScreen extends ConsumerStatefulWidget {
  final TransactionType initialType;
  final String? initialCard;
  final String selectedCurrency; // New

  const BuySellGiftCardScreen({
    super.key,
    this.initialType = TransactionType.buyGiftCard,
    this.initialCard,
    this.selectedCurrency = 'USD', // Default
  });

  @override
  ConsumerState<BuySellGiftCardScreen> createState() =>
      _BuySellGiftCardScreenState();
}

class _BuySellGiftCardScreenState extends ConsumerState<BuySellGiftCardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController(); // For Buy

  // Sell Fields
  final _cardNumberController = TextEditingController();
  final _pinController = TextEditingController();

  // Selected Card
  String _selectedCard = 'Amazon';
  final List<String> _cards = [
    'Amazon',
    'Apple',
    'Google Play',
    'Steam',
    'Vanilla',
    'Sephora'
  ];

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCard != null) {
      _selectedCard = widget.initialCard!;
    }
    final initialIndex =
        (widget.initialType == TransactionType.buyGiftCard) ? 0 : 1;
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _cardNumberController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submitTransaction() async {
    final isBuy = _tabController.index == 0;

    // Validation
    if (isBuy && _amountController.text.isEmpty) {
      _showError('Please enter an amount');
      return;
    }
    if (!isBuy && _imageFile == null) {
      _showError('Please upload an image of the card');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authControllerProvider).asData?.value;
      if (user == null) throw Exception('User not logged in');

      String? proofPath;
      if (!isBuy && _imageFile != null) {
        proofPath = await ref.read(storageServiceProvider).uploadFile(
              file: _imageFile!,
              bucket: 'gift-cards',
              path: '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
      }

      // Determine currency symbol
      String currencySymbol = '\$';
      if (widget.selectedCurrency == 'GBP') currencySymbol = '£';
      if (widget.selectedCurrency == 'EUR') currencySymbol = '€';
      if (widget.selectedCurrency == 'NGN') currencySymbol = '₦';

      final transaction =
          await ref.read(transactionServiceProvider).submitTransaction(
        type:
            isBuy ? TransactionType.buyGiftCard : TransactionType.sellGiftCard,
        amountFiat: double.tryParse(_amountController.text) ?? 0.0,
        currencyPair:
            '${widget.selectedCurrency}/$_selectedCard', // e.g. USD/Amazon
        proofImagePath: proofPath,
        details: {
          'card_name': _selectedCard,
          'card_type': _selectedCard,
          'card_number': isBuy ? null : _cardNumberController.text,
          'pin': isBuy ? null : _pinController.text,
          'currency_symbol': currencySymbol, // Save symbol
          if (!isBuy) ...{
            'user_bank_name': 'Fiat Wallet',
            'user_account_number': 'N/A',
            'user_account_name': 'Credited to Wallet',
          },
        },
      );

      if (!mounted) return;

      // Navigate to Status Screen (Replace current screen so they can't go back to form easily)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BuyerTransactionStatusScreen(
            transactionId: transaction.id,
            initialTransaction: transaction,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Friendly Error Handling
      // Friendly Error Handling
      final message = ErrorHandlerUtils.getUserFriendlyErrorMessage(e);
      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = _tabController.index == 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: Text('Gift Cards', style: AppTextStyles.titleLarge(context)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryOrange,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryOrange,
          tabs: const [
            Tab(text: 'Buy Card'),
            Tab(text: 'Sell Card'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Selector
            Text('Select Card Type', style: AppTextStyles.labelMedium(context)),
            const SizedBox(height: 10),
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  final isSelected = card == _selectedCard;
                  return ChoiceChip(
                    label: Text(card),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCard = card);
                    },
                    selectedColor: AppColors.primaryOrange,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: AppColors.backgroundElevated,
                    side: BorderSide.none,
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Amount Input (Face Value)
            Text('Card Value (${widget.selectedCurrency})',
                style: AppTextStyles.labelMedium(context)),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'e.g. 50, 100',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixText: _getCurrencySymbol(widget.selectedCurrency),
                prefixStyle: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),

            if (!isBuy) ...[
              const SizedBox(height: 24),
              Text('Card Details (Optional)',
                  style: AppTextStyles.labelMedium(context)),
              const SizedBox(height: 10),
              TextField(
                controller: _cardNumberController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Card Code',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: AppColors.backgroundCard,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _pinController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'PIN (if any)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: AppColors.backgroundCard,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              // Wallet Credit Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryOrange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet,
                            color: AppColors.primaryOrange, size: 20),
                        SizedBox(width: 8),
                        Text('Funds Destination',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Funds will be credited to your Fiat Wallet',
                      style: AppTextStyles.titleMedium(context)
                          .copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Once approved, the balance will be instantly available for withdrawal.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Card Image', style: AppTextStyles.labelMedium(context)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt,
                                size: 40, color: AppColors.textSecondary),
                            const SizedBox(height: 8),
                            Text('Tap to upload image',
                                style: AppTextStyles.bodyMedium(context)
                                    .copyWith(color: AppColors.textSecondary)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        ),
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _submitTransaction,
                child: _isLoading
                    ? const RocketLoader(size: 24, color: Colors.white)
                    : Text(
                        isBuy ? 'Purchase Card' : 'Sell This Card',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'NGN':
        return '₦';
      default:
        return '\$';
    }
  }
}
