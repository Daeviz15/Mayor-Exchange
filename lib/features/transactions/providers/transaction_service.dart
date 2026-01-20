import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_providers.dart';
import '../../admin/providers/admin_history_provider.dart'; // Import PaginatedState
import '../../auth/models/app_user.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final user = ref.watch(authControllerProvider).asData?.value;
  final supabaseClient = ref.watch(supabaseClientProvider);
  return TransactionService(repository, user, supabaseClient);
});

final recentUserTransactionsProvider = AsyncNotifierProvider<
    RecentUserTransactionsNotifier, List<TransactionModel>>(() {
  return RecentUserTransactionsNotifier();
});

// Added for backward compatibility if needed, or better to deprecate
final userTransactionsProvider = recentUserTransactionsProvider;

final userHistoryProvider =
    AsyncNotifierProvider<UserHistoryNotifier, PaginatedState>(
        UserHistoryNotifier.new);

class RecentUserTransactionsNotifier
    extends AsyncNotifier<List<TransactionModel>> {
  StreamSubscription<List<TransactionModel>>? _subscription;

  @override
  Future<List<TransactionModel>> build() async {
    final userId = ref.watch(authControllerProvider).asData?.value?.id;

    // Clean up previous subscription if build runs again (e.g. user change)
    _subscription?.cancel();
    ref.onDispose(() {
      _subscription?.cancel();
    });

    if (userId == null) return [];

    // 1. Load from cache (Offloaded to isolate if possible, or just async)
    List<TransactionModel> initialData = [];
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final jsonString = prefs.getString('cached_transactions');
      if (jsonString != null && jsonString.isNotEmpty) {
        // Offload decoding to prevent UI freeze
        initialData = await compute(_decodeTransactions, jsonString);
      }
    } catch (e) {
      // Debug removed
    }

    // 2. Setup Realtime Subscription & Fetch Fresh Data
    _setupRealtimeAndFetch(userId);

    return initialData;
  }

  Future<void> _setupRealtimeAndFetch(String userId) async {
    // Determine if we need to show loading (only if no cache)
    final bool hasCache = state.asData?.value.isNotEmpty ?? false;

    // Fetch fresh data immediately
    try {
      // We don't await this inside build, but we update state when done
      _fetchFreshData(userId, !hasCache);
    } catch (e) {
      // Debug removed
    }

    // Subscribe to stream
    _subscription = ref
        .read(transactionRepositoryProvider)
        .watchUserTransactions(userId, limit: 20) // Optimized: Limit to 20
        .listen((data) async {
      state = AsyncData(data);
      _cacheTransactions(data);
    }, onError: (error) {
      // Debug removed
    });
  }

  Future<void> _fetchFreshData(String userId, bool showLoading) async {
    if (showLoading) {
      state = const AsyncLoading();
    }

    try {
      final transactions = await ref
          .read(transactionRepositoryProvider)
          .watchUserTransactions(userId, limit: 20) // Optimized: Limit to 20
          .first;

      state = AsyncData(transactions);
      _cacheTransactions(transactions);
    } catch (e, stack) {
      // Debug removed
      if (!state.hasValue) {
        // Only show error if we have no data
        state = AsyncError(e, stack);
      }
    }
  }

  Future<void> _cacheTransactions(List<TransactionModel> transactions) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final jsonString = await compute(_encodeTransactions, transactions);
      await prefs.setString('cached_transactions', jsonString);
    } catch (e) {
      // Debug removed
    }
  }
}

// Paginated State for User History
class UserHistoryNotifier extends AsyncNotifier<PaginatedState> {
  static const int _pageSize = 20;

  @override
  Future<PaginatedState> build() async {
    return _fetchPage(0, const PaginatedState());
  }

  Future<PaginatedState> _fetchPage(
      int page, PaginatedState currentState) async {
    final userId = ref.read(authControllerProvider).asData?.value?.id;
    if (userId == null) return const PaginatedState();

    final service = ref.read(transactionServiceProvider);
    final newItems = await service.getTransactionsPaginated(
      page: page,
      pageSize: _pageSize,
      userId: userId,
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
        currentState.isFetchingNext) return;

    state = AsyncData(currentState.copyWith(isFetchingNext: true));

    try {
      final newState = await _fetchPage(currentState.page, currentState);
      state = AsyncData(newState);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchPage(0, const PaginatedState()));
  }
}

