import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                      style: AppTextStyles.labelMedium(context),
                    ),
                    const SizedBox(width: 8),
                    // Animated Eye Toggle
                    GestureDetector(
                      onTap: _toggleBalance,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: AnimatedEyeIcon(
                          isOpen: _isBalanceVisible,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.onViewPortfolio != null)
                  TextButton(
                    onPressed: widget.onViewPortfolio,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'View Portfolio',
                      style: AppTextStyles.labelMedium(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Balance Text with Cross-fade
            AnimatedCrossFade(
              firstChild: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: widget.balance),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, child) {
                  return Text(
                    '${widget.symbol}${animatedValue.toStringAsFixed(2)}',
                    style: AppTextStyles.balanceAmount(context),
                  );
                },
              ),
              secondChild: Text(
                '${widget.symbol} ****.**',
                style: AppTextStyles.balanceAmount(context),
              ),
              crossFadeState: _isBalanceVisible
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
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
                Text(
                  '${isPositive ? '+' : ''}${widget.changePercent.toStringAsFixed(1)}% in last 24h',
                  style: AppTextStyles.percentageChange(context, isPositive),
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
  final Color color;

  const AnimatedEyeIcon({
    super.key,
    required this.isOpen,
    this.size = 24,
    this.color = Colors.white,
  });

  @override
  State<AnimatedEyeIcon> createState() => _AnimatedEyeIconState();
}

class _AnimatedEyeIconState extends State<AnimatedEyeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _lookController;
  Animation<Offset>? _eyeAnimation;

  // Random generator for eye movement
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _lookController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Initial random movement
    _updateEyeAnimation();

    // Listen to status to trigger new movements
    _lookController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Wait a bit then look somewhere else
        Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1500)), () {
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
    // Generate a random offset within a small range (-0.3 to 0.3)
    final double dx = (_random.nextDouble() - 0.5) * 0.6;
    final double dy = (_random.nextDouble() - 0.5) * 0.4;
    final Offset target = Offset(dx, dy);

    // Current value (start from where we are)
    final Offset begin = _eyeAnimation?.value ?? Offset.zero;

    _eyeAnimation = Tween<Offset>(
      begin: begin,
      end: target,
    ).animate(CurvedAnimation(
      parent: _lookController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedEyeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _lookController.forward();
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
      height: widget.size * 0.6, // Eye aspect ratio
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Eye Outline / Sclera (White part)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: widget.size,
            height: widget.isOpen
                ? widget.size * 0.6
                : 2, // Squashes to line when closed
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.color,
                width: 1.5,
              ),
              borderRadius: BorderRadius.all(Radius.elliptical(
                  widget.size, widget.isOpen ? widget.size * 0.6 : 2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.elliptical(
                  widget.size, widget.isOpen ? widget.size * 0.6 : 2)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pupil
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: widget.isOpen ? 1.0 : 0.0,
                    child: AnimatedBuilder(
                      animation: _lookController,
                      builder: (context, child) {
                        // Only init animation if not done (defensive)
                        if (_eyeAnimation == null) return child!;

                        return Transform.translate(
                          offset: Offset(
                            _eyeAnimation!.value.dx * widget.size * 0.5,
                            _eyeAnimation!.value.dy * widget.size * 0.3,
                          ),
                          child: child,
                        );
                      },
                      child: Container(
                        width: widget.size * 0.35,
                        height: widget.size * 0.35,
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // Eyelid (for blinking/closing effect)
                  // We actually handle closing by squashing the container height,
                  // but we could add a lid here if needed.
                  // The AnimatedContainer height change effectively does the blinking/closing.
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
