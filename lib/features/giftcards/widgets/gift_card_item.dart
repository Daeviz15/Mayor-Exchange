import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../models/gift_card.dart';

/// Gift Card Item Widget
/// Displays a single gift card in the grid
class GiftCardItem extends StatelessWidget {
  final GiftCard giftCard;
  final VoidCallback? onTap;

  const GiftCardItem({
    super.key,
    required this.giftCard,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gift Card with Image Support
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: giftCard.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: giftCard.cardColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildCardContent(),
              ),
            ),
            const SizedBox(height: 12),
            // Gift Card Name
            Text(
              giftCard.name,
              style: AppTextStyles.titleSmall(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Build card content - image if available, otherwise text/icon fallback
  Widget _buildCardContent() {
    // If has image URL, show network image
    if (giftCard.hasImage) {
      return CachedNetworkImage(
        imageUrl: giftCard.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Use unique key based on URL to force refresh when URL changes
        cacheKey: giftCard.imageUrl,
        placeholder: (context, url) => _buildLoadingContent(),
        errorWidget: (context, url, error) => _buildFallbackContent(),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
      );
    }

    return _buildFallbackContent();
  }

  /// Build loading content while image loads
  Widget _buildLoadingContent() {
    return Container(
      color: giftCard.cardColor,
      child: const Center(
        child: RocketLoader(size: 24, color: Colors.white),
      ),
    );
  }

  /// Build fallback content (logo text or icon)
  Widget _buildFallbackContent() {
    return Center(
      child: giftCard.logoText != null
          ? Text(
              giftCard.logoText!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            )
          : giftCard.icon != null
              ? Icon(
                  giftCard.icon,
                  color: Colors.white,
                  size: 40,
                )
              : Text(
                  giftCard.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
    );
  }
}
