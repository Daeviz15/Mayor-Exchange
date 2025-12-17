import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App Text Styles
/// Centralized text style definitions for Mayor Exchange
class AppTextStyles {
  // Display Styles (Large Headings)
  static TextStyle displayLarge(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 32,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    );
  }

  static TextStyle displayMedium(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    );
  }

  static TextStyle displaySmall(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: -0.3,
    );
  }

  // Headline Styles
  static TextStyle headlineLarge(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle headlineMedium(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle headlineSmall(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
  }

  // Title Styles
  static TextStyle titleLarge(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 23,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle titleMedium(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle titleSmall(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  // Body Styles
  static TextStyle bodyLarge(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle bodySmall(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textTertiary,
    );
  }

  // Label Styles
  static TextStyle labelLarge(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle labelMedium(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle labelSmall(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.textTertiary,
    );
  }

  // Special Styles
  static TextStyle balanceAmount(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 36,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimary,
      letterSpacing: -1,
    );
  }

  static TextStyle cryptoPrice(BuildContext context) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle percentageChange(BuildContext context, bool isPositive) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: isPositive ? AppColors.success : AppColors.error,
    );
  }

  // Private constructor to prevent instantiation
  AppTextStyles._();
}
