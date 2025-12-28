import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Widget that displays how long ago prices were updated
/// Auto-refreshes the display every 10 seconds
class PriceTimestampWidget extends StatefulWidget {
  final DateTime lastUpdated;
  final TextStyle? textStyle;
  final Color? iconColor;
  final bool showIcon;

  const PriceTimestampWidget({
    super.key,
    required this.lastUpdated,
    this.textStyle,
    this.iconColor,
    this.showIcon = true,
  });

  @override
  State<PriceTimestampWidget> createState() => _PriceTimestampWidgetState();
}

class _PriceTimestampWidgetState extends State<PriceTimestampWidget> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh the display every 10 seconds to update "X min ago"
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _getUpdatedAgo() {
    final now = DateTime.now();
    final diff = now.difference(widget.lastUpdated);

    if (diff.inSeconds < 10) {
      return 'Just now';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = AppTextStyles.bodySmall(context).copyWith(
      color: AppColors.textTertiary,
      fontSize: 11,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          Icon(
            Icons.access_time,
            size: 12,
            color: widget.iconColor ?? AppColors.textTertiary,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          'Updated ${_getUpdatedAgo()}',
          style: widget.textStyle ?? defaultStyle,
        ),
      ],
    );
  }
}
