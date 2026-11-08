import 'package:hamrash_admin/api/models/team/staff_member.dart';

/// The numbers behind the Staffs list's login chips, from `list_staff`.
/// They follow the search, staff type, status and role filters but not the
/// login filter, so every chip shows how many people it would list.
class StaffCounts {
  const StaffCounts({
    required this.all,
    required this.onApp,
    required this.codeReady,
    required this.notOnApp,
    required this.suspended,
  });

  static const zero = StaffCounts(
    all: 0,
    onApp: 0,
    codeReady: 0,
    notOnApp: 0,
    suspended: 0,
  );

  final int all;

  /// Active logins, the owner included.
  final int onApp;
  final int codeReady;
  final int notOnApp;
  final int suspended;

  factory StaffCounts.fromJson(Map<String, dynamic> json) => StaffCounts(
    all: (json['all'] as num?)?.toInt() ?? 0,
    onApp: (json['on_app'] as num?)?.toInt() ?? 0,
    codeReady: (json['code_ready'] as num?)?.toInt() ?? 0,
    notOnApp: (json['not_on_app'] as num?)?.toInt() ?? 0,
    suspended: (json['suspended'] as num?)?.toInt() ?? 0,
  );
}

/// One page of the staff list from `list_staff`.
class StaffPage {
  const StaffPage({
    required this.rows,
    required this.nextCursor,
    required this.total,
    required this.counts,
  });

  final List<StaffMember> rows;

  /// Pass this back for the next page. Null on the last page.
  final String? nextCursor;

  /// Everyone matching every filter, not just this page.
  final int total;
  final StaffCounts counts;

  factory StaffPage.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'];
    return StaffPage(
      rows: [
        for (final row in (json['rows'] as List? ?? const []))
          StaffMember.fromJson(Map<String, dynamic>.from(row as Map)),
      ],
      nextCursor: json['next_cursor'] as String?,
      total: (json['total'] as num?)?.toInt() ?? 0,
      counts: counts is Map
          ? StaffCounts.fromJson(Map<String, dynamic>.from(counts))
          : StaffCounts.zero,
    );
  }
}
