import 'package:hamrash_admin/core/constants/spacing_constants.dart';

/// Sizes shared by the app bar, the tab bar and the scaffolds around them.
class AppNavMetrics {
  AppNavMetrics._();

  /// App bar row height, below the status bar. Screens without an app bar
  /// still keep this space so their titles line up with screens that have one.
  static const double appBarHeight = 60;

  /// Space between the app bar and the screen edges: the screen gutter, so the
  /// back button lines up with the title and content below it.
  static const double appBarSideInset = AppSpacing.screen;

  /// Floating buttons and pictures in the app bar.
  static const double buttonSize = 44;

  /// Space between buttons in the app bar.
  static const double buttonGap = 8;

  /// Tab bar height. The bar has no background; it sits on the page.
  static const double tabBarHeight = 52;

  /// Width of a tab slot, matching HireThem navigation.
  static const double tabWidth = 80;

  /// Space between the tab bar and the screen edges.
  static const double tabBarSideInset = AppSpacing.screen;

  /// How far below the app bar content fades out.
  static const double appBarFadeExtent = 32;

  /// How far above the tab bar content fades out.
  static const double tabBarFadeExtent = 64;

  /// Gap between the app bar row and the first piece of content, such as a
  /// screen title.
  static const double contentTopGap = AppSpacing.md;

  /// Gap between the last piece of content and the tab bar or the bottom
  /// safe area.
  static const double contentGap = 16;
}
