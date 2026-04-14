import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const canvas = Color(0xFFFDFBF7);
  static const ink = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const yellow = Color(0xFFFEF08A);
  static const pink = Color(0xFFFBCFE8);
  static const blue = Color(0xFFBFDBFE);
  static const green = Color(0xFFBBF7D0);
  static const purple = Color(0xFFE9D5FF);
  static const orange = Color(0xFFFED7AA);
  static const red = Color(0xFFFECACA);
  static const peach = orange;
  static const border = Color(0xFF1A1A1A);
  static const shadow = Color(0xFF1A1A1A);
  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF15803D);
  static const muted = Color(0xFF6B7280);
}

enum BackgroundPattern {
  graph,
  stripes,
  bold,
  solid,
  dotted;

  String get label {
    switch (this) {
      case BackgroundPattern.graph:
        return 'Graph';
      case BackgroundPattern.stripes:
        return 'Stripes';
      case BackgroundPattern.bold:
        return 'Bold';
      case BackgroundPattern.solid:
        return 'Solid';
      case BackgroundPattern.dotted:
        return 'Dotted';
    }
  }
}

class AppTheme {
  static ThemeData get theme {
    final textTheme = GoogleFonts.spaceGroteskTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: ColorScheme.light(
        surface: AppColors.canvas,
        primary: AppColors.ink,
        secondary: AppColors.blue,
        error: AppColors.error,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: AppColors.ink),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.ink,
          height: 1.35,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 2.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 2.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.ink, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 3),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
      ),
      dividerColor: AppColors.ink.withValues(alpha: 0.14),
      hoverColor: AppColors.yellow.withValues(alpha: 0.18),
      splashFactory: NoSplash.splashFactory,
    );
  }
}
