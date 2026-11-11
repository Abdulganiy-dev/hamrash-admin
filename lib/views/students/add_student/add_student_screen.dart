import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_icon_label.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_keyboard_bar.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_spring_pager.dart';
import 'package:hamrash_admin/core/widgets/app_step_segments.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_button.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/academic_calendar/sessions/academic_sessions_screen.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/steps/class_step.dart';
import 'package:hamrash_admin/views/students/add_student/steps/parents_step.dart';
import 'package:hamrash_admin/views/students/add_student/steps/personal_step.dart';
import 'package:hamrash_admin/views/students/add_student/steps/review_step.dart';
import 'package:hamrash_admin/views/students/add_student/steps/student_step.dart';
import 'package:hamrash_admin/views/students/add_student/steps/subjects_step.dart';
import 'package:hamrash_admin/views/students/add_student/widgets/registered_view.dart';
import 'package:hamrash_admin/views/students/student_detail/student_detail_screen.dart';
import 'package:stacked/stacked.dart';

/// 9.5–9.11 · Add a student, one step at a time. The steps sit side by
/// side in an [AppSpringPager], so typed text and scroll survive moving back
/// and forth. Pops `true` when a student was registered.
class AddStudentScreen extends StatelessWidget {
  const AddStudentScreen({super.key, required this.school, this.viewModel});

  final MemberSchool school;

  /// For tests: a view model built with fake services.
  final AddStudentViewModel? viewModel;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<AddStudentViewModel>.reactive(
        viewModelBuilder: () =>
            viewModel ?? AddStudentViewModel(school: school),
        builder: (context, model, _) {
          final keyboardOpen = AppKeyboardBar.isKeyboardOpen(context);
          final done = model.registered != null;
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _back(context, model);
            },
            child: DefaultScaffold(
              title: 'Add student',
              // Registered: a close button, because there is no step to go
              // back to once they are saved.
              showBackButton: !done,
              leading: done
                  ? AppNavIconButton(
                      icon: AppIcons.x,
                      semanticLabel: 'Close',
                      onPressed: () => _back(context, model),
                    )
                  : null,
              centerTitle: done ? true : null,
              onBackPressed: () => _back(context, model),
              backgroundColor: AppPalette.linen,
              extendBody: keyboardOpen,
              // The registered bar paints its own top hairline.
              bottomBarFade: !done,
              body: _Body(model: model),
              bottomNavigationBar: keyboardOpen
                  ? const AppKeyboardBar()
                  : _BottomBar(
                      model: model,
                      onContinue: () => _continue(context, model),
                      onOpenSessions: () => _openSessions(model),
                      onOpenProfile: () => _openProfile(model),
                    ),
            ),
          );
        },
      );

  static void _continue(BuildContext context, AddStudentViewModel model) {
    FocusScope.of(context).unfocus();
    model.next();
  }

  /// Back goes to the previous step. On the first step it closes, asking
  /// first when anything was entered.
  static Future<void> _back(
    BuildContext context,
    AddStudentViewModel model,
  ) async {
    FocusScope.of(context).unfocus();
    if (model.registered != null) {
      NavigationService.popScreen(true);
      return;
    }
    if (model.registering || model.back()) return;
    if (model.hasEntered) {
      final discard = await AppConfirmSheet.show(
        context,
        title: 'Discard this student?',
        message: "What you've entered so far won't be saved.",
        confirmLabel: 'Discard',
        cancelLabel: 'Keep editing',
        isDestructive: true,
      );
      if (discard != true) return;
    }
    model.discardPhotos();
    NavigationService.popScreen(model.registeredAny ? true : null);
  }

  /// A closed or missing session is fixed in Academic sessions; the session
  /// and classes are read again on return.
  static Future<void> _openSessions(AddStudentViewModel model) async {
    await NavigationService.animatedNavigation<void>(
      screen: AcademicSessionsScreen(school: model.school),
    );
    await model.reloadPlacement();
  }

  /// 9.11 · Open profile: the wizard makes way for the new student's page, so
  /// leaving the profile lands on the list, already reloaded.
  static Future<void> _openProfile(AddStudentViewModel model) async {
    final student = model.registered;
    if (student == null) return;
    NavigationService.popScreen(true);
    await NavigationService.animatedNavigation<void>(
      screen: StudentDetailScreen(school: model.school, studentId: student.id),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.model});

  final AddStudentViewModel model;

  @override
  Widget build(BuildContext context) {
    final insets = ScaffoldInsets.of(context);
    final done = model.registered != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: insets.bodyTopInset),
        // Registration is done, so there is no step to show progress for.
        if (!done) ...[
          Padding(
            padding: AppSpacing.screenPadding,
            child: AppStepSegments(
              current: model.stepIndex,
              count: model.stepCount,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
        ],
        Expanded(
          child: done
              ? RegisteredView(model: model)
              : AppSpringPager(
                  index: model.step.index,
                  children: [
                    StudentStep(model: model),
                    PersonalStep(model: model),
                    ParentsStep(model: model),
                    ClassStep(model: model),
                    SubjectsStep(model: model),
                    ReviewStep(model: model),
                  ],
                ),
        ),
      ],
    );
  }
}

