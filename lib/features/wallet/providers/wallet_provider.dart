import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transaction_service.dart';

final walletProvider =
    StateNotifierProvider<WalletNotifier, AsyncValue<void>>((ref) {
  return WalletNotifier(ref);
});

class WalletNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  WalletNotifier(this.ref) : super(const AsyncData(null));

  Future<void> requestWithdrawal({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    state = const AsyncLoading();

    try {
      final transactionService = ref.read(transactionServiceProvider);

      final details = {
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_name': accountName,
        'currency': 'USD', // Base currency for now
      };

      await transactionService.submitTransaction(
        type: TransactionType.withdrawal,
        amountFiat: amount,
        currencyPair:
            'USD/NGN', // Assuming withdrawal to local bank from USD wallet
        details: details,
      );

      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  /// Request USDT withdrawal to external wallet
  Future<void> requestUsdtWithdrawal({
    required double amountUsdt,
    required double amountNgn, // Calculated from USDT rate
    required String walletAddress,
    required String network, // e.g., 'TRC20', 'ERC20', 'BEP20'
  }) async {
    state = const AsyncLoading();

    try {
      final transactionService = ref.read(transactionServiceProvider);

      final details = {
        'withdrawal_method': 'usdt',
        'wallet_address': walletAddress,
        'network': network,
        'amount_usdt': amountUsdt,
      };

      await transactionService.submitTransaction(
        type: TransactionType.withdrawal,
        amountFiat: amountNgn, // NGN equivalent for balance deduction
        amountCrypto: amountUsdt,
        currencyPair: 'USDT/NGN',
        details: details,
      );

      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}
