import 'package:flutter/material.dart';

/// Disables iOS-style bounce overscroll app-wide.
///
/// [SmartRefresher] treats scroll as bouncing when [ScrollConfiguration]
/// returns [BouncingScrollPhysics], so this must be set on [MaterialApp].
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
