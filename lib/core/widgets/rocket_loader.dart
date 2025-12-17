import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RocketLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const RocketLoader({
    super.key,
    this.size = 100,
    this.color,
  });

  @override
  State<RocketLoader> createState() => _RocketLoaderState();
}

class _RocketLoaderState extends State<RocketLoader>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _fireController;

  @override
  void initState() {
    super.initState();

    // Rings rotation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Rocket subtle pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Fire flicker
    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _fireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? AppColors.primaryOrange;

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Ring (Clockwise)
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _RingPainter(
                      color: primaryColor.withValues(alpha: 0.3),
                      strokeWidth: 3,
                      startAngle: 0,
                      sweepAngle: 1.5 * math.pi,
                    ),
                  ),
                );
              },
            ),

            // Inner Ring (Counter-Clockwise)
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_rotationController.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(widget.size * 0.7, widget.size * 0.7),
                    painter: _RingPainter(
                      color: primaryColor,
                      strokeWidth: 2,
                      startAngle: math.pi,
                      sweepAngle: 1.5 * math.pi,
                    ),
                  ),
                );
              },
            ),

            // Rocket & Fire
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.9 + (_pulseController.value * 0.1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rocket Icon
                      Icon(
                        Icons.rocket_launch,
                        size: widget.size * 0.35,
                        color: Colors.white,
                      ),
                      // Animated Fire
                      AnimatedBuilder(
                        animation: _fireController,
                        builder: (context, child) {
                          return Container(
                            margin: const EdgeInsets.only(top: 2),
                            width:
                                widget.size * 0.1 + (_fireController.value * 4),
                            height: widget.size * 0.15 +
                                (_fireController.value * 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primaryOrange,
                                  Colors.red,
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double startAngle;
  final double sweepAngle;

  _RingPainter({
    required this.color,
    required this.strokeWidth,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => true;
}
