import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Base skeleton loader widget with shimmer effect
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0 - _controller.value * 2, 0.0),
              end: Alignment(1.0 - _controller.value * 2, 0.0),
              colors: [
                widget.baseColor ?? AppColors.backgroundCard,
                widget.highlightColor ?? AppColors.backgroundElevated,
                widget.baseColor ?? AppColors.backgroundCard,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton text widget
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonText({
    super.key,
    required this.width,
    this.height = 16,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(4),
    );
  }
}

/// Skeleton circle widget
class SkeletonCircle extends StatelessWidget {
  final double diameter;

  const SkeletonCircle({
    super.key,
    required this.diameter,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: diameter,
      height: diameter,
      borderRadius: BorderRadius.circular(diameter / 2),
    );
  }
}

