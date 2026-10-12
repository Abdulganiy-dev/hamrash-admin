import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shown when content failed to load: a plain red icon, what failed, the
/// likely reason and a "Try again" button.
///
/// Use [compact] inside a card or list so the rest of the page keeps
/// working; it becomes an [AppInlineState.error] with a Retry link.
///
/// ```dart
/// LoadErrorView(
///   title: 'Couldn’t load students',
///   message: 'You seem to be offline. Check your connection and try again.',
///   offline: true,
///   onRetry: model.load,
/// )
/// ```
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({
    super.key,
    this.message,
    this.onRetry,
    this.title = "Couldn't load",
    this.offline = false,
    this.compact = false,
    this.topPadding = AppSpacing.sm,
  });

  /// The likely reason, in plain words (typically the API error message).
  final String? message;

  /// When non-null, a "Try again" button is shown that calls this.
  final VoidCallback? onRetry;

  /// What failed, e.g. "Couldn't load students". Never just "Error".
  final String title;

  /// Shows the no-connection icon instead of the general alert.
  final bool offline;

  /// Small in-card version.
  final bool compact;

  /// Space above the state — small for cards, larger for full screens.
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: AppInlineState.error(
          title: title,
          message: message ?? 'The rest of the page still works.',
          onRetry: onRetry,
        ),
      );
    }

    return AppEmptyState(
      icon: offline ? LucideIcons.wifiOff300 : LucideIcons.circleAlert300,
      iconColor: LightColors.errorErrorDefault,
      title: title,
      subtitle:
          message ??
          (offline
              ? 'You seem to be offline. Check your connection and try again.'
              : 'Something went wrong on our side. Please try again.'),
      topPadding: topPadding,
      action: onRetry == null
          ? null
          : AppSecondaryButton(
              onPressed: onRetry,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.refreshCw500, size: 18),
                  SizedBox(width: 8),
                  AppText('Try again'),
                ],
              ),
            ),
    );
  }
}
