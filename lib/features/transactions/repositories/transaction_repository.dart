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
        .insert(transaction.toJson()
          ..removeWhere((key, value) => key == 'id' && value == ''))
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
  Stream<List<TransactionModel>> watchUserTransactions(String userId,
      {int? limit}) {
    var query = _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.map(
        (data) => data.map((json) => TransactionModel.fromJson(json)).toList());
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
  /// Uses a hybrid approach: fetch first, then subscribe to stream.
  /// LIMITED to recent 50 to prevent crash on large datasets.
  Stream<List<TransactionModel>> watchAllTransactions() async* {
    // 1. Immediately fetch current data (fast, reliable)
    try {
      final initialData = await _client
          .from('transactions')
          .select()
          .order('created_at', ascending: false)
          .limit(50); // Optimization: Limit to 50
      yield (initialData as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      // If initial fetch fails, yield empty and continue to stream
      yield <TransactionModel>[];
    }

    // 2. Then subscribe to realtime stream for updates
    // Note: Stream limits are tricky. We rely on the initial fetch for the bulk.
    // Realtime events will push new items.
    yield* _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50) // Optimization: Limit to 50
        .map((data) =>
            data.map((json) => TransactionModel.fromJson(json)).toList());
  }

  /// Fetch paginated transactions (for History tab infinite scroll)
  Future<List<TransactionModel>> getTransactionsPaginated({
    required int page,
    required int pageSize,
    TransactionStatus? status,
    String? userId, // Optional: Filter by user ID
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    // Start building query
    PostgrestFilterBuilder query = _client.from('transactions').select();

    // Apply filters
    if (status != null) {
      query = query.eq('status', status.value);
    }
    if (userId != null) {
      query = query.eq('user_id', userId);
    }

    // Apply sorting and pagination
    final response =
        await query.order('created_at', ascending: false).range(from, to);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  /// Watch transactions by status (for Admin Tabs)
  /// LIMITED to recent 50
  Stream<List<TransactionModel>> watchTransactionsByStatus(
      TransactionStatus status) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('status', status.value)
        .order('created_at', ascending: false)
        .limit(50) // Optimization: Limit to 50
        .map((data) =>
            data.map((json) => TransactionModel.fromJson(json)).toList());
  }

  /// Watch transactions by LIST of statuses
  /// Uses a hybrid approach: fetch first, then subscribe to stream.
  /// LIMITED to recent 50
  Stream<List<TransactionModel>> watchTransactionsByStatusList(
      List<TransactionStatus> statuses) async* {
    if (statuses.isEmpty) {
      yield <TransactionModel>[];
      return;
    }

    final statusValues = statuses.map((e) => e.value).toList();

    // 1. Immediately fetch current data (fast, reliable)
    try {
      final initialData = await _client
          .from('transactions')
          .select()
          .inFilter('status', statusValues)
          .order('created_at', ascending: false)
          .limit(50); // Optimization: Limit to 50
      yield (initialData as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      yield <TransactionModel>[];
    }

    // 2. Then subscribe to realtime stream for updates
    yield* _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50) // Optimization: Limit to 50
        .map((data) {
          return data
              .where((json) => statusValues.contains(json['status']))
              .map((json) => TransactionModel.fromJson(json))
              .toList();
        });
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
    double? amountFiat,
  }) async {
    final updates = <String, dynamic>{
      'status': newStatus.value,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (adminId != null) updates['admin_id'] = adminId;
    if (proofPath != null) updates['proof_image_path'] = proofPath;
    if (details != null) updates['details'] = details;
    if (amountFiat != null) updates['amount_fiat'] = amountFiat;

    final data = await _client
        .from('transactions')
        .update(updates)
        .eq('id', transactionId)
        .select();

    if (data.isEmpty) {
      throw Exception(
          'Transaction update failed. You may not have permission to update this transaction.');
    }
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
