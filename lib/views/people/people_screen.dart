import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_segmented_control.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_button.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/people/people_view_model.dart';
import 'package:hamrash_admin/views/people/people_filter_options.dart';
import 'package:hamrash_admin/views/people/students_view_model.dart';
import 'package:hamrash_admin/views/people/widgets/student_filter_sheet.dart';
import 'package:hamrash_admin/views/people/widgets/students_content.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_screen.dart';
import 'package:hamrash_admin/views/team/team_screen.dart';
import 'package:hamrash_admin/views/team/team_view_model.dart';
import 'package:stacked/stacked.dart';

/// 9.1 – 9.4a · The People tab. A Students | Staff switch sits under the
/// title and opens on Students; the app bar's filter and add buttons follow
/// the side that is showing. Staff are the old Staffs page, moved here from
/// More. Someone who can't see the team (the bursar) gets Students only.
class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key, required this.school, this.viewModel});

  final MemberSchool school;

  /// For tests: a view model built with fake services.
  final PeopleViewModel? viewModel;

  /// The switch's height, and the gap under it before the list.
  static const double _switchHeight = 44;
  static const double _switchGap = AppSpacing.md;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<PeopleViewModel>.reactive(
        viewModelBuilder: () => viewModel ?? PeopleViewModel(school: school),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) {
          final staff = model.side == PeopleSide.staff;
          final team = model.team;
          return DefaultScaffold(
            backgroundColor: AppPalette.linen,
            title: 'People',
            subtitle: _subtitle(model.students),
            actions: staff
                ? _staffActions(context, model, team!)
                : _studentActions(context, model),
            body: _Body(
              model: model,
              onOpenStudent: (_) =>
                  AppToast.show('Student profiles are coming soon'),
              onAddStudent: model.students.canAdd
                  ? () => _addStudent(context, model.students)
                  : null,
              onAddStaff: team != null && team.canAdd
                  ? () => TeamScreen.addStaff(context, team)
                  : null,
            ),
          );
        },
      );

  String _subtitle(StudentsViewModel students) {
    final session = students.sessionName;
    return session == null ? school.name : '${school.name} · $session';
  }

  List<Widget> _studentActions(BuildContext context, PeopleViewModel people) {
    final model = people.students;
    return [
      if (model.ready && !model.isEmpty)
        AppNavIconButton(
          icon: AppIcons.slidersHorizontal,
          iconColor: LightColors.primaryPrimaryDefault,
          appliedCount: model.filter.activeCount,
          semanticLabel: model.filter.activeCount == 0
              ? 'Filter students'
              : 'Filter students, ${model.filter.activeCount} applied',
          onPressed: () => _filterStudents(context, people),
        ),
      if (model.canAdd && model.ready)
        AppNavIconButton(
          icon: AppIcons.plus,
          iconSize: 18,
          iconColor: LightColors.primaryPrimaryDefault,
          semanticLabel: 'Add student',
          onPressed: () => _addStudent(context, model),
        ),
    ];
  }

  /// Reads the classes and subjects first, so the sheet opens with
  /// something to pick; says so when they can't be read.
  Future<PeopleFilterOptions?> _options(PeopleViewModel people) async {
    try {
      return await people.filterOptions();
    } catch (_) {
      AppToast.show(
        "Couldn't load the filters. Try again.",
        type: AppToastType.error,
      );
      return null;
    }
  }

  Future<void> _filterStudents(
    BuildContext context,
    PeopleViewModel people,
  ) async {
    final options = await _options(people);
    if (options == null || !context.mounted) return;
    final next = await StudentFilterSheet.show(
      context,
      initial: people.students.filter,
      options: options,
    );
    if (next != null) await people.students.applyFilter(next);
  }

  Future<void> _filterStaff(
    BuildContext context,
    PeopleViewModel people,
    TeamViewModel team,
  ) async {
    final options = await _options(people);
    if (options == null || !context.mounted) return;
    await TeamScreen.openFilter(context, team, options: options);
  }

  List<Widget> _staffActions(
    BuildContext context,
    PeopleViewModel people,
    TeamViewModel team,
  ) => [
    if (team.ready && !team.showEmptyState)
      AppNavIconButton(
        icon: AppIcons.slidersHorizontal,
        iconColor: LightColors.primaryPrimaryDefault,
        appliedCount: team.filter.activeCount,
        semanticLabel: team.filter.activeCount == 0
            ? 'Filter staff'
            : 'Filter staff, ${team.filter.activeCount} applied',
        onPressed: () => _filterStaff(context, people, team),
      ),
    if (team.canAdd && team.ready)
      AppNavIconButton(
        icon: AppIcons.plus,
        iconSize: 18,
        iconColor: LightColors.primaryPrimaryDefault,
        semanticLabel: 'Add staff member',
        onPressed: () => TeamScreen.addStaff(context, team),
      ),
  ];

  Future<void> _addStudent(
    BuildContext context,
    StudentsViewModel model,
  ) async {
    final registered = await NavigationService.animatedNavigation<bool>(
      screen: AddStudentScreen(school: model.school),
    );
    if (registered == true) await model.refresh().catchError((_) {});
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.model,
    required this.onOpenStudent,
    required this.onAddStudent,
    required this.onAddStaff,
  });

  final PeopleViewModel model;
  final ValueChanged<Object> onOpenStudent;
  final VoidCallback? onAddStudent;
  final VoidCallback? onAddStaff;

  @override
  Widget build(BuildContext context) {
    final insets = ScaffoldInsets.of(context);
    final team = model.team;
    final switchBlock = model.showStaffSide
        ? PeopleScreen._switchHeight + PeopleScreen._switchGap
        : 0.0;

    final content = model.side == PeopleSide.staff
        ? TeamContent(model: team!, onAdd: onAddStaff)
        : StudentsContent(
            model: model.students,
            onOpen: onOpenStudent.call,
            onAdd: onAddStudent,
          );

    return Stack(
      children: [
        // The lists leave room for the app bar themselves; the switch is
        // more room on top of that.
        Positioned.fill(
          child: ScaffoldInsets(
            topInset: insets.topInset + switchBlock,
            appBarHeight: insets.appBarHeight,
            appBarFadeHeight: insets.appBarFadeHeight,
            hasAppBar: insets.hasAppBar,
            bottomInset: insets.bottomInset,
            child: content,
          ),
        ),
        if (model.showStaffSide)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ColoredBox(
              color: AppPalette.linen,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  insets.bodyTopInset,
                  AppSpacing.screen,
                  PeopleScreen._switchGap,
                ),
                child: AppSegmentedControl<PeopleSide>(
                  height: PeopleScreen._switchHeight,
                  options: const [
                    AppSegmentOption(
                      value: PeopleSide.students,
                      label: 'Students',
                    ),
                    AppSegmentOption(value: PeopleSide.staff, label: 'Staff'),
                  ],
                  selected: model.side,
                  onChanged: model.select,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
