import 'package:flutter/material.dart';

/// App Color Scheme
/// Centralized color definitions for Mayor Exchange
class AppColors {
  // Primary Colors
  static const Color primaryOrange = Color(0xFFE6461E); // Deep Orange
  static const Color primaryOrangeLight = Color(0xFFFF6B3D);
  static const Color primaryOrangeDark = Color(0xFFCC2E0A);

  // Background Colors
  static const Color backgroundDark =
      Color(0xFF221910); // Main dark brown background
  static const Color backgroundCard = Color(0xFF2A1F15); // Card dark brown
  static const Color backgroundCardLight = Color(0xFF332A20);
  static const Color backgroundElevated = Color(0xFF3A2F25);

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFF8F9FA); // Light Grey/White
  static const Color textPrimaryLight = Color(0xFF1A1A1A); // Almost Black

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8B8);
  static const Color textTertiary = Color(0xFF8A8A8A);
  static const Color textDisabled = Color(0xFF5A5A5A);

  // Accent Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Chart Colors
  static const Color chartGreen = Color(0xFF4CAF50);
  static const Color chartRed = Color(0xFFE53935);
  static const Color chartNeutral = Color(0xFF9E9E9E);

  // Crypto Icon Backgrounds
  static const Color btcBackground = Color(0xFFFF9800);
  static const Color ethBackground = Color(0xFF627EEA);
  static const Color solBackground = Color(0xFF9945FF);
  static const Color trxBackground = Color(0xFFFF0013); // TRON Red
  static const Color dotBackground = Color(0xFFE6007A); // Polkadot Pink

  // Avatar Colors
  static const Color avatarBackground = Color(0xFF4CAF50);

  // Divider Colors
  static const Color divider = Color(0xFF3A2F25);
  static const Color dividerLight = Color(0xFF4A3F35);

  // Button Colors
  static const Color buttonPrimary = primaryOrange;
  static const Color buttonSecondary = backgroundCard;
  static const Color buttonDisabled = Color(0xFF4A3F35);

  // Navigation Bar
  static const Color navBarBackground = backgroundCard;
  static const Color navBarActive = primaryOrange;
  static const Color navBarInactive = textTertiary;

  // Private constructor to prevent instantiation
  AppColors._();
}
