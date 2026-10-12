import 'package:flutter/material.dart';

/// Corner radius scale. Reach for the role names first; small things get
/// small corners, surfaces get larger ones, badges are fully round.
class AppRadius {
  AppRadius._();

  // Scale
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double pill = 999.0;

  // Roles
  /// Checkboxes, progress bars, tiny indicators.
  static const double checkbox = xs;

  /// Square chips, icon tiles, tooltips, small buttons.
  static const double chip = sm;

  /// Buttons, text fields, dropdowns, segmented controls.
  static const double control = md;

  /// Cards, list groups, image thumbnails.
  static const double card = lg;

  /// Dialogs, bottom sheets (top corners), large tiles.
  static const double dialog = xl;

  /// Status badges, search fields, avatars.
  static const double badge = pill;

  // Pre-built BorderRadius — scale
  static const BorderRadius brNone = BorderRadius.zero;
  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));

  // Pre-built BorderRadius — roles
  static const BorderRadius brCheckbox = brXs;
  static const BorderRadius brChip = brSm;
  static const BorderRadius brControl = brMd;
  static const BorderRadius brCard = brLg;
  static const BorderRadius brDialog = brXl;
  static const BorderRadius brBadge = brPill;

  /// Bottom sheets: rounded top, square bottom.
  static const BorderRadius brSheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
