import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/school_area.dart';
import 'package:hamrash_admin/views/people/people_filter_options.dart';
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
    PeopleFilterOptionsLoader? options,
  }) : _options =
           options ?? PeopleFilterOptionsLoader(organizationId: school.id),
       students = students ?? StudentsViewModel(school: school),
       team = school.accessTo(SchoolArea.team).isVisible
           ? (team ?? TeamViewModel(school: school))
           : null {
    this.students.addListener(notifyListeners);
    this.team?.addListener(notifyListeners);
  }

  final MemberSchool school;
  final PeopleFilterOptionsLoader _options;
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

  bool _optionsReady = false;

  /// The classes, arms and subjects the filter sheets pick from. Read once,
  /// the first time a sheet is opened, with the page [busy] while it loads so
  /// the person sees something is happening; later opens are instant.
  /// Rethrows when it can't be read, so the screen can say so instead of
  /// opening a sheet with nothing to pick.
  Future<PeopleFilterOptions> filterOptions() async {
    if (_optionsReady) return _options.load();
    setBusy(true);
    try {
      final options = await _options.load();
      _optionsReady = true;
      return options;
    } finally {
      setBusy(false);
    }
  }

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
