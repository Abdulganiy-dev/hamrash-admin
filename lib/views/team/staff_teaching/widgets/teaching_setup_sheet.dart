import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_spinner.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/academic_calendar/sessions/academic_sessions_screen.dart';
import 'package:hamrash_admin/views/subjects/class_subjects/class_subjects_screen.dart';
import 'package:hamrash_admin/views/team/staff_teaching/teaching_setup_view_model.dart';
import 'package:hamrash_admin/views/team/staff_teaching/widgets/homeroom_sheet.dart';
import 'package:hamrash_admin/views/team/staff_teaching/widgets/subject_sheet.dart';
import 'package:hamrash_admin/views/team/staff_teaching/widgets/teaching_note.dart';
import 'package:hamrash_admin/views/team/staff_teaching/widgets/teaching_option_row.dart';
import 'package:stacked/stacked.dart';

/// The staff page's teaching action: where this person's homeroom and
/// subjects are set for the current session. Pops the change that was saved,
/// or null when nothing was.
class TeachingSetupSheet extends StatelessWidget {
  const TeachingSetupSheet({
    super.key,
    required this.school,
    required this.staff,
  });

  final MemberSchool school;
  final StaffMember staff;

  static Future<TeachingChange?> show(
    BuildContext context, {
    required MemberSchool school,
    required StaffMember staff,
  }) => Navigator.of(context).push<TeachingChange>(
    AppSheetRoute<TeachingChange>(
      size: AppSheetSize.floating,
      child: TeachingSetupSheet(school: school, staff: staff),
    ),
  );

  Future<void> _openHomeroom(
    BuildContext context,
    TeachingSetupViewModel model,
  ) async {
    final saved = await HomeroomSheet.show(context, model: model);
    if (saved == true && context.mounted) {
      Navigator.of(context).pop(TeachingChange.homeroom);
    }
  }

  Future<void> _openSubject(
    BuildContext context,
    TeachingSetupViewModel model,
  ) async {
    final saved = await SubjectSheet.show(
      context,
      model: model,
      onAddSubjects: (classId) => _addSubjects(model, classId),
    );
    if (saved == true && context.mounted) {
      Navigator.of(context).pop(TeachingChange.subject);
    }
  }

  Future<void> _addSubjects(
    TeachingSetupViewModel model,
    String classId,
  ) async {
    await NavigationService.animatedNavigation<void>(
      screen: ClassSubjectsScreen(school: model.school, classId: classId),
    );
    await model.refresh().catchError((_) {});
  }

  /// A closed session blocks both sheets; the sessions list is where a
  /// leader reopens it or marks another one current.
  Future<void> _openSessions(
    BuildContext context,
    TeachingSetupViewModel model,
  ) async {
    await NavigationService.animatedNavigation<void>(
      screen: AcademicSessionsScreen(school: model.school),
    );
    await model.load();
  }

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<TeachingSetupViewModel>.reactive(
        viewModelBuilder: () =>
            TeachingSetupViewModel(school: school, staff: staff),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) => AppSheet(
          title: 'Teaching setup',
          subtitle: model.hasSession
              ? '${model.schoolYear} · current session'
              : null,
          bodyPadding: const EdgeInsets.only(
            top: AppSpacing.xs,
            bottom: AppSpacing.ml,
          ),
          body: _body(context, model),
          footer: model.closed
              ? AppSecondaryButton(
                  onPressed: () => _openSessions(context, model),
                  child: const AppText('Open academic sessions'),
                )
              : null,
        ),
      );

  Widget _body(BuildContext context, TeachingSetupViewModel model) {
    if (model.loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: AppSpinner()),
      );
    }
    if (model.error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TeachingNote(
              note: "Couldn't load the teaching setup. Try again.",
              tone: TeachingTone.error,
            ),
            const SizedBox(height: AppSpacing.md),
            AppSecondaryButton(
              onPressed: model.load,
              child: const AppText('Try again'),
            ),
          ],
        ),
      );
    }
    if (!model.hasSession) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: TeachingNote(
          note:
              "There's no current session yet. Set one in the academic "
              'calendar first.',
          tone: TeachingTone.warning,
        ),
      );
    }
    final locked = model.closed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (locked)
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TeachingNote(
              note:
                  'This session is closed. Reopen it to change who teaches '
                  'where.',
              tone: TeachingTone.error,
            ),
          ),
        TeachingOptionRow(
          icon: AppIcons.graduationCap,
          tileColor: LightColors.categoryHoneyMute,
          iconColor: LightColors.categoryHoneyText,
          title: 'Set homeroom',
          caption: locked ? 'Unavailable' : model.homeroomCaption,
          enabled: !locked,
          onTap: () => _openHomeroom(context, model),
        ),
        const AppDivider(),
        TeachingOptionRow(
          icon: AppIcons.bookOpen,
          tileColor: LightColors.categoryTealMute,
          iconColor: LightColors.categoryTealText,
          title: 'Set subject',
          caption: locked ? 'Unavailable' : model.subjectCaption,
          enabled: !locked,
          onTap: () => _openSubject(context, model),
        ),
      ],
    );
  }
}
