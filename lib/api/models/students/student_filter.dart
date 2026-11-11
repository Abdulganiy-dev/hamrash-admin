import 'package:flutter/foundation.dart';
import 'package:hamrash_admin/api/models/students/student_summary.dart';

/// `public.student_status`.
enum StudentStatusFilter {
  active('active', 'Active'),
  graduated('graduated', 'Graduated'),
  transferred('transferred', 'Transferred'),
  withdrawn('withdrawn', 'Withdrawn');

  const StudentStatusFilter(this.value, this.label);

  final String value;
  final String label;
}

enum StudentSort {
  byClass('class', 'By class'),
  name('name', 'Name A–Z');

  const StudentSort(this.value, this.label);

  final String value;
  final String label;
}

/// A picked option: the id `list_students` filters on and the words the chip
/// and the sheet show.
@immutable
class FilterPick {
  const FilterPick(this.id, this.label);

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is FilterPick && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}

/// One applied filter, as the removable chip above the Students list.
class StudentFilterChip {
  const StudentFilterChip({required this.label, required this.without});

  final String label;

  /// The filter with just this one taken off.
  final StudentFilter without;
}

/// Everything the Students list is narrowed by. Active students only until
/// the statuses are changed; an empty [statuses] set means every status.
@immutable
class StudentFilter {
  const StudentFilter({
    this.search = '',
    this.schoolClass,
    this.arm,
    this.subject,
    this.statuses = defaultStatuses,
    this.sort = StudentSort.byClass,
  });

  static const initial = StudentFilter();

  static const defaultStatuses = {StudentStatusFilter.active};

  final String search;
  final FilterPick? schoolClass;

  /// An arm inside [schoolClass].
  final FilterPick? arm;
  final FilterPick? subject;
  final Set<StudentStatusFilter> statuses;
  final StudentSort sort;

  String get trimmedSearch => search.trim();

  /// The sheet sets these through [copyWith]; passing `clear…` takes one off,
  /// since null alone can't tell "keep" from "none".
  StudentFilter copyWith({
    String? search,
    FilterPick? schoolClass,
    bool clearClass = false,
    FilterPick? arm,
    bool clearArm = false,
    FilterPick? subject,
    bool clearSubject = false,
    Set<StudentStatusFilter>? statuses,
    StudentSort? sort,
  }) {
    final nextClass = clearClass ? null : (schoolClass ?? this.schoolClass);
    return StudentFilter(
      search: search ?? this.search,
      schoolClass: nextClass,
      // An arm belongs to one class; changing the class drops it.
      arm: clearArm || clearClass || (schoolClass != null && schoolClass != this.schoolClass)
          ? null
          : (arm ?? this.arm),
      subject: clearSubject ? null : (subject ?? this.subject),
      statuses: statuses ?? this.statuses,
      sort: sort ?? this.sort,
    );
  }

  bool get _defaultStatuses => setEquals(statuses, defaultStatuses);

  List<StudentFilterChip> get chips {
    final trimmed = trimmedSearch;
    return [
      if (trimmed.isNotEmpty)
        StudentFilterChip(label: '“$trimmed”', without: copyWith(search: '')),
      if (schoolClass != null)
        StudentFilterChip(
          label: schoolClass!.label,
          without: copyWith(clearClass: true),
        ),
      if (arm != null)
        StudentFilterChip(
          label: 'Arm ${arm!.label}',
          without: copyWith(clearArm: true),
        ),
      if (subject != null)
        StudentFilterChip(
          label: subject!.label,
          without: copyWith(clearSubject: true),
        ),
      if (!_defaultStatuses)
        if (statuses.isEmpty)
          StudentFilterChip(
            label: 'Any status',
            without: copyWith(statuses: defaultStatuses),
          )
        else
          for (final status in StudentStatusFilter.values)
            if (statuses.contains(status))
              StudentFilterChip(
                label: status.label,
                without: copyWith(statuses: _withoutStatus(status)),
              ),
      if (sort != StudentSort.byClass)
        StudentFilterChip(
          label: sort.label,
          without: copyWith(sort: StudentSort.byClass),
        ),
    ];
  }

  Set<StudentStatusFilter> _withoutStatus(StudentStatusFilter status) {
    final rest = {...statuses}..remove(status);
    return rest.isEmpty ? defaultStatuses : rest;
  }

  int get activeCount => chips.length;
  bool get isDefault => chips.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is StudentFilter &&
      other.search == search &&
      other.schoolClass == schoolClass &&
      other.arm == arm &&
      other.subject == subject &&
      setEquals(other.statuses, statuses) &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(
    search,
    schoolClass,
    arm,
    subject,
    Object.hashAllUnordered(statuses),
    sort,
  );
}

/// One page of the Students list from `list_students`.
class StudentPage {
  const StudentPage({
    required this.rows,
    required this.nextCursor,
    required this.total,
    required this.groupCounts,
  });

  final List<StudentSummary> rows;

  /// Pass this back for the next page. Null on the last page.
  final String? nextCursor;

  /// Everyone matching every filter, not just this page.
  final int total;

  /// Students in each arm across the whole filtered set, keyed by arm id
  /// (`''` for students with no arm), so a header is right before its whole
  /// group has loaded.
  final Map<String, int> groupCounts;

  factory StudentPage.fromJson(Map<String, dynamic> json) => StudentPage(
    rows: [
      for (final row in (json['rows'] as List? ?? const []))
        StudentSummary.fromJson(Map<String, dynamic>.from(row as Map)),
    ],
    nextCursor: json['next_cursor'] as String?,
    total: (json['total'] as num?)?.toInt() ?? 0,
    groupCounts: {
      for (final group in (json['groups'] as List? ?? const []))
        ((group as Map)['arm_id'] as String? ?? ''):
            (group['count'] as num).toInt(),
    },
  );
}
