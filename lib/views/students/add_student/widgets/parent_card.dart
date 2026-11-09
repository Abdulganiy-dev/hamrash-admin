import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';

/// The picture for a parent in the wizard: their saved photo, the photo
/// picked for a new parent, or their initials.
AppListLeading parentLeading(AddedParent parent) {
  if (parent.match?.photoUrl case final url?) {
    return AppListLeading.network(url, name: parent.fullName);
  }
  final photo = parent.photo;
  if (photo != null && !photo.isEmpty && photo.path != null) {
    return AppListLeading.local(photo.path!, name: parent.fullName);
  }
  return AppListLeading.initials(parent.fullName);
}

/// 11.6 · One parent on the Parents step: picture, name, relationship and
/// phone, and either the Main contact pill or "Make main".
class ParentCard extends StatelessWidget {
  const ParentCard({
    super.key,
    required this.parent,
    required this.isMain,
    required this.onMakeMain,
    required this.onTap,
  });

  final AddedParent parent;
  final bool isMain;
  final VoidCallback onMakeMain;

  /// Opens what can be done to this parent (make main, remove).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: AppSpacing.allMd,
    onTap: onTap,
    child: Row(
      children: [
        AppLeadingPicture(leading: parentLeading(parent), size: 52),
        const SizedBox(width: AppSpacing.ms),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                parent.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title.copyWith(
                  height: 22 / 16,
                  color: LightColors.textStrong,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              AppText(
                parent.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  height: 18 / 13,
                  color: LightColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (isMain)
          const AppBadge(
            'Main contact',
            tone: AppBadgeTone.success,
            showBorder: false,
          )
        else
          Semantics(
            button: true,
            label: 'Make ${parent.displayName} the main contact',
            excludeSemantics: true,
            child: BouncyButton(
              onPressed: onMakeMain,
              child: SizedBox(
                height: 44,
                child: Center(
                  widthFactor: 1,
                  child: AppText(
                    'Make main',
                    style: AppTypography.subtitle.copyWith(
                      color: LightColors.primaryPrimaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
