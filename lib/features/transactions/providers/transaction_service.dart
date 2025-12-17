import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final userId = ref.watch(authControllerProvider).asData?.value?.id;
  final supabaseClient = ref.watch(supabaseClientProvider);
  return TransactionService(repository, userId, supabaseClient);
});

final userTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final userId = ref.watch(authControllerProvider).asData?.value?.id;
  if (userId == null) return const Stream.empty();
  return ref.watch(transactionRepositoryProvider).watchUserTransactions(userId);
});

final allTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  // TODO: Verify admin role here or in repository policy?
  // RLS protects the data, but we can also return empty if not admin logic in UI.
  return ref.watch(transactionRepositoryProvider).watchAllTransactions();
});

class TransactionService {
  final TransactionRepository _repository;
  final String? _currentUserId;
  final SupabaseClient _supabaseClient;

  TransactionService(
      this._repository, this._currentUserId, this._supabaseClient);

  /// Submit a new Buy/Sell request
  Future<void> submitTransaction({
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

  // Generic status update
  Future<void> updateStatus({
    required String transactionId,
    required String targetUserId, // Added for notification
    required TransactionStatus newStatus,
    required TransactionStatus previousStatus,
    String? note,
    String? proofPath,
  }) async {
    if (_currentUserId == null) throw Exception('User not logged in');

    await _repository.updateStatus(
      transactionId: transactionId,
      newStatus: newStatus,
      proofPath: proofPath,
    );

    await _repository.createLog(
      transactionId: transactionId,
      actorId: _currentUserId!,
      newStatus: newStatus,
      previousStatus: previousStatus,
      note: note,
    );

    // Notify User
    String message =
        'Your transaction status has been updated to ${newStatus.name.replaceAll('_', ' ')}.';
    if (newStatus == TransactionStatus.paymentPending) {
      message = 'Payment has been sent. Please verify.';
    } else if (newStatus == TransactionStatus.completed) {
      message = 'Transaction completed! Thank you for trading.';
    } else if (newStatus == TransactionStatus.rejected) {
      message = 'Transaction rejected. ${note ?? ""}';
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
      print('Error creating notification: $e');
    }
  }
}
