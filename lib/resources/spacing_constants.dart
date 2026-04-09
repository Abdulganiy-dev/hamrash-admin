import 'package:flutter/material.dart';

/// Canonical spacing values for the Remita app design system.
///
/// Use these constants instead of magic numbers in [EdgeInsets], [SizedBox],
/// and other layout widgets to ensure consistent spacing throughout the app.
///
/// Usage examples:
/// ```dart
/// // Raw value in EdgeInsets
/// Padding(padding: EdgeInsets.all(AppSpacing.md))
///
/// // Raw value in SizedBox
/// SizedBox(height: AppSpacing.sm)
///
/// // Convenience EdgeInsets helper
/// Padding(padding: AppSpacing.allMd)
/// ```
class AppSpacing {
  AppSpacing._();

  // ========== Base spacing values ==========

  /// 4.0 - Extra-small spacing (tight gaps, icon padding)
  static const double xs = 4.0;

  /// 8.0 - Small spacing (list item gaps, compact padding)
  static const double sm = 8.0;

  /// 16.0 - Medium spacing (standard content padding, section gaps)
  static const double md = 16.0;

  /// 24.0 - Large spacing (section separators, card padding)
  static const double lg = 24.0;

  /// 32.0 - Extra-large spacing (major section breaks)
  static const double xl = 32.0;

  /// 48.0 - Double extra-large spacing (page-level margins)
  static const double xxl = 48.0;

  // ========== Extended spacing values ==========

  /// 1.0 - Fine borders, hairline gaps
  static const double xxs = 1.0;

  /// 2.0 - Tight padding
  static const double xxs2 = 2.0;

  /// 3.0 - Compact UI elements
  static const double xs2 = 3.0;

  /// 5.0 - Between xs(4) and sm(8)
  static const double xsSm = 5.0;

  /// 6.0 - Between xs(4) and sm(8)
  static const double smXs = 6.0;

  /// 10.0 - Between sm(8) and md(16), 43+ SizedBox usages
  static const double smMd = 10.0;

  /// 12.0 - Between sm(8) and md(16), 150+ occurrences (most common off-scale value)
  static const double smMd2 = 12.0;

  /// 13.0 - Between sm(8) and md(16)
  static const double smMd3 = 13.0;

  /// 14.0 - Between sm(8) and md(16)
  static const double smMd4 = 14.0;

  /// 15.0 - Between sm(8) and md(16), 18+ SizedBox usages
  static const double mdSm = 15.0;

  /// 20.0 - Between md(16) and lg(24), 51+ SizedBox usages
  static const double mdLg = 20.0;

  /// 25.0 - Between lg(24) and xl(32)
  static const double lgMd = 25.0;

  /// 28.0 - Between lg(24) and xl(32)
  static const double lgXl = 28.0;

  /// 30.0 - Between xl(32) and xxl(48)
  static const double xlLg = 30.0;

  /// 40.0 - Between xl(32) and xxl(48), 11+ usages
  static const double xlXxl = 40.0;

  /// 50.0 - Above xxl(48)
  static const double xxl2 = 50.0;

  /// 53.0 - Above xxl(48)
  static const double xxl3 = 53.0;

  /// 60.0 - Above xxl(48)
  static const double xxl4 = 60.0;

  /// 64.0 - Above xxl(48)
  static const double xxl5 = 64.0;

  /// 72.0 - Above xxl(48)
  static const double xxl6 = 72.0;

  /// 80.0 - Above xxl(48)
  static const double xxl7 = 80.0;

  /// 100.0 - Extra-large page padding
  static const double xxl8 = 100.0;

  // ========== Additional edge-case spacing values ==========

  /// 7.0 - Between smXs(6) and sm(8)
  static const double smXs2 = 7.0;

  /// 18.0 - Between md(16) and mdLg(20)
  static const double mdLg2 = 18.0;

  /// 46.0 - Between xlXxl(40) and xxl(48)
  static const double xlXxl2 = 46.0;

  /// 52.0 - Between xxl2(50) and xxl3(53)
  static const double xxl2a = 52.0;

  // ========== Convenience EdgeInsets: all sides ==========

  /// EdgeInsets.all(4.0)
  static final EdgeInsets allXs = EdgeInsets.all(xs);

  /// EdgeInsets.all(8.0)
  static final EdgeInsets allSm = EdgeInsets.all(sm);

  /// EdgeInsets.all(16.0)
  static final EdgeInsets allMd = EdgeInsets.all(md);

  /// EdgeInsets.all(24.0)
  static final EdgeInsets allLg = EdgeInsets.all(lg);

  // ========== Convenience EdgeInsets: horizontal ==========

  /// EdgeInsets.symmetric(horizontal: 8.0)
  static final EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);

  /// EdgeInsets.symmetric(horizontal: 16.0)
  static final EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);

  // ========== Convenience EdgeInsets: vertical ==========

  /// EdgeInsets.symmetric(vertical: 8.0)
  static final EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);

  /// EdgeInsets.symmetric(vertical: 16.0)
  static final EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);

  // ========== Extended convenience EdgeInsets ==========

  /// EdgeInsets.all(10.0)
  static final EdgeInsets allSmMd = EdgeInsets.all(smMd);

  /// EdgeInsets.all(12.0)
  static final EdgeInsets allSmMd2 = EdgeInsets.all(smMd2);

  /// EdgeInsets.all(20.0)
  static final EdgeInsets allMdLg = EdgeInsets.all(mdLg);

  /// EdgeInsets.all(32.0)
  static final EdgeInsets allXl = EdgeInsets.all(xl);

  /// EdgeInsets.symmetric(horizontal: 12.0)
  static final EdgeInsets horizontalSmMd2 =
      EdgeInsets.symmetric(horizontal: smMd2);

  /// EdgeInsets.symmetric(horizontal: 20.0)
  static final EdgeInsets horizontalMdLg =
      EdgeInsets.symmetric(horizontal: mdLg);

  /// EdgeInsets.symmetric(horizontal: 24.0)
  static final EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  /// EdgeInsets.symmetric(vertical: 12.0)
  static final EdgeInsets verticalSmMd2 =
      EdgeInsets.symmetric(vertical: smMd2);

  /// EdgeInsets.symmetric(vertical: 20.0)
  static final EdgeInsets verticalMdLg = EdgeInsets.symmetric(vertical: mdLg);

  /// EdgeInsets.symmetric(vertical: 24.0)
  static final EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
}
