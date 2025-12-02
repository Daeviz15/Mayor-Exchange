import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
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
            // Gift Card
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
              child: Center(
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
                        : const SizedBox(),
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
}

