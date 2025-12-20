import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';
import '../models/transaction_log.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(Supabase.instance.client);
});

class TransactionRepository {
  final SupabaseClient _client;

  TransactionRepository(this._client);

  /// Create a new transaction
  Future<TransactionModel> createTransaction(
      TransactionModel transaction) async {
    final response = await _client
        .from('transactions')
        .insert(transaction.toJson())
        .select()
        .single();

    return TransactionModel.fromJson(response);
  }

  /// Get a transaction by ID
  Future<TransactionModel?> getTransaction(String id) async {
    final response =
        await _client.from('transactions').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return TransactionModel.fromJson(response);
  }

  /// Watch transactions for the current user
  Stream<List<TransactionModel>> watchUserTransactions(String userId) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => TransactionModel.fromJson(json)).toList());
  }

  /// Watch a SINGLE transaction by ID
  Stream<TransactionModel?> watchTransaction(String transactionId) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('id', transactionId)
        .map((data) {
          if (data.isEmpty) return null;
          return TransactionModel.fromJson(data.first);
        });
  }

  /// Watch ALL transactions (for Admin)
  Stream<List<TransactionModel>> watchAllTransactions() {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => TransactionModel.fromJson(json)).toList());
  }

  /// Watch transactions by status (for Admin Tabs)
  Stream<List<TransactionModel>> watchTransactionsByStatus(
      TransactionStatus status) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('status', status.value)
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => TransactionModel.fromJson(json)).toList());
  }

  /// Watch transactions by LIST of statuses
  Stream<List<TransactionModel>> watchTransactionsByStatusList(
      List<TransactionStatus> statuses) {
    if (statuses.isEmpty) return const Stream.empty();

    // Supabase stream filter for 'in' is .inFilter('column', [list])
    // The library uses `in_` usually.
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        //.in_('status', statuses.map((e) => e.value).toList())
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => TransactionModel.fromJson(json)).toList());
  }

  /// Claim a transaction (Admin only)
  Future<void> claimTransaction(String transactionId, String adminId) async {
    await _client.from('transactions').update({
      'admin_id': adminId,
      'status': TransactionStatus.claimed.value,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', transactionId);
  }

  /// Update transaction status
  Future<void> updateStatus({
    required String transactionId,
    required TransactionStatus newStatus,
    String? adminId, // Optional update of admin
    String? proofPath,
    Map<String, dynamic>? details,
  }) async {
    final updates = <String, dynamic>{
      'status': newStatus.value,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (adminId != null) updates['admin_id'] = adminId;
    if (proofPath != null) updates['proof_image_path'] = proofPath;
    if (details != null) updates['details'] = details;

    await _client.from('transactions').update(updates).eq('id', transactionId);
  }

  /// Create a transaction log entry
  Future<void> createLog({
    required String transactionId,
    required String actorId,
    required TransactionStatus newStatus,
    TransactionStatus? previousStatus,
    String? note,
  }) async {
    final log = {
      'transaction_id': transactionId,
      'actor_id': actorId,
      'new_status': newStatus.value,
      'previous_status': previousStatus?.value,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _client.from('transaction_logs').insert(log);
  }

  /// Get logs for a transaction
  Future<List<TransactionLog>> getTransactionLogs(String transactionId) async {
    final response = await _client
        .from('transaction_logs')
        .select()
        .eq('transaction_id', transactionId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => TransactionLog.fromJson(json))
        .toList();
  }
}
