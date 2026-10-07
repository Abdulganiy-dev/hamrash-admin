import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/utils/extensions.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

/// Glass list sheet with multi-select state. Returns the final selection as a
/// `List<I>` when the user dismisses the sheet. The caller commits the list
/// to its source of truth after [show] resolves.
abstract final class MultiSelectBottomSheet {
  MultiSelectBottomSheet._();

  static Future<List<I>?> show<I>({
    required BuildContext context,
    required List<I> items,
    required List<I> initiallySelected,
    required Widget headerImage,
    required String title,
    String Function(I item)? labelBuilder,
    SheetSnappingConfig snappingConfig = const SheetSnappingConfig([0.7, 1.0]),
    bool originateAboveBottomViewInset = true,
    RouteSnapshotMode backgroundSnapshotMode = RouteSnapshotMode.always,
  }) {
    return Navigator.of(context).push<List<I>>(
      StupidSimpleGlassSheetRoute<List<I>>(
        snappingConfig: snappingConfig,
        originateAboveBottomViewInset: originateAboveBottomViewInset,
        backgroundSnapshotMode: backgroundSnapshotMode,
        child: Material(
          type: MaterialType.transparency,
          child: _MultiSelectBody<I>(
            headerImage: headerImage,
            title: title,
            items: items,
            initiallySelected: initiallySelected,
            labelBuilder: labelBuilder,
          ),
        ),
      ),
    );
  }
}

class _MultiSelectBody<I> extends StatefulWidget {
  const _MultiSelectBody({
    required this.headerImage,
    required this.title,
    required this.items,
    required this.initiallySelected,
    required this.labelBuilder,
  });

  final Widget headerImage;
  final String title;
  final List<I> items;
  final List<I> initiallySelected;
  final String Function(I item)? labelBuilder;

  @override
  State<_MultiSelectBody<I>> createState() => _MultiSelectBodyState<I>();
}

class _MultiSelectBodyState<I> extends State<_MultiSelectBody<I>> {
  late final Set<I> _selected = {...widget.initiallySelected};

  void _toggle(I item) {
    HapticHelpers.vibrate(VibrationType.selection);
    setState(() {
      if (!_selected.add(item)) _selected.remove(item);
    });
  }

  void _close() => Navigator.of(context).maybePop(_selected.toList());

  String _label(I item) => widget.labelBuilder?.call(item) ?? item.toString();

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor;
    final selectedCount = _selected.length;

    return PopScope<List<I>>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_selected.toList());
      },
      child: Column(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      widget.headerImage,
                      SizedBox(height: AppSpacing.sm),
                      AppText(
                        widget.title,
                        colorType: AppTextColor.textInverted,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (selectedCount > 0)
                        AppText(
                          '$selectedCount selected',
                          colorType: AppTextColor.textMute,
                          fontSize: 12,
                        ).padding(top: 2),
                    ],
                  ),
                ),
                AppHugeIconButton(
                  lucidIcon: LucideIcons.check,
                  lucidIconSize: 22,
                  foregroundColorType: AppButtonForegroundColor.textInverted,
                  padding: EdgeInsets.zero,
                  onPressed: _close,
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor)
              .padding(top: AppSpacing.md),
          Flexible(
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
              ),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = _selected.contains(item);
                return _MultiSelectTile(
                  label: _label(item),
                  isSelected: isSelected,
                  onTap: () => _toggle(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiSelectTile extends StatelessWidget {
  const _MultiSelectTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      title: AppText(label, colorType: AppTextColor.textInverted),
      trailing: _Checkbox(isSelected: isSelected),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final unselectedBorder = isLight
        ? LightColors.strokeColourStrokeMild
        : DarkColors.strokeColourStrokeMild;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isSelected ? LightColors.primaryPrimaryDefault : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? LightColors.primaryPrimaryDefault : unselectedBorder,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}
