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
    with SingleTickerProviderStateMixin, RouteAware {
  final ImagePicker _picker = ImagePicker();
  String? _uploadingDocType;
  late AnimationController _controller;

  // Store locally picked files for preview during upload
  final Map<String, File> _pickedFiles = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4), // Slower, smoother animation
      vsync: this,
    )..repeat(); // Continuous rotation (no reverse)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes to pause animation when not visible
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      // Note: RouteObserver would need to be added at MaterialApp level
      // For now, we'll rely on dispose
    }
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(String docType) async {
    // ... items ...
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // Store picked file for immediate preview
    setState(() {
      _uploadingDocType = docType;
      _pickedFiles[docType] = File(picked.path);
    });

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

      // Clear local file after successful upload (server image will be used)
      _pickedFiles.remove(docType);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to upload: $e'),
            backgroundColor: AppColors.error),
      );
      // Keep local file so user can see what failed
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

          // All 3 documents uploaded - show animated pending verification screen
          final allDocsUploaded = kyc != null &&
              kyc.identityDocUrl != null &&
              kyc.addressDocUrl != null &&
              kyc.selfieUrl != null;

          if (isInProgress || allDocsUploaded) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Custom animated hourglass with sand + rotation
                    SizedBox(
                      width: 140,
                      height: 180,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          // Smooth 180° rotation over the animation cycle
                          final rotationAngle =
                              _controller.value * 3.14159; // 0 to π
                          return Transform.rotate(
                            angle: rotationAngle,
                            child: CustomPaint(
                              painter: _HourglassPainter(
                                progress: _controller.value,
                                sandColor: AppColors.primaryOrange,
                                glassColor:
                                    Colors.white.withValues(alpha: 0.15),
                                frameColor: AppColors.primaryOrange,
                              ),
                              size: const Size(140, 180),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Animated dots after "Pending"
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final dots =
                            '.' * ((_controller.value * 3).toInt() + 1);
                        return Text(
                          'Verification Pending$dots',
                          style: const TextStyle(
                            color: AppColors.primaryOrange,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'All documents submitted successfully!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your documents are being reviewed by our team.\nThis usually takes 1-2 business days.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Reassuring info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: AppColors.primaryOrange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "We'll notify you once verification is complete.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
    final localFile = _pickedFiles[docType];

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

          // Image Preview - show local file or server URL
          if (localFile != null || imageUrl != null) ...[
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.backgroundElevated,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: localFile != null
                        ? Image.file(
                            localFile,
                            fit: BoxFit.cover,
                            height: 150,
                            width: double.infinity,
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            height: 150,
                            width: double.infinity,
                            placeholder: (context, url) => const Center(
                              child: RocketLoader(size: 30),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child:
                                  Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                  ),
                ),
                // Upload overlay with loading indicator
                if (isThisUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RocketLoader(size: 30, color: Colors.white),
                            SizedBox(height: 8),
                            Text(
                              'Uploading...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],

          if (onUpload != null && !isThisUploading) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_file,
                    size: 20, color: Colors.white),
                label: Text(
                    isUploaded || localFile != null
                        ? 'Re-Upload Document'
                        : 'Upload Document',
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

/// Custom painter for animated hourglass with flowing sand
class _HourglassPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 (animation progress)
  final Color sandColor;
  final Color glassColor;
  final Color frameColor;

  _HourglassPainter({
    required this.progress,
    required this.sandColor,
    required this.glassColor,
    required this.frameColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final width = size.width * 0.65;
    final height = size.height * 0.8;
    final neckWidth = 6.0; // Width of the narrow middle part

    // Sand flows from top to bottom over the full animation cycle
    // progress 0.0 = full top, 0.5 = half/half, 1.0 = full bottom
    final topSandLevel = 1.0 - progress;
    final bottomSandLevel = progress;

    // Define key points for hourglass shape
    final topY = centerY - height / 2;
    final bottomY = centerY + height / 2;
    final neckY = centerY;

    // Build hourglass path (curvy hourglass)
    Path buildHourglassPath() {
      final path = Path();

      // Start from top-left
      path.moveTo(centerX - width / 2, topY);

      // Top edge
      path.lineTo(centerX + width / 2, topY);

      // Right side - curve down to neck
      path.quadraticBezierTo(
        centerX + width / 2,
        neckY - 20,
        centerX + neckWidth / 2,
        neckY,
      );

      // Right side - curve down to bottom
      path.quadraticBezierTo(
        centerX + width / 2,
        neckY + 20,
        centerX + width / 2,
        bottomY,
      );

      // Bottom edge
      path.lineTo(centerX - width / 2, bottomY);

      // Left side - curve up to neck
      path.quadraticBezierTo(
        centerX - width / 2,
        neckY + 20,
        centerX - neckWidth / 2,
        neckY,
      );

      // Left side - curve up to top
      path.quadraticBezierTo(
        centerX - width / 2,
        neckY - 20,
        centerX - width / 2,
        topY,
      );

      path.close();
      return path;
    }

    final hourglassPath = buildHourglassPath();

    // Paints
    final glassPaint = Paint()
      ..color = glassColor
      ..style = PaintingStyle.fill;

    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final sandPaint = Paint()
      ..color = sandColor
      ..style = PaintingStyle.fill;

    final streamPaint = Paint()
      ..color = sandColor
      ..strokeWidth = 2;

    // Draw glass background
    canvas.drawPath(hourglassPath, glassPaint);

    // Clip to hourglass shape for sand
    canvas.save();
    canvas.clipPath(hourglassPath);

    // Draw sand in top chamber (triangle shape)
    if (topSandLevel > 0.02) {
      final sandHeight = (height / 2 - 15) * topSandLevel;
      final sandTop = topY + 5;
      final sandBottom = topY + 5 + sandHeight;
      // Width tapers as it goes down
      final widthAtBottom =
          width * 0.4 * (1 - sandHeight / (height / 2 - 15)) + neckWidth;

      final topSandPath = Path();
      topSandPath.moveTo(centerX - width / 2 + 5, sandTop);
      topSandPath.lineTo(centerX + width / 2 - 5, sandTop);
      topSandPath.lineTo(centerX + widthAtBottom / 2, sandBottom);
      topSandPath.lineTo(centerX - widthAtBottom / 2, sandBottom);
      topSandPath.close();

      canvas.drawPath(topSandPath, sandPaint);
    }

    // Draw sand in bottom chamber (inverted triangle, fills from bottom up)
    if (bottomSandLevel > 0.02) {
      final sandHeight = (height / 2 - 15) * bottomSandLevel;
      final sandBottom = bottomY - 5;
      final sandTop = sandBottom - sandHeight;
      // Width increases as sand piles up
      final widthAtTop = width * 0.4 * bottomSandLevel + neckWidth;

      final bottomSandPath = Path();
      bottomSandPath.moveTo(centerX - widthAtTop / 2, sandTop);
      bottomSandPath.lineTo(centerX + widthAtTop / 2, sandTop);
      bottomSandPath.lineTo(centerX + width / 2 - 5, sandBottom);
      bottomSandPath.lineTo(centerX - width / 2 + 5, sandBottom);
      bottomSandPath.close();

      canvas.drawPath(bottomSandPath, sandPaint);
    }

    // Draw falling sand stream through neck
    if (progress > 0.05 && progress < 0.95) {
      canvas.drawLine(
        Offset(centerX, neckY - 12),
        Offset(centerX, neckY + 12),
        streamPaint,
      );
    }

    canvas.restore();

    // Draw hourglass frame outline
    canvas.drawPath(hourglassPath, framePaint);

    // Draw decorative caps at top and bottom
    final capPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Top cap
    canvas.drawLine(
      Offset(centerX - width / 2 - 8, topY),
      Offset(centerX + width / 2 + 8, topY),
      capPaint,
    );

    // Bottom cap
    canvas.drawLine(
      Offset(centerX - width / 2 - 8, bottomY),
      Offset(centerX + width / 2 + 8, bottomY),
      capPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
