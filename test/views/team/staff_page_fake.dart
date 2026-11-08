import 'package:hamrash_admin/api/models/team/staff_filter.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/staff_page.dart';

/// What `list_staff` would answer for [all], close enough for the screens:
/// the filters, the chip counts (which ignore the login filter) and a cursor
/// that is just the index of the next row. Sorting is left to the caller's
/// order.
StaffPage fakeStaffPage(
  List<StaffMember> all, {
  StaffFilter filter = StaffFilter.initial,
  int limit = 30,
  String? cursor,
}) {
  bool matches(StaffMember person, {required bool withLogin}) {
    final search = filter.trimmedSearch.toLowerCase();
    if (search.isNotEmpty && !person.fullName.toLowerCase().contains(search)) {
      return false;
    }
    if (filter.roles.isNotEmpty &&
        !filter.roles.contains(person.login?.role)) {
      return false;
    }
    if (filter.staffType.value != null &&
        person.staffType != filter.staffType.value) {
      return false;
    }
    if (filter.statuses.isNotEmpty &&
        !filter.statuses.contains(person.status)) {
      return false;
    }
    if (!withLogin) return true;
    return switch (filter.login) {
      StaffLoginFilter.all => true,
      StaffLoginFilter.onApp =>
        person.access == StaffAccess.onApp ||
            person.access == StaffAccess.owner,
      StaffLoginFilter.codeReady => person.access == StaffAccess.invitePending,
      StaffLoginFilter.notOnApp => person.access == StaffAccess.notOnApp,
      StaffLoginFilter.suspended => person.access == StaffAccess.suspended,
    };
  }

  final base = [
    for (final person in all)
      if (matches(person, withLogin: false)) person,
  ];
  final counts = StaffCounts(
    all: base.length,
    onApp: base
        .where(
          (p) =>
              p.access == StaffAccess.onApp || p.access == StaffAccess.owner,
        )
        .length,
    codeReady: base.where((p) => p.access == StaffAccess.invitePending).length,
    notOnApp: base.where((p) => p.access == StaffAccess.notOnApp).length,
    suspended: base.where((p) => p.access == StaffAccess.suspended).length,
  );
  final rows = [
    for (final person in all)
      if (matches(person, withLogin: true)) person,
  ];
  final start = cursor == null ? 0 : int.parse(cursor);
  final end = (start + limit).clamp(0, rows.length);
  return StaffPage(
    rows: rows.sublist(start.clamp(0, rows.length), end),
    nextCursor: end < rows.length ? '$end' : null,
    total: rows.length,
    counts: counts,
  );
}
