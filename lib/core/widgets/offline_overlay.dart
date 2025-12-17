import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

class OfflineOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const OfflineOverlay({super.key, required this.child});

  @override
  ConsumerState<OfflineOverlay> createState() => _OfflineOverlayState();
}

class _OfflineOverlayState extends ConsumerState<OfflineOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _eyeController;
  late Animation<double> _pupilAnimation;

  @override
  void initState() {
    super.initState();
    // Eye movement animation (looking left and right)
    _eyeController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pupilAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _eyeController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _eyeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final networkStatus = ref.watch(connectivityProvider);
    final isOffline = networkStatus == NetworkStatus.offline;

    return Stack(
      children: [
        widget.child,

        // Animated Offline Indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          // Only show if offline, otherwise move off-screen or hide
          height: isOffline ? null : 0,
          child: isOffline
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: const Color(0xFFFF4500)
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Animated Eye Icon
                                _AnimatedEye(animation: _pupilAnimation),
                                const SizedBox(width: 12),
                                const Text(
                                  'You are offline',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14, // Decreased font size
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _AnimatedEye extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedEye({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Center(
            child: Transform.translate(
              offset: Offset(animation.value, 0),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4500), // Primary Orange for pupil
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
