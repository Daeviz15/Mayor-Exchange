import 'package:flutter/material.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/theme/app_colors.dart';

/// Skeleton loader for Transaction Card
/// Mimics the structure of _CompactTransactionCard widget
class TransactionCardSkeleton extends StatelessWidget {
  const TransactionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Icon skeleton (circle)
          const SkeletonCircle(diameter: 40),
          const SizedBox(width: 12),
          // Text skeleton (title + subtitle)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonText(width: 120, height: 14),
                SizedBox(height: 6),
                SkeletonText(width: 80, height: 12),
              ],
            ),
          ),
          // Amount + Status skeleton
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              SkeletonText(width: 70, height: 14),
              SizedBox(height: 6),
              SkeletonText(width: 50, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// Multiple transaction card skeletons
class TransactionCardSkeletonList extends StatelessWidget {
  final int count;

  const TransactionCardSkeletonList({
    super.key,
    this.count = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          count,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < count - 1 ? 12 : 0),
            child: const TransactionCardSkeleton(),
          ),
        ),
      ),
    );
  }
}
