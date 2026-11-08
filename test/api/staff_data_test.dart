import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/staff_private_details.dart';

StaffMember _staff({required bool fullNameFields}) => StaffMember(
  id: 's1',
  firstName: 'Ada',
  middleName: fullNameFields ? 'Chidi' : null,
  lastName: 'Okafor',
  staffType: 'teaching',
  status: StaffRecordStatus.active,
  createdAt: DateTime(2026),
);

void main() {
  test('parses middle name, gender and private details safely', () {
    final staff = StaffMember.fromJson({
      'id': 's1',
      'first_name': 'Ada',
      'middle_name': 'Chidi',
      'last_name': 'Okafor',
      'job_title': 'Teacher',
      'gender': 'female',
      'phone': null,
      'email': 'ada@example.com',
      'photo_url': null,
      'staff_number': 'KCL/STF/0001',
      'staff_type': 'teaching',
      'status': 'active',
      'created_at': '2026-11-08T09:00:00Z',
      'member_id': null,
      'private_details': {
        'address': '1 School Road',
        'residence_state': 'Lagos',
        'residence_lga': 'Ikeja',
      },
    });

    expect(staff.middleName, 'Chidi');
    expect(staff.gender, StaffGender.female);
    expect(staff.privateDetails?.address, '1 School Road');
    expect(staff.privateDetails?.residenceState, 'Lagos');
    expect(staff.privateDetails?.residenceLga, 'Ikeja');
  });

  test('null gender and private details stay null', () {
    final staff = StaffMember.fromJson({
      'id': 's1',
      'first_name': 'Ada',
      'last_name': 'Okafor',
      'job_title': null,
      'gender': null,
      'staff_type': 'non_teaching',
      'status': 'active',
      'created_at': '2026-11-08T09:00:00Z',
    });

    expect(staff.middleName, isNull);
    expect(staff.gender, isNull);
    expect(staff.privateDetails, isNull);
  });

  test('fullNameWithMiddle uses the middle name only when present', () {
    expect(_staff(fullNameFields: true).fullNameWithMiddle, 'Ada Chidi Okafor');
    expect(_staff(fullNameFields: false).fullNameWithMiddle, 'Ada Okafor');
  });

  test('record status values and labels match staff_status', () {
    expect(StaffRecordStatus.active.value, 'active');
    expect(StaffRecordStatus.onLeave.value, 'on_leave');
    expect(StaffRecordStatus.exited.value, 'exited');
    expect(StaffRecordStatus.active.label, 'Active');
    expect(StaffRecordStatus.onLeave.label, 'On leave');
    expect(StaffRecordStatus.exited.label, 'Exited');
    expect(StaffRecordStatus.fromJson('on_leave'), StaffRecordStatus.onLeave);
    expect(() => StaffRecordStatus.fromJson('gone'), throwsFormatException);
  });

  test('gender values and labels match public.gender', () {
    expect(StaffGender.male.value, 'male');
    expect(StaffGender.female.value, 'female');
    expect(StaffGender.male.label, 'Male');
    expect(StaffGender.female.label, 'Female');
    expect(StaffGender.fromJson('female'), StaffGender.female);
    expect(() => StaffGender.fromJson('other'), throwsFormatException);
  });

  test('private details read the residence fields', () {
    final details = StaffPrivateDetails.fromJson({
      'date_of_birth': '1990-05-01',
      'address': '1 School Road',
      'state_of_origin': 'Anambra',
      'employment_date': '2020-09-01',
      'residence_state': 'Lagos',
      'residence_lga': 'Ikeja',
    });

    expect(details.dateOfBirth, DateTime(1990, 5, 1));
    expect(details.address, '1 School Road');
    expect(details.stateOfOrigin, 'Anambra');
    expect(details.employmentDate, DateTime(2020, 9, 1));
    expect(details.residenceState, 'Lagos');
    expect(details.residenceLga, 'Ikeja');
  });

  test('private details columns include residence', () {
    expect(StaffPrivateDetails.columns, contains('residence_state'));
    expect(StaffPrivateDetails.columns, contains('residence_lga'));
  });
}
