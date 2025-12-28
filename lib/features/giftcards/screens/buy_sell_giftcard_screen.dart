import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_handler_utils.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../auth/providers/auth_providers.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transaction_service.dart';
import '../../transactions/services/forex_service.dart';
import '../providers/giftcard_rates_provider.dart';
import '../models/gift_card.dart';

class BuySellGiftCardScreen extends ConsumerStatefulWidget {
  final GiftCard giftCard;
  final bool isBuy; // true = Buy from platform, false = Sell to platform

  const BuySellGiftCardScreen({
    super.key,
    required this.giftCard,
    this.isBuy = false, // Default to sell (more common use case)
  });

  @override
  ConsumerState<BuySellGiftCardScreen> createState() =>
      _BuySellGiftCardScreenState();
}

class _BuySellGiftCardScreenState extends ConsumerState<BuySellGiftCardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _denominationController = TextEditingController();
  final _cardCodeController =
      TextEditingController(); // For sell - card code/pin

  File? _proofImage;
  final _picker = ImagePicker();

  bool _isLoading = false;

  // Common denominations
  final List<double> _commonDenominations = [25, 50, 100, 200, 500];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.isBuy ? 0 : 1,
    );
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _denominationController.dispose();
    _cardCodeController.dispose();
    super.dispose();
  }

  double get _cardValueUSD {
    return double.tryParse(_denominationController.text) ?? 0.0;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _proofImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProof(String userId) async {
    if (_proofImage == null) return null;
    try {
      final client = ref.read(supabaseClientProvider);
      final fileExt = _proofImage!.path.split('.').last;
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = await client.storage
          .from('transaction-proofs')
          .upload(fileName, _proofImage!);
      return path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error uploading image: $e'),
              backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  bool get _isValidOrder {
    final isBuy = _tabController.index == 0;
    final hasValue = _cardValueUSD > 0;

    if (isBuy) {
      // Buy: just need denomination
      return hasValue;
    } else {
      // Sell: need denomination + proof of card
      return hasValue && _proofImage != null;
    }
  }

  Future<void> _submitTransaction(GiftCardRate rate) async {
    if (_cardValueUSD <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a card value')));
      return;
    }

    final isBuy = _tabController.index == 0;

    // Sell orders require proof
    if (!isBuy && _proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please upload an image of your gift card')));
      return;
    }

    // Calculate amounts - User-Centric Logic
    final fiatAmountNGN = isBuy
        ? rate.calculateBuyPayout(
            _cardValueUSD) // User BUY -> uses Admin BUY Rate
        : rate.calculateSellCost(
            _cardValueUSD); // User SELL -> uses Admin SELL Rate

    // Get user's currency for display
    final authState = ref.read(authControllerProvider);
    final user = authState.asData?.value;
    final userCurrency = user?.currency ?? 'NGN';
    final forexService = ref.read(forexServiceProvider);
    final fiatInUserCurrency =
        forexService.convert(fiatAmountNGN, userCurrency);

    // Use helper method for currency symbol
    final currencySymbol = _getCurrencySymbol(userCurrency);

    // Convert rate to user's currency for display - User-Centric Logic
    final rateInUserCurrency = forexService.convert(
        isBuy ? rate.buyRate : rate.sellRate, userCurrency);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.giftCard.cardColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: widget.giftCard.icon != null
                    ? Icon(widget.giftCard.icon, color: Colors.white, size: 18)
                    : Text(
                        widget.giftCard.logoText?.substring(0, 1) ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Confirm ${isBuy ? 'Purchase' : 'Sale'}',
              style: AppTextStyles.titleLarge(context),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmRow('Gift Card:', widget.giftCard.name),
            _buildConfirmRow(
                'Card Value:', '\$${_cardValueUSD.toStringAsFixed(0)}'),
            _buildConfirmRow(
              'Rate:',
              '$currencySymbol${rateInUserCurrency.toStringAsFixed(2)}/\$1',
            ),
            const Divider(color: AppColors.divider),
            _buildConfirmRow(
              isBuy ? 'You Pay:' : 'You Receive:',
              '$currencySymbol${fiatInUserCurrency.toStringAsFixed(2)}',
              highlight: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primaryOrange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isBuy
                          ? 'After payment, admin will send the gift card code.'
                          : 'Admin will verify your card and credit your wallet.',
                      style: TextStyle(color: Colors.orange[300], fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Confirm ${isBuy ? 'Buy' : 'Sell'}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Proceed with submission
    setState(() => _isLoading = true);

    final type =
        isBuy ? TransactionType.buyGiftCard : TransactionType.sellGiftCard;
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser!.id;

    try {
      // Upload proof for sell orders
      String? proofPath;
      if (!isBuy && _proofImage != null) {
        proofPath = await _uploadProof(userId);
        if (proofPath == null) throw 'Image upload failed';
      }

      // Submit transaction
      await ref.read(transactionServiceProvider).submitTransaction(
        type: type,
        amountFiat: fiatAmountNGN,
        amountCrypto: _cardValueUSD, // Store card value in crypto field
        currencyPair: '${widget.giftCard.id}/NGN',
        proofImagePath: proofPath,
        details: {
          'card_id': widget.giftCard.id,
          'card_name': widget.giftCard.name,
          'card_value_usd': _cardValueUSD,
          'rate_applied': isBuy ? rate.sellRate : rate.buyRate,
          'card_code': _cardCodeController.text.isNotEmpty
              ? _cardCodeController.text
              : null,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isBuy ? 'Buy' : 'Sell'} request submitted!'),
          backgroundColor: Colors.green,
        ),
      );

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      final message = ErrorHandlerUtils.getUserFriendlyErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildConfirmRow(String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color:
                  highlight ? AppColors.primaryOrange : AppColors.textPrimary,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              fontSize: highlight ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to get currency symbol for display
  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'GHS':
        return 'GH₵';
      case 'CAD':
        return 'C\$';
      case 'NGN':
      default:
        return '₦';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rateAsync =
        ref.watch(giftCardRateForCardProvider(widget.giftCard.id));
    final isBuy = _tabController.index == 0;

    // Get user's currency
    final authState = ref.watch(authControllerProvider);
    final user = authState.asData?.value;
    final userCurrency = user?.currency ?? 'NGN';
    final forexService = ref.read(forexServiceProvider);

    // Get the correct currency symbol
    final currencySymbol = _getCurrencySymbol(userCurrency);

    // Calculate the rate in user's currency (rates are stored in NGN)
    // Rate per $1 in user's currency = NGN rate converted to user currency
    double getRateInUserCurrency(double rateInNGN) {
      return forexService.convert(rateInNGN, userCurrency);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.giftCard.cardColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: widget.giftCard.icon != null
                    ? Icon(widget.giftCard.icon, color: Colors.white, size: 18)
                    : Text(
                        widget.giftCard.logoText?.substring(0, 1) ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.giftCard.name,
                style: AppTextStyles.titleLarge(context)),
          ],
        ),
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
      body: rateAsync == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.textSecondary, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'This gift card is not available for trading yet.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context)
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check back later or contact support.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall(context)
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rate Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isBuy ? Icons.shopping_cart : Icons.sell,
                          color: AppColors.primaryOrange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBuy ? 'Buy Rate' : 'Sell Rate',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Builder(builder: (context) {
                                // Convert rate from NGN to user's currency
                                final rateInNGN = isBuy
                                    ? rateAsync
                                        .buyRate // User BUY tab -> uses Admin BUY Rate
                                    : rateAsync
                                        .sellRate; // User SELL tab -> uses Admin SELL Rate
                                final rateInUserCurrency =
                                    getRateInUserCurrency(rateInNGN);
                                return Text(
                                  '$currencySymbol${rateInUserCurrency.toStringAsFixed(2)} per \$1',
                                  style: AppTextStyles.titleMedium(context)
                                      .copyWith(color: AppColors.primaryOrange),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Denomination Selector
                  Text('Card Value (USD)',
                      style: AppTextStyles.labelMedium(context)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _commonDenominations.map((denom) {
                      final isSelected =
                          _denominationController.text == denom.toString();
                      return ChoiceChip(
                        label: Text('\$$denom'),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _denominationController.text = denom.toString();
                            });
                          }
                        },
                        selectedColor: AppColors.primaryOrange,
                        backgroundColor: AppColors.backgroundElevated,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _denominationController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Or enter custom value',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      prefixText: '\$ ',
                      prefixStyle:
                          const TextStyle(color: Colors.white, fontSize: 18),
                      filled: true,
                      fillColor: AppColors.backgroundCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sell-specific: Proof upload
                  if (!isBuy) ...[
                    Text('Upload Card Image',
                        style: AppTextStyles.labelMedium(context)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _proofImage != null
                                ? Colors.green
                                : Colors.white10,
                          ),
                        ),
                        child: _proofImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    Image.file(_proofImage!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      color: AppColors.textSecondary, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to upload card photo',
                                    style: TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Optional card code
                    TextField(
                      controller: _cardCodeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Card Code/PIN (Optional)',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        hintText: 'Enter if you have the code',
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.backgroundCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Info message about wallet credit
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.account_balance_wallet,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your funds will be credited to your wallet',
                                  style: TextStyle(
                                    color: Colors.green[300],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Once your gift card is verified by admin, the funds will be automatically credited to your wallet balance.',
                                  style: TextStyle(
                                    color: Colors.green[200],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Payout/Cost Display
                  if (_cardValueUSD > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppColors.primaryOrange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isBuy ? 'You Pay:' : 'You Receive:',
                            style: AppTextStyles.labelMedium(context),
                          ),
                          Builder(builder: (context) {
                            final amountNGN = isBuy
                                ? rateAsync.calculateBuyPayout(
                                    _cardValueUSD) // User BUY -> uses BUY Rate
                                : rateAsync.calculateSellCost(
                                    _cardValueUSD); // User SELL -> uses SELL Rate
                            final amountUser =
                                forexService.convert(amountNGN, userCurrency);
                            return Text(
                              '$currencySymbol${amountUser.toStringAsFixed(2)}',
                              style: AppTextStyles.titleLarge(context).copyWith(
                                color: AppColors.primaryOrange,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isValidOrder && !_isLoading
                          ? () => _submitTransaction(rateAsync)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        disabledBackgroundColor: AppColors.backgroundElevated,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const RocketLoader(size: 24, color: Colors.white)
                          : Text(
                              isBuy ? 'Buy Gift Card' : 'Sell Gift Card',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
