import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/list_bottom_sheet_util.dart';
import 'package:hamrash_admin/core/bottomSheets/multi_select_bottom_sheet_util.dart';
import 'package:hamrash_admin/core/bottomSheets/paginated_list_bottom_sheet_util.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/widgets/app_field_style.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The box every picker field draws: looks like [AppTextField] (label above,
/// 48 tall, helper or error below) but opens a sheet when tapped.
///
/// While the sheet from [onTap] is up the border turns aubergine and a chevron
/// flips up, so it's clear which field is being changed. Errors clear when
/// the field is tapped, like text fields.
///
/// Prefer the typed fields: [AppSelectField], [AppMultiSelectField],
/// [AppDateField], [AppDateRangeField] and [AppTimeField].
class AppPickerField extends StatefulWidget {
  const AppPickerField({
    super.key,
    required this.label,
    required this.onTap,
    this.valueText,
    this.valueChild,
    this.placeholder,
    this.icon = LucideIcons.chevronDown,
    this.isOptional = false,
    this.helperText,
    this.warningText,
    this.errorText,
    this.validator,
    this.enabled = true,
    this.animateChanges = false,
  });

  final String label;

  /// Opens the picker. The field shows as open until the returned future
  /// completes (i.e. until the sheet closes).
  final Future<void> Function() onTap;

  /// The chosen value as text. Null or empty shows [placeholder].
  final String? valueText;

  /// Draws the value instead of [valueText], e.g. names with a "+3" pill.
  final Widget? valueChild;

  final String? placeholder;

  /// Chevron for lists, calendar for dates, clock for times. Disabled
  /// fields show a lock instead.
  final IconData icon;

  /// Adds a muted "(optional)" after the label.
  final bool isOptional;

  final String? helperText;

  /// Non-blocking date or value warning, shown in amber.
  final String? warningText;

  /// Error from outside (e.g. the API). Hidden once the field is tapped.
  final String? errorText;

  /// Checked by the surrounding [Form] on validate, like a text field's.
  final String? Function()? validator;

  final bool enabled;

  /// Animates value and supporting text changes within this field.
  final bool animateChanges;

  @override
  State<AppPickerField> createState() => _AppPickerFieldState();
}

class _AppPickerFieldState extends State<AppPickerField> {
  final _fieldKey = GlobalKey<FormFieldState<Object?>>();
  bool _open = false;
  bool _hideExternalError = false;

