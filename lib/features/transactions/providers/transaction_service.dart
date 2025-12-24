import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final userId = ref.watch(authControllerProvider).asData?.value?.id;
  final supabaseClient = ref.watch(supabaseClientProvider);
  return TransactionService(repository, userId, supabaseClient);
});

final userTransactionsProvider =
    AsyncNotifierProvider<UserTransactionsNotifier, List<TransactionModel>>(() {
  return UserTransactionsNotifier();
});

class UserTransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  List<TransactionModel> build() {
    final userId = ref.watch(authControllerProvider).asData?.value?.id;
    if (userId == null) return [];

    // 1. Load from cache synchronously
    final cached = _loadFromCacheSync();

    // 2. Fetch fresh data background
    Future.microtask(() {
      _subscribeToRealtime(userId);
      _fetchFreshData(userId);
    });

    return cached;
  }

  List<TransactionModel> _loadFromCacheSync() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final jsonString = prefs.getString('cached_transactions');

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading cached transactions: $e');
    }
    return [];
  }

  Future<void> _fetchFreshData(String userId) async {
    // Only set loading if we have no cache?
    // Or just let it update silently.
    // For transactions, silent update is usually better if we have cache.
    // If empty cache, maybe loading?
    if (state.asData?.value.isEmpty ?? true) {
      state = const AsyncLoading();
    }

    try {
      // Get the stream and take the first value as "fresh" data
      final transactions = await ref
          .read(transactionRepositoryProvider)
          .watchUserTransactions(userId)
          .first;

      // Cache it
      final prefs = ref.read(sharedPreferencesProvider);
      final jsonString =
          jsonEncode(transactions.map((e) => e.toJson()).toList());
      await prefs.setString('cached_transactions', jsonString);

      state = AsyncData(transactions);
    } catch (e, stack) {
      debugPrint('Error fetching fresh transactions: $e');
      if (state.asData?.value.isEmpty ?? true) {
        state = AsyncError(e, stack);
      }
    }
  }

  void _subscribeToRealtime(String userId) {
    ref
        .read(transactionRepositoryProvider)
        .watchUserTransactions(userId)
        .listen((data) {
      state = AsyncData(data);
      // Update cache on stream update
      final prefs = ref.read(sharedPreferencesProvider);
      final jsonString = jsonEncode(data.map((e) => e.toJson()).toList());
      prefs.setString('cached_transactions', jsonString);
    }, onError: (error) {
      debugPrint('Error in transaction stream: $error');
      // Optionally handle specific errors or retry logic here
    });
  }
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
  final String? _currentUserId;
  final SupabaseClient _supabaseClient;

  TransactionService(
      this._repository, this._currentUserId, this._supabaseClient);

  /// Submit a new Buy/Sell request
  Future<TransactionModel> submitTransaction({
    required TransactionType type,
    required double amountFiat,
    required String currencyPair,
    required Map<String, dynamic> details,
    double? amountCrypto,
    String? proofImagePath,
  }) async {
    if (_currentUserId == null) throw Exception('User not logged in');

    final transaction = TransactionModel(
      id: '', // DB handles this
      userId: _currentUserId!,
      type: type,
      status: TransactionStatus.pending, // Default
      amountFiat: amountFiat,
      amountCrypto: amountCrypto,
      currencyPair: currencyPair,
      details: details,
      proofImagePath: proofImagePath,
      createdAt: DateTime.now(), // DB will override
      updatedAt: DateTime.now(), // DB will override
    );

    // Create Transaction
    final created = await _repository.createTransaction(transaction);

    // Log creation
    await _repository.createLog(
      transactionId: created.id,
      actorId: _currentUserId!,
      newStatus: TransactionStatus.pending,
      note: 'Request submitted',
    );
    // Notify admin? (Optional future enhancement)

    return created;
  }

  /// Admin Claims a Request
  Future<void> claimRequest(String transactionId, String targetUserId) async {
    if (_currentUserId == null) throw Exception('User not logged in');

    await _repository.claimTransaction(transactionId, _currentUserId!);

    await _repository.createLog(
      transactionId: transactionId,
      actorId: _currentUserId!,
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
    if (_currentUserId == null) throw Exception('User not logged in');
    // Logic: Move to 'payment_pending' or 'verification_pending' depends on flow.
  }

  /// Admin Accepts Request & Provides Bank Details (Buy Flow)
  Future<void> adminAcceptRequest({
    required String transactionId,
    required String targetUserId,
    required Map<String, dynamic> bankDetails,
    required TransactionStatus currentStatus,
  }) async {
    if (_currentUserId == null) throw Exception('User not logged in');

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
      'admin_id': _currentUserId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', transactionId);

    // Create Log
    await _repository.createLog(
      transactionId: transactionId,
      actorId: _currentUserId!,
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
    if (_currentUserId == null) throw Exception('User not logged in');

    // Update Transaction
    await _repository.updateStatus(
      transactionId: transactionId,
      newStatus: TransactionStatus.verificationPending,
      proofPath: proofPath,
    );

    // Create Log
    await _repository.createLog(
      transactionId: transactionId,
      actorId: _currentUserId!,
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
  }) async {
    if (_currentUserId == null) throw Exception('User not logged in');

    await _repository.updateStatus(
      transactionId: transactionId,
      newStatus: newStatus,
      proofPath: proofPath,
      details: details,
    );

    await _repository.createLog(
      transactionId: transactionId,
      actorId: _currentUserId!,
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
