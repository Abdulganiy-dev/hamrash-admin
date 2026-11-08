import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';

/// The two things both teaching sheets need before anything else: the
/// school's current session and its classes and arms. Each is read the
/// first time a sheet asks and kept, so the homeroom and subject sheets
/// share one read of each, and reopening a sheet reads nothing.
///
/// The staff page owns one for as long as it is open and calls [invalidate]
/// when it is refreshed.
class TeachingCatalog {
  TeachingCatalog({
    required this.organizationId,
    ClassStructureService? structure,
  }) : _structureOverride = structure;

  final String organizationId;
  final ClassStructureService? _structureOverride;

  final _session = _Once<AcademicSession?>();
  final _sections = _Once<List<SchoolSection>>();

  ClassStructureService get _structure =>
      _structureOverride ?? locator<ClassStructureService>();

  /// The current session, or null when none is marked current.
  Future<AcademicSession?> session() =>
      _session.get(() => _structure.getCurrentSession(organizationId));

  /// Every section with its classes and arms.
  Future<List<SchoolSection>> sections() =>
      _sections.get(() => _structure.getStructure(organizationId));

  /// Forget both, so the next sheet reads them again.
  void invalidate() {
    _session.clear();
    _sections.clear();
  }
}

/// One read, shared by everyone who asks while it is running or done. A
/// failed read is forgotten, so asking again tries again.
class _Once<T> {
  Future<T>? _future;

  Future<T> get(Future<T> Function() load) {
    final existing = _future;
    if (existing != null) return existing;
    final future = load();
    _future = future;
    future.then<void>(
      (_) {},
      onError: (_) {
        if (identical(_future, future)) _future = null;
      },
    );
    return future;
  }

  void clear() => _future = null;
}
