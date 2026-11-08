import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_filter.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';

void main() {
  group('StaffFilter', () {
    test('starts on active staff by name with nothing applied', () {
      const filter = StaffFilter.initial;

      expect(filter.isDefault, isTrue);
      expect(filter.activeCount, 0);
      expect(filter.chips, isEmpty);
      expect(filter.statuses, {StaffRecordStatus.active});
      expect(filter.sort, StaffSort.name);
    });

    test('a blank search is not a filter', () {
      expect(const StaffFilter(search: '   ').isDefault, isTrue);
    });

    test('every applied filter is one chip, in the order the list shows', () {
      const filter = StaffFilter(
        search: 'zzz',
        login: StaffLoginFilter.onApp,
        roles: {OrganizationMemberRole.teacher, OrganizationMemberRole.bursar},
        staffType: StaffTypeFilter.teaching,
        statuses: {StaffRecordStatus.onLeave, StaffRecordStatus.exited},
        sort: StaffSort.newest,
      );

      expect(filter.isDefault, isFalse);
      expect(filter.chips.map((chip) => chip.label), [
        '“zzz”',
        'On app',
        'Bursar',
        'Teacher',
        'Teaching',
        'On leave',
        'Exited',
        'Newest first',
      ]);
      expect(filter.activeCount, 8);
    });

    test('the default status alone is not a chip, any other is', () {
      expect(
        const StaffFilter(statuses: {StaffRecordStatus.exited}).activeCount,
        1,
      );
      expect(
        const StaffFilter(
          statuses: {StaffRecordStatus.active, StaffRecordStatus.onLeave},
        ).activeCount,
        2,
      );
      // No status ticked means every status: not the default, one chip.
      const any = StaffFilter(statuses: {});
      expect(any.isDefault, isFalse);
      expect(any.chips.single.label, 'Any status');
    });

    test('a chip knows the filter without it', () {
      const filter = StaffFilter(
        search: 'ada',
        roles: {OrganizationMemberRole.admin, OrganizationMemberRole.teacher},
        statuses: {StaffRecordStatus.exited},
      );

      final byLabel = {for (final chip in filter.chips) chip.label: chip};
      expect(byLabel['“ada”']!.without.search, '');
      expect(byLabel['Admin']!.without.roles, {OrganizationMemberRole.teacher});
      // Taking off the last status goes back to Active, not to every status.
      expect(
        byLabel['Exited']!.without.statuses,
        StaffFilter.defaultStatuses,
      );
    });

    test('equal filters compare equal', () {
      expect(
        const StaffFilter(roles: {OrganizationMemberRole.admin}),
        const StaffFilter(roles: {OrganizationMemberRole.admin}),
      );
      expect(
        const StaffFilter(),
        isNot(const StaffFilter(sort: StaffSort.newest)),
      );
    });
  });
}
