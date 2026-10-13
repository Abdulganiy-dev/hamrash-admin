import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_rows.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

typedef ListBottomSheetItemBuilder<I> =
    Widget Function(BuildContext context, I item, int index);

/// Sheet showing a short list of rows in one stone-50 group.
///
/// Up to [floatingLimit] items it floats and sizes to its content; longer
/// lists open as a full sheet.
abstract final class ListBottomSheet {
  ListBottomSheet._();

  /// Lists that fit in a floating sheet.
  static const floatingLimit = 6;

  /// Any rows you build, usually [AppSelectionRow]s.
  static Future<R?> show<R, I>({
    required BuildContext context,
    required List<I> items,
    required ListBottomSheetItemBuilder<I> itemBuilder,
    required String title,
    String? subtitle,
    AppSheetSize? size,
    SheetSnappingConfig snappingConfig = SheetSnappingConfig.full,
  }) {
    return Navigator.of(context).push<R>(
      AppSheetRoute<R>(
        size:
            size ??
            (items.length <= floatingLimit
                ? AppSheetSize.floating
                : AppSheetSize.full),
        snappingConfig: snappingConfig,
        child: Builder(
          builder: (context) => AppSheet(
            title: title,
            subtitle: subtitle,
            body: AppRowGroup.inset(
              children: [
                for (var i = 0; i < items.length; i++)
                  itemBuilder(context, items[i], i),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pick one: each row has a radio; tapping a row picks it and closes.
  ///
  /// ```dart
  /// ListBottomSheet.showSelectable(
  ///   context: context,
  ///   title: 'Choose term',
  ///   items: terms,
  ///   currentValue: model.term,
  ///   labelBuilder: (t) => t.name,
  ///   subtitleBuilder: (t) => t.dates,
  ///   onSelected: model.setTerm,
  /// );
  /// ```
  static Future<void> showSelectable<I>({
    required BuildContext context,
    required List<I> items,
    required I? currentValue,
    required ValueChanged<I> onSelected,
    required String title,
    String? subtitle,
    String Function(I item)? labelBuilder,
    String Function(I item)? subtitleBuilder,
    AppSheetSize? size,
  }) {
    return show<void, I>(
      context: context,
      title: title,
      subtitle: subtitle,
      size: size,
      items: items,
      itemBuilder: (context, item, index) {
        final selected = currentValue == item;
        return AppSelectionRow(
          title: labelBuilder?.call(item) ?? item.toString(),
          subtitle: subtitleBuilder?.call(item),
          control: AppRadio<I>(value: item, groupValue: currentValue),
          onTap: () {
            if (!selected) onSelected(item);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
