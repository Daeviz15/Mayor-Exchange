import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // Required for StateNotifier in v3
import '../../../core/providers/supabase_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/kyc_request.dart';
import '../repositories/kyc_repository.dart';

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return KycRepository(client);
});

// Stream of KYC Request for the current user
final kycStatusProvider = StreamProvider.autoDispose<KycRequest?>((ref) {
  final client = ref.read(supabaseClientProvider);
  final user = ref.watch(authUserProvider);

  if (user == null) return Stream.value(null);

  return client
      .from('kyc_requests')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((data) => data.isNotEmpty ? KycRequest.fromJson(data.first) : null);
});

/// Returns true if the current user's KYC is verified.
/// Use this in UI to gate transaction access.
final isKycVerifiedProvider = Provider.autoDispose<bool>((ref) {
  final kycAsync = ref.watch(kycStatusProvider);
  final kycRequest = kycAsync.asData?.value;
  return kycRequest?.status == 'verified';
});

/// Returns a summary string for the user's current KYC status.
/// Useful for displaying messages in the KYC modal.
final kycStatusSummaryProvider = Provider.autoDispose<String>((ref) {
  final kycAsync = ref.watch(kycStatusProvider);

  return kycAsync.when(
    data: (kyc) {
      if (kyc == null) return 'not_started';
      return kyc.status; // 'pending', 'in_progress', 'verified', 'rejected'
    },
    loading: () => 'loading',
    error: (_, __) => 'error',
  );
});

class KycController extends StateNotifier<AsyncValue<void>> {
  final KycRepository _repository;
  final String? _userId;

  KycController(this._repository, this._userId) : super(const AsyncData(null));

  Future<void> submitDocument({
    required File file,
    required String docType, // 'identity', 'address', 'selfie'
  }) async {
    if (_userId == null) return;
    state = const AsyncLoading();
    try {
      final url = await _repository.uploadDocument(file, _userId!, docType);

      // Update specific field based on docType
      String? identityUrl;
      String? addressUrl;
      String? selfieUrl;

      if (docType == 'identity') identityUrl = url;
      if (docType == 'address') addressUrl = url;
      if (docType == 'selfie') selfieUrl = url;

      await _repository.submitKyc(
        userId: _userId!,
        identityDocUrl: identityUrl,
        addressDocUrl: addressUrl,
        selfieUrl: selfieUrl,
      );
      if (mounted) state = const AsyncData(null);
    } catch (e, st) {
      if (mounted) state = AsyncError(e, st);
    }
  }
}

final kycControllerProvider =
    StateNotifierProvider.autoDispose<KycController, AsyncValue<void>>((ref) {
  final repository = ref.read(kycRepositoryProvider);
  final user = ref.watch(authUserProvider);
  return KycController(repository, user?.id);
});
