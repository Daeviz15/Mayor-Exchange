import 'package:flutter/material.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/theme/app_colors.dart';

/// Skeleton loader for Gift Card in dashboard grid
class GiftCardSkeleton extends StatelessWidget {
  const GiftCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon skeleton
          const SkeletonLoader(
            width: 32,
            height: 32,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(height: 8),
          // Name skeleton
          const SkeletonText(width: 60, height: 14),
          const SizedBox(height: 4),
          // Rate skeleton
          const SkeletonText(width: 50, height: 10),
        ],
      ),
    );
  }
}

/// Grid of gift card skeletons
class GiftCardSkeletonGrid extends StatelessWidget {
  final int count;

  const GiftCardSkeletonGrid({
    super.key,
    this.count = 4,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const GiftCardSkeleton(),
    );
  }
}
