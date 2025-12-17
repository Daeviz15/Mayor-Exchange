import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../kyc/models/kyc_request.dart';
import '../../kyc/providers/kyc_provider.dart';
import '../../kyc/repositories/kyc_repository.dart';

// Provider to store the currently selected status filter (Pending, Verified, Rejected)
final adminKycFilterProvider = StateProvider<String>((ref) => 'pending');

// Provider to fetch KYC requests based on the selected filter
final adminKycRequestsProvider =
    FutureProvider.autoDispose<List<KycRequest>>((ref) async {
  final repository = ref.watch(kycRepositoryProvider);
  final status = ref.watch(adminKycFilterProvider);

  // If status is "all", we might pass null, but for this UI we likely use tabs.
  // The filter string should match database values: 'pending', 'verified', 'rejected', 'in_progress'
  return repository.getAllKycRequests(status: status);
});

// Logic controller for Admin actions
class AdminKycController extends StateNotifier<AsyncValue<void>> {
  final KycRepository _repository;
  final Ref _ref;

  AdminKycController(this._repository, this._ref)
      : super(const AsyncData(null));

  Future<void> updateStatus({
    required String userId,
    required String status,
    String? note,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.updateKycStatus(
        userId: userId,
        status: status,
        adminNote: note,
      );

      // Invalidate the list so it refreshes UI
      _ref.invalidate(adminKycRequestsProvider);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final adminKycControllerProvider =
    StateNotifierProvider<AdminKycController, AsyncValue<void>>((ref) {
  final repository = ref.watch(kycRepositoryProvider);
  return AdminKycController(repository, ref);
});
