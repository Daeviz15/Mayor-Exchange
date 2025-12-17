import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_service.dart';
import '../providers/rates_provider.dart';

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
  ]; // Expanded list

  // Market Prices (USD) - Ideally fetch these live
  final Map<String, double> _marketPrices = {
    'BTC': 98000.0,
    'ETH': 3800.0,
    'USDT': 1.0,
    'SOL': 240.0,
    'BNB': 650.0,
    'XRP': 2.50,
    'DOGE': 0.40,
    'ADA': 1.10,
    'TRX': 0.20,
    'DOT': 9.0,
  };

  bool _isLoading = false;

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
      setState(() {}); // Rebuild to update UI based on tab
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get _amountUSD {
    return double.tryParse(_amountController.text) ?? 0.0;
  }

  // Calculate Crypto Amount based on USD Input and Market Price
  double get _cryptoAmount {
    final price = _marketPrices[_selectedAsset] ?? 1.0;
    if (price == 0) return 0.0;
    return _amountUSD / price;
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

  double _calculateFiatAmount(CryptoRate? rate, bool isBuy) {
    if (rate == null) return 0.0;
    final fxRate = isBuy ? rate.buyRate : rate.sellRate;

    // Logic:
    // If Asset is USDT (Stable), calculation is direct: USD_Amount * FX_Rate.
    // If Asset is volatile (BTC), Admin Rate might be "NGN per BTC" or "NGN per USD".
    //
    // Assumption for this Admin System:
    // Admin sets rates per UNIT of the asset.
    // e.g. BTC Buy Rate = 165,000,000.
    // So Fiat Amount = Crypto_Amount * Admin_Rate.

    return _cryptoAmount * fxRate;
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

    // For Buy: Address is User Wallet. For Sell: Address is User Bank Details.
    final detailsValid = _addressController.text.isNotEmpty;

    if (isBuy) {
      // Buy requires Proof Image
      return amountValid && detailsValid && _proofImage != null;
    } else {
      // Sell just requires details (and amount)
      return amountValid && detailsValid;
    }
  }

  Future<void> _submitTransaction(CryptoRate? rate) async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    // User must upload proof for BUY orders
    final isBuy = _tabController.index == 0;
    if (isBuy && _proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a proof of payment')));
      return;
    }

    setState(() => _isLoading = true);

    final type = isBuy ? TransactionType.buyCrypto : TransactionType.sellCrypto;
    final amountCrypto = _cryptoAmount;
    final amountFiatNGN = _calculateFiatAmount(rate, isBuy);
    final fxRateApplied = isBuy ? rate?.buyRate : rate?.sellRate;
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser!.id;

    try {
      // 1. Upload Proof if Buy
      String? proofPath;
      if (isBuy) {
        proofPath = await _uploadProof(
            userId); // This returns the path 'userId/timestamp.jpg'
        if (proofPath == null) throw 'Image upload failed';
      }

      // 2. Submit Transaction
      await ref.read(transactionServiceProvider).submitTransaction(
        type: type,
        amountFiat: amountFiatNGN,
        amountCrypto: amountCrypto,
        currencyPair: '$_selectedAsset/NGN',
        proofImagePath: proofPath,
        details: {
          'asset': _selectedAsset,
          'usd_input': _amountUSD,
          'fx_rate_applied': fxRateApplied,
          'target_address': isBuy
              ? _addressController.text
              : 'Admin Deposit Wallet', // For Sell, we show Admin Wallet in UI (mock)
          'user_bank_details': isBuy
              ? 'N/A'
              : _addressController.text, // User gives bank when selling
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isBuy ? 'Buy' : 'Sell'} request submitted!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
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
    final ratesAsync = ref.watch(ratesProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final isBuy = _tabController.index == 0;

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
      body: ratesAsync.when(
        loading: () => const Center(
            child: RocketLoader(size: 40, color: AppColors.primaryOrange)),
        error: (err, _) => Center(
            child: Text('Error rates: $err',
                style: const TextStyle(color: Colors.red))),
        data: (rates) {
          final currentRate = _getAdminRate(rates);
          final activeRate =
              isBuy ? currentRate?.buyRate : currentRate?.sellRate;
          final payReceiveText = isBuy ? 'You Pay:' : 'You Receive:';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Asset Selector
                Text('Select Asset', style: AppTextStyles.labelMedium(context)),
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

                // Rate Display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      Text(
                        '1 $_selectedAsset = ₦${activeRate?.toStringAsFixed(0)}',
                        style: AppTextStyles.titleMedium(context)
                            .copyWith(color: AppColors.primaryOrange),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Amount Input
                Text('Amount (USD)', style: AppTextStyles.labelMedium(context)),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                              '${_cryptoAmount.toStringAsFixed(6)} $_selectedAsset',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      // NGN Required (The big number)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(payReceiveText,
                              style: AppTextStyles.bodyLarge(context)),
                          Text(
                            '₦${_calculateFiatAmount(currentRate, isBuy).toStringAsFixed(2)}',
                            style: AppTextStyles.titleLarge(context)
                                .copyWith(color: AppColors.primaryOrange),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Dynamic Section: Bank Details (Buy) OR Wallet (Buy)
                if (isBuy) ...[
                  // Show User where to pay
                  Text('Make Payment To:',
                      style: AppTextStyles.labelMedium(context)),
                  const SizedBox(height: 10),
                  settingsAsync.when(
                    data: (settings) => Container(
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
                          Text(
                              settings.bankDetails['bank_name'] ??
                                  'Bank Name Not Set',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          SelectableText(
                              settings.bankDetails['account_number'] ??
                                  '0000000000',
                              style: const TextStyle(
                                  color: AppColors.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(
                              settings.bankDetails['account_name'] ??
                                  'Account Name',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const Text('Error loading bank details',
                        style: TextStyle(color: Colors.red)),
                  ),

                  const SizedBox(height: 24),

                  // User Wallet Input
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

                  // Proof of Payment
                  Text('Proof of Payment',
                      style: AppTextStyles.labelMedium(context)),
                  const SizedBox(height: 8),
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
                                Text('Tap to upload screenshot',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
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
                    error: (_, __) => const Text('Error loading wallet',
                        style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 24),

                  // User Bank Details Input
                  Text('Receive Cash At:',
                      style: AppTextStyles.labelMedium(context)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        hintText: 'Bank Name:\nAccount Number:\nAccount Name:',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: AppColors.backgroundCard,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none)),
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
                    onPressed: (_isLoading || !_isValidOrder)
                        ? null
                        : () => _submitTransaction(currentRate),
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
    );
  }
}
