import 'package:flutter/material.dart';

enum SlideDirection { up, down, left, right, none }

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double distance;
  final SlideDirection direction;
  final Curve curve;
  final Duration delay;

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.distance = 30.0,
    this.direction = SlideDirection.up,
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    Offset beginOffset;
    switch (widget.direction) {
      case SlideDirection.up:
        beginOffset = Offset(0, widget.distance);
        break;
      case SlideDirection.down:
        beginOffset = Offset(0, -widget.distance);
        break;
      case SlideDirection.left:
        beginOffset = Offset(widget.distance, 0);
        break;
      case SlideDirection.right:
        beginOffset = Offset(-widget.distance, 0);
        break;
      case SlideDirection.none:
        beginOffset = Offset.zero;
        break;
    }

    _offset = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
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
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: -_offset.value, // Negate? Wait.
            // If direction is up, beginOffset is (0, distance).
            // Tween goes from beginOffset (0, distance) to (0,0).
            // So translation starts at +distance (down) and moves to 0.
            // If we want "Slide Up", it should start *below* (positive Y) and move to 0. Yes.
            // If we want "Slide Down", it should start *above* (negative Y) and move to 0. Yes.
            // The logic in initState seems correct for a standard Transform.translate usage. Except horizontal?
            // Left: begin (distance, 0). Starts right, moves left? No. "Slide Left" usually means "Move TO Left".
            // So start at Right (+x) and go to 0.
            // My switch case: case Left: beginOffset = Offset(distance, 0).
            // So it starts at +30 and goes to 0. That looks like "Coming from right, moving left". Consistent.
            // Case Right: beginOffset = (-distance, 0). Starts left (-30), moves right to 0. Consistent.
            // Case Up: beginOffset = (0, distance). Starts down (+30), moves up to 0. Consistent.

            // Wait, Transform.translate(offset) moves the paint.
            // If offset is (0, 30), it is drawn 30px down.
            // So "Slide Up" means visually moving UP. So it should start LOW.
            // My logic: begin = (0, 30). Tween goes 30 -> 0.
            // T=0: Offset(0, 30). Drawn 30px down.
            // T=1: Offset(0, 0). Drawn at origin.
            // Movement: 30 -> 0. That is UP. Correct.

            child: widget.child,
          ),
        );
      },
    );
  }
}
