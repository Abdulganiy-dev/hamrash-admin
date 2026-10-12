import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_metrics.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_tab_bar.dart';

/// One tab of an [AppTabShell]: its tab bar item and the page it shows.
class AppTab {
  const AppTab({required this.item, required this.builder});

  final AppTabItem item;

  /// Builds the page, usually a [DefaultScaffold] without a back button.
  /// Called the first time the tab is opened; the page is then kept alive.
  final WidgetBuilder builder;
}

/// Home of the app: tab pages with the floating [AppTabBar] on top and
/// content fading out above it.
///
/// Detail screens are pushed on the root navigator, so they cover the shell
/// and show no tab bar.
///
/// ```dart
/// AppTabShell(tabs: [
///   AppTab(
///     item: AppTabItem(icon: LucideIcons.house, activeIcon: LucideIcons.house500, label: 'Home'),
///     builder: (_) => const HomeView(),
///   ),
///   ...
/// ])
/// ```
class AppTabShell extends StatefulWidget {
  const AppTabShell({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.onTabChanged,
  });

  final List<AppTab> tabs;
  final int initialIndex;
  final ValueChanged<int>? onTabChanged;

  @override
  State<AppTabShell> createState() => _AppTabShellState();
}

class _AppTabShellState extends State<AppTabShell> {
  late int _index = widget.initialIndex;

  /// Tabs opened so far. Unopened tabs are not built.
  late final Set<int> _opened = {_index};

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _opened.add(index);
    });
    widget.onTabChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).scaffoldBackgroundColor;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    // Sit just above the home indicator, or 16 up on phones without one.
    final barBottom = math.max(safeBottom - 8, 16.0);
    final barTop = barBottom + AppNavMetrics.tabBarHeight;

    return PopScope(
      // Back on another tab returns to the first tab before leaving the app.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: AppTabShellScope(
        currentIndex: _index,
        select: _select,
        bottomClearance: barTop + AppNavMetrics.contentGap,
        child: ColoredBox(
          color: surface,
          child: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: _index,
                  children: [
                    for (var i = 0; i < widget.tabs.length; i++)
                      _opened.contains(i)
                          ? TickerMode(
                              enabled: i == _index,
                              child: widget.tabs[i].builder(context),
                            )
                          : const SizedBox.shrink(),
                  ],
                ),
              ),
              // Content fades out behind the bar. Visual only.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: barTop + AppNavMetrics.tabBarFadeExtent,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          surface,
                          surface,
                          surface.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppNavMetrics.tabBarSideInset,
                right: AppNavMetrics.tabBarSideInset,
                bottom: barBottom,
                child: AppTabBar(
                  items: [for (final tab in widget.tabs) tab.item],
                  currentIndex: _index,
                  onTap: _select,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lets pages inside an [AppTabShell] switch tabs and leave room for the
/// tab bar.
class AppTabShellScope extends InheritedWidget {
  const AppTabShellScope({
    super.key,
    required this.currentIndex,
    required this.select,
    required this.bottomClearance,
    required super.child,
  });

  final int currentIndex;

  /// Switches to another tab, e.g. from a "View all" button on Home.
  final ValueChanged<int> select;

  /// Space at the bottom of the screen that content should scroll past so
  /// its last item is not hidden by the tab bar.
  final double bottomClearance;

  static AppTabShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTabShellScope>();

  @override
  bool updateShouldNotify(AppTabShellScope oldWidget) =>
      currentIndex != oldWidget.currentIndex ||
      bottomClearance != oldWidget.bottomClearance;
}
