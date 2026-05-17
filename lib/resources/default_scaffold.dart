import 'package:flutter/material.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/widgets/app_button.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hugeicons/hugeicons.dart';

enum DefaultScaffoldAppBarType { standard, custom, none }

/// Publishes the layout metrics of the enclosing [DefaultScaffold] so any
/// descendant widget can read the top inset it needs to clear (safe area +
/// app bar + fade region) without the scaffold having to push the body down
/// globally.
///
/// Usage from any view inside a [DefaultScaffold]:
///
/// ```dart
/// final top = ScaffoldInsets.bodyTopInsetOf(context);
/// // or access the full metrics:
/// final insets = ScaffoldInsets.of(context);
/// ```
class ScaffoldInsets extends InheritedWidget {
  const ScaffoldInsets({
    super.key,
    required this.topInset,
    required this.appBarHeight,
    required this.appBarFadeHeight,
    required this.hasAppBar,
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

  /// Total top space a body child should leave clear so it is not covered by
  /// the translucent app bar overlay. The safe area is always included; the
  /// app bar and its fade region are only included when an app bar exists.
  double get bodyTopInset =>
      topInset + (hasAppBar ? appBarHeight - 15  : 0);

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

  @override
  bool updateShouldNotify(ScaffoldInsets oldWidget) {
    return topInset != oldWidget.topInset ||
        appBarHeight != oldWidget.appBarHeight ||
        appBarFadeHeight != oldWidget.appBarFadeHeight ||
        hasAppBar != oldWidget.hasAppBar;
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

  @Deprecated('Safe area top is always handled internally for consistency.')
  final bool showSafeAreaTop;
  @Deprecated('Scaffold now uses an internal gradient app bar.')
  final Color? appBarBackgroundColor;
  @Deprecated('Body is always laid out beneath a custom app bar layer.')
  final bool extendBodyBehindAppBar;

  const DefaultScaffold({
    super.key,
    required this.body,
    this.title,
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
    this.drawer,
    this.endDrawer,
    this.automaticallyImplyLeading = true,
    this.appBarHeight = kToolbarHeight,
    this.appBarFadeHeight = 20,
    this.customAppBar,
    this.appBarType,
    this.bodyPadding,
    this.busy = false,
  });


  /// Default function to pop the current route
  void _defaultPop(BuildContext context) {
    HapticHelpers.vibrate(VibrationType.light);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildDefaultLeading(BuildContext context) {
    return AppHugeIconButton(
      hugeIcon: HugeIcons.strokeRoundedArrowLeft01,
      hugeIconStrokeWidth: 2,
      hugeIconRasterSize: 30,
      foregroundColorType: AppButtonForegroundColor.textInverted,
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

    return SizedBox(
      height: appBarHeight,
      child: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: leadingWidget,
                ),
              ),
              const Spacer(),
              if (actions != null && actions!.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ).padding(right: 8)
              else
                const SizedBox(width: 72),
            ],
          ),
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 72),
                child: title != null
                    ? AppText(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarLayer(
    BuildContext context, {
    required double topInset,
    required Color surface,
    required Widget appBarContent,
  }) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                surface.withValues(alpha: 0.96),
                surface.withValues(alpha: 0.76),
                surface.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.62, 1.0],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topInset),
              appBarContent,
              IgnorePointer(child: SizedBox(height: appBarFadeHeight)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final resolvedAppBarType = _resolveAppBarType();

    final Widget? appBarContent;
    switch (resolvedAppBarType) {
      case DefaultScaffoldAppBarType.standard:
        appBarContent = _buildStandardAppBar(context);
        break;
      case DefaultScaffoldAppBarType.custom:
        appBarContent = customAppBar;
        break;
      case DefaultScaffoldAppBarType.none:
        appBarContent = null;
        break;
    }

    final hasAppBarLayer = appBarContent != null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ScaffoldInsets(
        topInset: topInset,
        appBarHeight: appBarHeight,
        appBarFadeHeight: appBarFadeHeight,
        hasAppBar: hasAppBarLayer,
        child: Stack(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width, child: body),
            if (hasAppBarLayer)
              _buildAppBarLayer(
                context,
                topInset: topInset,
                surface: colorScheme.surface,
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
    ).padding(bottom: 10, left: 16, right: 16, top: 0);
  }
}
