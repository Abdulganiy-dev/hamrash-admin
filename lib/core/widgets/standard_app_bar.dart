import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_metrics.dart';

/// App bar that sits on the page. It has no background of its own; only its
/// buttons and pictures float ([AppNavIconButton], [AppNavPicture]).
///
/// Tab screens: title on the left, actions on the right.
/// Detail screens: back button, centred title ([centerTitle]), actions.
///
/// ```dart
/// StandardAppBar(
///   title: 'Students',
///   subtitle: 'JSS 2 Gold · 32 of 1,248',
///   actions: [
///     AppNavIconButton(icon: LucideIcons.search, onPressed: search),
///   ],
/// )
/// ```
class StandardAppBar extends StatelessWidget {
  const StandardAppBar({
    super.key,
    this.leading,
    this.actions,
    this.title,
    this.subtitle,
    this.centerTitle = false,
    this.height = AppNavMetrics.appBarHeight,
  });

  final Widget? leading;
  final List<Widget>? actions;
  final String? title;
  final String? subtitle;

  /// Centre the title between [leading] and [actions]. Use on detail screens.
  final bool centerTitle;

  final double height;

  @override
  Widget build(BuildContext context) {
    final hasActions = actions != null && actions!.isNotEmpty;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppNavMetrics.appBarSideInset,
        ),
        child: NavigationToolbar(
          // NavigationToolbar stretches leading to full height; keep it its
          // own size.
          leading: leading == null
              ? null
              : Center(widthFactor: 1, child: leading),
          middle: title == null ? null : _title(),
          trailing: hasActions
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < actions!.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppNavMetrics.buttonGap),
                      actions![i],
                    ],
                  ],
                )
              : null,
          centerMiddle: centerTitle,
          middleSpacing: leading == null && !centerTitle ? 0 : 10,
        ),
      ),
    );
  }

  Widget _title() {
    final align = centerTitle ? TextAlign.center : TextAlign.start;
    final titleStyle = centerTitle
        ? AppTypography.title.copyWith(fontWeight: FontWeight.w800)
        : AppTypography.h4.copyWith(height: 22 / 18, letterSpacing: -0.18);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centerTitle
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        AppText(
          title!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: titleStyle.copyWith(color: LightColors.textStrong),
        ),
        if (subtitle != null)
          AppText(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            variant: AppTextVariant.label,
            colorType: AppTextColor.textMuted,
          ),
      ],
    );
  }
}
