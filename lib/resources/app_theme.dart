import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App theme configuration with light and dark mode support
class AppTheme {
  /// Font family name for Nunito
  static const String _fontFamily = 'Nunito';
  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily, // Default font family for all text
      colorScheme: ColorScheme.light(
        primary: LightColors.primaryPrimaryDefault,
        secondary: LightColors.extraExtraDefault,
        error: LightColors.errorErrorDefault,
        surface: LightColors.backgroundSurfacePrimaryBG,
        onPrimary: LightColors.primaryOncolorWhite,
        onSecondary: LightColors.primaryOncolorWhite,
        onError: LightColors.primaryOncolorWhite,
        onSurface: LightColors.textTextPrimary,
        background: LightColors.backgroundSurfacePrimaryBG,
        onBackground: LightColors.textTextPrimary,
      ),
      scaffoldBackgroundColor: LightColors.backgroundSurfacePrimaryBG,
      cardColor: LightColors.backgroundSurfaceMute,
      dividerColor: LightColors.strokeColourStrokeMild,
      // Text theme with Nunito font
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 57,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        displayMedium: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 45,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        displaySmall: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 36,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        headlineLarge: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 32,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        headlineMedium: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 28,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        headlineSmall: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 24,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        titleLarge: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 22,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
        titleMedium: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
        titleSmall: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
        bodyLarge: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        bodyMedium: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        bodySmall: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        labelLarge: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
        labelMedium: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
        labelSmall: TextStyle(
          color: LightColors.textTextInverted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
      ),
      // Icon theme
      iconTheme: const IconThemeData(
        color: LightColors.iconIconInverted,
        size: 24,
      ),
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LightColors.backgroundSurfaceMute,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: LightColors.strokeColourStrokeMild,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: LightColors.strokeColourStrokeMild,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: LightColors.strokeColourStrokePrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: LightColors.errorErrorDefault,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: LightColors.errorErrorDefault,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: LightColors.strokeColourStrokeSoft,
          ),
        ),
      ),
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LightColors.primaryPrimaryDefault,
          foregroundColor: LightColors.primaryOncolorWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LightColors.primaryPrimaryDefault,
          side: const BorderSide(
            color: LightColors.strokeColourStrokePrimary,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LightColors.primaryPrimaryDefault,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Card theme
      cardTheme: CardThemeData(
        color: LightColors.backgroundSurfaceMute,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: LightColors.strokeColourStrokeSoft,
          ),
        ),
      ),
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: LightColors.backgroundSurfacePrimaryBG,
        foregroundColor: LightColors.textTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily, // Default font family for all text
      colorScheme: ColorScheme.dark(
        primary: DarkColors.primaryPrimaryDefault,
        secondary: DarkColors.extraExtraDefault,
        error: DarkColors.errorErrorDefault,
        surface: DarkColors.backgroundSurfacePrimaryBG,
        onPrimary: DarkColors.primaryOncolorBlack,
        onSecondary: DarkColors.primaryOncolorBlack,
        onError: DarkColors.primaryOncolorWhite,
        onSurface: DarkColors.textTextPrimary,
        background: DarkColors.backgroundSurfacePrimaryBG,
        onBackground: DarkColors.textTextPrimary,
      ),
      scaffoldBackgroundColor: DarkColors.backgroundSurfacePrimaryBG,
      cardColor: DarkColors.backgroundSurfaceMute,
      dividerColor: DarkColors.strokeColourStrokeMild,
      // Text theme with Nunito font
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: DarkColors.textTextPrimary,
          fontSize: 57,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        displayMedium: TextStyle(
          color: DarkColors.textTextPrimary,
          fontSize: 45,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        displaySmall: TextStyle(
          color: DarkColors.textTextPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        headlineLarge: TextStyle(
          color: DarkColors.textTextPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        headlineMedium: TextStyle(
          color: DarkColors.textTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        headlineSmall: TextStyle(
          color: DarkColors.textTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        titleLarge: TextStyle(
          color: DarkColors.textTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
        titleMedium: TextStyle(
          color: DarkColors.textTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
        titleSmall: TextStyle(
          color: DarkColors.textTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
        bodyLarge: TextStyle(
          color: DarkColors.textTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        bodyMedium: TextStyle(
          color: DarkColors.textTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        bodySmall: TextStyle(
          color: DarkColors.textTextMute,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: _fontFamily,
        ),
        labelLarge: TextStyle(
          color: DarkColors.textTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
        labelMedium: TextStyle(
          color: DarkColors.textTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
        labelSmall: TextStyle(
          color: DarkColors.textTextMute,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
      ),
      // Icon theme
      iconTheme: const IconThemeData(
        color: DarkColors.iconIconPrimary,
        size: 24,
      ),
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DarkColors.backgroundSurfaceMute,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: DarkColors.strokeColourStrokeMild,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: DarkColors.strokeColourStrokeMild,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: DarkColors.strokeColourStrokePrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: DarkColors.errorErrorDefault,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: DarkColors.errorErrorDefault,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: DarkColors.strokeColourStrokeSoft,
          ),
        ),
      ),
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DarkColors.primaryPrimaryDefault,
          foregroundColor: DarkColors.primaryOncolorBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DarkColors.primaryPrimaryDefault,
          side: const BorderSide(
            color: DarkColors.strokeColourStrokePrimary,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DarkColors.primaryPrimaryDefault,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Card theme
      cardTheme: CardThemeData(
        color: DarkColors.backgroundSurfaceMute,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: DarkColors.strokeColourStrokeSoft,
          ),
        ),
      ),
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: DarkColors.backgroundSurfacePrimaryBG,
        foregroundColor: DarkColors.textTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}

