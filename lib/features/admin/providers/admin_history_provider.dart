import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transaction_service.dart';

// State class for pagination
class PaginatedState {
  final List<TransactionModel> transactions;
  final bool hasMore;
  final int page;
  final bool isFetchingNext;

  const PaginatedState({
    this.transactions = const [],
    this.hasMore = true,
    this.page = 0,
    this.isFetchingNext = false,
  });

  PaginatedState copyWith({
    List<TransactionModel>? transactions,
    bool? hasMore,
    int? page,
    bool? isFetchingNext,
  }) {
    return PaginatedState(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      isFetchingNext: isFetchingNext ?? this.isFetchingNext,
    );
  }
}

class AdminHistoryNotifier extends AsyncNotifier<PaginatedState> {
  static const int _pageSize = 20;

  @override
  Future<PaginatedState> build() async {
    return _fetchPage(0, const PaginatedState());
  }

  Future<PaginatedState> _fetchPage(
      int page, PaginatedState currentState) async {
    final service = ref.read(transactionServiceProvider);
    final newItems = await service.getTransactionsPaginated(
      page: page,
      pageSize: _pageSize,
    );

    return currentState.copyWith(
      transactions: [...currentState.transactions, ...newItems],
      page: page + 1,
      hasMore: newItems.length >= _pageSize,
      isFetchingNext: false,
    );
  }

  Future<void> loadNextPage() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isFetchingNext) {
      return;
    }

    // Set fetching flag to prevent duplicate calls and update UI if needed
    state = AsyncData(currentState.copyWith(isFetchingNext: true));

    state = await AsyncValue.guard(() async {
      return _fetchPage(currentState.page, currentState);
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _fetchPage(0, const PaginatedState());
    });
  }
}

final adminHistoryProvider =
    AsyncNotifierProvider<AdminHistoryNotifier, PaginatedState>(
        AdminHistoryNotifier.new);
