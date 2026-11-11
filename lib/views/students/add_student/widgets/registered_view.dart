import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_dashed_border.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icon_label.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_person_photo.dart';
import 'package:hamrash_admin/core/widgets/app_section_card.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';
import 'package:hamrash_admin/views/team/widgets/staff_info_rows.dart';

/// 9.11 · Registered: their picture with a check, the class and session, the
/// admission number to copy, and what was saved (main contact, subjects,
/// parents). The actions live in the pinned bar below the page.
class RegisteredView extends StatelessWidget {
  const RegisteredView({super.key, required this.model});

  final AddStudentViewModel model;

  @override
  Widget build(BuildContext context) {
    final student = model.registered!;
    final parents = student.parentIds.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Hero(model: model),
          const SizedBox(height: AppSpacing.lg + AppSpacing.xs),
          _AdmissionNumber(number: student.admissionNumber),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: AppSectionCard.cardPadding,
            child: Column(
              children: [
                StaffInfoRow(
                  icon: AppIcons.phone,
                  label: 'Main contact',
                  value: model.mainContact?.displayName,
                ),
                const AppDivider(indent: 0, endIndent: 0),
                StaffInfoRow(
                  icon: AppIcons.bookOpen,
                  label: 'Subjects',
                  value: model.registeredSubjects,
                ),
                const AppDivider(indent: 0, endIndent: 0),
                StaffInfoRow(
                  icon: AppIcons.users,
                  label: 'Parents',
                  value: parents == 1 ? '1 linked' : '$parents linked',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The 96 picture with the green check on its corner, then "Chioma is
/// registered" and the class and session.
class _Hero extends StatelessWidget {
  const _Hero({required this.model});

  final AddStudentViewModel model;

  /// The photo's inner circle: 96 less the 1px ring and 3px white gap.
  static const _photoSize = 88.0;

  /// Radius of the check's green disc.
  static const _badgeSize = 34.0;

  @override
  Widget build(BuildContext context) {
    final student = model.registered!;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppPalette.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppPalette.stone200),
              ),
              child: ClipOval(
                child: AppPersonPhoto(
                  url: model.studentPhoto.uploaded?.url,
                  size: _photoSize,
                  fallback: _Initials(
                    name: '${student.firstName} ${student.lastName}',
                  ),
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: _badgeSize,
                height: _badgeSize,
                decoration: BoxDecoration(
                  color: LightColors.successSuccessDefault,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppPalette.linen, width: 3),
                ),
                child: const AppIcon(
                  AppIcons.check,
                  size: 16,
                  color: AppPalette.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md + AppSpacing.xxs),
        AppText(
          '${student.firstName} is registered',
          textAlign: TextAlign.center,
          style: AppTypography.heading(
            28,
            lineHeight: 34,
          ).copyWith(letterSpacing: -0.56, color: LightColors.textStrong),
        ),
        const SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
        AppText(
          model.registeredPlacement,
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            fontSize: 15,
            height: 22 / 15,
            fontWeight: FontWeight.w600,
            color: LightColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// The admission number on a dashed stone-50 block, with Copy on the right.
class _AdmissionNumber extends StatelessWidget {
  const _AdmissionNumber({required this.number});

  final String number;

  /// 14 between the block's edge and its text.
  static const _vertical = AppSpacing.ms + AppSpacing.xxs;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: number));
    AppToast.show('Admission number copied');
  }

  @override
  Widget build(BuildContext context) => AppDashedBorder(
    radius: AppRadius.lg,
    fill: AppPalette.stone50,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        _vertical,
        AppSpacing.sm,
        _vertical,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'ADMISSION NUMBER',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.96,
                    color: LightColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                AppText(
                  number,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading(22, lineHeight: 28).copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.22,
                    color: LightColors.textStrong,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          Semantics(
            button: true,
            label: 'Copy admission number',
            excludeSemantics: true,
            child: BouncyButton(
              onPressed: _copy,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
                child: SizedBox(
                  height: 44,
                  child: AppIconLabel(
                    icon: AppIcons.copy,
                    label: 'Copy',
                    iconSize: 16,
                    gap: 6,
                    iconColor: LightColors.primaryPrimaryDefault,
                    hugContent: true,
                    style: AppTypography.button.copyWith(
                      fontSize: 14,
                      height: 20 / 14,
                      color: LightColors.primaryPrimaryDefault,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Initials on an aubergine-50 circle, for a student registered without a
/// photo.
class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  String get _letters {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: LightColors.primaryPrimaryMute,
    child: Center(
      child: AppText(
        _letters,
        style: AppTypography.heading(
          30,
          lineHeight: 36,
        ).copyWith(letterSpacing: -0.3, color: LightColors.primaryPrimaryText),
      ),
    ),
  );
}
