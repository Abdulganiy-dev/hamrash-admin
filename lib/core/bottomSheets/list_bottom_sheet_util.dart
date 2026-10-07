import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/utils/extensions.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/haptic_list_tile.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

typedef ListBottomSheetItemBuilder<I> =
    Widget Function(BuildContext context, I item, int index);


abstract final class ListBottomSheet {
  ListBottomSheet._();


  static Future<R?> show<R, I>({
    required BuildContext context,
    required List<I> items,
    required ListBottomSheetItemBuilder<I> itemBuilder,
    required Widget headerImage,
    required String title,
    SheetSnappingConfig snappingConfig = const SheetSnappingConfig([0.5, 1.0]),
    bool originateAboveBottomViewInset = true,
    RouteSnapshotMode backgroundSnapshotMode = RouteSnapshotMode.always,
  }) {
    return Navigator.of(context).push<R>(
      StupidSimpleGlassSheetRoute<R>(
        snappingConfig: snappingConfig,
        originateAboveBottomViewInset: originateAboveBottomViewInset,
        backgroundSnapshotMode: backgroundSnapshotMode,
        child: Material(
          type: MaterialType.transparency,
          child: _ListBottomSheetBody<I>(
            headerImage: headerImage,
            title: title,
            items: items,
            itemBuilder: itemBuilder,
          ),
        ),
      ),
    );
  }

 
  static Future<void> showSelectable<I>({
    required BuildContext context,
    required List<I> items,
    required I? currentValue,
    required ValueChanged<I> onSelected,
    required IconData headerIcon,
    required String title,
    String Function(I item)? labelBuilder,
    SheetSnappingConfig snappingConfig = const SheetSnappingConfig([0.5, 1.0]),
    bool originateAboveBottomViewInset = true,
    RouteSnapshotMode backgroundSnapshotMode = RouteSnapshotMode.animating,
  }) {
    return show<void, I>(
      context: context,
      title: title,
      snappingConfig: snappingConfig,
      originateAboveBottomViewInset: originateAboveBottomViewInset,
      backgroundSnapshotMode: backgroundSnapshotMode,
      headerImage: Icon(headerIcon, color: LightColors.primaryPrimaryDefault, size: 28),
      items: items,
      itemBuilder: (context, item, index) {
        final isSelected = currentValue == item;
        final label = labelBuilder?.call(item) ?? item.toString();
        return HapticListTile(
          title: AppText(
            label,
            colorType: AppTextColor.textInverted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          trailing: isSelected
              ? Icon(
                  LucideIcons.circleCheck,
                  color: LightColors.primaryPrimaryDefault,
                  size: 22,
                )
              : null,
          onTap: () {
            onSelected(item);
            NavigationService.popScreen();
          },
        );
      },
    );
  }
}

class _ListBottomSheetBody<I> extends StatelessWidget {
  const _ListBottomSheetBody({
    required this.headerImage,
    required this.title,
    required this.items,
    required this.itemBuilder,
  });

  final Widget headerImage;
  final String title;
  final List<I> items;
  final ListBottomSheetItemBuilder<I> itemBuilder;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    headerImage,
                    SizedBox(height: AppSpacing.sm),
                    AppText(
                      title,
                      colorType: AppTextColor.textInverted,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppHugeIconButton(
                lucidIcon: LucideIcons.x,
                lucidIconSize: 22,
                foregroundColorType: AppButtonForegroundColor.textInverted,
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).maybePop(),
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
            itemCount: items.length,
            itemBuilder: (context, index) {
              return itemBuilder(context, items[index], index);
            },
          ),
        ),
      ],
    );
  }
}
