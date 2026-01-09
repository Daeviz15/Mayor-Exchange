import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/currency_text.dart';

/// Balance Card Widget
/// Displays user's total balance with authenticated eye toggle animation
class BalanceCard extends StatefulWidget {
  final double balance;
  final double changePercent;
  final String symbol;
  final VoidCallback? onViewPortfolio;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.changePercent,
    this.symbol = '₦',
    this.onViewPortfolio,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard>
    with SingleTickerProviderStateMixin {
  bool _isBalanceVisible = true;

  void _toggleBalance() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.changePercent >= 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Total Balance',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _toggleBalance,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: AnimatedEyeIcon(
                          isOpen: _isBalanceVisible,
                          size: 26, // Reduced size
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.onViewPortfolio != null)
                  GestureDetector(
                    onTap: widget.onViewPortfolio,
                    child: Text(
                      'View Portfolio',
                      style: AppTextStyles.labelMedium(context).copyWith(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Balance Text with Cross-fade
            // Add Eye Icon next to balance? Or keep it separate?
            // Design doesn't explicitly show eye icon, but good for privacy.
            // We'll attach it to the balance text or remove if strict to design.
            // Design shows just the balance. Let's keep privacy but maybe simpler.
            // Wait, design has no eye icon visible.
            // Let's keep the functionality but maybe tapping the balance toggles it?
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleBalance,
                    child: AnimatedCrossFade(
                      firstChild: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: widget.balance),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedValue, child) {
                          return CurrencyText(
                            symbol: widget.symbol,
                            amount: animatedValue.toStringAsFixed(2),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          );
                        },
                      ),
                      secondChild: CurrencyText(
                        symbol: widget.symbol,
                        amount: ' ****.**',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      crossFadeState: _isBalanceVisible
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySmall(context),
                    children: [
                      TextSpan(
                        text:
                            '${isPositive ? '+' : ''}${widget.changePercent.toStringAsFixed(1)}% ',
                        style: TextStyle(
                          color:
                              isPositive ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A custom animated eye icon that looks around when open and closes smoothly
class AnimatedEyeIcon extends StatefulWidget {
  final bool isOpen;
  final double size;

  const AnimatedEyeIcon({
    super.key,
    required this.isOpen,
    this.size = 26,
  });

  @override
  State<AnimatedEyeIcon> createState() => _AnimatedEyeIconState();
}

class _AnimatedEyeIconState extends State<AnimatedEyeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _lookController;
  Animation<Offset>? _eyeAnimation;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    // Faster movement duration (was 2000ms)
    _lookController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _updateEyeAnimation();

    _lookController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Faster pause between movements (was 500+1500ms)
        Future.delayed(Duration(milliseconds: 200 + _random.nextInt(800)), () {
          if (mounted && widget.isOpen) {
            _updateEyeAnimation();
            _lookController.forward(from: 0);
          }
        });
      }
    });

    if (widget.isOpen) {
      _lookController.forward();
    }
  }

  void _updateEyeAnimation() {
    // Range -0.4 to 0.4 for broader looking
    final double dx = (_random.nextDouble() - 0.5) * 0.8;
    final double dy = (_random.nextDouble() - 0.5) * 0.5;
    final Offset target = Offset(dx, dy);
    final Offset begin = _eyeAnimation?.value ?? Offset.zero;

    _eyeAnimation = Tween<Offset>(
      begin: begin,
      end: target,
    ).animate(CurvedAnimation(
      parent: _lookController,
      curve: Curves.elasticOut, // Snappy look
    ));
  }

  @override
  void didUpdateWidget(AnimatedEyeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        // Restart animation
        _updateEyeAnimation();
        _lookController.forward(from: 0);
      } else {
        _lookController.stop();
      }
    }
  }

  @override
  void dispose() {
    _lookController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 0.6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sclera (White part) - The base of the eye
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            width: widget.size,
            height: widget.isOpen ? widget.size * 0.6 : 4,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE), // Slightly off-white sclera
              borderRadius: BorderRadius.circular(widget.size),
              border: Border.all(color: Colors.grey.shade400, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size),
              child: Stack(alignment: Alignment.center, children: [
                // Inner Shadow for depth
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1)
                      ],
                      radius: 1.0,
                    )),
                  ),
                ),

                // Iris and Pupil
                if (widget.isOpen)
                  AnimatedBuilder(
                    animation: _lookController,
                    builder: (context, child) {
                      final offset = _eyeAnimation?.value ?? Offset.zero;
                      return Transform.translate(
                        offset: Offset(
                          offset.dx * widget.size * 0.4,
                          offset.dy * widget.size * 0.2,
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      width: widget.size * 0.45,
                      height: widget.size * 0.45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Realistic Iris Gradient - Orange
                        gradient: RadialGradient(
                          colors: [
                            Colors.deepOrange.shade900,
                            AppColors.primaryOrange,
                            Colors.orange.shade300
                          ],
                          stops: const [0.2, 0.7, 1.0],
                        ),
                        border: Border.all(
                            color: Colors.deepOrange.shade900, width: 0.5),
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pupil
                            Container(
                              width: widget.size * 0.22,
                              height: widget.size * 0.22,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Glint / Reflection (Top Left)
                            Positioned(
                              top: widget.size * 0.08,
                              left: widget.size * 0.08,
                              child: Container(
                                width: widget.size * 0.08,
                                height: widget.size * 0.08,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