// Top-level function for isolate decoding
List<TransactionModel> _decodeTransactions(String jsonString) {
  final List<dynamic> jsonList = jsonDecode(jsonString);
  return jsonList
      .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

// Top-level function for isolate encoding
String _encodeTransactions(List<TransactionModel> transactions) {
  return jsonEncode(transactions.map((e) => e.toJson()).toList());
}

final adminTransactionsByStatusProvider =
    StreamProvider.family<List<TransactionModel>, List<TransactionStatus>>(
        (ref, statuses) {
  return ref
      .watch(transactionRepositoryProvider)
      .watchTransactionsByStatusList(statuses);
});

final adminTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAllTransactions();
});

final singleTransactionProvider =
    StreamProvider.family<TransactionModel?, String>((ref, id) {
  return ref.watch(transactionRepositoryProvider).watchTransaction(id);
});

class TransactionService {
  final TransactionRepository _repository;
  final AppUser? _currentUser;
  final SupabaseClient _supabaseClient;

  TransactionService(this._repository, this._currentUser, this._supabaseClient);

  /// Submit a new Buy/Sell request
  Future<TransactionModel> submitTransaction({
    required TransactionType type,
    required double amountFiat,
    required String currencyPair,
    required Map<String, dynamic> details,
    double? amountCrypto,
    String? proofImagePath,
  }) async {
    if (_currentUser == null) throw Exception('User not logged in');

    // Snapshot user country/currency
    final enrichedDetails = Map<String, dynamic>.from(details);
    enrichedDetails['user_country'] = _currentUser!.country ?? 'Unknown';
    enrichedDetails['user_currency'] = _currentUser!.currency ?? 'NGN';
    enrichedDetails['user_full_name'] = _currentUser!.fullName ?? 'Unknown';

    final transaction = TransactionModel(
      id: '', // DB handles this
      userId: _currentUser!.id,
      type: type,
      status: TransactionStatus.pending, // Default
      amountFiat: amountFiat,
      amountCrypto: amountCrypto,
      currencyPair: currencyPair,
      details: enrichedDetails,
      proofImagePath: proofImagePath,
      createdAt: DateTime.now(), // DB will override
      updatedAt: DateTime.now(), // DB will override
    );

    // Create Transaction
    TransactionModel created = await _repository.createTransaction(transaction);

    // Log creation
    await _repository.createLog(
      transactionId: created.id,
      actorId: _currentUser!.id,
      newStatus: TransactionStatus.pending,
      note: 'Request submitted',
    );

    return created;
  }

  /// Admin Claims a Request
  Future<void> claimRequest(String transactionId, String targetUserId) async {
    if (_currentUser == null) throw Exception('User not logged in');

    await _repository.claimTransaction(transactionId, _currentUser!.id);

    final adminName = _currentUser!.fullName ?? 'Admin Agent';
    final tx = await _supabaseClient
        .from('transactions')
        .select('details')
        .eq('id', transactionId)
        .single();
    final currentDetails = Map<String, dynamic>.from(tx['details'] ?? {});
    currentDetails['admin_name'] = adminName;

    await _repository.updateStatus(
        transactionId: transactionId,
        newStatus: TransactionStatus.claimed,
        adminId: _currentUser!.id,
        details: currentDetails);

    await _repository.createLog(
      transactionId: transactionId,
      actorId: _currentUser!.id,
      newStatus: TransactionStatus.claimed,
      previousStatus: TransactionStatus.pending,
      note: 'Admin claimed the request',
    );

    // Notify User
    await _createNotification(
      userId: targetUserId,
      title: 'Transaction Update',
      message:
          'Your transaction has been claimed by an admin and is being processed.',
      type: 'transaction',
      relatedId: transactionId,
    );
  }

