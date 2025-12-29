import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayor_exchange/core/theme/app_colors.dart';
import 'package:mayor_exchange/features/kyc/providers/kyc_provider.dart';
import 'package:mayor_exchange/features/kyc/screens/kyc_verification_screen.dart';

/// A premium bottom sheet modal that blocks transaction access
/// for users who have not completed KYC verification.
class KycRequiredModal extends ConsumerWidget {
  const KycRequiredModal({super.key});

  /// Shows the KYC Required modal as a bottom sheet.
  /// Returns `true` if the user is verified, `false` otherwise.
  static Future<bool> showIfRequired(
      BuildContext context, WidgetRef ref) async {
    final isVerified = ref.read(isKycVerifiedProvider);
    if (isVerified) return true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const KycRequiredModal(),
    );
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusSummary = ref.watch(kycStatusSummaryProvider);

    // Determine icon, title, and message based on status
    IconData icon;
    Color iconColor;
    String title;
    String message;
    String buttonText;

    switch (statusSummary) {
      case 'pending':
      case 'in_progress':
        icon = Icons.hourglass_top_rounded;
        iconColor = Colors.amber;
        title = 'Verification In Progress';
        message =
            'Your identity verification is being reviewed by our team. This usually takes a few hours. We\'ll notify you once approved!';
        buttonText = 'Got It';
        break;
      case 'rejected':
        icon = Icons.error_outline_rounded;
        iconColor = Colors.red;
        title = 'Verification Failed';
        message =
            'We couldn\'t verify your identity with the documents provided. Please re-submit your documents for review.';
        buttonText = 'Re-Submit Documents';
        break;
      case 'not_started':
      default:
        icon = Icons.verified_user_outlined;
        iconColor = AppColors.primaryOrange;
        title = 'Identity Verification Required';
        message =
            'To buy or sell assets on Mayor Exchange, we need to verify your identity. This is a one-time process to keep your account secure and comply with regulations.';
        buttonText = 'Verify My Account';
        break;
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 28),

          // Icon with glow effect
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, size: 48, color: iconColor),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Message
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Primary Action Button
          if (statusSummary != 'pending' && statusSummary != 'in_progress')
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context); // Close modal
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const KycVerificationScreen(),
                    ),
                  );
                },
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Secondary "Maybe Later" button
          if (statusSummary == 'not_started') ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Maybe Later',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],

          // Just a close button for pending status
          if (statusSummary == 'pending' || statusSummary == 'in_progress') ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Understood'),
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
