import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'rocket_loader.dart';

class CustomRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? loaderColor;

  const CustomRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.loaderColor,
  });

  @override
  State<CustomRefreshWrapper> createState() => _CustomRefreshWrapperState();
}

class _CustomRefreshWrapperState extends State<CustomRefreshWrapper> {
  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: widget.onRefresh,
      builder: (
        BuildContext context,
        Widget child,
        IndicatorController controller,
      ) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            if (!controller.isIdle)
              Positioned(
                top: 35.0 * controller.value,
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: Transform.scale(
                    scale: controller.value,
                    child: RocketLoader(
                      size: 60,
                      color: widget.loaderColor ?? AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(0, 100.0 * controller.value),
              child: child,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
