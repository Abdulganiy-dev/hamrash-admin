import 'package:flutter/material.dart';

/// Type scale for the app. Sizes and line heights are in logical pixels;
/// Flutter's `height` is line height ÷ font size.
///
/// Styles here carry no color — [AppTypography.textTheme] adds the colors
/// for light/dark, and [AppTextVariant] picks a style from the theme.
///
/// One family: Nunito. Display and H1–H2 — screen, sheet and dialog titles
/// and big numbers — are ExtraBold; H3–H4 are Bold; everything else —
/// titles, list names, body, buttons, labels — uses the lighter weights.
/// Section headers above cards are [title], not a heading.
class AppTypography {
  static const String fontFamily = 'Nunito';

  static TextStyle _style(
    double size,
    double lineHeight,
    FontWeight weight, {
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }

  /// Heading weight for a size: ExtraBold from 24 up, Bold below.
  static TextStyle _heading(
    double size,
    double lineHeight, {
    double letterSpacing = 0,
  }) => _style(
    size,
    lineHeight,
    size >= 24 ? FontWeight.w800 : FontWeight.w700,
    letterSpacing: letterSpacing,
  );

  /// A heading at any size, for one-off titles and big numbers (e.g. a stat
  /// value).
  static TextStyle heading(double size, {double? lineHeight}) =>
      _heading(size, lineHeight ?? (size * 1.25).roundToDouble());

  // Headings — tighter tracking on the large sizes.
  static final display = _heading(40, 48, letterSpacing: -0.8);
  static final h1 = _heading(32, 40, letterSpacing: -0.64);
  static final h2 = _heading(24, 32, letterSpacing: -0.24);
  static final h3 = _heading(20, 28);
  static final h4 = _heading(18, 26);

  // Titles — Nunito, for list names and section headers above cards.
  static final title = _style(16, 24, FontWeight.w700);
  static final subtitle = _style(14, 20, FontWeight.w700);

  // Body
  static final bodyLarge = _style(16, 24, FontWeight.w400);
  static final body = _style(14, 20, FontWeight.w400);
  static final caption = _style(12, 16, FontWeight.w400);

  // Labels
  static final button = _style(14, 20, FontWeight.w700);
  static final label = _style(12, 16, FontWeight.w600);
  static final overline = _style(11, 16, FontWeight.w700, letterSpacing: 0.88);

  /// Builds the Material text theme. [strong] is for headings and labels,
  /// [body] for running text, [muted] for captions and overlines.
  static TextTheme textTheme({
    required Color strong,
    required Color body,
    required Color muted,
  }) {
    return TextTheme(
      displayLarge: display.copyWith(color: strong),
      displayMedium: h1.copyWith(color: strong),
      displaySmall: _heading(
        28,
        36,
        letterSpacing: -0.42,
      ).copyWith(color: strong),
      headlineLarge: h2.copyWith(color: strong),
      headlineMedium: h3.copyWith(color: strong),
      headlineSmall: h4.copyWith(color: strong),
      titleLarge: h4.copyWith(color: strong),
      titleMedium: title.copyWith(color: strong),
      titleSmall: subtitle.copyWith(color: strong),
      bodyLarge: bodyLarge.copyWith(color: body),
      bodyMedium: AppTypography.body.copyWith(color: body),
      bodySmall: caption.copyWith(color: muted),
      labelLarge: button.copyWith(color: strong),
      labelMedium: label.copyWith(color: strong),
      labelSmall: overline.copyWith(color: muted),
    );
  }
}

/// Named text styles for [AppText]. Each resolves to a slot in the current
/// theme's [TextTheme], so light/dark colors come along for free.
enum AppTextVariant {
  display,
  h1,
  h2,
  h3,
  h4,
  title,
  subtitle,
  bodyLarge,
  body,
  caption,
  button,
  label,
  overline;

  TextStyle? resolve(TextTheme theme) => switch (this) {
    AppTextVariant.display => theme.displayLarge,
    AppTextVariant.h1 => theme.displayMedium,
    AppTextVariant.h2 => theme.headlineLarge,
    AppTextVariant.h3 => theme.headlineMedium,
    AppTextVariant.h4 => theme.headlineSmall,
    AppTextVariant.title => theme.titleMedium,
    AppTextVariant.subtitle => theme.titleSmall,
    AppTextVariant.bodyLarge => theme.bodyLarge,
    AppTextVariant.body => theme.bodyMedium,
    AppTextVariant.caption => theme.bodySmall,
    AppTextVariant.button => theme.labelLarge,
    AppTextVariant.label => theme.labelMedium,
    AppTextVariant.overline => theme.labelSmall,
  };
}
