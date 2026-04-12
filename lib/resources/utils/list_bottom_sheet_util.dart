import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

typedef ListBottomSheetItemBuilder<I> =
    Widget Function(BuildContext context, I item, int index);

/// Glass list sheet built on [StupidSimpleGlassSheetRoute] (not [showModalBottomSheet]).
abstract final class ListBottomSheet {
  ListBottomSheet._();

  /// Opens a glass sheet with a header (image, title, close), divider, and a scrollable list.
  ///
  /// [headerImage] sits above [title]; the close control is aligned to the trailing side
  /// of that block. [items] are rendered with [itemBuilder].
  static Future<R?> show<R, I>({
    required BuildContext context,
    required List<I> items,
    required ListBottomSheetItemBuilder<I> itemBuilder,
    required Widget headerImage,
    required String title,
    SheetSnappingConfig snappingConfig = const SheetSnappingConfig([0.45, 1.0]),
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
                hugeIcon: HugeIcons.strokeRoundedCancel01,
                hugeIconStrokeWidth: 2,
                hugeIconRasterSize: 28,
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
            padding: EdgeInsets.only(
             
              top: AppSpacing.sm,
              bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
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
