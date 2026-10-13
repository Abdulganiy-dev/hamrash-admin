import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_scroll_fade.dart';
import 'package:hamrash_admin/core/widgets/app_surface.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

/// How a sheet sits on the screen.
enum AppSheetSize {
  /// Short sheets (menus, pickers, results, confirmations): a card inset 8
  /// from the sides, resting just above the home indicator, with 32 corners
  /// and sized to its content.
  floating,

  /// Tall sheets (forms, filters, long or searchable lists): edge to edge
  /// with 24 top corners, filling the screen below the status bar.
  full,
}

/// Route for every sheet in the app. Built on `stupid_simple_sheet`'s plain
/// route, so it keeps the spring motion and scroll-to-drag hand-off, and
/// draws our own solid cream surface and espresso scrim.
///
/// Usually you call [AppSheet.show]; push this directly when the sheet needs
/// its own state (see the pickers in this folder).
class AppSheetRoute<T> extends StupidSimpleSheetRoute<T> {
  AppSheetRoute({
    required Widget child,
    this.size = AppSheetSize.full,
    bool dismissible = true,
    super.draggable,
    super.snappingConfig,
    super.originateAboveBottomViewInset = true,
    super.backgroundSnapshotMode = RouteSnapshotMode.animating,
    super.settings,
  }) : super(
         barrierColor: _scrim,
         barrierDismissible: dismissible,
         child: _AppSheetFrame(size: size, child: child),
       );

  /// Espresso at 36%.
  static const _scrim = Color(0x5C2A1712);

  final AppSheetSize size;
}

/// Draws the sheet surface for [AppSheetRoute] and tells [AppSheet] which
/// size it is in.
class _AppSheetFrame extends StatelessWidget {
  const _AppSheetFrame({required this.size, required this.child});

  final AppSheetSize size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = Material(
      type: MaterialType.transparency,
      child: AppSurfaceScope(
        surface: AppSurface.card,
        child: _AppSheetSizeScope(size: size, child: child),
      ),
    );

    switch (size) {
      case AppSheetSize.floating:
        // Sit above the home indicator so the rounded screen corners never
        // clip the sheet. `padding` drops to 0 while the keyboard is open,
        // so the sheet then rests 8 above the keyboard instead.
        final bottom = math.max(8.0, MediaQuery.paddingOf(context).bottom);
        return SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, bottom),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: AppShadows.overlay,
              ),
              child: SheetBackground(
                backgroundColor: AppPalette.cream,
                extensionAtBottom: 0,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: content,
              ),
            ),
          ),
        );
      case AppSheetSize.full:
        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SheetBackground(
              backgroundColor: AppPalette.cream,
              shape: const RoundedSuperellipseBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: content,
            ),
          ),
        );
    }
  }
}

class _AppSheetSizeScope extends InheritedWidget {
  const _AppSheetSizeScope({required this.size, required super.child});

  final AppSheetSize size;

  @override
  bool updateShouldNotify(_AppSheetSizeScope oldWidget) =>
      size != oldWidget.size;
}

