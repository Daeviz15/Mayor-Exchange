import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App Theme Configuration
/// Centralized theme for Mayor Exchange
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryOrange,
        secondary: AppColors.primaryOrangeLight,
        surface: AppColors.backgroundCard,
        error: AppColors.error,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.workSans(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.backgroundCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.workSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          textStyle: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.workSans(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBarBackground,
        selectedItemColor: AppColors.navBarActive,
        unselectedItemColor: AppColors.navBarInactive,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Text Theme
      textTheme: GoogleFonts.workSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
          headlineLarge: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          titleSmall: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textTertiary,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

