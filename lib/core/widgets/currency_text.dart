import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A widget that displays currency amounts with proper symbol rendering.
/// Uses system font for the currency symbol to ensure special characters
/// like Naira (₦) display correctly, while using the app font for the amount.
class CurrencyText extends StatelessWidget {
  final String symbol;
  final String amount;
  final TextStyle? style;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;

  const CurrencyText({
    super.key,
    required this.symbol,
    required this.amount,
    this.style,
    this.color,
    this.fontSize,
    this.fontWeight,
  });

  /// Factory constructor for convenience
  factory CurrencyText.fromAmount({
    required String symbol,
    required double amount,
    TextStyle? style,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    int decimals = 2,
  }) {
    return CurrencyText(
      symbol: symbol,
      amount: amount.toStringAsFixed(decimals),
      style: style,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final effectiveColor =
        color ?? effectiveStyle.color ?? AppColors.textPrimary;
    final effectiveFontSize = fontSize ?? effectiveStyle.fontSize ?? 16;
    final effectiveFontWeight =
        fontWeight ?? effectiveStyle.fontWeight ?? FontWeight.normal;

    return RichText(
      text: TextSpan(
        children: [
          // Currency symbol with system font (Roboto has Naira symbol)
          TextSpan(
            text: symbol,
            style: TextStyle(
              fontFamily: 'Roboto', // System font that includes Naira
              fontFamilyFallback: const ['Noto Sans', 'Arial'],
              fontSize: effectiveFontSize,
              fontWeight: effectiveFontWeight,
              color: effectiveColor,
              letterSpacing: effectiveStyle.letterSpacing,
              height: effectiveStyle.height,
            ),
          ),
          // Amount with app font
          TextSpan(
            text: amount,
            style: TextStyle(
              fontFamily: 'Host Grotesk',
              fontFamilyFallback: const ['Roboto', 'Noto Sans'],
              fontSize: effectiveFontSize,
              fontWeight: effectiveFontWeight,
              color: effectiveColor,
              letterSpacing: effectiveStyle.letterSpacing,
              height: effectiveStyle.height,
            ),
          ),
        ],
      ),
    );
  }
}
