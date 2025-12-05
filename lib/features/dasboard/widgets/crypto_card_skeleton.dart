import 'package:flutter/material.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/theme/app_colors.dart';

/// Skeleton loader for Crypto Card
/// Mimics the structure of CryptoCard widget
class CryptoCardSkeleton extends StatelessWidget {
  const CryptoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Crypto Icon Skeleton
          const SkeletonCircle(diameter: 48),
          const SizedBox(width: 16),
          // Crypto Info Skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(width: 100, height: 18),
                const SizedBox(height: 8),
                const SkeletonText(width: 60, height: 14),
              ],
            ),
          ),
          // Chart Skeleton
          const SkeletonLoader(
            width: 60,
            height: 30,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(width: 16),
          // Price and Change Skeleton
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SkeletonText(width: 70, height: 16),
              const SizedBox(height: 8),
              const SkeletonText(width: 50, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}

/// Multiple crypto card skeletons
class CryptoCardSkeletonList extends StatelessWidget {
  final int count;

  const CryptoCardSkeletonList({
    super.key,
    this.count = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => const CryptoCardSkeleton(),
      ),
    );
  }
}

