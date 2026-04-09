import 'package:flutter/material.dart';

/// Canonical border radius values for the Remita app design system.
///
/// Use these constants instead of magic numbers in [BorderRadius.circular]
/// calls to ensure consistent corner rounding throughout the app.
///
/// Two usage patterns are supported:
///
/// 1. Raw value for custom shapes:
/// ```dart
/// BorderRadius.only(
///   topLeft: Radius.circular(AppRadius.md),
///   topRight: Radius.circular(AppRadius.md),
/// )
/// ```
///
/// 2. Pre-built BorderRadius for the common circular case:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: AppRadius.borderRadiusMd,
///   ),
/// )
/// ```
class AppRadius {
  AppRadius._();

  // ========== Base radius values ==========

  /// 4.0 - Small radius (subtle rounding, chips)
  static const double sm = 4.0;

  /// 8.0 - Medium radius (cards, inputs, buttons)
  static const double md = 8.0;

  /// 12.0 - Large radius (modals, dialogs)
  static const double lg = 12.0;

  /// 16.0 - Extra-large radius (prominent containers)
  static const double xl = 16.0;

  /// 100.0 - Pill shape (fully rounded, tags, badges)
  static const double pill = 100.0;

  // ========== Extended radius values ==========

  /// 0.0 - No rounding
  static const double none = 0.0;

  /// 1.0 - Subtle rounding
  static const double xxs = 1.0;

  /// 2.0 - Minimal rounding (12 BorderRadius + 26 Radius usages)
  static const double xs = 2.0;

  /// 3.0 - Between xs(2) and sm(4)
  static const double smXs = 3.0;

  /// 5.0 - Between sm(4) and md(8)
  static const double smMd = 5.0;

  /// 6.0 - Between sm(4) and md(8) (15 BorderRadius + 28 Radius usages)
  static const double smMd2 = 6.0;

  /// 7.0 - Near md(8)
  static const double mdSm = 7.0;

  /// 9.0 - Between md(8) and lg(12)
  static const double mdLg = 9.0;

  /// 10.0 - Between md(8) and lg(12) (24 BorderRadius + 32 Radius usages)
  static const double mdLg2 = 10.0;

  /// 11.0 - Near lg(12) (5 BorderRadius + 5 Radius usages)
  static const double lgSm = 11.0;

  /// 14.0 - Near xl(16) (4 BorderRadius + multiple Radius usages)
  static const double xlSm = 14.0;

  /// 15.0 - Near xl(16)
  static const double xlLg = 15.0;

  /// 20.0 - Above xl(16) (3 BorderRadius + 22 Radius usages)
  static const double xl2 = 20.0;

  /// 24.0 - (3 BorderRadius + 6 Radius usages)
  static const double xl3 = 24.0;

  /// 30.0 - (1 BorderRadius + 14 Radius usages)
  static const double xl4 = 30.0;

  /// 32.0 - (6 Radius usages)
  static const double xl5 = 32.0;

  /// 40.0 - (6 BorderRadius + 7 Radius usages)
  static const double xxl = 40.0;

  /// 50.0 - Large rounding
  static const double xxl2 = 50.0;

  /// 200.0 - Near-circle for large containers
  static const double xxl3 = 200.0;

  // ========== Pre-built BorderRadius objects ==========

  /// BorderRadius.circular(4.0)
  static final BorderRadius borderRadiusSm = BorderRadius.circular(sm);

  /// BorderRadius.circular(8.0)
  static final BorderRadius borderRadiusMd = BorderRadius.circular(md);

  /// BorderRadius.circular(12.0)
  static final BorderRadius borderRadiusLg = BorderRadius.circular(lg);

  /// BorderRadius.circular(16.0)
  static final BorderRadius borderRadiusXl = BorderRadius.circular(xl);

  /// BorderRadius.circular(100.0)
  static final BorderRadius borderRadiusPill = BorderRadius.circular(pill);

  // ========== Extended pre-built BorderRadius objects ==========

  /// BorderRadius.circular(0.0)
  static final BorderRadius borderRadiusNone = BorderRadius.circular(none);

  /// BorderRadius.circular(2.0)
  static final BorderRadius borderRadiusXs = BorderRadius.circular(xs);

  /// BorderRadius.circular(6.0)
  static final BorderRadius borderRadiusSmMd2 = BorderRadius.circular(smMd2);

  /// BorderRadius.circular(10.0)
  static final BorderRadius borderRadiusMdLg2 = BorderRadius.circular(mdLg2);

  /// BorderRadius.circular(11.0)
  static final BorderRadius borderRadiusLgSm = BorderRadius.circular(lgSm);

  /// BorderRadius.circular(20.0)
  static final BorderRadius borderRadiusXl2 = BorderRadius.circular(xl2);

  /// BorderRadius.circular(24.0)
  static final BorderRadius borderRadiusXl3 = BorderRadius.circular(xl3);

  /// BorderRadius.circular(30.0)
  static final BorderRadius borderRadiusXl4 = BorderRadius.circular(xl4);

  /// BorderRadius.circular(32.0)
  static final BorderRadius borderRadiusXl5 = BorderRadius.circular(xl5);

  /// BorderRadius.circular(40.0)
  static final BorderRadius borderRadiusXxl = BorderRadius.circular(xxl);
}
