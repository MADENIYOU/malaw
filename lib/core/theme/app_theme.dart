import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.sunAccent,
        error: AppColors.error,
        surface: AppColors.surface,
      ),
    );

    final textTheme = GoogleFonts.nunitoSansTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.baloo2(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: AppColors.brown,
      ),
      headlineLarge: GoogleFonts.baloo2(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        color: AppColors.brown,
      ),
      headlineMedium: GoogleFonts.baloo2(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.brown,
      ),
      headlineSmall: GoogleFonts.baloo2(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.brown,
      ),
      titleLarge: GoogleFonts.baloo2(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.brown,
      ),
      titleMedium: GoogleFonts.nunitoSans(
        fontWeight: FontWeight.w700,
        color: AppColors.brown,
      ),
      bodyLarge: GoogleFonts.nunitoSans(color: AppColors.brown),
      bodyMedium: GoogleFonts.nunitoSans(color: AppColors.brown),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.brown,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.baloo2(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.brown,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        labelStyle: GoogleFonts.nunitoSans(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        side: const BorderSide(color: AppColors.divider),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}
