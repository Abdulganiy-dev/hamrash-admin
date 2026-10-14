import 'package:flutter/material.dart';

/// A term as saved, e.g. "First term", 7 Sep – 11 Dec.
class AcademicTerm {
  const AcademicTerm({
    required this.id,
    required this.name,
    required this.sequence,
    required this.dates,
    required this.isCurrent,
  });

  factory AcademicTerm.fromJson(Map<String, dynamic> json) => AcademicTerm(
    id: json['id'] as String,
    name: json['name'] as String,
    sequence: json['sequence'] as int,
    dates: DateTimeRange(
      start: DateTime.parse(json['starts_on'] as String),
      end: DateTime.parse(json['ends_on'] as String),
    ),
    isCurrent: json['is_current'] as bool,
  );

  static const columns = 'id, name, sequence, starts_on, ends_on, is_current';

  final String id;
  final String name;
  final int sequence;
  final DateTimeRange dates;
  final bool isCurrent;
}

/// Where a session is in its life, for the list's badges and the details
/// page's label.
enum SessionStatus {
  current('Current'),
  upcoming('Upcoming'),

  /// Started but not current, and not over yet.
  open('Open'),

  /// Over, but not closed yet.
  toClose('To close'),
  closed('Closed');

  const SessionStatus(this.label);

  final String label;
}

/// A school year, e.g. 2026/27, with its terms in order.
class AcademicSession {
  const AcademicSession({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.dates,
    required this.isCurrent,
    required this.terms,
    this.closedAt,
  });

  factory AcademicSession.fromJson(Map<String, dynamic> json) {
    final terms =
        (json['terms'] as List<dynamic>? ?? const [])
            .map((row) => AcademicTerm.fromJson(row as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return AcademicSession(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      dates: DateTimeRange(
        start: DateTime.parse(json['starts_on'] as String),
        end: DateTime.parse(json['ends_on'] as String),
      ),
      isCurrent: json['is_current'] as bool,
      closedAt: switch (json['closed_at']) {
        final String value => DateTime.parse(value).toLocal(),
        _ => null,
      },
      terms: terms,
    );
  }

  /// The session with its terms, embedded through their foreign key.
  static const columns =
      'id, organization_id, name, starts_on, ends_on, is_current, closed_at, '
      'terms:academic_terms!academic_terms_session_fkey(${AcademicTerm.columns})';

  final String id;
  final String organizationId;
  final String name;
  final DateTimeRange dates;
  final bool isCurrent;
  final DateTime? closedAt;
  final List<AcademicTerm> terms;

  bool get isClosed => closedAt != null;

  int? get currentTermIndex {
    final index = terms.indexWhere((term) => term.isCurrent);
    return index < 0 ? null : index;
  }

  SessionStatus statusOn(DateTime today) {
    if (isClosed) return SessionStatus.closed;
    if (isCurrent) return SessionStatus.current;
    final day = DateUtils.dateOnly(today);
    if (dates.start.isAfter(day)) return SessionStatus.upcoming;
    if (dates.end.isBefore(day)) return SessionStatus.toClose;
    return SessionStatus.open;
  }
}

/// What still uses a session, from the database's `session_usage`. A session
/// can only be removed when all of these are zero.
class SessionUsage {
  const SessionUsage({
    required this.terms,
    required this.placements,
    required this.studentSubjects,
    required this.classTeachers,
    required this.teachingAssignments,
  });

  factory SessionUsage.fromJson(Map<String, dynamic> json) => SessionUsage(
    terms: json['terms'] as int,
    placements: json['placements'] as int,
    studentSubjects: json['student_subjects'] as int,
    classTeachers: json['class_teachers'] as int,
    teachingAssignments: json['teaching_assignments'] as int,
  );

  final int terms;
  final int placements;
  final int studentSubjects;
  final int classTeachers;
  final int teachingAssignments;

  bool get isEmpty =>
      terms +
          placements +
          studentSubjects +
          classTeachers +
          teachingAssignments ==
      0;

  /// Why the session can't be removed, apart from its own terms (which go
  /// with it), or null when nothing else uses it.
  String? get blockedReasonBesidesTerms {
    if (placements > 0) {
      return '${_count(placements, 'student')} are placed in classes for it.';
    }
    if (studentSubjects > 0 || teachingAssignments > 0 || classTeachers > 0) {
      return 'Its subjects and teachers are still set up.';
    }
    return null;
  }

  static String _count(int n, String noun) =>
      n == 1 ? '1 $noun' : '$n ${noun}s';
}
