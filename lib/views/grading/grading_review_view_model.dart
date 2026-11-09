import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/grading_setup.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/services/supabase_services/grading_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

/// 9.39 · Review how one section is graded. The score fields are worked out
/// locally; nothing on this page is saved.
class GradingReviewViewModel extends BaseViewModel {
  GradingReviewViewModel({
    required this.school,
    required this.section,
    GradingService? service,
  }) : _service = service ?? locator<GradingService>();

  final MemberSchool school;
  final SchoolSection section;
  final GradingService _service;

  GradingSetup? _setup;
  Object? _error;
  bool _changed = false;

  Object? get error => _error;
  bool get loading => _setup == null && _error == null;
  bool get canChange => school.canRunSetup;
  bool get changed => _changed;

  SectionGrading get grading => _setup!.forSection(section);

  Future<void> load() async {
    _error = null;
    notifyListeners();
    try {
      await _fetch();
    } catch (error, stackTrace) {
      _error = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'GradingReview.load',
        showErrorModal: false,
      );
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      await _fetch();
      _error = null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'GradingReview.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> markChanged() async {
    _changed = true;
    await refresh().catchError((_) {});
  }

  Future<void> _fetch() async {
    _setup = await _service.getSetup(school.id);
  }
}
