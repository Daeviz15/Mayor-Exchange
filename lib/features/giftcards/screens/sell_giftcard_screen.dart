import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_handler_utils.dart';
import '../../../core/utils/permission_utils.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../../core/widgets/currency_text.dart';

import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transaction_service.dart';
import '../../transactions/services/forex_service.dart';
import '../models/gift_card.dart';
import '../models/gift_card_variant.dart';
import '../../giftcards/providers/gift_cards_providers.dart';

/// Screen for selling gift cards to the platform.
/// Customers sell their gift cards in exchange for NGN or USDT.
class SellGiftCardScreen extends ConsumerStatefulWidget {
  final GiftCard giftCard;

  const SellGiftCardScreen({
    super.key,
    required this.giftCard,
  });

  @override
  ConsumerState<SellGiftCardScreen> createState() => _SellGiftCardScreenState();
}

class _SellGiftCardScreenState extends ConsumerState<SellGiftCardScreen> {
  final _denominationController = TextEditingController();
  final _cardCodeController = TextEditingController();

  File? _proofImage;
  final _picker = ImagePicker();

  bool _isLoading = false;
  bool _isPhysicalCard = false; // false = E-Code, true = Physical

  // Apple variant selection (only for Apple cards)
  GiftCardVariant? _selectedVariant;
  double? _selectedDenomination;

  @override
  void dispose() {
    _denominationController.dispose();
    _cardCodeController.dispose();
    super.dispose();
  }

  double get _cardValueUSD {
    return double.tryParse(_denominationController.text) ?? 0.0;
  }

