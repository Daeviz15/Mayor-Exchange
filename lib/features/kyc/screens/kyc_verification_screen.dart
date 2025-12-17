import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../kyc/models/kyc_request.dart';
import '../../kyc/providers/kyc_provider.dart';

class KycVerificationScreen extends ConsumerStatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  ConsumerState<KycVerificationScreen> createState() =>
      _KycVerificationScreenState();
}

class _KycVerificationScreenState extends ConsumerState<KycVerificationScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  String? _uploadingDocType;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(String docType) async {
    // ... items ...
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploadingDocType = docType);
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${docType}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        quality: 70,
        minWidth: 800,
        minHeight: 800,
      );

      final fileToSave = File(compressed?.path ?? picked.path);
      await ref
          .read(kycControllerProvider.notifier)
          .submitDocument(file: fileToSave, docType: docType);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to upload: $e'),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _uploadingDocType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kycAsync = ref.watch(kycStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('KYC Verification',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: kycAsync.when(
        data: (kyc) {
          final isPending = kyc == null || kyc.status == 'pending';
          final isInProgress = kyc?.status == 'in_progress';
          final isVerified = kyc?.status == 'verified';
          final isRejected = kyc?.status == 'rejected';

          if (isVerified) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset:
                            Offset(0, 10 * _controller.value), // Bobbing 10px
                        child: child,
                      );
                    },
                    child: SizedBox(
                      height: 250,
                      child: Image.asset(
                        'assets/images/dancing_bot.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'All set!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You are fully verified and ready to go.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(kyc),
                const SizedBox(height: 32),
                Text('Required Document',
                    style: AppTextStyles.titleMedium(context)),
                const SizedBox(height: 16),
                _buildDocItem(
                  docType: 'identity',
                  title: 'Identity Document',
                  subtitle:
                      'Government-issued ID, Passport, or Driver\'s License',
                  icon: Icons.description_outlined,
                  isUploaded: kyc?.identityDocUrl != null,
                  imageUrl: kyc?.identityDocUrl,
                  onUpload: (isPending || isRejected)
                      ? () => _pickAndUpload('identity')
                      : null,
                  color: const Color(0xFF2E7D32), // Green tint
                ),
                const SizedBox(height: 16),
                _buildDocItem(
                  docType: 'address',
                  title: 'Proof of Address',
                  subtitle: 'Utility bill, bank statement (max 3 months old)',
                  icon: Icons.home_outlined,
                  isUploaded: kyc?.addressDocUrl != null,
                  imageUrl: kyc?.addressDocUrl,
                  onUpload: (isPending || isRejected)
                      ? () => _pickAndUpload('address')
                      : null,
                  color: const Color(0xFFE65100), // Orange tint
                ),
                const SizedBox(height: 16),
                _buildDocItem(
                  docType: 'selfie',
                  title: 'Selfie Verification',
                  subtitle: 'Take a selfie holding your ID document',
                  icon: Icons.person_outline,
                  isUploaded: kyc?.selfieUrl != null,
                  imageUrl: kyc?.selfieUrl,
                  onUpload: (isPending || isRejected)
                      ? () => _pickAndUpload('selfie')
                      : null,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 32),
                _buildImportantNotes(),
              ],
            ),
          );
        },
        loading: () => const Center(child: RocketLoader()),
        error: (e, s) => Center(
            child:
                Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildStatusCard(KycRequest? kyc) {
    Color bgColor;
    Color iconColor;
    String title;
    String subtitle;
    String badgeText;
    Color badgeColor;

    if (kyc == null || kyc.status == 'pending') {
      bgColor = AppColors.backgroundCard; // Default dark
      iconColor = AppColors.textTertiary;
      title = 'Verification Status';
      subtitle =
          'Your documents are being reviewed. This usually takes 1-2 business days.'; // Generic
      badgeText = 'Pending';
      badgeColor = AppColors.textTertiary;
    } else if (kyc.status == 'in_progress') {
      bgColor = AppColors.backgroundCard;
      iconColor = AppColors.primaryOrange;
      title = 'Verification Status';
      subtitle = 'Your documents are currently under review by our team.';
      badgeText = 'In Progress';
      badgeColor = AppColors.primaryOrange;
    } else if (kyc.status == 'verified') {
      bgColor = AppColors.backgroundCard;
      iconColor = AppColors.success;
      title = 'Verification Status';
      subtitle = 'Your identity has been verified. You now have full access.';
      badgeText = 'Verified';
      badgeColor = AppColors.success;
    } else {
      // Rejected
      bgColor = AppColors.backgroundCard;
      iconColor = AppColors.error;
      title = 'Verification Status';
      subtitle = kyc.adminNote ??
          'Your verification failed. Please check the notes and re-upload.';
      badgeText = 'Failed';
      badgeColor = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.textTertiary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2), // Light tint
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined, color: iconColor, size: 32),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badgeText,
                    style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Level 1',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
          const SizedBox(height: 12),
          Text(subtitle,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDocItem({
    required String docType,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isUploaded,
    required String? imageUrl,
    required VoidCallback? onUpload,
    required Color color,
  }) {
    // Determine border color based on upload state
    final borderColor = isUploaded
        ? const Color(0xFF2E7D32) // Green border for uploaded
        : color.withValues(alpha: 0.5);

    final isThisUploading = _uploadingDocType == docType;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        if (isUploaded) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle,
                              color: AppColors.success, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),

          // Image Preview
          if (imageUrl != null) ...[
            const SizedBox(height: 16),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.backgroundElevated,
                image: DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],

          if (onUpload != null) ...[
            const SizedBox(height: 16),
            if (isThisUploading)
              const Center(child: RocketLoader(size: 40))
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file,
                      size: 20, color: Colors.white),
                  label: Text(
                      isUploaded ? 'Re-Upload Document' : 'Upload Document',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE64A19), // Deep Orange
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                ),
              ),
          ],
          if (isUploaded && onUpload == null) ...[
            const SizedBox(height: 12),
            const Text('Verification in progress...',
                style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildImportantNotes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2630), // Dark Blueish Grey
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                const Color(0xFF2196F3).withValues(alpha: 0.3)), // Blue Border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 20),
              SizedBox(width: 8),
              Text('Important Notes',
                  style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _buildBulletPoint('Documents must be clear and legible'),
          _buildBulletPoint('All four corners must be visible'),
          _buildBulletPoint('Documents should not be expired'),
          _buildBulletPoint('File formats: JPG, PNG, PDF (max 10MB)'),
          _buildBulletPoint('Processing time: 1-2 business days'),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•',
              style: TextStyle(
                  color: Color(0xFF64B5F6), fontSize: 14)), // Light blue bullet
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(color: Color(0xFF64B5F6), fontSize: 14))),
        ],
      ),
    );
  }
}
