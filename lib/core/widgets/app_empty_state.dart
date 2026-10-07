import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:flutter/material.dart';

/// A reusable empty-state placeholder: a muted icon above a title and an
/// optional subtitle, centered with a top offset.
///
/// Use it anywhere a list or section has no content to show.
///
/// ```dart
/// // Minimal
/// AppEmptyState(
///   icon: LucideIcons.search,
///   title: 'No results found',
///   subtitle: 'Try searching by name, class, or status.',
/// )
///
/// // With a call-to-action
/// AppEmptyState(
///   icon: LucideIcons.users,
///   title: 'No students yet',
///   action: AppButton(label: 'Add student', onPressed: _addStudent),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = 36,
    this.iconColor,
    this.titleColorType = AppTextColor.textInverted,
    this.subtitleColorType = AppTextColor.textMute,
    this.titleFontSize = 15,
    this.subtitleFontSize = 13,
    this.topPadding = AppSpacing.s50,
  });

  /// The icon shown above the text.
  final IconData icon;

  /// Primary line, e.g. "No results found".
  final String title;

  /// Optional supporting line shown below the title.
  final String? subtitle;

  /// Optional widget (typically a button) shown below the subtitle.
  final Widget? action;

  /// Icon size. Defaults to 36.
  final double iconSize;

  /// Icon color. Defaults to the theme's muted icon color.
  final Color? iconColor;

  /// Color type for the title.
  final AppTextColor titleColorType;

  /// Color type for the subtitle.
  final AppTextColor subtitleColorType;

  /// Title font size.
  final double titleFontSize;

  /// Subtitle font size.
  final double subtitleFontSize;

  /// Space above the empty state.
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final resolvedIconColor = iconColor ??
        (isLight ? LightColors.iconIconMute : DarkColors.iconIconMute);

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: resolvedIconColor),
            SizedBox(height: AppSpacing.sm),
            AppText(
              title,
              colorType: titleColorType,
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: AppSpacing.xs),
              AppText(
                subtitle!,
                colorType: subtitleColorType,
                fontSize: subtitleFontSize,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
