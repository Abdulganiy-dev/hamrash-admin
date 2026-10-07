import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/utils/extensions.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

/// Snap presets for the three sheet categories used across the app.
///
/// * [compact] — utility / menu sheets (short, content-sized).
/// * [detail] — read-only detail sheets (open near full height).
/// * [form] — input sheets (full height, keyboard-aware).
///
/// Pass an explicit `snappingConfig` to [GlassSheet.show] to override.
enum GlassSheetSize { compact, detail, form }

extension on GlassSheetSize {
  SheetSnappingConfig get snapping => switch (this) {
    GlassSheetSize.compact => const SheetSnappingConfig([0.45]),
    GlassSheetSize.detail => const SheetSnappingConfig([0.9, 1.0]),
    GlassSheetSize.form => const SheetSnappingConfig([1.0]),
  };
}

/// A reusable glass bottom sheet: a header (optional [leadingIcon] + [title] +
/// close button), a divider, a scrollable [body], and an optional pinned
/// [footer] (e.g. a form's submit button, which stays above the keyboard).
///
/// This is the single shell behind the app's detail / form / utility sheets —
/// callers supply only the content view and a [GlassSheetSize].
///
/// ```dart
/// // Detail (read-only)
/// GlassSheet.show(
///   context: context,
///   title: 'Alert Details',
///   size: GlassSheetSize.detail,
///   leadingIcon: LucideIcons.triangleAlert,
///   leadingIconColor: LightColors.warningWarningDefault,
///   body: AlertDetailContent(alert: alert),
/// );
///
/// // Form (pinned submit button; the handler shows SuccessModal)
/// GlassSheet.show(
///   context: context,
///   title: 'Create Announcement',
///   size: GlassSheetSize.form,
///   leadingIcon: LucideIcons.fileText,
///   body: AnnouncementForm(viewModel: vm),
///   footer: AppPrimaryButton(onPressed: submit, child: AppText('Submit')),
/// );
/// ```
class GlassSheet extends StatelessWidget {
  final String title;

  /// Optional helper line shown beneath the title in the header.
  final String? subtitle;

  final Widget body;

  /// Optional icon shown before the title in the header.
  final IconData? leadingIcon;
  final Color? leadingIconColor;

  /// Optional widget pinned below the scrollable body (stays above the
  /// keyboard). Typically a form's primary action button.
  final Widget? footer;

  /// Whether to wrap [body] in a scroll view. Defaults to true.
  final bool scrollableBody;

  final VoidCallback? onDismiss;

  const GlassSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.leadingIcon,
    this.leadingIconColor,
    this.footer,
    this.scrollableBody = true,
    this.onDismiss,
  });

  static Future<R?> show<R>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget body,
    GlassSheetSize size = GlassSheetSize.detail,
    IconData? leadingIcon,
    Color? leadingIconColor,
    Widget? footer,
    bool scrollableBody = true,
    SheetSnappingConfig? snappingConfig,
    bool originateAboveBottomViewInset = true,
    RouteSnapshotMode backgroundSnapshotMode = RouteSnapshotMode.always,
    VoidCallback? onDismiss,
  }) async {
    final result = await Navigator.of(context).push<R>(
      StupidSimpleGlassSheetRoute<R>(
        snappingConfig: snappingConfig ?? size.snapping,
        originateAboveBottomViewInset: originateAboveBottomViewInset,
        backgroundSnapshotMode: backgroundSnapshotMode,
        child: Material(
          type: MaterialType.transparency,
          child: GlassSheet(
            title: title,
            subtitle: subtitle,
            body: body,
            leadingIcon: leadingIcon,
            leadingIconColor: leadingIconColor,
            footer: footer,
            scrollableBody: scrollableBody,
            onDismiss: onDismiss,
          ),
        ),
      ),
    );

    onDismiss?.call();
    return result;
  }

  void _close(BuildContext context) => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    // When a footer is pinned it owns the bottom inset; otherwise the
    // scrollable body carries it so content clears the keyboard / home bar.
    final bodyBottomPadding = footer != null
        ? AppSpacing.md
        : bottomInset + safeBottom + AppSpacing.lg;
    final bodyPadding = EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      bodyBottomPadding,
    );

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(
                      leadingIcon,
                      color: leadingIconColor ?? LightColors.primaryPrimaryDefault,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: AppText(
                      title,
                      colorType: AppTextColor.textInverted,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppHugeIconButton(
                    lucidIcon: LucideIcons.x,
                    lucidIconSize: 22,
                    foregroundColorType: AppButtonForegroundColor.textInverted,
                    padding: EdgeInsets.zero,
                    onPressed: () => _close(context),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  subtitle!,
                  colorType: AppTextColor.textMute,
                  fontSize: 13,
                  softWrap: true,
                ),
              ],
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: dividerColor,
        ).padding(top: AppSpacing.md),
        Expanded(
          child: scrollableBody
              ? SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: bodyPadding,
                  child: body,
                )
              : Padding(padding: bodyPadding, child: body),
        ),
        if (footer != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              bottomInset + safeBottom + AppSpacing.lg,
            ),
            child: footer,
          ),
      ],
    );
  }
}
