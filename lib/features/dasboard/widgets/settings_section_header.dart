import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

/// Settings Section Header Widget
class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 24, bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.titleMedium(
          context,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
