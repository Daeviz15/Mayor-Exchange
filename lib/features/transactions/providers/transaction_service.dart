import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_providers.dart';
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

final userTransactionsProvider =
    AsyncNotifierProvider<UserTransactionsNotifier, List<TransactionModel>>(() {
  return UserTransactionsNotifier();
});

class UserTransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
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
      debugPrint('Error loading cached transactions: $e');
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
      debugPrint('Error initiating fetch: $e');
    }

    // Subscribe to stream
    _subscription = ref
        .read(transactionRepositoryProvider)
        .watchUserTransactions(userId)
        .listen((data) async {
      state = AsyncData(data);
      _cacheTransactions(data);
    }, onError: (error) {
      debugPrint('Error in transaction stream: $error');
    });
  }

  Future<void> _fetchFreshData(String userId, bool showLoading) async {
    if (showLoading) {
      state = const AsyncLoading();
    }

    try {
      final transactions = await ref
          .read(transactionRepositoryProvider)
          .watchUserTransactions(userId)
          .first;

      state = AsyncData(transactions);
      _cacheTransactions(transactions);
    } catch (e, stack) {
      debugPrint('Error fetching fresh transactions: $e');
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
      debugPrint('Error caching transactions: $e');
    }
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

final adminTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  // TODO: Verify admin role here or in repository policy?
  // RLS protects the data, but we can also return empty if not admin logic in UI.
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

    debugPrint('Submitting transaction...');
    // Create Transaction
    TransactionModel created;
    try {
      created = await _repository
          .createTransaction(transaction)
          .timeout(const Duration(seconds: 15));
      debugPrint('Transaction created: ${created.id}');
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      rethrow;
    }

    // Log creation (Fire and forget or minimal wait to prevent blocking UI if logs fail)
    try {
      await _repository
          .createLog(
            transactionId: created.id,
            actorId: _currentUser!.id,
            newStatus: TransactionStatus.pending,
            note: 'Request submitted',
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Warning: Failed to create log: $e');
      // Don't fail the transaction just because log failed
    }

    return created;
  }

// ... (keep class definition)

  /// Admin Claims a Request
  Future<void> claimRequest(String transactionId, String targetUserId) async {
    if (_currentUser == null) throw Exception('User not logged in');

    await _repository.claimTransaction(transactionId, _currentUser!.id);

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

  /// Update Payment Status (Admin confirms payment sent/received)
  Future<void> markPaymentSent(String transactionId,
      {String? proofPath, String? note}) async {
    if (_currentUser == null) throw Exception('User not logged in');
    // Logic: Move to 'payment_pending' or 'verification_pending' depends on flow.
  }

  /// Admin Accepts Request & Provides Bank Details (Buy Flow)
  Future<void> adminAcceptRequest({
    required String transactionId,
    required String targetUserId,
    required Map<String, dynamic> bankDetails,
    required TransactionStatus currentStatus,
  }) async {
    if (_currentUser == null) throw Exception('User not logged in');

    // Fetch current details to merge
    final tx = await _supabaseClient
        .from('transactions')
        .select('details')
        .eq('id', transactionId)
        .single();
    final currentDetails = Map<String, dynamic>.from(tx['details']);
    final newDetails = {...currentDetails, 'admin_bank_details': bankDetails};

    // Update Transaction
    await _supabaseClient.from('transactions').update({
      'status': TransactionStatus.paymentPending.value,
      'details': newDetails,
      'admin_id': _currentUser!.id,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', transactionId);

    // Create Log
    await _repository.createLog(
      transactionId: transactionId,
      actorId: _currentUser!.id,
      newStatus: TransactionStatus.paymentPending,
      previousStatus: currentStatus,
      note: 'Admin accepted request and provided account details',
    );

    // Notify User
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

    // Update Transaction
    await _repository.updateStatus(
      transactionId: transactionId,
      newStatus: TransactionStatus.verificationPending,
      proofPath: proofPath,
    );

    // Create Log
    await _repository.createLog(
      transactionId: transactionId,
      actorId: _currentUser!.id,
      newStatus: TransactionStatus.verificationPending,
      previousStatus: TransactionStatus.paymentPending,
      note: 'User submitted proof of payment',
    );

    // Note: In a real app we'd notify the specific admin or all admins here
  }

  // Generic status update
  Future<void> updateStatus({
    required String transactionId,
    required String targetUserId, // Added for notification
    required TransactionStatus newStatus,
    required TransactionStatus previousStatus,
    String? note,
    String? proofPath,
    String? notificationMessage, // Custom override
    Map<String, dynamic>? details,
    double? finalPayoutAmount,
  }) async {
    if (_currentUser == null) throw Exception('User not logged in');

    // If we are updating the amountFiat, we should snapshot the original for records
    Map<String, dynamic>? effectiveDetails = details;
    if (finalPayoutAmount != null) {
      // We don't have current transaction here easily without fetching.
      // But we can assume if finalPayoutAmount is provided, we should save "original_amount_estimated" presumably?
      // Actually, fetching is safer.
      final tx = await _supabaseClient
          .from('transactions')
          .select('amount_fiat, details')
          .eq('id', transactionId)
          .maybeSingle(); // Use maybeSingle to be safe

      if (tx != null) {
        final currentAmount = (tx['amount_fiat'] as num).toDouble();
        final currentDetails = Map<String, dynamic>.from(tx['details'] ?? {});

        // Only snapshot if not already done
        if (!currentDetails.containsKey('original_amount_fiat')) {
          currentDetails['original_amount_fiat'] = currentAmount;
        }

        // Merge with incoming details
        effectiveDetails = {...currentDetails, ...(details ?? {})};
      }
    }

    await _repository.updateStatus(
      transactionId: transactionId,
      newStatus: newStatus,
      proofPath: proofPath,
      details: effectiveDetails ?? details, // Use merged details
      amountFiat: finalPayoutAmount,
    );

    await _repository.createLog(
      transactionId: transactionId,
      actorId: _currentUser!.id,
      newStatus: newStatus,
      previousStatus: previousStatus,
      note: note,
    );

    // Notify User
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
      // Fail silently regarding notifications so transaction doesn't fail
      debugPrint('Error creating notification: $e');
    }
  }
}
