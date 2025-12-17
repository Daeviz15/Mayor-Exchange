import 'package:flutter/material.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/theme/app_colors.dart';

/// Skeleton loader for Crypto Details Screen
/// Mimics the structure of the full crypto details layout
class CryptoDetailsSkeleton extends StatelessWidget {
  const CryptoDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header Skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Crypto Pair Selector Skeleton
                  Row(
                    children: [
                      const SkeletonText(width: 80, height: 24),
                      const SizedBox(width: 8),
                      const SkeletonCircle(diameter: 20),
                    ],
                  ),
                  // Profile Icon Skeleton
                  const SkeletonCircle(diameter: 40),
                ],
              ),
            ),

            // Content Skeleton
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Price and Change Skeleton
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonText(width: 200, height: 40),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const SkeletonCircle(diameter: 16),
                            const SizedBox(width: 8),
                            const SkeletonText(width: 180, height: 18),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Price Chart Skeleton
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
                          (index) => const Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              child: SkeletonText(
                                  width: double.infinity, height: 24),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Data Cards Skeleton
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: List.generate(
                        4,
                        (index) => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SkeletonCircle(diameter: 20),
                              const SizedBox(height: 10),
                              const SkeletonText(width: 80, height: 14),
                              const SizedBox(height: 8),
                              const SkeletonText(width: 100, height: 18),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buy/Sell Buttons Skeleton
                    Row(
                      children: [
                        Expanded(
                          child: SkeletonLoader(
                            width: double.infinity,
                            height: 56,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SkeletonLoader(
                            width: double.infinity,
                            height: 56,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Order Form Skeleton
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonText(width: 120, height: 18),
                          const SizedBox(height: 16),
                          const SkeletonText(
                              width: double.infinity, height: 50),
                          const SizedBox(height: 12),
                          const SkeletonText(
                              width: double.infinity, height: 50),
                          const SizedBox(height: 20),
                          SkeletonLoader(
                            width: double.infinity,
                            height: 56,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
