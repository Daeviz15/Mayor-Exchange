import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../kyc/models/kyc_request.dart';
import '../providers/admin_kyc_provider.dart';

import '../../kyc/providers/kyc_provider.dart';

class AdminKycDetailScreen extends ConsumerStatefulWidget {
  final KycRequest request;

  const AdminKycDetailScreen({super.key, required this.request});

  @override
  ConsumerState<AdminKycDetailScreen> createState() =>
      _AdminKycDetailScreenState();
}

class _AdminKycDetailScreenState extends ConsumerState<AdminKycDetailScreen> {
  final _noteController = TextEditingController();
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profile = await ref
          .read(kycRepositoryProvider)
          .fetchUserProfile(widget.request.userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    final controller = ref.read(adminKycControllerProvider.notifier);
    await controller.updateStatus(
      userId: widget.request.userId,
      status: status,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    // Check for error in state
    final state = ref.read(adminKycControllerProvider);
    if (!mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${state.error}'),
            backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Status updated to $status'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final isLoading = ref.watch(adminKycControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: Text('KYC Detail', style: AppTextStyles.titleLarge(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo(request),
            const SizedBox(height: 24),
            _buildSectionTitle('Documents'),
            const SizedBox(height: 16),
            _buildDocPreview('Identity Document', request.identityDocUrl),
            _buildDocPreview('Proof of Address', request.addressDocUrl),
            _buildDocPreview('Selfie', request.selfieUrl),
            const SizedBox(height: 32),
            _buildSectionTitle('Admin Actions'),
            const SizedBox(height: 16),
            _buildActionButtons(isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(KycRequest request) {
    String displayName = 'Loading...';
    if (!_isLoadingProfile && _userProfile != null) {
      displayName = _userProfile!['full_name'] ??
          _userProfile!['email'] ??
          'Unknown User';
    } else if (!_isLoadingProfile) {
      displayName = 'Unknown User';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('User', displayName),
          const SizedBox(height: 8),
          _buildInfoRow('User ID', request.userId),
          const SizedBox(height: 8),
          _buildInfoRow('Current Status', request.status.toUpperCase()),
          const SizedBox(height: 8),
          _buildInfoRow(
              'Submitted', request.createdAt.toString().split('.')[0]),
          if (request.adminNote != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Note', request.adminNote!),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.titleMedium(context));
  }

  Widget _buildDocPreview(String label, String? url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          if (url != null)
            GestureDetector(
              onTap: () {
                // Open full screen image
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => _FullScreenImage(url: url)));
              },
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                        child: RocketLoader(
                            size: 30, color: AppColors.primaryOrange)),
                    errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Text('No Document Uploaded',
                  style: TextStyle(color: AppColors.textTertiary)),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isLoading) {
    if (isLoading) {
      return const Center(child: RocketLoader());
    }

    return Column(
      children: [
        // Verification In Progress Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _updateStatus('in_progress'),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Mark Verification In Progress',
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus('rejected'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0),
                child: const Text('Reject',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus('verified'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Approve',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Add note (required for rejection)...',
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.backgroundElevated,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String url;
  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: url,
            placeholder: (_, __) => const RocketLoader(),
            errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
