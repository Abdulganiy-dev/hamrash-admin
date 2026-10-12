import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/constants/radius_containers.dart';

/// App theme configuration with light and dark mode support
class AppTheme {
  static const String _fontFamily = AppTypography.fontFamily;

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
      textTheme: AppTypography.textTheme(
        strong: LightColors.textTextInverted,
        body: LightColors.textTextPrimary,
        muted: LightColors.textTextMute,
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
          borderRadius: AppRadius.brControl,
          borderSide: const BorderSide(
            color: LightColors.strokeColourStrokeMild,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
          borderSide: const BorderSide(
            color: LightColors.strokeColourStrokeMild,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
          borderSide: const BorderSide(
            color: LightColors.strokeColourStrokePrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
          borderSide: const BorderSide(color: LightColors.errorErrorDefault),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
          borderSide: const BorderSide(
            color: LightColors.errorErrorDefault,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
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
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brControl),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LightColors.primaryPrimaryDefault,
          side: const BorderSide(color: LightColors.strokeColourStrokePrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brControl),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LightColors.primaryPrimaryDefault,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brControl),
        ),
      ),
      // Card theme
      cardTheme: CardThemeData(
        color: LightColors.backgroundSurfaceMute,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brCard,
          side: const BorderSide(color: LightColors.strokeColourStrokeSoft),
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
      textTheme: AppTypography.textTheme(
        strong: DarkColors.textTextInverted,
        body: DarkColors.textTextPrimary,
        muted: DarkColors.textTextMute,
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
          borderRadius: AppRadius.brControl,
          borderSide: const BorderSide(
            color: DarkColors.strokeColourStrokeMild,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
          borderSide: const BorderSide(
            color: DarkColors.strokeColourStrokeMild,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
          borderSide: const BorderSide(
            color: DarkColors.strokeColourStrokePrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
          borderSide: const BorderSide(color: DarkColors.errorErrorDefault),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
          borderSide: const BorderSide(
            color: DarkColors.errorErrorDefault,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
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
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brControl),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DarkColors.primaryPrimaryDefault,
          side: const BorderSide(color: DarkColors.strokeColourStrokePrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brControl),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DarkColors.primaryPrimaryDefault,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brControl),
        ),
      ),
      // Card theme
      cardTheme: CardThemeData(
        color: DarkColors.backgroundSurfaceMute,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brCard,
          side: const BorderSide(color: DarkColors.strokeColourStrokeSoft),
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