  Future<void> _pickImage() async {
    final hasPermission =
        await PermissionUtils.requestGalleryPermission(context);
    if (!hasPermission) return;

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

  /// Sell orders require: valid card value + proof image
  /// For Apple cards: also requires variant and denomination selection
  bool _isOrderValid(GiftCard card) {
    if (_cardValueUSD <= 0 || _proofImage == null) return false;

    // Apple cards require variant + denomination selection
    if (card.id == 'apple') {
      if (_selectedVariant == null || _selectedDenomination == null)
        return false;
      final rate =
          _selectedVariant!.getRateForDenomination(_selectedDenomination!);
      return rate > 0;
    }

    // Other cards: validate against min/max/allowedDenominations
    return card.isValidValue(_cardValueUSD);
  }

  @override
  Widget build(BuildContext context) {
    // Watch for real-time updates to this card
    final allCardsAsync = ref.watch(giftCardsFromDbProvider);
    final GiftCard liveCard = allCardsAsync.when(
      data: (cards) => cards.firstWhere(
        (c) => c.id == widget.giftCard.id,
        orElse: () => widget.giftCard,
      ),
      loading: () => widget.giftCard,
      error: (_, __) => widget.giftCard,
    );

    // Check if this is Apple card (has variants)
    final isAppleCard = liveCard.id == 'apple';

    // Load Apple variants if applicable
    final appleVariantsAsync = isAppleCard
        ? ref.watch(appleVariantsProvider)
        : const AsyncValue<List<GiftCardVariant>>.data([]);

    // Determine rate based on card type
    // For Apple: use variant-specific denomination rate
    // For others: use physical/ecode rate
    double buyRate;
    if (isAppleCard &&
        _selectedVariant != null &&
        _selectedDenomination != null) {
      buyRate =
          _selectedVariant!.getRateForDenomination(_selectedDenomination!);
    } else {
      buyRate = liveCard.getRate(isPhysical: _isPhysicalCard);
    }

    // For Apple, tradable if isActive and we have variants loaded
    // For others, tradable if isActive and buyRate > 0
    final isTradable = liveCard.isActive &&
        (isAppleCard
            ? appleVariantsAsync.asData?.value.isNotEmpty ?? false
            : buyRate > 0);
    debugPrint('===================');

    // Get user's currency

    const userCurrency = 'NGN'; // Hardcoded - country selection coming in v2.0
    final forexService = ref.read(forexServiceProvider);
    final currencySymbol = _getCurrencySymbol(userCurrency);

    double getRateInUserCurrency(double rateInNGN) {
      return forexService.convert(rateInNGN, userCurrency);
    }

    // Check if we are still loading critical data
    final bool isStreamLoading = allCardsAsync.isLoading;
    final bool isAppleLoading = isAppleCard && appleVariantsAsync.isLoading;

    if (isStreamLoading || isAppleLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(child: RocketLoader()),
      );
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
                color: liveCard.cardColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: liveCard.icon != null
                    ? Icon(liveCard.icon, color: Colors.white, size: 18)
                    : Text(
                        liveCard.logoText?.substring(0, 1) ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Text('Sell ${liveCard.name}',
                style: AppTextStyles.titleLarge(context)),
          ],
        ),
      ),
      body: !isTradable
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
                      !liveCard.isActive
                          ? '${liveCard.name} is currently inactive.'
                          : 'This gift card is not available for trading yet.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context)
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAppleCard &&
                              (appleVariantsAsync.asData?.value.isEmpty ??
                                  false)
                          ? 'No active variants found for this card.'
                          : 'Please check back later or contact support.',
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
                  // Rate Display - Only for non-Apple cards
                  // Apple cards use variant-based pricing
                  if (!isAppleCard) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sell,
                              color: AppColors.primaryOrange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Buy Rate',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                Builder(builder: (context) {
                                  final rateInUserCurrency =
                                      getRateInUserCurrency(buyRate);
                                  return Row(
                                    children: [
                                      CurrencyText(
                                        symbol: currencySymbol,
                                        amount:
                                            '${rateInUserCurrency.toStringAsFixed(2)} per \$1',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryOrange,
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ============================================
                  // APPLE VARIANT SELECTOR (only for Apple cards)
                  // ============================================
                  if (isAppleCard) ...[
                    Text('Select Card Type',
                        style: AppTextStyles.labelMedium(context)),
                    const SizedBox(height: 10),
                    appleVariantsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              color: AppColors.primaryOrange),
                        ),
                      ),
                      error: (e, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Error loading variants: $e',
                            style: const TextStyle(color: Colors.red)),
                      ),
                      data: (variants) => Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: variants.map((variant) {
                          final isSelected = _selectedVariant?.id == variant.id;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedVariant = variant;
                                _selectedDenomination =
                                    null; // Reset denomination
                                _denominationController.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryOrange
                                    : AppColors.backgroundCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : Colors.white10,
                                ),
                              ),
                              child: Text(
                                variant.name.replaceFirst('AppleCard ', ''),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Denomination selector for selected variant
                    if (_selectedVariant != null) ...[
                      Text('Select Denomination',
                          style: AppTextStyles.labelMedium(context)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _selectedVariant!.denominationRates
                            .where((r) =>
                                r.rate >
                                0) // Only show denominations with rates set
                            .map((rate) {
                          final isSelected =
                              _selectedDenomination == rate.denomination;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDenomination = rate.denomination;
                                _denominationController.text =
                                    rate.denomination.toStringAsFixed(0);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryOrange
                                    : AppColors.backgroundCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : Colors.white10,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '\$${rate.denomination.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₦${rate.rate.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white70
                                          : AppColors.textSecondary,
                                      fontSize: 10,
                                      fontFamily: 'Roboto',
                                      fontFamilyFallback: const [
                                        'Noto Sans',
                                        'Arial'
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Show message if no rates are set
                      if (_selectedVariant!.denominationRates
                          .every((r) => r.rate <= 0))
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Rates not set for this variant. Please contact admin.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                    ],

                    const SizedBox(height: 24),
                  ],

                  // ============================================
                  // STANDARD CARD TYPE TOGGLE (for non-Apple cards)
                  // ============================================
                  if (!isAppleCard) ...[
                    // Card Type Toggle (Physical vs E-Code)
                    Text('Card Type',
                        style: AppTextStyles.labelMedium(context)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _isPhysicalCard = false),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: !_isPhysicalCard
                                      ? AppColors.primaryOrange
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.qr_code,
                                      color: !_isPhysicalCard
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'E-Code',
                                      style: TextStyle(
                                        color: !_isPhysicalCard
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _isPhysicalCard = true),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _isPhysicalCard
                                      ? AppColors.primaryOrange
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.credit_card,
                                      color: _isPhysicalCard
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Physical',
                                      style: TextStyle(
                                        color: _isPhysicalCard
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Denomination Selector (use dynamic denominations from card)
                    Text('Card Value (USD)',
                        style: AppTextStyles.labelMedium(context)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: liveCard.getValidDenominations().map((denom) {
                        final isSelected = _denominationController.text ==
                            denom.toInt().toString();
                        return ChoiceChip(
                          label: Text('\$${denom.toInt()}'),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _denominationController.text =
                                    denom.toInt().toString();
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
                        hintText: liveCard.allowedDenominations.isEmpty
                            ? 'Enter value (\$${liveCard.minValue.toInt()} - \$${liveCard.maxValue.toInt()})'
                            : 'Select a denomination above',
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
                  ], // End of if (!isAppleCard)

                  const SizedBox(height: 24),

                  // Proof upload section
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
                                  style:
                                      TextStyle(color: AppColors.textSecondary),
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

                  const SizedBox(height: 24),

                  // Payout Display
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
                            'You Receive:',
                            style: AppTextStyles.labelMedium(context),
                          ),
                          Builder(builder: (context) {
                            final amountNGN = _cardValueUSD * buyRate;
                            final amountUser =
                                forexService.convert(amountNGN, userCurrency);
                            return CurrencyText(
                              symbol: currencySymbol,
                              amount: amountUser.toStringAsFixed(2),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryOrange,
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
                      onPressed: (_isOrderValid(liveCard) && !_isLoading)
                          ? () => _submitTransaction(liveCard, buyRate)
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
                          : const Text(
                              'Sell Gift Card',
                              style: TextStyle(
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

  Future<void> _submitTransaction(GiftCard card, double rate) async {
    if (_cardValueUSD <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a card value')));
      return;
    }

    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please upload an image of your gift card')));
      return;
    }

    // Calculate payout using Buy Rate
    final fiatAmountNGN = _cardValueUSD * rate;

    // Get user's currency for display

    const userCurrency = 'NGN'; // Hardcoded - country selection coming in v2.0
    final forexService = ref.read(forexServiceProvider);
    final fiatInUserCurrency =
        forexService.convert(fiatAmountNGN, userCurrency);
    final currencySymbol = _getCurrencySymbol(userCurrency);
    final rateInUserCurrency = forexService.convert(rate, userCurrency);

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
                color: card.cardColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: card.icon != null
                    ? Icon(card.icon, color: Colors.white, size: 18)
                    : Text(
                        card.logoText?.substring(0, 1) ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Confirm Sale',
              style: AppTextStyles.titleLarge(context),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmRow('Gift Card:', card.name),
            _buildConfirmRow(
                'Card Value:', '\$${_cardValueUSD.toStringAsFixed(0)}'),
            _buildConfirmRow(
              'Rate:',
              '$currencySymbol${rateInUserCurrency.toStringAsFixed(2)}/\$1',
            ),
            const Divider(color: AppColors.divider),
            _buildConfirmRow(
              'You Receive:',
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
                      'Admin will verify your card and credit your wallet.',
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
            child: const Text(
              'Confirm Sale',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Proceed with submission
    setState(() => _isLoading = true);

    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser!.id;

    try {
      // Upload proof
      final proofPath = await _uploadProof(userId);
      if (proofPath == null) throw 'Image upload failed';

      // Submit transaction
      await ref.read(transactionServiceProvider).submitTransaction(
        type: TransactionType.sellGiftCard,
        amountFiat: fiatAmountNGN,
        amountCrypto: _cardValueUSD, // Store card value in crypto field
        currencyPair: '${card.id}/NGN',
        proofImagePath: proofPath,
        details: {
          'card_id': card.id,
          'card_name': _selectedVariant != null
              ? '${card.name} (${_selectedVariant!.name.replaceFirst("AppleCard ", "")})'
              : card.name,
          'card_type': _selectedVariant != null
              ? 'variant'
              : (_isPhysicalCard ? 'physical' : 'ecode'),
          'variant_id': _selectedVariant?.id,
          'variant_name': _selectedVariant?.name,
          'card_value_usd': _cardValueUSD,
          'rate_applied': rate,
          'card_code': _cardCodeController.text.isNotEmpty
              ? _cardCodeController.text
              : null,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sell request submitted!'),
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

  String _getCurrencySymbol(String currencyCode) {
    if (currencyCode == 'USD') return '\$';
    if (currencyCode == 'NGN') return '\u20A6';
    if (currencyCode == 'EUR') return '€';
    if (currencyCode == 'GBP') return '£';
    return currencyCode;
  }

  Widget _buildConfirmRow(String label, String value,
      {bool highlight = false}) {
    // Detect if the value is a currency string (starts with $, \u20A6, etc.)
    final isCurrency = value.startsWith('\$') || value.startsWith('\u20A6');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          isCurrency
              ? _buildCurrencyValue(value, highlight)
              : Text(
                  value,
                  style: TextStyle(
                    color: highlight ? AppColors.primaryOrange : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: highlight ? 18 : 14,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildCurrencyValue(String value, bool highlight) {
    // Split symbol and amount (e.g., "$50" or "₦1450.00/$1")
    String symbol = '';
    String amount = '';

    if (value.startsWith('\$') || value.startsWith('\u20A6')) {
      symbol = value.substring(0, 1);
      amount = value.substring(1);
    }

    return CurrencyText(
      symbol: symbol,
      amount: amount,
      style: TextStyle(
        color: highlight ? AppColors.primaryOrange : Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: highlight ? 18 : 14,
      ),
    );
  }
}
