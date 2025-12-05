import 'package:flutter_riverpod/legacy.dart';

/// User Balance State
class BalanceState {
  final double totalBalance;
  final double changePercent24h;

  const BalanceState({
    this.totalBalance = 12450.78,
    this.changePercent24h = 2.5,
  });

  BalanceState copyWith({double? totalBalance, double? changePercent24h}) {
    return BalanceState(
      totalBalance: totalBalance ?? this.totalBalance,
      changePercent24h: changePercent24h ?? this.changePercent24h,
    );
  }
}

/// Balance Provider
final balanceProvider = StateNotifierProvider<BalanceNotifier, BalanceState>((
  ref,
) {
  return BalanceNotifier();
});

class BalanceNotifier extends StateNotifier<BalanceState> {
  BalanceNotifier() : super(const BalanceState());

  void updateBalance(double newBalance) {
    state = state.copyWith(totalBalance: newBalance);
  }

  void updateChangePercent(double newPercent) {
    state = state.copyWith(changePercent24h: newPercent);
  }
}
