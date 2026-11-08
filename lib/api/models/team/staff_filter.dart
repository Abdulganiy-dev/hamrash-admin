import 'package:flutter/foundation.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';

/// Where a person's login has got to, as `list_staff` filters on it.
enum StaffLoginFilter {
  all('all', 'All'),
  onApp('on_app', 'On app'),
  codeReady('code_ready', 'Code ready'),
  notOnApp('not_on_app', 'Not on app'),
  suspended('suspended', 'Suspended');

  const StaffLoginFilter(this.value, this.label);

  final String value;
  final String label;
}

enum StaffTypeFilter {
  all(null, 'All'),
  teaching('teaching', 'Teaching'),
  nonTeaching('non_teaching', 'Non-teaching');

  const StaffTypeFilter(this.value, this.label);

  /// `staff_type`, or null for both.
  final String? value;
  final String label;
}

enum StaffSort {
  name('name', 'Name A–Z'),
  newest('newest', 'Newest first');

  const StaffSort(this.value, this.label);

  final String value;
  final String label;
}

/// One applied filter, as the removable chip on the Staffs list.
class StaffFilterChip {
  const StaffFilterChip({required this.label, required this.without});

  final String label;

  /// The filter with just this one taken off.
  final StaffFilter without;
}

/// Everything the Staffs list is narrowed by: search, login, roles, staff
/// type, record status and sort.
///
/// An empty [roles] set means every role. An empty [statuses] set means every
/// status, so it is not the default; the default is Active only.
@immutable
class StaffFilter {
  const StaffFilter({
    this.search = '',
    this.login = StaffLoginFilter.all,
    this.roles = const {},
    this.staffType = StaffTypeFilter.all,
    this.statuses = defaultStatuses,
    this.sort = StaffSort.name,
  });

  static const initial = StaffFilter();

  static const defaultStatuses = {StaffRecordStatus.active};

  /// What the roles filter offers: the roles a staff login can have.
  static const roleOptions = [
    OrganizationMemberRole.owner,
    OrganizationMemberRole.admin,
    OrganizationMemberRole.principal,
    OrganizationMemberRole.vicePrincipal,
    OrganizationMemberRole.bursar,
    OrganizationMemberRole.teacher,
    OrganizationMemberRole.staff,
  ];

  final String search;
  final StaffLoginFilter login;
  final Set<OrganizationMemberRole> roles;
  final StaffTypeFilter staffType;
  final Set<StaffRecordStatus> statuses;
  final StaffSort sort;

  String get trimmedSearch => search.trim();

  StaffFilter copyWith({
    String? search,
    StaffLoginFilter? login,
    Set<OrganizationMemberRole>? roles,
    StaffTypeFilter? staffType,
    Set<StaffRecordStatus>? statuses,
    StaffSort? sort,
  }) => StaffFilter(
    search: search ?? this.search,
    login: login ?? this.login,
    roles: roles ?? this.roles,
    staffType: staffType ?? this.staffType,
    statuses: statuses ?? this.statuses,
    sort: sort ?? this.sort,
  );

  bool get _defaultStatuses => setEquals(statuses, defaultStatuses);

  /// The applied filters, in the order the list shows them: search, login,
  /// each role, staff type, each status beyond the default, sort.
  List<StaffFilterChip> get chips {
    final trimmed = trimmedSearch;
    return [
      if (trimmed.isNotEmpty)
        StaffFilterChip(
          label: '“$trimmed”',
          without: copyWith(search: ''),
        ),
      if (login != StaffLoginFilter.all)
        StaffFilterChip(
          label: login.label,
          without: copyWith(login: StaffLoginFilter.all),
        ),
      for (final role in OrganizationMemberRole.values)
        if (roles.contains(role))
          StaffFilterChip(
            label: role.teamLabel,
            without: copyWith(roles: {...roles}..remove(role)),
          ),
      if (staffType != StaffTypeFilter.all)
        StaffFilterChip(
          label: staffType.label,
          without: copyWith(staffType: StaffTypeFilter.all),
        ),
      if (!_defaultStatuses)
        if (statuses.isEmpty)
          StaffFilterChip(
            label: 'Any status',
            without: copyWith(statuses: defaultStatuses),
          )
        else
          for (final status in StaffRecordStatus.values)
            if (statuses.contains(status))
              StaffFilterChip(
                label: status.label,
                without: copyWith(statuses: _withoutStatus(status)),
              ),
      if (sort != StaffSort.name)
        StaffFilterChip(
          label: sort.label,
          without: copyWith(sort: StaffSort.name),
        ),
    ];
  }

  /// Taking off the last status goes back to the default rather than to
  /// "every status".
  Set<StaffRecordStatus> _withoutStatus(StaffRecordStatus status) {
    final rest = {...statuses}..remove(status);
    return rest.isEmpty ? defaultStatuses : rest;
  }

  /// How many filter chips are applied (the badge on the filter button).
  int get activeCount => chips.length;

  bool get isDefault => chips.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is StaffFilter &&
      other.search == search &&
      other.login == login &&
      setEquals(other.roles, roles) &&
      other.staffType == staffType &&
      setEquals(other.statuses, statuses) &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(
    search,
    login,
    Object.hashAllUnordered(roles),
    staffType,
    Object.hashAllUnordered(statuses),
    sort,
  );
}
