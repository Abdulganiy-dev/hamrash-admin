import 'package:flutter/material.dart';

/// Spacing on a 4pt grid. Reach for the role names first (screen, card,
/// section, stack, inline); use the scale when no role fits.
class AppSpacing {
  AppSpacing._();

  // Scale
  static const double none = 0.0;
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double ms = 12.0;
  static const double md = 16.0;
  static const double ml = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Roles
  /// Horizontal padding at the edge of every screen.
  static const double screen = md;

  /// Padding inside cards and sheets.
  static const double card = ml;

  /// Gap between unrelated sections on a screen.
  static const double section = lg;

  /// Gap between related items stacked in a list or form.
  static const double stack = ms;

  /// Gap between items on one line (icon + label, button row).
  static const double inline = sm;

  /// Gap inside a tightly grouped element (title + caption).
  static const double tight = xs;

  // EdgeInsets — all sides
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMs = EdgeInsets.all(ms);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allMl = EdgeInsets.all(ml);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  // EdgeInsets — horizontal
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMs = EdgeInsets.symmetric(horizontal: ms);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalMl = EdgeInsets.symmetric(horizontal: ml);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  // EdgeInsets — vertical
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMs = EdgeInsets.symmetric(vertical: ms);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalMl = EdgeInsets.symmetric(vertical: ml);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);

  // EdgeInsets — roles
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screen,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(card);
}
