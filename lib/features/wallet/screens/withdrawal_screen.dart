import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/wallet_provider.dart';
import '../../dasboard/providers/balance_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../../transactions/services/forex_service.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _submitWithdrawal(
      double convertedBalance, String currency, ForexService forex) async {
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

    setState(() => _isLoading = true);

    try {
      // Convert Foreign Currency back to NGN for the backend wallet logic
      final amountInNgn = forex.convertToNgn(amountEntered, currency);

      // Implement withdrawal logic via provider
      await ref.read(walletProvider.notifier).requestWithdrawal(
            amount: amountInNgn,
            bankName: _bankNameController.text,
            accountNumber: _accountNumberController.text,
            accountName: _accountNameController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal request submitted successfully'),
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

  @override
  Widget build(BuildContext context) {
    final balanceState = ref.watch(balanceProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.asData?.value;
    final currency = user?.currency ?? 'NGN';
    final forexService = ref.watch(forexServiceProvider);

    // Convert Total Balance (NGN) to User Currency
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                        Text(
                          '$symbol${convertedBalance.toStringAsFixed(2)}',
                          style: AppTextStyles.headlineMedium(context).copyWith(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.account_balance_wallet,
                        color: AppColors.textSecondary, size: 32),
                  ],
                ),
              ),

              const SizedBox(height: 32),

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

              Text('Withdrawal Amount',
                  style: AppTextStyles.titleMedium(context)),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                style: AppTextStyles.bodyMedium(context),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration('Amount ($currency)').copyWith(
                  prefixText: '$symbol ',
                  prefixStyle: AppTextStyles.bodyMedium(context),
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
                    _submitWithdrawal(convertedBalance, currency, forexService),
              ),
            ],
          ),
        ),
      ),
    );
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
}
