import 'package:flutter/material.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/widgets/app_button.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hugeicons/hugeicons.dart';

enum DefaultScaffoldAppBarType { standard, custom, none }

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
      hugeIconRasterSize: 35,
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
        appBarContent = customAppBar != null
            ? SizedBox(height: appBarHeight, child: customAppBar!)
            : null;
        break;
      case DefaultScaffoldAppBarType.none:
        appBarContent = null;
        break;
    }

    final hasAppBarLayer = appBarContent != null;
    final bodyTopInset =
        topInset + (hasAppBarLayer ? appBarHeight + appBarFadeHeight : 0);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          body,
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
    ).padding(bottom: 10, left: 16, right: 16);
  }
}