/// The pinned button for the step on screen, full width. On the subjects
/// step the running subject total sits above Continue. Once they are
/// registered it is their profile and a text link to start another.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.model,
    required this.onContinue,
    required this.onOpenSessions,
    required this.onOpenProfile,
  });

  final AddStudentViewModel model;
  final VoidCallback onContinue;
  final VoidCallback onOpenSessions;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final done = model.registered != null;
    return SafeArea(
      top: false,
      child: Container(
        decoration: done
            ? const BoxDecoration(
                border: Border(top: BorderSide(color: AppPalette.stone200)),
              )
            : null,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          done ? AppSpacing.ms : AppSpacing.sm,
          AppSpacing.screen,
          done ? AppSpacing.xs : AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buttons(),
        ),
      ),
    );
  }

  List<Widget> _buttons() {
    final student = model.registered;
    if (student != null) {
      return [
        AppPrimaryButton(
          size: AppButtonSize.large,
          onPressed: onOpenProfile,
          child: Text('Open ${student.firstName}’s profile'),
        ),
        const SizedBox(height: AppSpacing.md),
        _AddAnotherStudent(onPressed: model.startAnother),
      ];
    }
    final step = model.step;
    if (step == AddStudentStep.placement && model.placementBlocked) {
      return [
        AppPrimaryButton(
          size: AppButtonSize.large,
          onPressed: onOpenSessions,
          child: const Text('Open academic sessions'),
        ),
      ];
    }
    if (step == AddStudentStep.review) {
      return [
        if (model.error case final message?) AppSheetError(message),
        AppPrimaryButton(
          size: AppButtonSize.large,
          isLoading: model.registering,
          loadingText: 'Registering…',
          isDisabled: !model.canRegister && !model.registering,
          onPressed: model.register,
          child: const Text('Register student'),
        ),
      ];
    }
    return [
      if (step == AddStudentStep.subjects) ...[
        SubjectsTotal(model: model),
        const SizedBox(height: AppSpacing.ms),
      ],
      AppPrimaryButton(
        size: AppButtonSize.large,
        isDisabled: !model.canContinue,
        onPressed: onContinue,
        child: const Text('Continue'),
      ),
    ];
  }
}

/// "+ Add another student": a 44 tall text link, centred, not a bordered
/// secondary button.
class _AddAnotherStudent extends StatelessWidget {
  const _AddAnotherStudent({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Add another student',
    excludeSemantics: true,
    child: BouncyButton(
      onPressed: onPressed,
      child: SizedBox(
        height: 44,
        child: Center(
          child: AppIconLabel(
            icon: AppIcons.plus,
            label: 'Add another student',
            iconSize: 16,
            gap: 6,
            iconColor: LightColors.primaryPrimaryDefault,
            hugContent: true,
            style: AppTypography.button.copyWith(
              fontSize: 16,
              height: 24 / 16,
              color: LightColors.primaryPrimaryDefault,
            ),
          ),
        ),
      ),
    ),
  );
}
