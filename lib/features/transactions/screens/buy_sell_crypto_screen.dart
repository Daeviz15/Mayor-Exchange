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
import '../../settings/providers/settings_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../../crypto/providers/crypto_providers.dart';
import '../../dasboard/models/crypto_data.dart';
import '../models/transaction.dart';
import '../providers/transaction_service.dart';
import '../providers/rates_provider.dart';
import '../services/forex_service.dart';
import '../../../core/widgets/price_timestamp_widget.dart';
import '../../../core/providers/navigation_provider.dart';

class BuySellCryptoScreen extends ConsumerStatefulWidget {
  final TransactionType initialType;
  final String? initialAsset;

  const BuySellCryptoScreen({
    super.key,
    this.initialType = TransactionType.buyCrypto,
    this.initialAsset,
  });

  @override
  ConsumerState<BuySellCryptoScreen> createState() =>
      _BuySellCryptoScreenState();
}

class _BuySellCryptoScreenState extends ConsumerState<BuySellCryptoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _addressController =
      TextEditingController(); // Wallet Addr (Buy) or Bank Details (Sell)

  File? _proofImage;
  final _picker = ImagePicker();

  // Selected Asset
  String _selectedAsset = 'BTC';
  final List<String> _assets = [
    'BTC',
    'ETH',
    'USDT',
    'SOL',
    'BNB',
    'XRP',
    'DOGE',
    'ADA',
    'TRX',
    'DOT'
  ];

  bool _isLoading = false;
  Timer? _priceRefreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAsset != null) {
      if (_assets.contains(widget.initialAsset)) {
        _selectedAsset = widget.initialAsset!;
      }
    }
    final initialIndex =
        (widget.initialType == TransactionType.buyCrypto) ? 0 : 1;
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      setState(() {});
    });

    // Start auto-refresh timer (every 30 seconds)
    _startPriceRefreshTimer();
  }

  void _startPriceRefreshTimer() {
    _priceRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _autoRefreshPrices();
    });
  }

  Future<void> _autoRefreshPrices() async {
    if (!mounted) return;

    // Only refresh if this screen is the active tab (index 1 = Trade)
    // This prevents background refreshes when user is on other tabs
    final currentTabIndex = ref.read(navigationProvider);
    if (currentTabIndex != 1) {
      debugPrint(
          '🔄 Trade screen not active (tab=$currentTabIndex), skipping auto-refresh');
      return;
    }

    // Debug removed
    setState(() => _isRefreshing = true);

    try {
      // Refresh crypto prices silently
      await ref.read(cryptoListProvider.notifier).refresh();
    } catch (e) {
      // Debug removed
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  void dispose() {
    _priceRefreshTimer?.cancel();
    _tabController.dispose();
    _amountController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get _amountUSD {
    return double.tryParse(_amountController.text) ?? 0.0;
  }

  // Get live market price for selected asset from cryptoListProvider
  double _getMarketPrice(List<CryptoData> cryptoList) {
    for (final crypto in cryptoList) {
      if (crypto.symbol.toUpperCase() == _selectedAsset.toUpperCase()) {
        return crypto.price;
      }
    }
    return 0.0;
  }

  // Calculate Crypto Amount based on USD Input and Live Market Price
  double _calculateCryptoAmount(double marketPrice) {
    if (marketPrice <= 0) return 0.0;
    return _amountUSD / marketPrice;
  }

  // Get dynamic FX Rate (NGN/USD) from Admin Rates (using USDT as base or specific asset rate)
  CryptoRate? _getAdminRate(List<CryptoRate> rates) {
    try {
      // 1. Try to get rate for current asset
      // 2. Fallback to USDT rate
      final assetRate = rates.firstWhere(
        (r) => r.assetSymbol == _selectedAsset,
        orElse: () => rates.firstWhere(
          (r) => r.assetSymbol == 'USDT',
          orElse: () =>
              CryptoRate(assetSymbol: 'DEFAULT', buyRate: 1650, sellRate: 1600),
        ),
      );
      return assetRate;
    } catch (e) {
      return null;
    }
  }

  double _calculateFiatAmount(
      CryptoRate? rate, bool isBuy, double cryptoAmount) {
    if (rate == null) return 0.0;
    final fxRate = isBuy ? rate.buyRate : rate.sellRate;

    // Admin sets rates per UNIT of the asset.
    // e.g. BTC Buy Rate = 165,000,000 NGN.
    // So Fiat Amount = Crypto_Amount * Admin_Rate.

    return cryptoAmount * fxRate;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red),
      );
      return null;
    }
  }

  bool get _isValidOrder {
    final isBuy = _tabController.index == 0;
    final amountValid = _amountUSD > 0;

    if (isBuy) {
      // Buy only requires amount + wallet address (proof comes later after admin claims)
      return amountValid && _addressController.text.isNotEmpty;
    } else {
      // Sell requires amount + proof of crypto transfer
      return amountValid && _proofImage != null;
    }
  }

  // Pull to refresh functionality
  Future<void> _refreshData() async {
    // Invalidate both rates and crypto list providers to force fresh fetch
    ref.invalidate(ratesProvider);
    ref.invalidate(cryptoListProvider);
    // Small delay to show loading indicator
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _submitTransaction(CryptoRate? rate, double marketPrice) async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    // Sell orders require proof upload
    final isBuy = _tabController.index == 0;
    if (!isBuy && _proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please upload proof of your crypto transfer')));
      return;
    }

    // Step 1: Fetch fresh price before submission
    setState(() => _isLoading = true);

    double freshMarketPrice = marketPrice;
    try {
      // Force refresh to get the absolute latest price
      await ref.read(cryptoListProvider.notifier).refresh();

      // Get the fresh price
      final cryptoList = ref.read(cryptoListProvider).asData?.value ?? [];
      freshMarketPrice = _getMarketPrice(cryptoList);

      if (freshMarketPrice <= 0) {
        throw 'Could not fetch current market price';
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching current price: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    // Step 2: Calculate amounts with fresh price
    final freshCryptoAmount = _calculateCryptoAmount(freshMarketPrice);
    final freshFiatAmount =
        _calculateFiatAmount(rate, isBuy, freshCryptoAmount);
    final fxRateApplied = isBuy ? rate?.buyRate : rate?.sellRate;

    // Get currency symbol for display
    final authState = ref.read(authControllerProvider);
    final user = authState.asData?.value;
    final userCurrency = user?.currency ?? 'NGN';
    final currencySymbol = _getCurrencySymbol(userCurrency);
    final forexService = ref.read(forexServiceProvider);
    final fiatInUserCurrency =
        forexService.convert(freshFiatAmount, userCurrency);

    // Step 3: Show confirmation dialog with fresh price
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isBuy ? Icons.shopping_cart : Icons.sell,
              color: AppColors.primaryOrange,
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
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current market price (just fetched)',
                      style: TextStyle(color: Colors.blue[300], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Transaction details
            _buildConfirmRow('Asset:', _selectedAsset),
            _buildConfirmRow(
                'Market Price:', '\$${freshMarketPrice.toStringAsFixed(2)}'),
            _buildConfirmRow(
                'Amount (USD):', '\$${_amountUSD.toStringAsFixed(2)}'),
            _buildConfirmRow('Crypto Amount:',
                '${freshCryptoAmount.toStringAsFixed(8)} $_selectedAsset'),
            const Divider(color: AppColors.divider),
            _buildConfirmRow(
              isBuy ? 'You Pay:' : 'You Receive:',
              '$currencySymbol${fiatInUserCurrency.toStringAsFixed(2)}',
              highlight: true,
            ),

            const SizedBox(height: 16),

            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber,
                      color: AppColors.primaryOrange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Final price may vary slightly based on admin rates at time of processing.',
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
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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

    // Step 4: Proceed with actual submission
    setState(() => _isLoading = true);

    final type = isBuy ? TransactionType.buyCrypto : TransactionType.sellCrypto;
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser!.id;

    try {
      // Upload proof only for Sell orders (Buy proof comes later after admin claims)
      String? proofPath;
      if (!isBuy && _proofImage != null) {
        proofPath = await _uploadProof(userId);
        if (proofPath == null) throw 'Image upload failed';
      }

      // Submit Transaction with fresh price data
      await ref.read(transactionServiceProvider).submitTransaction(
        type: type,
        amountFiat: freshFiatAmount, // Use fresh calculated amount
        amountCrypto: freshCryptoAmount, // Use fresh calculated amount
        currencyPair: '$_selectedAsset/NGN',
        proofImagePath: proofPath, // null for Buy, path for Sell
        details: {
          'asset': _selectedAsset,
          'usd_input': _amountUSD,
          'market_price_at_submission':
              freshMarketPrice, // Record the price used
          'fx_rate_applied': fxRateApplied,
          'target_address':
              isBuy ? _addressController.text : 'Admin Deposit Wallet',
          'user_bank_details':
              isBuy ? 'Awaiting Payment Details' : 'Credited to Fiat Wallet',
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isBuy ? 'Buy' : 'Sell'} request submitted!'),
          backgroundColor: Colors.green,
        ),
      );

      // Safely navigate back - check if we can pop first
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      // Friendly Error Handling
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
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
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

  // Helper to get currency symbol
  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'CAD':
        return 'C\$';
      case 'GHS':
        return '₵';
      default:
        return '₦';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(ratesProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final isBuy = _tabController.index == 0;

    // Get user's preferred currency
    final authState = ref.watch(authControllerProvider);
    final user = authState.asData?.value;
    final userCurrency = user?.currency ?? 'NGN';
    final currencySymbol = _getCurrencySymbol(userCurrency);
    final forexService = ref.read(forexServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: Text('Trade Crypto', style: AppTextStyles.titleLarge(context)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryOrange,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryOrange,
          tabs: const [
            Tab(text: 'Buy Crypto'),
            Tab(text: 'Sell Crypto'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primaryOrange,
        backgroundColor: AppColors.backgroundCard,
        child: ratesAsync.when(
          loading: () => const Center(
              child: RocketLoader(size: 40, color: AppColors.primaryOrange)),
          error: (err, _) => LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          ErrorHandlerUtils.getUserFriendlyErrorMessage(err),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Pull down to refresh',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          data: (rates) {
            final currentRate = _getAdminRate(rates);
            final activeAdminRate =
                isBuy ? currentRate?.buyRate : currentRate?.sellRate;
            final payReceiveText = isBuy ? 'You Pay:' : 'You Receive:';

            // Watch crypto list for real-time market prices
            final cryptoListAsync = ref.watch(cryptoListProvider);
            final cryptoList = cryptoListAsync.asData?.value ?? [];
            final marketPrice = _getMarketPrice(cryptoList);
            final cryptoAmount = _calculateCryptoAmount(marketPrice);

            // Get the selected crypto for timestamp
            final selectedCrypto = cryptoList.isNotEmpty
                ? cryptoList.firstWhere(
                    (c) =>
                        c.symbol.toUpperCase() == _selectedAsset.toUpperCase(),
                    orElse: () => cryptoList.first,
                  )
                : null;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Asset Selector
                  Text('Select Asset',
                      style: AppTextStyles.labelMedium(context)),
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
                      itemCount: _assets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final asset = _assets[index];
                        final isSelected = asset == _selectedAsset;
                        return ChoiceChip(
                          label: Text(asset),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedAsset = asset);
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
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Market Price Display (Real-time from API)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        _isRefreshing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue,
                                ),
                              )
                            : const Icon(Icons.show_chart,
                                color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Market Price',
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 8),
                                  if (selectedCrypto != null)
                                    PriceTimestampWidget(
                                      lastUpdated: selectedCrypto.lastUpdated,
                                      textStyle: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 10,
                                      ),
                                      iconColor: Colors.blue,
                                      showIcon: false,
                                    ),
                                ],
                              ),
                              Text(
                                marketPrice > 0
                                    ? '1 $_selectedAsset = \$${marketPrice.toStringAsFixed(2)}'
                                    : 'Loading...',
                                style: AppTextStyles.titleMedium(context)
                                    .copyWith(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Admin Rate Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primaryOrange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up,
                            color: AppColors.primaryOrange, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isBuy ? 'Admin Buy Rate' : 'Admin Sell Rate',
                                  style: TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                              Builder(builder: (context) {
                                final rateInNgn = activeAdminRate ?? 0.0;
                                final rateInUserCurrency = forexService.convert(
                                    rateInNgn, userCurrency);
                                return Text(
                                  '1 $_selectedAsset = $currencySymbol${rateInUserCurrency.toStringAsFixed(2)}',
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

                  // Amount Input
                  Text('Amount (USD)',
                      style: AppTextStyles.labelMedium(context)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.attach_money,
                          color: AppColors.primaryOrange), // USD Icon
                      filled: true,
                      fillColor: AppColors.backgroundCard,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Conversion Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        // Crypto Equivalent
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Crypto:',
                                style: AppTextStyles.bodyMedium(context)),
                            Text(
                                '${cryptoAmount.toStringAsFixed(6)} $_selectedAsset',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(color: Colors.white10),
                        // Fiat Amount (Converted to User's Currency)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(payReceiveText,
                                style: AppTextStyles.bodyLarge(context)),
                            Builder(builder: (context) {
                              final fiatNgn = _calculateFiatAmount(
                                  currentRate, isBuy, cryptoAmount);
                              final fiatUserCurrency =
                                  forexService.convert(fiatNgn, userCurrency);
                              return Text(
                                '$currencySymbol${fiatUserCurrency.toStringAsFixed(2)}',
                                style: AppTextStyles.titleLarge(context)
                                    .copyWith(color: AppColors.primaryOrange),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dynamic Section: Wallet Address (Buy) OR Admin Wallet + Proof (Sell)
                  if (isBuy) ...[
                    // Buy Mode: User provides their wallet address to receive crypto
                    Text('Receive $_selectedAsset At:',
                        style: AppTextStyles.labelMedium(context)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                          hintText: 'Your $_selectedAsset Wallet Address',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: AppColors.backgroundCard,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none)),
                    ),

                    const SizedBox(height: 24),

                    // Info box explaining the buy flow
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text('How It Works',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. Place your order\n'
                            '2. Admin will claim and provide payment details\n'
                            '3. Make payment and upload proof\n'
                            '4. Receive crypto at your wallet address',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Sell Mode: Show Admin Wallet
                    Text('Send $_selectedAsset To:',
                        style: AppTextStyles.labelMedium(context)),
                    const SizedBox(height: 10),
                    settingsAsync.when(
                      data: (settings) {
                        final adminWallet =
                            settings.adminWallets[_selectedAsset] ??
                                'Contact Admin for Address';
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Admin Deposit Wallet',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              SelectableText(adminWallet,
                                  style: const TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text('(Official $_selectedAsset Address)',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (err, __) => Text(
                          ErrorHandlerUtils.getUserFriendlyErrorMessage(err),
                          style: const TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(height: 24),

                    // User Bank Details Input
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
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
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

                    // Proof of Crypto Transfer (Sell)
                    Text('Upload Proof of Transfer',
                        style: AppTextStyles.labelMedium(context)),
                    const SizedBox(height: 6),
                    Text(
                      'Upload a screenshot showing you sent crypto to the admin wallet',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _proofImage != null
                                  ? AppColors.primaryOrange
                                  : Colors.white24,
                              style: BorderStyle.solid),
                        ),
                        child: _proofImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    Image.file(_proofImage!, fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_outlined,
                                      color: AppColors.primaryOrange, size: 40),
                                  SizedBox(height: 8),
                                  Text('Tap to upload transfer proof',
                                      style: TextStyle(
                                          color: AppColors.textSecondary)),
                                ],
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
                        disabledBackgroundColor: Colors.grey[800],
                      ),
                      onPressed: (_isLoading ||
                              !_isValidOrder ||
                              marketPrice <= 0)
                          ? null
                          : () => _submitTransaction(currentRate, marketPrice),
                      child: _isLoading
                          ? const RocketLoader(size: 24, color: Colors.white)
                          : Text(
                              isBuy ? 'Place Buy Order' : 'Place Sell Order',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ), // Close RefreshIndicator
    );
  }
}
