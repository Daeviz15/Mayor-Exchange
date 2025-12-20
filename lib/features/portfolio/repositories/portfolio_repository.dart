import 'package:supabase_flutter/supabase_flutter.dart';
import '../../transactions/models/transaction.dart';

class PortfolioRepository {
  final SupabaseClient _supabase;

  PortfolioRepository(this._supabase);

  Future<List<TransactionModel>> fetchAllTransactions(String userId) async {
    final response = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .eq('status', 'completed') // Only count completed transactions
        .order('created_at', ascending: true); // Process in order

    // Map response to TransactionModel
    // Note: Assuming TransactionModel.fromJson handles the JSON structure correctly
    return (response as List).map((e) => TransactionModel.fromJson(e)).toList();
  }
}
