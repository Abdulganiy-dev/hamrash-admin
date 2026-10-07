import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:flutter/material.dart';

/// A single option inside an [AppSegmentedControl].
///
/// `value` is what the parent receives in `onChanged`. `label` is what the
/// user sees. `icon` is rendered to the left of the label when provided.
class AppSegmentOption<T> {
  const AppSegmentOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// Horizontal segmented control with rounded outlined pills.
///
/// Each option fills the available width equally. The currently-selected pill
/// uses the primary accent for fill, border, and content. Tapping fires a
/// selection haptic and calls [onChanged] with that option's value.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.height = 48,
    this.gap,
  });

  final List<AppSegmentOption<T>> options;
  final T? selected;
  final ValueChanged<T> onChanged;
  final double height;
  final double? gap;

  @override
  Widget build(BuildContext context) {
    final spacing = gap ?? AppSpacing.sm;
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          Expanded(
            child: _SegmentButton<T>(
              option: options[i],
              isSelected: selected == options[i].value,
              height: height,
              onTap: () {
                HapticHelpers.vibrate(VibrationType.selection);
                onChanged(options[i].value);
              },
            ),
          ),
          if (i < options.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.option,
    required this.isSelected,
    required this.height,
    required this.onTap,
  });

  final AppSegmentOption<T> option;
  final bool isSelected;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = LightColors.primaryPrimaryDefault;
    final bg = isSelected
        ? accent.withOpacity(0.08)
        : (isLight
              ? LightColors.backgroundSurfacePrimaryBG
              : DarkColors.backgroundSurfacePrimaryBG);
    final borderColor = isSelected
        ? accent
        : (isLight
              ? LightColors.strokeColourStrokeMild
              : DarkColors.strokeColourStrokeMild);
    final fgColor = isSelected
        ? accent
        : (isLight ? LightColors.textTextMute : DarkColors.textTextMute);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.icon != null) ...[
              Icon(option.icon, size: 16, color: fgColor),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: AppText(
                option.label,
                color: fgColor,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