  @override
  void didUpdateWidget(AppPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != oldWidget.errorText) _hideExternalError = false;
  }

  Future<void> _handleTap() async {
    if (_open) return;
    setState(() {
      _open = true;
      _hideExternalError = true;
    });
    final field = _fieldKey.currentState;
    if (field != null && field.hasError) field.clearError();
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _open = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<Object?>(
      key: _fieldKey,
      validator: widget.validator == null ? null : (_) => widget.validator!(),
      builder: (field) {
        final error =
            (_hideExternalError ? null : widget.errorText) ?? field.errorText;
        final footer = error != null
            ? _Footer.error(error)
            : widget.warningText != null
            ? _Footer.warning(widget.warningText!)
            : widget.helperText != null
            ? _Footer.helper(widget.helperText!)
            : const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label(
              text: widget.label,
              isOptional: widget.isOptional,
              enabled: widget.enabled,
            ),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              enabled: widget.enabled,
              label: widget.label,
              value: widget.valueText,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.enabled ? _handleTap : null,
                child: _Box(
                  open: _open,
                  hasError: error != null,
                  hasWarning: error == null && widget.warningText != null,
                  enabled: widget.enabled,
                  icon: widget.icon,
                  valueText: widget.valueText,
                  valueChild: widget.valueChild,
                  placeholder: widget.placeholder,
                  animateChanges: widget.animateChanges,
                ),
              ),
            ),
            if (widget.animateChanges)
              AnimatedSize(
                duration: _changeDuration(context),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: _changeDuration(context),
                  layoutBuilder: _startAligned,
                  child: KeyedSubtree(
                    key: ValueKey((
                      error,
                      widget.warningText,
                      widget.helperText,
                    )),
                    child: footer,
                  ),
                ),
              )
            else if (footer is! SizedBox)
              footer,
          ],
        );
      },
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.open,
    required this.hasError,
    required this.hasWarning,
    required this.enabled,
    required this.icon,
    required this.valueText,
    required this.valueChild,
    required this.placeholder,
    required this.animateChanges,
  });

  final bool open;
  final bool hasError;
  final bool hasWarning;
  final bool enabled;
  final IconData icon;
  final String? valueText;
  final Widget? valueChild;
  final String? placeholder;
  final bool animateChanges;

  @override
  Widget build(BuildContext context) {
    final hasValue =
        valueChild != null || (valueText != null && valueText!.isNotEmpty);
    final Color borderColor;
    final double borderWidth;
    if (hasError) {
      borderColor = AppFieldStyle.errorBorder(context);
      borderWidth = 1.5;
    } else if (hasWarning) {
      borderColor = LightColors.warningWarningDefault;
      borderWidth = 1.5;
    } else if (open) {
      borderColor = AppFieldStyle.focusBorder(context);
      borderWidth = 1.5;
    } else {
      borderColor = AppFieldStyle.restBorder(context);
      borderWidth = 1;
    }

    final isChevron = icon == LucideIcons.chevronDown;
    final Widget trailing = !enabled
        ? Icon(
            LucideIcons.lock,
            size: AppFieldStyle.iconSize,
            color: AppFieldStyle.placeholder(context),
          )
        : AnimatedRotation(
            turns: open && isChevron ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Icon(
              icon,
              size: AppFieldStyle.iconSize,
              color: open
                  ? AppFieldStyle.focusBorder(context)
                  : AppFieldStyle.icon(context),
            ),
          );

    final value = hasValue
        ? valueChild ??
              AppText(
                valueText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppFieldStyle.text(context, enabled: enabled),
                ),
              )
        : AppText(
            placeholder ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyLarge.copyWith(
              color: AppFieldStyle.placeholder(context),
            ),
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: const BoxConstraints(minHeight: AppFieldStyle.height),
      padding: const EdgeInsets.only(left: 16, right: 14),
      decoration: BoxDecoration(
        color: AppFieldStyle.fill(
          context,
          enabled: enabled,
          active: open || hasError,
        ),
        borderRadius: AppRadius.brControl,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Row(
        children: [
          Expanded(
            child: animateChanges
                ? AnimatedSwitcher(
                    duration: _changeDuration(context),
                    layoutBuilder: _startAligned,
                    child: KeyedSubtree(
                      key: ValueKey(valueText ?? placeholder ?? ''),
                      child: value,
                    ),
                  )
                : value,
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

/// AnimatedSwitcher centres its children by default; field values and the
/// lines under them read from the start.
Widget _startAligned(Widget? current, List<Widget> previous) => Stack(
  alignment: AlignmentDirectional.centerStart,
  children: [...previous, ?current],
);

Duration _changeDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 220);

class _Label extends StatelessWidget {
  const _Label({
    required this.text,
    required this.isOptional,
    required this.enabled,
  });

  final String text;
  final bool isOptional;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.subtitle.copyWith(
      color: AppFieldStyle.text(context, enabled: enabled),
    );
    if (!isOptional) return AppText(text, style: style);
    return Text.rich(
      TextSpan(
        text: text,
        style: style,
        children: [
          TextSpan(
            text: '  (optional)',
            style: AppTypography.body.copyWith(color: LightColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer.error(this.text) : tone = _FooterTone.error;
  const _Footer.warning(this.text) : tone = _FooterTone.warning;
  const _Footer.helper(this.text) : tone = _FooterTone.helper;

  final String text;
  final _FooterTone tone;

  @override
  Widget build(BuildContext context) {
    if (tone == _FooterTone.helper) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AppText(
          text,
          maxLines: 5,
          style: AppTypography.caption.copyWith(color: LightColors.textMuted),
        ),
      );
    }
    final warning = tone == _FooterTone.warning;
    final color = warning
        ? LightColors.warningWarningText
        : LightColors.errorErrorText;
    if (warning) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AppText(
          text,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.circleAlert500, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: AppText(
              text,
              style: AppTypography.caption.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

enum _FooterTone { helper, warning, error }

/// Pick one item. Opens the list sheet (floating up to 6 items, full
/// above), or with [AppSelectField.search] the searchable, paged sheet for
/// server data.
///
/// ```dart
/// AppSelectField<SchoolClass>(
///   label: 'Class',
///   placeholder: 'Choose a class',
///   value: model.schoolClass,
///   items: model.classes,
///   labelBuilder: (c) => c.name,
///   onChanged: model.setClass,
///   validator: (c) => c == null ? 'Pick the class this student joins.' : null,
/// )
/// ```
class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required List<T> this.items,
    required this.onChanged,
    this.labelBuilder,
    this.subtitleBuilder,
    this.placeholder = 'Choose…',
    this.sheetTitle,
    this.isOptional = false,
    this.helperText,
    this.errorText,
    this.validator,
    this.enabled = true,
  }) : loadPage = null,
       idBuilder = null,
       cacheKey = null,
       searchHint = null,
       onCleared = null;

  /// Searches and pages through [loadPage] (e.g. teachers from the API).
  /// [cacheKey] keeps loaded pages between openings.
  const AppSelectField.search({
    super.key,
    required this.label,
    required this.value,
    required PaginatedListLoader<T> this.loadPage,
    required String Function(T) this.idBuilder,
    required Object this.cacheKey,
    required this.onChanged,
    this.labelBuilder,
    this.subtitleBuilder,
    this.searchHint = 'Search…',
    this.onCleared,
    this.placeholder = 'Choose…',
    this.sheetTitle,
    this.isOptional = false,
    this.helperText,
    this.errorText,
    this.validator,
    this.enabled = true,
  }) : items = null;

  final String label;
  final T? value;
  final List<T>? items;
  final ValueChanged<T> onChanged;
  final String Function(T item)? labelBuilder;
  final String Function(T item)? subtitleBuilder;
  final String placeholder;

  /// Defaults to [label].
  final String? sheetTitle;
  final bool isOptional;
  final String? helperText;
  final String? errorText;
  final String? Function(T? value)? validator;
  final bool enabled;

  final PaginatedListLoader<T>? loadPage;
  final String Function(T item)? idBuilder;
  final Object? cacheKey;
  final String? searchHint;

  /// Search mode only: shows a "Clear selection" action.
  final VoidCallback? onCleared;

  String _label(T item) => labelBuilder?.call(item) ?? item.toString();

  Future<void> _open(BuildContext context) {
    final title = sheetTitle ?? label;
    if (items != null) {
      return ListBottomSheet.showSelectable<T>(
        context: context,
        title: title,
        items: items!,
        currentValue: value,
        labelBuilder: _label,
        subtitleBuilder: subtitleBuilder,
        onSelected: onChanged,
      );
    }
    return PaginatedListBottomSheet.showSelectable<T>(
      context: context,
      title: title,
      loadPage: loadPage!,
      idBuilder: idBuilder!,
      cacheKey: cacheKey!,
      labelBuilder: _label,
      subtitleBuilder: subtitleBuilder,
      searchHint: searchHint!,
      currentValue: value,
      onSelected: onChanged,
      onCleared: onCleared,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = value;
    return AppPickerField(
      label: label,
      valueText: current == null ? null : _label(current),
      placeholder: placeholder,
      isOptional: isOptional,
      helperText: helperText,
      errorText: errorText,
      validator: validator == null ? null : () => validator!(value),
      enabled: enabled,
      onTap: () => _open(context),
    );
  }
}

/// Pick several items from the multi-select sheet. Shows the names that
/// fit, then a "+N" pill for the rest.
///
/// ```dart
/// AppMultiSelectField<Subject>(
///   label: 'Subjects taught',
///   values: model.subjects,
///   items: model.allSubjects,
///   labelBuilder: (s) => s.name,
///   onChanged: model.setSubjects,
/// )
/// ```
class AppMultiSelectField<T> extends StatelessWidget {
  const AppMultiSelectField({
    super.key,
    required this.label,
    required this.values,
    required this.items,
    required this.onChanged,
    this.labelBuilder,
    this.subtitleBuilder,
    this.placeholder = 'Choose…',
    this.sheetTitle,
    this.showSelectAll = true,
    this.isOptional = false,
    this.helperText,
    this.errorText,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final List<T> values;
  final List<T> items;
  final ValueChanged<List<T>> onChanged;
  final String Function(T item)? labelBuilder;
  final String Function(T item)? subtitleBuilder;
  final String placeholder;

  /// Defaults to [label].
  final String? sheetTitle;
  final bool showSelectAll;
  final bool isOptional;
  final String? helperText;
  final String? errorText;
  final String? Function(List<T> values)? validator;
  final bool enabled;

  String _label(T item) => labelBuilder?.call(item) ?? item.toString();

  @override
  Widget build(BuildContext context) {
    final names = values.map(_label).toList();
    return AppPickerField(
      label: label,
      valueText: names.join(', '),
      valueChild: names.isEmpty
          ? null
          : _NamesThatFit(
              names: names,
              style: AppTypography.bodyLarge.copyWith(
                color: AppFieldStyle.text(context, enabled: enabled),
              ),
            ),
      placeholder: placeholder,
      isOptional: isOptional,
      helperText: helperText,
      errorText: errorText,
      validator: validator == null ? null : () => validator!(values),
      enabled: enabled,
      onTap: () async {
        final picked = await MultiSelectBottomSheet.show<T>(
          context: context,
          title: sheetTitle ?? label,
          items: items,
          initiallySelected: values,
          labelBuilder: _label,
          subtitleBuilder: subtitleBuilder,
          showSelectAll: showSelectAll,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

/// As many names as fit on one line, then a stone pill counting the rest.
class _NamesThatFit extends StatelessWidget {
  const _NamesThatFit({required this.names, required this.style});

  final List<String> names;
  final TextStyle style;

  static const _pillGap = 8.0;
  static const _pillPadding = 16.0;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final pillStyle = AppTypography.label.copyWith(
      fontWeight: FontWeight.w700,
      color: LightColors.textBody,
    );

    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        var shown = 1;
        for (var k = names.length; k >= 1; k--) {
          final rest = names.length - k;
          final pill = rest == 0
              ? 0.0
              : _pillGap + _pillPadding + measure('+$rest', pillStyle);
          if (measure(names.take(k).join(', '), style) + pill <=
              constraints.maxWidth) {
            shown = k;
            break;
          }
        }
        final rest = names.length - shown;
        return Row(
          children: [
            Flexible(
              child: AppText(
                names.take(shown).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            if (rest > 0) ...[
              const SizedBox(width: _pillGap),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _pillPadding / 2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.stone100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AppText('+$rest', style: pillStyle),
              ),
            ],
          ],
        );
      },
    );
  }
}
