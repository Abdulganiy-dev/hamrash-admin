import 'package:flutter/widgets.dart';

/// What a widget is sitting on. Lets inputs pick a fill that stands out:
/// white on the linen page, stone-50 on white cards, sheets and dialogs.
enum AppSurface {
  /// The linen page.
  page,

  /// White cards, sheets and dialogs.
  card,

  /// A stone-50 group inside a card or sheet ([AppRowGroup.inset]).
  inset,
}

/// Marks its subtree as sitting on [surface]. [AppCard], [AppSheet],
/// [AppAlertDialog] and [AppRowGroup.inset] add this for you; everything
/// else is the page.
class AppSurfaceScope extends InheritedWidget {
  const AppSurfaceScope({
    super.key,
    required this.surface,
    required super.child,
  });

  final AppSurface surface;

  static AppSurface of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSurfaceScope>()?.surface ??
      AppSurface.page;

  @override
  bool updateShouldNotify(AppSurfaceScope oldWidget) =>
      surface != oldWidget.surface;
}
