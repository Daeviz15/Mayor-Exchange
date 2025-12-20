import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayor_exchange/core/theme/app_colors.dart';
import 'package:mayor_exchange/core/theme/app_text_styles.dart';
import 'package:mayor_exchange/core/theme/theme_provider.dart';

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: Theme.of(context).iconTheme.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Theme', style: AppTextStyles.titleLarge(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildThemeOption(
              context: context,
              ref: ref,
              title: 'System Default',
              value: ThemeMode.system,
              groupValue: themeMode,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context: context,
              ref: ref,
              title: 'Light Mode',
              value: ThemeMode.light,
              groupValue: themeMode,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context: context,
              ref: ref,
              title: 'Dark Mode',
              value: ThemeMode.dark,
              groupValue: themeMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required ThemeMode value,
    required ThemeMode groupValue,
  }) {
    final isSelected = value == groupValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setTheme(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryOrange
                  : (isDark
                      ? Colors.white10
                      : Colors.grey.withValues(alpha: 0.2)),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
            ]),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryOrange
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryOrange : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
