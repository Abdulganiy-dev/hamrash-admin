import 'package:flutter/material.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

/// A reusable glass bottom sheet with a title, close control, and custom [body].
///
/// Built on [StupidSimpleGlassSheetRoute] (same stack as [WarningModal] and
/// [ListBottomSheet]).
///
/// ```dart
/// GlassSheet.show(
///   context,
///   title: 'Edit subject',
///   body: CreateEditSubjectForm(),
/// );
/// ```
class GlassSheet extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onDismiss;

  const GlassSheet({
    super.key,
    required this.title,
    required this.body,
    this.onDismiss,
  });

  static Future<R?> show<R>({
    required BuildContext context,
    required String title,
    required Widget body,
    SheetSnappingConfig snappingConfig = const SheetSnappingConfig([
      0.5,
      0.9,
    ]),
    bool originateAboveBottomViewInset = true,
    RouteSnapshotMode backgroundSnapshotMode = RouteSnapshotMode.always,
    VoidCallback? onDismiss,
  }) async {
    HapticHelpers.vibrate(VibrationType.selection);

    final result = await Navigator.of(context).push<R>(
      StupidSimpleGlassSheetRoute<R>(
        snappingConfig: snappingConfig,
        originateAboveBottomViewInset: originateAboveBottomViewInset,
        backgroundSnapshotMode: backgroundSnapshotMode,
        child: Material(
          type: MaterialType.transparency,
          child: GlassSheet(
            title: title,
            body: body,
            onDismiss: onDismiss,
          ),
        ),
      ),
    );

    onDismiss?.call();
    return result;
  }

  void _close(BuildContext context) {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor;

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                hugeIcon: HugeIcons.strokeRoundedCancel01,
                hugeIconStrokeWidth: 2,
                hugeIconRasterSize: 28,
                foregroundColorType: AppButtonForegroundColor.textInverted,
                padding: EdgeInsets.zero,
                onPressed: () => _close(context),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: dividerColor)
            .padding(top: AppSpacing.md),
        Flexible(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              MediaQuery.paddingOf(context).bottom + AppSpacing.lgXl,
            ),
            child: body,
          ),
        ),
      ],
    );
  }
}
