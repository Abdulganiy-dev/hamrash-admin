import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/utils/extensions.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_button.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_metrics.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_tab_shell.dart';
import 'package:hamrash_admin/core/widgets/standard_app_bar.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum DefaultScaffoldAppBarType { standard, custom, none }

/// Publishes the layout metrics of the enclosing [DefaultScaffold] so any
/// descendant widget can read the space it needs to clear at the top (safe
/// area + app bar) and bottom (tab bar or safe area) without the scaffold
/// having to push the body in globally. Content scrolls under both bars.
///
/// Usage from any view inside a [DefaultScaffold]:
///
/// ```dart
/// ListView(
///   padding: EdgeInsets.only(
///     top: ScaffoldInsets.bodyTopInsetOf(context),
///     bottom: ScaffoldInsets.bodyBottomInsetOf(context),
///   ),
/// )
/// ```
class ScaffoldInsets extends InheritedWidget {
  const ScaffoldInsets({
    super.key,
    required this.topInset,
    required this.appBarHeight,
    required this.appBarFadeHeight,
    required this.hasAppBar,
    required this.bottomInset,
    required super.child,
  });

  /// System status bar inset (safe area top).
  final double topInset;

  /// Height of the app bar content area.
  final double appBarHeight;

  /// Height of the fade region beneath the app bar content.
  final double appBarFadeHeight;

  /// Whether the enclosing scaffold is actually rendering an app bar layer.
  final bool hasAppBar;

  /// Bottom space a body child should leave clear: the tab bar
  /// inside an [AppTabShell], otherwise the safe area.
  final double bottomInset;

  /// Total top space a body child should leave clear so it is not covered by
  /// the app bar. The app bar row is reserved even when there is no app bar,
  /// so the first title sits at the same height on every screen.
  double get bodyTopInset =>
      topInset + appBarHeight + AppNavMetrics.contentTopGap;

  /// Total bottom space a body child should leave clear.
  double get bodyBottomInset => bottomInset;

  /// Returns the nearest [ScaffoldInsets], or `null` if no [DefaultScaffold]
  /// is an ancestor of [context].
  static ScaffoldInsets? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ScaffoldInsets>();
  }

  /// Returns the nearest [ScaffoldInsets]. Throws if called outside of a
  /// [DefaultScaffold].
  static ScaffoldInsets of(BuildContext context) {
    final insets = maybeOf(context);
    assert(
      insets != null,
      'ScaffoldInsets.of() called outside of a DefaultScaffold. '
      'Use ScaffoldInsets.maybeOf(context) if the widget can also be used '
      'outside a DefaultScaffold.',
    );
    return insets!;
  }

  /// Convenience accessor for [bodyTopInset]. Falls back to the safe area
  /// top when no [DefaultScaffold] is in the tree.
  static double bodyTopInsetOf(BuildContext context) {
    final insets = maybeOf(context);
    if (insets != null) return insets.bodyTopInset;
    return MediaQuery.viewPaddingOf(context).top;
  }

  /// Convenience accessor for [bodyBottomInset]. Falls back to the safe area
  /// bottom when no [DefaultScaffold] is in the tree.
  static double bodyBottomInsetOf(BuildContext context) {
    final insets = maybeOf(context);
    if (insets != null) return insets.bodyBottomInset;
    return MediaQuery.viewPaddingOf(context).bottom;
  }

  @override
  bool updateShouldNotify(ScaffoldInsets oldWidget) {
    return topInset != oldWidget.topInset ||
        appBarHeight != oldWidget.appBarHeight ||
        appBarFadeHeight != oldWidget.appBarFadeHeight ||
        hasAppBar != oldWidget.hasAppBar ||
        bottomInset != oldWidget.bottomInset;
  }
}

class DefaultScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool automaticallyImplyLeading;
  final double appBarHeight;
  final double appBarFadeHeight;
  final Widget? customAppBar;
  final DefaultScaffoldAppBarType? appBarType;
  final EdgeInsetsGeometry? bodyPadding;
  final bool busy;
  final String? subtitle;

  /// Centre the title. Defaults to true when a back button shows (detail
  /// screens) and false otherwise (tab screens).
  final bool? centerTitle;

  @Deprecated('Safe area top is always handled internally for consistency.')
  final bool showSafeAreaTop;
  @Deprecated('Scaffold now uses an internal gradient app bar.')
  final Color? appBarBackgroundColor;
  @Deprecated('Body is always laid out beneath a custom app bar layer.')
  final bool extendBodyBehindAppBar;

  /// Off by default: the keyboard (and any bar riding on it) floats over
  /// the page instead of shrinking it, so content never jumps when a field
  /// is focused.
  final bool resizeToAvoidBottomInset;

  /// Lay the body out behind [bottomNavigationBar] too, e.g. while a
  /// keyboard bar floats over the page.
  final bool extendBody;

  const DefaultScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.showBackButton = false,
    this.showSafeAreaTop = true,
    this.onBackPressed,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.appBarBackgroundColor,
    this.extendBodyBehindAppBar = true,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = false,
    this.extendBody = false,
    this.drawer,
    this.endDrawer,
    this.automaticallyImplyLeading = true,
    this.appBarHeight = AppNavMetrics.appBarHeight,
    this.appBarFadeHeight = AppNavMetrics.appBarFadeExtent,
    this.customAppBar,
    this.appBarType,
    this.bodyPadding,
    this.busy = false,
    this.centerTitle,
  });

  /// Default function to pop the current route
  void _defaultPop(BuildContext context) {
    HapticHelpers.vibrate(VibrationType.light);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildDefaultLeading(BuildContext context) {
    return AppNavIconButton(
      icon: LucideIcons.chevronLeft500,
      iconSize: 22,
      iconColor: AppPalette.stone900,
      semanticLabel: 'Back',
      onPressed: onBackPressed ?? () => _defaultPop(context),
    );
  }

  DefaultScaffoldAppBarType _resolveAppBarType() {
    if (appBarType != null) return appBarType!;
    if (customAppBar != null) return DefaultScaffoldAppBarType.custom;
    final hasStandardConfig =
        title != null ||
        showBackButton ||
        leading != null ||
        (actions?.isNotEmpty ?? false);
    return hasStandardConfig
        ? DefaultScaffoldAppBarType.standard
        : DefaultScaffoldAppBarType.none;
  }

  Widget _buildStandardAppBar(BuildContext context) {
    final showDefaultBackButton =
        showBackButton &&
        leading == null &&
        (Navigator.of(context).canPop() || onBackPressed != null);

    final leadingWidget =
        leading ??
        (automaticallyImplyLeading && showDefaultBackButton
            ? _buildDefaultLeading(context)
            : null);

    return StandardAppBar(
      leading: leadingWidget,
      actions: actions,
      title: title,
      subtitle: subtitle,
      centerTitle: centerTitle ?? showDefaultBackButton,
      height: appBarHeight,
    );
  }

  Widget _buildAppBarLayer(
    BuildContext context, {
    required double topInset,
    required Color surface,
    required Widget appBarContent,
  }) {
    final solidHeight = topInset + appBarHeight;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Content fades out under the bar. Solid behind the title, then
          // fades over [appBarFadeHeight]. Visual only — must not steal taps.
          IgnorePointer(
            child: Container(
              width: double.infinity,
              height: solidHeight + appBarFadeHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [surface, surface, surface.withValues(alpha: 0)],
                  stops: [0, solidHeight / (solidHeight + appBarFadeHeight), 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: topInset),
            child: appBarContent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface =
        backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset =
        AppTabShellScope.maybeOf(context)?.bottomClearance ??
        MediaQuery.viewPaddingOf(context).bottom + AppNavMetrics.contentGap;
    final resolvedAppBarType = _resolveAppBarType();

    final Widget? appBarContent;
    switch (resolvedAppBarType) {
      case DefaultScaffoldAppBarType.standard:
        appBarContent = _buildStandardAppBar(context);
        break;
      case DefaultScaffoldAppBarType.custom:
        appBarContent = customAppBar != null
            ? SizedBox(height: appBarHeight, child: customAppBar)
            : null;
        break;
      case DefaultScaffoldAppBarType.none:
        appBarContent = null;
        break;
    }

    final hasAppBarLayer = appBarContent != null;

    return Scaffold(
      backgroundColor: surface,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      body: ScaffoldInsets(
        topInset: topInset,
        appBarHeight: appBarHeight,
        appBarFadeHeight: appBarFadeHeight,
        hasAppBar: hasAppBarLayer,
        bottomInset: bottomInset,
        child: Stack(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: body,
            ),
            if (hasAppBarLayer)
              _buildAppBarLayer(
                context,
                topInset: topInset,
                surface: surface,
                appBarContent: appBarContent,
              ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ).hideIf(!busy),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
    );
  }
}

class ScaffoldColumn extends StatelessWidget {
  const ScaffoldColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  final CrossAxisAlignment crossAxisAlignment; // = CrossAxisAlignment.center
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    ).padding(
      bottom: 10,
      left: AppSpacing.screen,
      right: AppSpacing.screen,
      top: 0,
    );
  }
}