/// The inside of every sheet: grabber, header (title on the left, round
/// close button on the right), body and an optional pinned footer.
///
/// ```dart
/// // Form: full height, button pinned above the keyboard.
/// AppSheet.show(
///   context: context,
///   title: 'Record payment',
///   subtitle: 'A receipt goes to the guardian by SMS.',
///   body: RecordPaymentForm(viewModel: vm),
///   footer: AppPrimaryButton(onPressed: save, child: AppText('Save payment')),
/// );
///
/// // Menu: floating, sized to its content.
/// AppSheet.show(
///   context: context,
///   size: AppSheetSize.floating,
///   title: student.name,
///   body: AppRowGroup.inset(children: [...]),
/// );
/// ```
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.leading,
    this.footer,
    this.scrollableBody = true,
    this.showCloseButton = true,
    this.showGrabber = true,
    this.bodyPadding,
  });

  final String? title;

  /// Helper line under the title.
  final String? subtitle;

  /// Optional picture before the title, e.g. a student's avatar.
  final Widget? leading;

  final Widget body;

  /// Pinned below the body (stays above the keyboard). Usually one primary
  /// button, or a secondary + primary pair.
  final Widget? footer;

  /// Wrap [body] in a scroll view that fades out under the header once
  /// scrolled. Turn off when the body brings its own list (it must then size
  /// itself to the space it is given; wrap that list in [AppScrollFade]).
  final bool scrollableBody;

  final bool showCloseButton;

  /// The drag handle. Hide it on sheets that cannot be dragged.
  final bool showGrabber;

  /// Defaults to 16 on every side.
  final EdgeInsets? bodyPadding;

  static Future<R?> show<R>({
    required BuildContext context,
    required Widget body,
    String? title,
    String? subtitle,
    Widget? leading,
    Widget? footer,
    AppSheetSize size = AppSheetSize.full,
    bool scrollableBody = true,
    bool showCloseButton = true,
    bool dismissible = true,
    bool draggable = true,
    SheetSnappingConfig snappingConfig = SheetSnappingConfig.full,
    EdgeInsets? bodyPadding,
    VoidCallback? onDismiss,
  }) async {
    final result = await Navigator.of(context).push<R>(
      AppSheetRoute<R>(
        size: size,
        dismissible: dismissible,
        draggable: draggable,
        snappingConfig: snappingConfig,
        child: AppSheet(
          title: title,
          subtitle: subtitle,
          leading: leading,
          body: body,
          footer: footer,
          scrollableBody: scrollableBody,
          showCloseButton: showCloseButton,
          showGrabber: draggable,
          bodyPadding: bodyPadding,
        ),
      ),
    );
    onDismiss?.call();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final size =
        context
            .dependOnInheritedWidgetOfExactType<_AppSheetSizeScope>()
            ?.size ??
        AppSheetSize.full;
    final floating = size == AppSheetSize.floating;

    // Space below the last thing in the sheet: floating sheets end inside
    // their own card; full sheets clear the home indicator, or sit just
    // above the keyboard when it is open.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomGap = floating
        ? 20.0
        : (keyboardOpen ? 12.0 : MediaQuery.paddingOf(context).bottom + 12);

    final padding =
        bodyPadding ??
        EdgeInsets.fromLTRB(16, 16, 16, footer == null ? bottomGap : 16);

    final content = scrollableBody
        // Rows fade out under the header once the body scrolls.
        ? AppScrollFade(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: padding,
              child: body,
            ),
          )
        : Padding(padding: padding, child: body);

    final hasHeader = title != null || leading != null || showCloseButton;

    return Column(
      mainAxisSize: floating ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showGrabber) const _Grabber() else const SizedBox(height: 8),
        if (hasHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 10, 0),
            child: _Header(
              title: title,
              subtitle: subtitle,
              leading: leading,
              showCloseButton: showCloseButton,
            ),
          ),
        if (floating) Flexible(child: content) else Expanded(child: content),
        if (footer != null)
          DecoratedBox(
            decoration: BoxDecoration(
              border: floating
                  ? null
                  : const Border(top: BorderSide(color: AppPalette.stone100)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                floating ? 4 : 12,
                16,
                bottomGap,
              ),
              child: footer,
            ),
          ),
      ],
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: AppPalette.stone300,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.showCloseButton,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        crossAxisAlignment: subtitle == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Padding(
              // Line the title up with the middle of the close button.
              padding: EdgeInsets.only(top: subtitle == null ? 0 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    AppText(
                      title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3.copyWith(
                        color: LightColors.textStrong,
                      ),
                    ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: AppText(
                        subtitle!,
                        variant: AppTextVariant.body,
                        colorType: AppTextColor.textBody,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showCloseButton) ...[
            const SizedBox(width: 8),
            const AppSheetCloseButton(),
          ],
        ],
      ),
    );
  }
}

/// Round stone-100 close button used in sheet headers. 36 visible, 44 to
/// tap. Pops the sheet with no result.
class AppSheetCloseButton extends StatelessWidget {
  const AppSheetCloseButton({super.key, this.onPressed});

  /// Defaults to closing the sheet.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: BouncyButton(
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppPalette.stone100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.x500,
                size: 18,
                color: AppPalette.stone700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
