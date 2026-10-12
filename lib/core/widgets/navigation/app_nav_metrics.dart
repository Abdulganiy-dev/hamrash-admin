/// Sizes shared by the app bar, the tab bar and the scaffolds around them.
class AppNavMetrics {
  AppNavMetrics._();

  /// App bar row height, below the status bar.
  static const double appBarHeight = 60;

  /// Space between the app bar and the screen edges.
  static const double appBarSideInset = 16;

  /// Floating buttons and pictures in the app bar.
  static const double buttonSize = 44;

  /// Space between buttons in the app bar.
  static const double buttonGap = 8;

  /// Tab bar height. The bar has no background; it sits on the page.
  static const double tabBarHeight = 52;

  /// Space between the tab bar and the screen edges.
  static const double tabBarSideInset = 16;

  /// How far below the app bar content fades out.
  static const double appBarFadeExtent = 32;

  /// How far above the tab bar content fades out.
  static const double tabBarFadeExtent = 64;

  /// Gap between a bar and the first or last piece of content.
  static const double contentGap = 16;
}
