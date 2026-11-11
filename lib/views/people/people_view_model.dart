import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/school_area.dart';
import 'package:hamrash_admin/views/people/students_view_model.dart';
import 'package:hamrash_admin/views/team/team_view_model.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// The two sides of the People tab.
enum PeopleSide { students, staff }

/// 9.1 / 9.3 · The People tab: a Students | Staff switch that opens on
/// Students. It owns both lists' view models so the app bar can follow the
/// side that is showing, and re-notifies when either changes.
///
/// Staff are for leaders only: someone who can't see the team (the bursar)
/// gets Students alone, with no switch.
class PeopleViewModel extends BaseViewModel {
  PeopleViewModel({
    required this.school,
    StudentsViewModel? students,
    TeamViewModel? team,
  }) : students = students ?? StudentsViewModel(school: school),
       team = school.accessTo(SchoolArea.team).isVisible
           ? (team ?? TeamViewModel(school: school))
           : null {
    this.students.addListener(notifyListeners);
    this.team?.addListener(notifyListeners);
  }

  final MemberSchool school;
  final StudentsViewModel students;

  /// Null when this person can't see the team.
  final TeamViewModel? team;

  PeopleSide _side = PeopleSide.students;

  bool get showStaffSide => team != null;
  PeopleSide get side => showStaffSide ? _side : PeopleSide.students;

  /// First visit to the tab: Students always loads; Staff loads when its side
  /// is first opened.
  bool _staffLoaded = false;

  Future<void> load() => students.load();

  void select(PeopleSide value) {
    if (value == _side || (value == PeopleSide.staff && !showStaffSide)) return;
    _side = value;
    if (value == PeopleSide.staff && !_staffLoaded) {
      _staffLoaded = true;
      team!.load();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    students.removeListener(notifyListeners);
    team?.removeListener(notifyListeners);
    students.dispose();
    team?.dispose();
    super.dispose();
  }
}
