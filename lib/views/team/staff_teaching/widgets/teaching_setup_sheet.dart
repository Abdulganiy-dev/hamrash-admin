import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/teaching.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/animated_section_content.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_spinner.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/academic_calendar/sessions/academic_sessions_screen.dart';
import 'package:hamrash_admin/views/subjects/class_subjects/class_subjects_screen.dart';
import 'package:hamrash_admin/views/team/staff_teaching/teaching_catalog.dart';
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
    required this.catalog,
    this.homerooms = const [],
    this.assignments = const [],
  });

  final MemberSchool school;
  final StaffMember staff;

  /// The staff page's cache of the session and the classes and arms.
  final TeachingCatalog catalog;

  /// What the staff page already read for this person, for the captions.
  final List<ClassTeacher> homerooms;
  final List<TeachingAssignment> assignments;

  static Future<TeachingChange?> show(
    BuildContext context, {
    required MemberSchool school,
    required StaffMember staff,
    required TeachingCatalog catalog,
    List<ClassTeacher> homerooms = const [],
    List<TeachingAssignment> assignments = const [],
  }) => Navigator.of(context).push<TeachingChange>(
    AppSheetRoute<TeachingChange>(
      size: AppSheetSize.floating,
      child: TeachingSetupSheet(
        school: school,
        staff: staff,
        catalog: catalog,
        homerooms: homerooms,
        assignments: assignments,
      ),
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
    // The arm may take subjects now; the next choice reads it again.
    model.forgetArmSubjects();
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
    // The session may have changed; read it again, and the classes with it.
    model.catalog.invalidate();
    await model.loadSession();
  }

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<TeachingSetupViewModel>.reactive(
        viewModelBuilder: () => TeachingSetupViewModel(
          school: school,
          staff: staff,
          catalog: catalog,
          homerooms: homerooms,
          assignments: assignments,
        ),
        onViewModelReady: (model) => model.loadSession(),
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

  /// Loading, error, no session and the two rows swap through the app's
  /// blur-and-fade, and the sheet's height follows.
  Widget _body(BuildContext context, TeachingSetupViewModel model) =>
      AnimatedSectionContent(child: _state(context, model));

  Widget _state(BuildContext context, TeachingSetupViewModel model) {
    if (model.loading) {
      return const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: AppSpinner()),
      );
    }
    if (model.error != null) {
      return Padding(
        key: const ValueKey('error'),
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
              onPressed: model.loadSession,
              child: const AppText('Try again'),
            ),
          ],
        ),
      );
    }
    if (!model.hasSession) {
      return const Padding(
        key: ValueKey('no-session'),
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
      key: ValueKey(locked ? 'closed' : 'ready'),
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
