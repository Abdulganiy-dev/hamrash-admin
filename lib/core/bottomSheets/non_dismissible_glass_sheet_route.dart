import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

/// A [StupidSimpleGlassSheetRoute] that ignores barrier (scrim) taps, so the
/// sheet can only be dismissed via its own buttons.
///
/// The stock route derives `barrierDismissible` from the snap config, which is
/// `true` for partial-height sheets — meaning a tap on the dimmed area closes
/// them. Use this for confirmation modals (success / error) that must be
/// acknowledged with a button. Pair with `draggable: false` to also lock out
/// the swipe-down gesture.
class NonDismissibleGlassSheetRoute<T> extends StupidSimpleGlassSheetRoute<T> {
  NonDismissibleGlassSheetRoute({
    required super.child,
    super.snappingConfig,
    super.draggable,
  });

  @override
  bool get barrierDismissible => false;
}
