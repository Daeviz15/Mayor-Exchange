import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App Theme Configuration
/// Centralized theme for Mayor Exchange
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryOrange,
        secondary: AppColors.primaryOrangeLight,
        surface: Colors.white,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryLight, // Needs definition or use black
        onError: Colors.white,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.backgroundLight, // Needs definition

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.getFont(
            'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryOrange, width: 2),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: _lightTextStyle(32, FontWeight.w900, -0.5),
        displayMedium: _lightTextStyle(28, FontWeight.w900, -0.5),
        displaySmall: _lightTextStyle(24, FontWeight.w800, -0.3),
        headlineLarge: _lightTextStyle(30, FontWeight.w700),
        headlineMedium: _lightTextStyle(28, FontWeight.w800),
        headlineSmall: _lightTextStyle(22, FontWeight.w700),
        titleLarge: _lightTextStyle(23, FontWeight.w600),
        titleMedium: _lightTextStyle(18, FontWeight.w800),
        titleSmall: _lightTextStyle(16, FontWeight.w600),
        bodyLarge: _lightTextStyle(16, FontWeight.w400),
        bodyMedium: _lightTextStyle(14, FontWeight.w400, 0, Colors.black54),
        bodySmall: _lightTextStyle(12, FontWeight.w400, 0, Colors.black45),
        labelLarge: _lightTextStyle(14, FontWeight.w600),
        labelMedium: _lightTextStyle(12, FontWeight.w500, 0, Colors.black54),
        labelSmall: _lightTextStyle(10, FontWeight.w500, 0, Colors.black45),
      ),
    );
  }

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
        titleTextStyle: GoogleFonts.getFont(
          'Plus Jakarta Sans',
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
          textStyle: GoogleFonts.getFont(
            'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          textStyle: GoogleFonts.getFont(
            'Plus Jakarta Sans',
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
          borderSide:
              const BorderSide(color: AppColors.primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.getFont(
          'Plus Jakarta Sans',
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
      textTheme: TextTheme(
        displayLarge: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleSmall: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
        labelLarge: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelMedium: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.getFont(
          'Plus Jakarta Sans',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  static TextStyle _lightTextStyle(
    double fontSize,
    FontWeight fontWeight, [
    double? letterSpacing,
    Color? color,
  ]) {
    return GoogleFonts.getFont(
      'Plus Jakarta Sans',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Colors.black, // Default to black for light mode
      letterSpacing: letterSpacing,
    );
  }
}
