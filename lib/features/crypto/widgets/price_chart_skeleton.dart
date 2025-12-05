import 'package:flutter/material.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/theme/app_colors.dart';

/// Skeleton loader for Price Chart Widget
/// Mimics the structure of the price chart
class PriceChartSkeleton extends StatelessWidget {
  const PriceChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chart Skeleton
        Container(
          height: 280,
          padding: const EdgeInsets.fromLTRB(0, 24, 16, 0),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const SkeletonLoader(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
        const SizedBox(height: 24),
        // Time Range Selectors Skeleton
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              5,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

