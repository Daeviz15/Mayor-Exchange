import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kyc_request.dart';

class KycRepository {
  final SupabaseClient _supabaseClient;
  // Repository for handling KYC requests

  KycRepository(this._supabaseClient);

  Future<KycRequest?> getKycStatus(String userId) async {
    try {
      final response = await _supabaseClient
          .from('kyc_requests')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return KycRequest.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch KYC status: ${e.toString()}');
    }
  }

  Future<String> uploadDocument(
      File file, String userId, String docType) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName =
          '${docType}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '$userId/$fileName';

      await _supabaseClient.storage.from('kyc_documents').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl =
          _supabaseClient.storage.from('kyc_documents').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload document: ${e.toString()}');
    }
  }

  Future<KycRequest> submitKyc({
    required String userId,
    String? identityDocUrl,
    String? addressDocUrl,
    String? selfieUrl,
  }) async {
    try {
      // check if exists
      final existing = await getKycStatus(userId);

      final data = {
        'user_id': userId,
        if (identityDocUrl != null) 'identity_doc_url': identityDocUrl,
        if (addressDocUrl != null) 'address_doc_url': addressDocUrl,
        if (selfieUrl != null) 'selfie_url': selfieUrl,
        'status': 'pending', // Revert to pending on update
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing == null) {
        // Create new
        final response = await _supabaseClient
            .from('kyc_requests')
            .insert(data)
            .select()
            .single();
        return KycRequest.fromJson(response);
      } else {
        // Update existing (Admin notes might persist, but status usually resets to pending if user re-submits)
        // However, if status was 'rejected', we want to reset to 'pending'.
        // If it was 'pending', we just update docs.

        final response = await _supabaseClient
            .from('kyc_requests')
            .update(data)
            .eq('user_id', userId)
            .select()
            .single();
        return KycRequest.fromJson(response);
      }
    } catch (e) {
      throw Exception('Failed to submit KYC request: ${e.toString()}');
    }
  }

  Future<List<KycRequest>> getAllKycRequests({String? status}) async {
    try {
      var query = _supabaseClient.from('kyc_requests').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((e) => KycRequest.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch KYC requests: ${e.toString()}');
    }
  }

  Future<void> updateKycStatus({
    required String userId,
    required String status,
    String? adminNote,
  }) async {
    try {
      final data = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (adminNote != null) 'admin_note': adminNote,
      };

      await _supabaseClient
          .from('kyc_requests')
          .update(data)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update KYC status: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    try {
      final response = await _supabaseClient.rpc('get_user_profile', params: {
        'target_user_id': userId,
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      // Fallback if RPC fails or not yet created (return basic ID)
      return {'id': userId, 'email': 'Unknown (RPC Error)'};
    }
  }
}
