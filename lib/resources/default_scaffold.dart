import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hugeicons/hugeicons.dart';

/// A modern, premium default scaffold widget with customizable app bar
/// and optional back navigation button.
///
/// Features:
/// - No app bar shadow for a clean, modern look
/// - Optional back arrow button with customizable action
/// - Premium, minimalist design
/// - Flexible configuration options
class DefaultScaffold extends StatelessWidget {
  /// The main content of the scaffold
  final Widget body;

  /// Optional title to display in the app bar
  final String? title;

  /// Whether to show the back arrow button
  final bool showBackButton;

  /// Custom function to execute when back button is pressed.
  /// If null, defaults to Navigator.pop()
  final VoidCallback? onBackPressed;

  /// Optional leading widget (replaces back button if provided)
  final Widget? leading;

  /// Optional list of action widgets to display in the app bar
  final List<Widget>? actions;

  /// Background color of the scaffold
  final Color? backgroundColor;

  /// Background color of the app bar
  final Color? appBarBackgroundColor;

  /// Whether to extend the body behind the app bar
  final bool extendBodyBehindAppBar;

  /// Optional floating action button
  final Widget? floatingActionButton;

  /// Optional bottom navigation bar
  final Widget? bottomNavigationBar;

  /// Optional drawer
  final Widget? drawer;

  /// Optional end drawer
  final Widget? endDrawer;

  /// Whether the app bar should automatically imply leading widget
  final bool automaticallyImplyLeading;

  /// Custom app bar height
  final double? appBarHeight;

  /// Padding for the body content
  final EdgeInsetsGeometry? bodyPadding;

  /// Whether to show a loading overlay on the body
  final bool busy;

  final bool showSafeAreaTop;

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
    this.extendBodyBehindAppBar = false,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.automaticallyImplyLeading = true,
    this.appBarHeight,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isLightMode = theme.brightness == Brightness.light;
    final Color appBarBackgroundColor = isLightMode
        ? LightColors.backgroundSurfacePrimaryBG
        : DarkColors.backgroundSurfacePrimaryBG;

    // Determine if we should show the back button
    final shouldShowBackButton =
        showBackButton &&
        (leading == null) &&
        (Navigator.of(context).canPop() || onBackPressed != null);

    // Build the leading widget
    Widget? leadingWidget;
    if (leading != null) {
      leadingWidget = leading;
    } else if (shouldShowBackButton) {
     leadingWidget = GestureDetector(
        onTap: onBackPressed ?? () => _defaultPop(context),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          size: 24.0,
          color: isLightMode
              ? LightColors.textTextInverted
              : DarkColors.textTextInverted,
          strokeWidth: 1.5,
        ),
      );
    }

    // Determine if app bar exists
    final hasAppBar =
        title != null ||
        shouldShowBackButton ||
        leading != null ||
        actions != null;

    return Scaffold(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: hasAppBar
          ? AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor:
                  appBarBackgroundColor, // Match scaffold background
              surfaceTintColor: Colors.transparent, // Remove tint effect
              leading: leadingWidget,
              automaticallyImplyLeading:
                  automaticallyImplyLeading &&
                  (leadingWidget != null || shouldShowBackButton),
              title: title != null
                  ? AppText(
                      title!,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    )
                  : null,
              actions: actions,
              toolbarHeight: appBarHeight,
              centerTitle: false,
            )
          : null,
      body: SafeArea(
        bottom: false,
        top: showSafeAreaTop,

        child: Stack(
          children: [
            SizedBox.expand(child: body),

            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
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
    ).paddingSymmetric(horizontal: 16, vertical: 24);
  }
}