  /// Admin Accepts Request & Provides Bank Details (Buy Flow)
  Future<void> adminAcceptRequest({
    required String transactionId,
    required String targetUserId,
    required Map<String, dynamic> bankDetails,
    required TransactionStatus currentStatus,
  }) async {
    if (_currentUser == null) throw Exception('User not logged in');

    final tx = await _supabaseClient
        .from('transactions')
        .select('details')
        .eq('id', transactionId)
        .single();
    final currentDetails = Map<String, dynamic>.from(tx['details']);
    final newDetails = {...currentDetails, 'admin_bank_details': bankDetails};
    newDetails['admin_name'] = _currentUser!.fullName ?? 'Admin Agent';

    await _supabaseClient.from('transactions').update({
      'status': TransactionStatus.paymentPending.value,
      'details': newDetails,
      'admin_id': _currentUser!.id,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', transactionId);

    await _repository.createLog(
      transactionId: transactionId,
      actorId: _currentUser!.id,
      newStatus: TransactionStatus.paymentPending,
      previousStatus: currentStatus,
      note: 'Admin accepted request and provided account details',
    );

    await _createNotification(
      userId: targetUserId,
      title: 'Order Accepted',
      message:
          'Your order has been accepted! Please check the app to view payment details.',
      type: 'transaction',
      relatedId: transactionId,
    );
  }

  /// User Submits Proof of Payment (Buy Flow)
  Future<void> userSubmitProof({
    required String transactionId,
    required String proofPath,
  }) async {
    if (_currentUser == null) throw Exception('User not logged in');

    await _repository.updateStatus(
      transactionId: transactionId,
      newStatus: TransactionStatus.verificationPending,
      proofPath: proofPath,
    );

    await _repository.createLog(
      transactionId: transactionId,
      actorId: _currentUser!.id,
      newStatus: TransactionStatus.verificationPending,
      previousStatus: TransactionStatus.paymentPending,
      note: 'User submitted proof of payment',
    );
  }

  Future<void> updateStatus({
    required String transactionId,
    required String targetUserId,
    required TransactionStatus newStatus,
    required TransactionStatus previousStatus,
    String? note,
    String? proofPath,
    String? notificationMessage,
    Map<String, dynamic>? details,
    double? finalPayoutAmount,
  }) async {
    if (_currentUser == null) throw Exception('User not logged in');

    Map<String, dynamic>? effectiveDetails = details;
    if (finalPayoutAmount != null) {
      final tx = await _supabaseClient
          .from('transactions')
          .select('amount_fiat, details')
          .eq('id', transactionId)
          .maybeSingle();

      if (tx != null) {
        final currentAmount = (tx['amount_fiat'] as num).toDouble();
        final currentDetails = Map<String, dynamic>.from(tx['details'] ?? {});
        if (!currentDetails.containsKey('original_amount_fiat')) {
          currentDetails['original_amount_fiat'] = currentAmount;
        }
        effectiveDetails = {...currentDetails, ...(details ?? {})};
      }
    }

    if (newStatus != TransactionStatus.pending &&
        newStatus != TransactionStatus.verificationPending &&
        newStatus != TransactionStatus.cancelled) {
      if (effectiveDetails == null) {
        final tx = await _supabaseClient
            .from('transactions')
            .select('details')
            .eq('id', transactionId)
            .maybeSingle();
        effectiveDetails =
            tx != null ? Map<String, dynamic>.from(tx['details'] ?? {}) : {};
      }
      effectiveDetails['admin_name'] = _currentUser!.fullName ?? 'Admin Agent';
    }

    if (note != null && note.isNotEmpty) {
      if (effectiveDetails == null) {
        final tx = await _supabaseClient
            .from('transactions')
            .select('details')
            .eq('id', transactionId)
            .maybeSingle();
        effectiveDetails =
            tx != null ? Map<String, dynamic>.from(tx['details'] ?? {}) : {};
      }
      effectiveDetails['note'] = note;
    }

    await _repository.updateStatus(
      transactionId: transactionId,
      newStatus: newStatus,
      proofPath: proofPath,
      details: effectiveDetails ?? details,
      amountFiat: finalPayoutAmount,
    );

    await _repository.createLog(
      transactionId: transactionId,
      actorId: _currentUser!.id,
      newStatus: newStatus,
      previousStatus: previousStatus,
      note: note,
    );

    String message = notificationMessage ??
        'Your transaction status has been updated to ${newStatus.name.replaceAll('_', ' ')}.';

    if (notificationMessage == null) {
      if (newStatus == TransactionStatus.paymentPending) {
        message = 'Payment has been sent. Please verify.';
      } else if (newStatus == TransactionStatus.completed) {
        message = 'Transaction completed! Thank you for trading.';
      } else if (newStatus == TransactionStatus.rejected) {
        message = 'Transaction rejected. ${note ?? ""}';
      }
    }

    await _createNotification(
      userId: targetUserId,
      title: 'Transaction Update',
      message: message,
      type: 'transaction',
      relatedId: transactionId,
    );
  }

  Future<String?> getRejectionReason(String transactionId) async {
    try {
      final logs = await _repository.getTransactionLogs(transactionId);
      for (final log in logs) {
        if ((log.newStatus == TransactionStatus.rejected ||
                log.newStatus == TransactionStatus.cancelled) &&
            log.note != null &&
            log.note!.isNotEmpty) {
          return log.note;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get paginated transactions for history
  /// Get paginated transactions for history
  Future<List<TransactionModel>> getTransactionsPaginated({
    required int page,
    required int pageSize,
    TransactionStatus? status,
    String? userId,
  }) {
    return _repository.getTransactionsPaginated(
      page: page,
      pageSize: pageSize,
      status: status,
      userId: userId,
    );
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      await _supabaseClient.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'related_id': relatedId,
        'is_read': false,
      });
    } catch (e) {
      // Fail silently
    }
  }
}
