import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Standard "couldn't load" state for a section or screen: an alert icon, a
/// title, the failure [message], and an optional **Retry** action. Shown in
/// place of content when a load fails and there is nothing cached to display.
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({
    super.key,
    this.message,
    this.onRetry,
    this.title = "Couldn't load",
    this.topPadding = AppSpacing.sm,
  });

  /// The failure detail (typically the API error message).
  final String? message;

  /// When non-null, a Retry button is shown that invokes this.
  final VoidCallback? onRetry;

  /// Headline above the message.
  final String title;

  /// Space above the state — tune small for cards, larger for full screens.
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: LucideIcons.circleAlert,
      iconColor: LightColors.errorErrorDefault,
      title: title,
      subtitle: message,
      topPadding: topPadding,
      action: onRetry == null
          ? null
          : BouncyButton(
              onPressed: onRetry,
              child: AppText(
                'Retry',
                colorType: AppTextColor.textInverted,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
    );
  }
}
