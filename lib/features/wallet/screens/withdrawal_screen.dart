import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/currency_text.dart';
import '../providers/wallet_provider.dart';
import '../../dasboard/providers/balance_provider.dart';
import '../../transactions/services/forex_service.dart';
import '../../transactions/providers/rates_provider.dart';

/// Withdrawal method enum
enum WithdrawalMethod { bank, usdt }

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();

  // Bank fields
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  // USDT fields
  final _usdtAmountController = TextEditingController();
  final _walletAddressController = TextEditingController();
  String _selectedNetwork = 'TRC20';

  // Supported USDT networks
  final List<String> _networks = [
    'TRC20',
    'ERC20',
    'BEP20',
    'SOL',
    'POLYGON',
    'ARBITRUM',
    'OPTIMISM',
    'AVAX',
    'TON',
  ];

  bool _isLoading = false;
  WithdrawalMethod _selectedMethod = WithdrawalMethod.bank;

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _usdtAmountController.dispose();
    _walletAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanceState = ref.watch(balanceProvider);
    const currency = 'NGN';
    final forexService = ref.watch(forexServiceProvider);
    final usdtRate = ref.watch(rateForAssetProvider('USDT'));

    final convertedBalance =
        forexService.convert(balanceState.totalBalance, currency);
    final symbol = _getSymbol(currency);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title:
            Text('Withdraw Funds', style: AppTextStyles.titleMedium(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Display
              _buildBalanceCard(symbol, convertedBalance),

              const SizedBox(height: 24),

              // Method Toggle
              _buildMethodToggle(),

              const SizedBox(height: 24),

              // Form based on selected method
              if (_selectedMethod == WithdrawalMethod.bank)
                _buildBankForm(symbol, currency, convertedBalance, forexService)
              else
                _buildUsdtForm(convertedBalance, usdtRate, forexService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String symbol, double convertedBalance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Balance',
                  style: AppTextStyles.bodySmall(context)),
              const SizedBox(height: 8),
              CurrencyText(
                symbol: symbol,
                amount: convertedBalance.toStringAsFixed(2),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryOrange,
              ),
            ],
          ),
          const Icon(Icons.account_balance_wallet,
              color: AppColors.textSecondary, size: 32),
        ],
      ),
    );
  }

  Widget _buildMethodToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedMethod = WithdrawalMethod.bank),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedMethod == WithdrawalMethod.bank
                      ? AppColors.primaryOrange
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: _selectedMethod == WithdrawalMethod.bank
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bank Transfer',
                      style: TextStyle(
                        color: _selectedMethod == WithdrawalMethod.bank
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
                  setState(() => _selectedMethod = WithdrawalMethod.usdt),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedMethod == WithdrawalMethod.usdt
                      ? AppColors.primaryOrange
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.currency_bitcoin,
                      color: _selectedMethod == WithdrawalMethod.usdt
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'USDT Wallet',
                      style: TextStyle(
                        color: _selectedMethod == WithdrawalMethod.usdt
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankForm(String symbol, String currency, double convertedBalance,
      ForexService forexService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bank Details', style: AppTextStyles.titleMedium(context)),
        const SizedBox(height: 16),

        // Bank Name
        TextFormField(
          controller: _bankNameController,
          style: AppTextStyles.bodyMedium(context),
          decoration: _inputDecoration('Bank Name'),
          validator: (v) =>
              v?.isEmpty == true ? 'Please enter bank name' : null,
        ),
        const SizedBox(height: 16),

        // Account Number
        TextFormField(
          controller: _accountNumberController,
          style: AppTextStyles.bodyMedium(context),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration('Account Number'),
          validator: (v) =>
              v?.isEmpty == true ? 'Please enter account number' : null,
        ),
        const SizedBox(height: 16),

        // Account Name
        TextFormField(
          controller: _accountNameController,
          style: AppTextStyles.bodyMedium(context),
          decoration: _inputDecoration('Account Name'),
          validator: (v) =>
              v?.isEmpty == true ? 'Please enter account name' : null,
        ),

        const SizedBox(height: 32),

        Text('Withdrawal Amount', style: AppTextStyles.titleMedium(context)),
        const SizedBox(height: 16),

        // Amount
        TextFormField(
          controller: _amountController,
          style: AppTextStyles.bodyMedium(context),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDecoration('Amount ($currency)').copyWith(
            prefixText: '$symbol ',
            prefixStyle: AppTextStyles.bodyMedium(context).copyWith(
              fontFamily: 'Roboto', // Roboto has naira symbol
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter amount';
            final val = double.tryParse(v);
            if (val == null || val <= 0) return 'Invalid amount';
            if (val > convertedBalance) {
              return 'Insufficient balance';
            }
            return null;
          },
        ),

        const SizedBox(height: 48),

        CustomButton(
          text: 'Process Withdrawal',
          isLoading: _isLoading,
          onPressed: () =>
              _submitBankWithdrawal(convertedBalance, currency, forexService),
        ),
      ],
    );
  }

  Widget _buildUsdtForm(double convertedBalanceNgn, CryptoRate? usdtRate,
      ForexService forexService) {
    final sellRate = usdtRate?.sellRate ?? 0;
    final maxUsdt = sellRate > 0 ? convertedBalanceNgn / sellRate : 0.0;

    // Calculate live NGN equivalent
    final usdtAmount = double.tryParse(_usdtAmountController.text) ?? 0;
    final ngnEquivalent = usdtAmount * sellRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Display
        if (sellRate > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: AppColors.primaryOrange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current USDT Rate',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      CurrencyText(
                        symbol: '₦',
                        amount: '${sellRate.toStringAsFixed(2)} per USDT',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryOrange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        if (sellRate == 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'USDT rate not set. Please contact support.',
                    style: TextStyle(color: Colors.red[300]),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        Text('Network', style: AppTextStyles.titleMedium(context)),
        const SizedBox(height: 12),

        // Network Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedNetwork,
              isExpanded: true,
              dropdownColor: AppColors.backgroundCard,
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppColors.textSecondary),
              items: _networks.map((network) {
                return DropdownMenuItem(
                  value: network,
                  child: Text(network),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedNetwork = value);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        Text('Wallet Address', style: AppTextStyles.titleMedium(context)),
        const SizedBox(height: 12),

        TextFormField(
          controller: _walletAddressController,
          style: AppTextStyles.bodyMedium(context),
          decoration: _inputDecoration('Enter your USDT wallet address'),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter wallet address';
            if (v.length < 20) return 'Invalid wallet address';
            return null;
          },
        ),

        const SizedBox(height: 24),

        Text('Amount (USDT)', style: AppTextStyles.titleMedium(context)),
        const SizedBox(height: 12),

        TextFormField(
          controller: _usdtAmountController,
          style: AppTextStyles.bodyMedium(context),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDecoration('Minimum: \$1').copyWith(
            prefixText: '\$ ',
            prefixStyle: AppTextStyles.bodyMedium(context),
            suffixText:
                maxUsdt > 0 ? 'Max: ${maxUsdt.toStringAsFixed(2)}' : null,
            suffixStyle:
                TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          onChanged: (_) => setState(() {}), // Trigger rebuild for live calc
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter amount';
            final val = double.tryParse(v);
            if (val == null || val < 1) return 'Minimum \$1';
            if (val > maxUsdt) return 'Insufficient balance';
            return null;
          },
        ),

        // Error message when exceeding balance
        if (usdtAmount > maxUsdt && maxUsdt > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Amount exceeds available balance. Maximum: \$${maxUsdt.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.red[300], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Live NGN calculation
        if (usdtAmount > 0 && usdtAmount <= maxUsdt && sellRate > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('You will receive:',
                    style: TextStyle(color: AppColors.textSecondary)),
                CurrencyText(
                  symbol: '\$',
                  amount: usdtAmount.toStringAsFixed(2),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Deducted from balance: ',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
              CurrencyText(
                symbol: '\u20A6',
                amount: ngnEquivalent.toStringAsFixed(2),
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ],

        const SizedBox(height: 32),

        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Make sure to double-check your wallet address and network. Sending to wrong address/network may result in permanent loss of funds.',
                  style: TextStyle(color: Colors.blue[200], fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        CustomButton(
          text: 'Withdraw USDT',
          isLoading: _isLoading,
          onPressed: (sellRate > 0 &&
                  usdtAmount >= 1 &&
                  usdtAmount <= maxUsdt &&
                  _walletAddressController.text.length >= 20)
              ? () => _submitUsdtWithdrawal(convertedBalanceNgn, sellRate)
              : null,
        ),
      ],
    );
  }

  void _submitBankWithdrawal(
      double convertedBalance, String currency, ForexService forex) {
    if (!_formKey.currentState!.validate()) return;

    final amountEntered = double.tryParse(_amountController.text) ?? 0;

    if (amountEntered > convertedBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _showBankConfirmationDialog(
        amountEntered, convertedBalance, currency, forex);
  }

  void _submitUsdtWithdrawal(double convertedBalanceNgn, double sellRate) {
    if (!_formKey.currentState!.validate()) return;

    final amountUsdt = double.tryParse(_usdtAmountController.text) ?? 0;
    final amountNgn = amountUsdt * sellRate;

    if (amountNgn > convertedBalanceNgn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _showUsdtConfirmationDialog(amountUsdt, amountNgn, sellRate);
  }

  Future<void> _processBankWithdrawal(double amountEntered,
      double convertedBalance, String currency, ForexService forex) async {
    setState(() => _isLoading = true);

    try {
      final amountInNgn = forex.convertToNgn(amountEntered, currency);

      await ref.read(walletProvider.notifier).requestWithdrawal(
            amount: amountInNgn,
            bankName: _bankNameController.text,
            accountNumber: _accountNumberController.text,
            accountName: _accountNameController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Withdrawal request submitted. Balance will be updated upon approval.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processUsdtWithdrawal(
      double amountUsdt, double amountNgn) async {
    setState(() => _isLoading = true);

    try {
      await ref.read(walletProvider.notifier).requestUsdtWithdrawal(
            amountUsdt: amountUsdt,
            amountNgn: amountNgn,
            walletAddress: _walletAddressController.text,
            network: _selectedNetwork,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'USDT withdrawal request submitted. You will receive your USDT shortly.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.backgroundElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryOrange),
      ),
    );
  }

  String _getSymbol(String currency) {
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

  void _showBankConfirmationDialog(double amountEntered,
      double convertedBalance, String currency, ForexService forex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Confirm Withdrawal',
              style: AppTextStyles.titleMedium(context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrencyDetailRow(
                  'Amount', '\u20A6', amountEntered.toStringAsFixed(2)),
              const SizedBox(height: 8),
              _buildDetailRow('Bank Name', _bankNameController.text),
              const SizedBox(height: 8),
              _buildDetailRow('Account Number', _accountNumberController.text),
              const SizedBox(height: 8),
              _buildDetailRow('Account Name', _accountNameController.text),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processBankWithdrawal(
                    amountEntered, convertedBalance, currency, forex);
              },
              child: const Text('Confirm',
                  style: TextStyle(color: AppColors.primaryOrange)),
            ),
          ],
        );
      },
    );
  }

  void _showUsdtConfirmationDialog(
      double amountUsdt, double amountNgn, double rate) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Confirm USDT Withdrawal',
              style: AppTextStyles.titleMedium(context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  'Amount', '\$${amountUsdt.toStringAsFixed(2)} USDT'),
              const SizedBox(height: 8),
              _buildDetailRow('Network', _selectedNetwork),
              const SizedBox(height: 8),
              _buildDetailRow(
                  'Wallet',
                  _walletAddressController.text.length > 20
                      ? '${_walletAddressController.text.substring(0, 10)}...${_walletAddressController.text.substring(_walletAddressController.text.length - 10)}'
                      : _walletAddressController.text),
              const SizedBox(height: 8),
              _buildCurrencyDetailRow(
                  'Rate', '\u20A6', '${rate.toStringAsFixed(2)}/USDT'),
              const SizedBox(height: 8),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 8),
              _buildCurrencyDetailRow(
                  'Deducted', '\u20A6', amountNgn.toStringAsFixed(2),
                  highlight: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processUsdtWithdrawal(amountUsdt, amountNgn);
              },
              child: const Text('Confirm',
                  style: TextStyle(color: AppColors.primaryOrange)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: highlight ? AppColors.primaryOrange : Colors.white,
              fontSize: highlight ? 16 : 14,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build detail row with currency symbol using CurrencyText widget
  Widget _buildCurrencyDetailRow(String label, String symbol, String amount,
      {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        CurrencyText(
          symbol: symbol,
          amount: amount,
          fontSize: highlight ? 16 : 14,
          fontWeight: FontWeight.bold,
          color: highlight ? AppColors.primaryOrange : Colors.white,
        ),
      ],
    );
  }
}
