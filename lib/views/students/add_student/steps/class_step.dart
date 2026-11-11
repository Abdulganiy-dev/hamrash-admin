import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/animated_section_content.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_spinner.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/pickers/app_picker_field.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/step_lead.dart';

/// 9.8 / 9.8a · Step 3: the class, then the arm, for the current session.
/// With no current session, or a closed one, the step is blocked and the
/// bottom button opens Academic sessions.
class ClassStep extends StatelessWidget {
  const ClassStep({super.key, required this.model});

  final AddStudentViewModel model;

  @override
  Widget build(BuildContext context) {
    final ready =
        !model.placementLoading &&
        model.placementError == null &&
        !model.placementBlocked;
    return StepScroll(
      children: [
        StepLead(
          eyebrow: model.stepEyebrow(AddStudentStep.placement),
          title: 'Which class do they join?',
          body: ready
              ? 'They are placed for ${model.sessionName}, the current '
                    'session.'
              : null,
        ),
        AnimatedSectionContent(child: _state()),
      ],
    );
  }

  Widget _state() {
    if (model.placementLoading) {
      return const Padding(
        key: ValueKey('loading'),
        padding: AppSpacing.allLg,
        child: Center(child: AppSpinner()),
      );
    }
    if (model.placementError != null) {
      return AppInlineState.error(
        key: const ValueKey('error'),
        title: "Couldn't load the classes",
        message: 'Check your connection and try again.',
        onRetry: model.reloadPlacement,
      );
    }
    if (model.placementBlocked) {
      return _Blocked(key: const ValueKey('blocked'), model: model);
    }
    final classes = model.classes;
    if (classes.isEmpty) {
      return const AppInlineState(
        key: ValueKey('empty'),
        icon: AppIcons.layoutGrid,
        title: 'No classes to choose from',
        message: 'Add a class with at least one arm in Classes first.',
      );
    }
    final chosenClass = model.schoolClass;
    return Column(
      key: const ValueKey('ready'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChipGroup(
          label: 'Class',
          children: [
            for (final each in classes)
              AppFilterChip(
                label: each.name,
                selected: each.id == chosenClass?.id,
                onTap: () => model.pickClass(each),
              ),
          ],
        ),
        if (chosenClass != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _ChipGroup(
            label: 'Arm',
            children: [
              for (final arm in model.armsOf(chosenClass))
                AppFilterChip(
                  label: arm.name,
                  selected: arm.id == model.arm?.id,
                  onTap: () => model.pickArm(arm),
                ),
            ],
          ),
        ],
        if (model.arm != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _ArmSummary(model: model),
        ],
      ],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppText(
        label,
        style: AppTypography.subtitle.copyWith(color: LightColors.textStrong),
      ),
      // The chips' 48 tap areas add 4 above the 40 pill.
      const SizedBox(height: AppSpacing.sm),
      Wrap(spacing: AppSpacing.sm, children: children),
    ],
  );
}

/// "JSS 1 Gold · 9 compulsory subjects · 4 optional to pick next", from the
/// one read of what the arm offers.
class _ArmSummary extends StatelessWidget {
  const _ArmSummary({required this.model});

  final AddStudentViewModel model;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: AppSpacing.allMd,
    onTap: model.offeringsFailed ? model.loadOfferings : null,
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: LightColors.categoryTealMute,
            borderRadius: BorderRadius.circular(14),
          ),
          child: model.offeringsLoading
              ? const AppSpinner(color: LightColors.categoryTealText)
              : const AppIcon(
                  AppIcons.graduationCap,
                  size: 22,
                  color: LightColors.categoryTealText,
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                model.armLabel,
                style: AppTypography.title.copyWith(
                  height: 22 / 16,
                  color: LightColors.textStrong,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              AppText(
                model.armSummary,
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  height: 18 / 13,
                  color: model.offeringsFailed
                      ? LightColors.errorErrorText
                      : LightColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// 9.8a · No current session (or a closed one): why, and the pickers off.
class _Blocked extends StatelessWidget {
  const _Blocked({super.key, required this.model});

  final AddStudentViewModel model;

  @override
  Widget build(BuildContext context) {
    final closed = model.sessionClosed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: AppSpacing.allMd,
          decoration: BoxDecoration(
            color: LightColors.errorErrorMute,
            borderRadius: AppRadius.brCard,
            border: Border.all(color: LightColors.errorErrorThin),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                closed
                    ? '${model.sessionName} is closed'
                    : 'There’s no current session',
                style: AppTypography.subtitle.copyWith(
                  fontSize: 15,
                  color: LightColors.errorErrorText,
                ),
              ),
              const SizedBox(height: 6),
              AppText(
                closed
                    ? 'Nothing new can be added to a closed session. Reopen it '
                          'or make another session current, then come back. '
                          'What you have entered is kept.'
                    : 'Students are placed in a session, so one has to be '
                          'open first. Set one in the academic calendar, then '
                          'come back. What you have entered is kept.',
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  height: 18 / 13,
                  color: LightColors.textBody,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppPickerField(
          label: 'Class',
          placeholder: 'Unavailable',
          enabled: false,
          onTap: () async {},
        ),
        const SizedBox(height: AppSpacing.md),
        AppPickerField(
          label: 'Arm',
          placeholder: 'Unavailable',
          enabled: false,
          onTap: () async {},
        ),
      ],
    );
  }
}
