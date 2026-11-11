import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_job_title.dart';
import 'package:hamrash_admin/api/models/team/staff_filter.dart';
import 'package:hamrash_admin/api/models/team/staff_member.dart';
import 'package:hamrash_admin/api/models/team/staff_page.dart';
import 'package:hamrash_admin/api/models/team/staff_private_details.dart';
import 'package:hamrash_admin/api/models/team/invite_code.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/api/services/supabase_services/team_service.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/views/team/add_staff/add_staff_view_model.dart';
import 'package:hamrash_admin/views/team/staff_detail/staff_detail_view_model.dart';
import 'package:hamrash_admin/views/team/team_view_model.dart';
import 'package:hamrash_admin/views/team/widgets/access_card.dart';

import 'staff_page_fake.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _now = DateTime(2026, 11, 8, 12);

StaffLogin _login({
  String id = 'm1',
  OrganizationMemberRole role = OrganizationMemberRole.teacher,
  OrganizationMemberStatus status = OrganizationMemberStatus.invited,
  String? code = 'K7M2QX9P',
  DateTime? joinedAt,
  DateTime? createdAt,
  String? clerkUserId,
}) => StaffLogin(
  id: id,
  role: role,
  status: status,
  claimCode: code,
  joinedAt: joinedAt,
  createdAt: createdAt ?? DateTime(2026, 11, 5),
  clerkUserId: clerkUserId,
);

StaffMember _staff({
  required String id,
  required String firstName,
  String lastName = 'Okafor',
  String? jobTitle,
  StaffRecordStatus status = StaffRecordStatus.active,
  DateTime? createdAt,
  StaffLogin? login,
}) => StaffMember(
  id: id,
  firstName: firstName,
  lastName: lastName,
  jobTitle: jobTitle,
  phone: '+2348030000000',
  email: null,
  staffType: 'non_teaching',
  status: status,
  createdAt: createdAt ?? DateTime(2026, 11, 8),
  memberId: login?.id,
  login: login,
);

StaffMember _with(StaffMember staff, {StaffLogin? login, String? memberId}) =>
    StaffMember(
      id: staff.id,
      firstName: staff.firstName,
      lastName: staff.lastName,
      jobTitle: staff.jobTitle,
      phone: staff.phone,
      email: staff.email,
      photoUrl: staff.photoUrl,
      staffType: staff.staffType,
      status: staff.status,
      createdAt: staff.createdAt,
      memberId: memberId ?? staff.memberId,
      login: login ?? staff.login,
    );

final _owner = _staff(
  id: 'own',
  firstName: 'Amina',
  lastName: 'Bello',
  jobTitle: 'Owner',
  login: _login(
    id: 'm-owner',
    role: OrganizationMemberRole.owner,
    status: OrganizationMemberStatus.active,
    code: null,
    joinedAt: DateTime(2026, 9, 3),
    clerkUserId: 'user-owner',
  ),
);

final _admin = _staff(
  id: 'adm',
  firstName: 'Chidi',
  lastName: 'Eze',
  jobTitle: 'Admin',
  login: _login(
    id: 'm-admin',
    role: OrganizationMemberRole.admin,
    status: OrganizationMemberStatus.active,
    code: null,
    joinedAt: DateTime(2026, 9, 3),
    clerkUserId: 'user-admin',
  ),
);

final _bursar = _staff(
  id: 'bur',
  firstName: 'Ada',
  lastName: 'Nwosu',
  jobTitle: 'Bursar',
  login: _login(
    id: 'm-bursar',
    role: OrganizationMemberRole.bursar,
    createdAt: DateTime(2026, 11, 5),
  ),
);

final _teacher = _staff(
  id: 'tch',
  firstName: 'Tunde',
  lastName: 'Ade',
  jobTitle: 'Teacher',
  createdAt: DateTime(2026, 11, 8),
);

class _Team extends TeamService {
  _Team(this.people)
    : super(SupabaseClient('https://example.supabase.co', 'k'));

  List<StaffMember> people;
  Object? failWith;
  String? invitedRole;
  String? changedRole;
  bool? suspended;
  String? removedId;
  String? createdPhone;
  String? createdJobTitle;
  String? createdStaffType;
  String? createdMiddleName;
  StaffGender? createdGender;
  DateTime? createdDateOfBirth;
  DateTime? createdEmploymentDate;
  String? createdStateOfOrigin;
  String? createdAddress;
  String? createdResidenceState;
  String? createdResidenceLga;

  @override
  Future<StaffPage> listStaffPage({
    required String organizationId,
    StaffFilter filter = StaffFilter.initial,
    int limit = TeamService.pageSize,
    String? cursor,
  }) async =>
      fakeStaffPage(people, filter: filter, limit: limit, cursor: cursor);

  @override
  Future<StaffMember> getStaff(String staffId) async =>
      people.firstWhere((person) => person.id == staffId);

  int editReads = 0;

  @override
  Future<({StaffMember staff, StaffPrivateDetails privateDetails})>
  getStaffForEditing(String staffId) async {
    editReads++;
    return (
      staff: people.firstWhere((person) => person.id == staffId),
      privateDetails: const StaffPrivateDetails(),
    );
  }

  @override
  Future<StaffMember> createStaff({
    required String organizationId,
    required String firstName,
    required String lastName,
    required String? phone,
    required String? email,
    required String jobTitle,
    required String staffType,
    String? middleName,
    StaffGender? gender,
    DateTime? dateOfBirth,
    DateTime? employmentDate,
    String? stateOfOrigin,
    String? address,
    String? residenceState,
    String? residenceLga,
  }) async {
    if (failWith case final error?) throw error;
    createdPhone = phone;
    createdJobTitle = jobTitle;
    createdStaffType = staffType;
    createdMiddleName = middleName;
    createdGender = gender;
    createdDateOfBirth = dateOfBirth;
    createdEmploymentDate = employmentDate;
    createdStateOfOrigin = stateOfOrigin;
    createdAddress = address;
    createdResidenceState = residenceState;
    createdResidenceLga = residenceLga;
    final staff = _staff(
      id: 'new',
      firstName: firstName,
      lastName: lastName,
      jobTitle: jobTitle,
    );
    people = [...people, staff];
    return staff;
  }

  @override
  Future<String> inviteStaff({
    required String staffId,
    required OrganizationMemberRole role,
  }) async {
    if (failWith case final error?) throw error;
    invitedRole = role.value;
    final index = people.indexWhere((person) => person.id == staffId);
    final login = _login(id: 'm-new', role: role, createdAt: _now);
    people[index] = _with(people[index], login: login, memberId: 'm-new');
    return 'K7M2QX9P';
  }

  @override
  Future<void> cancelInvite(String memberId) async {
    if (failWith case final error?) throw error;
    final index = people.indexWhere((person) => person.memberId == memberId);
    people[index] = _with(people[index], memberId: null);
  }

  @override
  Future<void> changeRole({
    required String memberId,
    required OrganizationMemberRole role,
  }) async {
    if (failWith case final error?) throw error;
    changedRole = role.value;
  }

  @override
  Future<void> setSuspended({
    required List<String> memberIds,
    required bool suspended,
  }) async {
    if (failWith case final error?) throw error;
    this.suspended = suspended;
    suspendedMemberIds = memberIds;
  }

  List<String>? suspendedMemberIds;
  OrganizationMemberRole? addedRole;
  String? addedToMember;

  @override
  Future<StaffLogin> addMemberRole({
    required String memberId,
    required OrganizationMemberRole role,
  }) async {
    if (failWith case final error?) throw error;
    addedToMember = memberId;
    addedRole = role;
    final index = people.indexWhere(
      (person) => person.logins.any((login) => login.id == memberId),
    );
    final added = _login(
      id: 'm-added',
      role: role,
      status: OrganizationMemberStatus.active,
      code: null,
      createdAt: _now,
      clerkUserId: people[index].login?.clerkUserId,
    );
    people[index] = people[index].copyWith(
      memberships: [...people[index].logins, added],
    );
    return added;
  }

  @override
  Future<void> removeStaff(String staffId) async {
    if (failWith case final error?) throw error;
    removedId = staffId;
  }
}

MemberSchool _school({
  OrganizationMemberRole role = OrganizationMemberRole.owner,
  List<String> memberIds = const [],
}) => MemberSchool(
  organization: Organization(
    id: 'kings',
    name: 'Kings College',
    status: OrganizationStatus.trial,
    createdBy: 'platform',
    numberPrefix: 'KCL',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  roles: [role],
  memberIds: memberIds,
);

void main() {
  test('codes are shown 4-4 and kept raw for sharing', () {
    expect(InviteCode.format('K7M2QX9P'), 'K7M2-QX9P');
    expect(InviteCode.format('k7m2-qx9p'), 'K7M2-QX9P');
    expect(InviteCode.rawOf('K7M2-QX9P'), 'K7M2QX9P');
  });

  group('TeamViewModel', () {
    Future<(TeamViewModel, _Team)> loaded() async {
      final service = _Team([_owner, _admin, _bursar, _teacher]);
      final model = TeamViewModel(
        school: _school(memberIds: ['m-owner']),
        team: service,
        now: () => _now,
      );
      await model.load();
      return (model, service);
    }

    test('the login filter and the counts come from the server', () async {
      final (model, _) = await loaded();

      expect(model.counts.all, 4);
      expect(model.counts.onApp, 2); // owner and admin
      expect(model.counts.notOnApp, 1); // no login; the invite is "Code ready"
      expect(model.counts.codeReady, 1);

      await model.applyFilter(const StaffFilter(login: StaffLoginFilter.onApp));
      expect(model.staff.map((person) => person.firstName), ['Amina', 'Chidi']);
      expect(model.total, 2);
      // The counts don't move when only the login changes.
      expect(model.counts.all, 4);
      expect(model.counts.notOnApp, 1);
    });

    test('says the role and where the person is', () async {
      final (model, _) = await loaded();

      expect(model.subtitleFor(_owner), 'Owner · you');
      expect(model.subtitleFor(_admin), 'Admin · joined 3 Sep');
      expect(model.subtitleFor(_bursar), 'Bursar · code shared 5 Nov');
      expect(model.subtitleFor(_teacher), 'Teacher · added today');
    });

    test('non-active records suffix the subtitle', () async {
      final (model, _) = await loaded();
      final onLeave = _staff(
        id: 'leave',
        firstName: 'Ada',
        jobTitle: 'Teacher',
        status: StaffRecordStatus.onLeave,
        login: _login(id: 'm-leave'),
      );
      final exited = _staff(
        id: 'gone',
        firstName: 'Bola',
        jobTitle: 'Teacher',
        status: StaffRecordStatus.exited,
      );
      expect(model.subtitleFor(onLeave), endsWith(' · on leave'));
      expect(model.subtitleFor(exited), endsWith(' · exited'));
    });
  });

  group('StaffDetailViewModel', () {
    Future<(StaffDetailViewModel, _Team)> loaded(
      StaffMember staff, {
      OrganizationMemberRole role = OrganizationMemberRole.owner,
      List<String> memberIds = const [],
    }) async {
      final service = _Team([staff, _teacher]);
      final model = StaffDetailViewModel(
        school: _school(role: role, memberIds: memberIds),
        staffId: staff.id,
        team: service,
      );
      await model.load();
      return (model, service);
    }

    test(
      'the Change details record is ready before the button is tapped',
      () async {
        final (model, service) = await loaded(_teacher);
        await Future<void>.delayed(Duration.zero);

        expect(model.editDetailsReady, isTrue);
        expect(service.editReads, 1);

        final record = await model.loadEditDetails();
        expect(record?.staff.id, _teacher.id);
        // Tapping reads nothing more.
        expect(service.editReads, 1);
      },
    );

    test('a refresh drops the cached record and reads a fresh one', () async {
      final (model, service) = await loaded(_teacher);
      await Future<void>.delayed(Duration.zero);

      await model.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(service.editReads, 2);
      expect(model.editDetailsReady, isTrue);
    });

    test('the opening flag starts off so only one tap gets through', () async {
      final (model, _) = await loaded(_teacher);
      expect(model.openingDetails, isFalse);
    });

    test('not on the app offers an invite to a leader', () async {
      final (model, _) = await loaded(
        _teacher,
        role: OrganizationMemberRole.principal,
      );

      expect(model.access, StaffAccess.notOnApp);
      expect(model.identityMeta, 'Teacher · Non-teaching');
      expect(model.canInvite, isTrue);
      expect(model.canManageAccess, isFalse);
      expect(model.canRemove, isFalse);
      expect(model.isOwnerRow, isFalse);
    });

    test(
      'an unused code shows the code, who waits, and the share text',
      () async {
        final (model, _) = await loaded(
          _bursar,
          role: OrganizationMemberRole.principal,
        );

        expect(model.access, StaffAccess.invitePending);
        expect(model.identityMeta, 'Bursar · Non-teaching');
        expect(model.displayCode, 'K7M2-QX9P');
        expect(model.canCancelInvite, isTrue);
        expect(
          model.currentShareMessage,
          "Hi Ada, you've been added to Kings College on Hamrash. Open Hamrash "
          'Admin, sign in with Apple or Google, and enter K7M2-QX9P.',
        );
      },
    );

    test('labels status, employment and state of origin', () async {
      final staff = StaffMember(
        id: 's1',
        firstName: 'Ada',
        lastName: 'Okafor',
        jobTitle: 'Teacher',
        staffType: 'teaching',
        status: StaffRecordStatus.onLeave,
        createdAt: DateTime(2026, 11, 8),
        privateDetails: StaffPrivateDetails(
          employmentDate: DateTime(2020, 9, 1),
          stateOfOrigin: 'Imo',
        ),
      );
      final (model, _) = await loaded(staff);

      expect(model.statusLabel, 'On leave');
      expect(model.employmentDateLabel, '1 Sep 2020');
      expect(model.stateOfOrigin, 'Imo');
    });

    test(
      'the access card also holds remove for someone never invited',
      () async {
        final (model, _) = await loaded(_teacher);

        expect(model.access, StaffAccess.notOnApp);
        expect(model.showAccess, isTrue);
        expect(model.canAddRole, isFalse);
      },
    );

    test('the invite caption uses the login\'s created date', () async {
      final (model, _) = await loaded(_bursar);

      expect(model.invitedCaption, 'Invited 5 Nov');
      expect(model.joinedCaption, isNull);
    });

    test("the teaching card's empty rows still read clearly", () async {
      final (model, _) = await loaded(_teacher);

      expect(model.homeroomCaption, 'Homeroom');
      expect(model.homeroomValue, 'Not assigned');
      expect(model.subjectsCaption, 'Subjects · 0 this session');
      expect(model.subjectsValue, 'None this session');
    });

    test('a claimed login can be managed by its owner', () async {
      final (model, _) = await loaded(_admin, memberIds: ['m-owner']);

      expect(model.access, StaffAccess.onApp);
      expect(model.identityMeta, 'Admin · Non-teaching');
      expect(model.joinedCaption, 'Joined 3 Sep 2026');
      expect(model.canManageAccess, isTrue);
      expect(model.canRemove, isTrue);
      expect(model.canInvite, isFalse);
    });

    test("the owner's row has no actions", () async {
      final (model, _) = await loaded(_owner, memberIds: ['m-owner']);

      expect(model.access, StaffAccess.owner);
      expect(model.identityMeta, 'Owner · Non-teaching');
      expect(model.canManageAccess, isFalse);
      expect(model.canRemove, isFalse);
      expect(model.isOwnerRow, isTrue);
    });

    test(
      'a principal cannot pick Admin, and an admin job title falls back',
      () async {
        final (model, _) = await loaded(
          _staff(id: 'adm2', firstName: 'Ngozi', jobTitle: 'Admin'),
          role: OrganizationMemberRole.principal,
        );

        expect(model.canInviteRole(OrganizationMemberRole.admin), isFalse);
        expect(model.canInviteRole(OrganizationMemberRole.principal), isTrue);
        expect(model.defaultInviteRole, OrganizationMemberRole.principal);
      },
    );

    test('an owner may invite everyone but the owner', () async {
      final (model, _) = await loaded(_teacher);

      expect(model.canInviteRole(OrganizationMemberRole.admin), isTrue);
      expect(model.canInviteRole(OrganizationMemberRole.staff), isTrue);
      expect(model.canInviteRole(OrganizationMemberRole.owner), isFalse);
    });

    test('creating an invite moves the page into its pending state', () async {
      final (model, service) = await loaded(
        _teacher,
        role: OrganizationMemberRole.principal,
      );

      final result = await model.invite(OrganizationMemberRole.teacher);

      expect(result.code, 'K7M2QX9P');
      expect(result.error, isNull);
      expect(service.invitedRole, 'teacher');
      expect(model.access, StaffAccess.invitePending);
      expect(model.changed, isTrue);
      expect(model.displayCode, 'K7M2-QX9P');
    });

    test('a refused invite returns the database reason', () async {
      final (model, service) = await loaded(_teacher);
      service.failWith = const SupabaseRefusal(TeamService.inviteRefused);

      final result = await model.invite(OrganizationMemberRole.admin);

      expect(result.code, isNull);
      expect(result.error, TeamService.inviteRefused);
    });

    test('a refused suspend keeps the confirmation open', () async {
      final (model, service) = await loaded(_admin);
      service.failWith = const SupabaseRefusal(TeamService.ownersOnly);

      await expectLater(
        model.setSuspended(true),
        throwsA(isA<AppAlertError>()),
      );
    });

    test('removing keeps the database message', () async {
      final (model, service) = await loaded(_admin);
      service.failWith = const SupabaseRefusal(
        "This is an owner's staff record. Make someone else the owner first.",
      );

      await expectLater(
        model.remove(),
        throwsA(
          isA<AppAlertError>().having(
            (error) => error.message,
            'message',
            contains("This is an owner's staff record"),
          ),
        ),
      );
    });
  });

  group('AddStaffViewModel', () {
    Future<(AddStaffViewModel, _Team)> form() async {
      final service = _Team([]);
      final model = AddStaffViewModel(school: _school(), team: service);
      addTearDown(model.dispose);
      return (model, service);
    }

    test('needs both names and a job title before saving', () async {
      final (model, _) = await form();
      expect(model.canSave, isFalse);

      model.firstName.text = 'Chinedu';
      model.lastName.text = 'Obi';
      expect(model.canSave, isFalse);

      model.pickJobTitle(StaffJobTitleOption.teacher);
      expect(model.canSave, isTrue);
      expect(model.previewSubtitle, 'Teacher · not on the app yet');
    });

    test('checks an email only when one is typed', () async {
      final (model, _) = await form();
      model.firstName.text = 'Chinedu';
      model.lastName.text = 'Obi';
      model.pickJobTitle(StaffJobTitleOption.teacher);

      model.email.text = 'not-an-email';
      expect(model.canSave, isFalse);
      expect(model.emailProblem, isNotNull);

      model.email.text = '';
      expect(model.canSave, isTrue);
    });

    test('normalises the phone after the +234 prefix', () async {
      final (model, service) = await form();
      model.firstName.text = 'Chinedu';
      model.lastName.text = 'Obi';
      model.pickJobTitle(StaffJobTitleOption.otherStaff);
      model.phone.text = '0803 000 0000';

      final result = await model.save();

      expect(result.staff?.fullName, 'Chinedu Obi');
      expect(service.createdPhone, '+2348030000000');
      expect(service.createdJobTitle, 'Staff');
      expect(service.createdStaffType, 'non_teaching');
    });

    test('the new optional fields go into the payload', () async {
      final (model, service) = await form();
      model.firstName.text = 'Chinedu';
      model.lastName.text = 'Obi';
      model.middleName.text = 'Emeka';
      model.pickJobTitle(StaffJobTitleOption.teacher);
      model.pickGender(StaffGender.male);
      model.pickDateOfBirth(DateTime(1991, 3, 12));
      model.pickEmploymentDate(DateTime(2020, 9, 1));
      model.pickStateOfOrigin('Imo');
      model.pickState('Lagos');
      model.pickLga('Ikeja');
      model.address.text = '12 Allen Avenue';

      await model.save();

      expect(service.createdMiddleName, 'Emeka');
      expect(service.createdGender, StaffGender.male);
      expect(service.createdDateOfBirth, DateTime(1991, 3, 12));
      expect(service.createdEmploymentDate, DateTime(2020, 9, 1));
      expect(service.createdStateOfOrigin, 'Imo');
      expect(service.createdAddress, '12 Allen Avenue');
      expect(service.createdResidenceState, 'Lagos');
      expect(service.createdResidenceLga, 'Ikeja');
    });

    test('gender starts empty and the date of birth is optional', () async {
      final (model, _) = await form();
      expect(model.gender, isNull);
      expect(model.dateOfBirth, isNull);

      model.pickGender(StaffGender.female);
      model.pickDateOfBirth(DateTime(1991, 3, 12));
      expect(model.gender, StaffGender.female);
      expect(model.dateOfBirth, DateTime(1991, 3, 12));
    });

    test('a new state clears the LGA', () async {
      final (model, _) = await form();
      model.pickState('Lagos');
      model.pickLga('Ikeja');
      expect(model.residenceLga, 'Ikeja');

      model.pickState('Oyo');
      expect(model.residenceState, 'Oyo');
      expect(model.residenceLga, isNull);
    });

    test('a teacher is stored as teaching staff', () async {
      final (model, service) = await form();
      model.firstName.text = 'Chinedu';
      model.lastName.text = 'Obi';
      model.pickJobTitle(StaffJobTitleOption.teacher);

      await model.save();

      expect(service.createdJobTitle, 'Teacher');
      expect(service.createdStaffType, 'teaching');
    });

    test('save and add another keeps the job title', () async {
      final (model, _) = await form();
      model.firstName.text = 'Chinedu';
      model.lastName.text = 'Obi';
      model.pickJobTitle(StaffJobTitleOption.bursar);

      await model.save();
      model.clearForAnother();

      expect(model.jobTitle, StaffJobTitleOption.bursar);
      expect(model.firstName.text, isEmpty);
      expect(model.lastName.text, isEmpty);
      expect(model.middleName.text, isEmpty);
      expect(model.address.text, isEmpty);
      expect(model.gender, isNull);
      expect(model.dateOfBirth, isNull);
      expect(model.employmentDate, isNull);
      expect(model.stateOfOrigin, isNull);
      expect(model.residenceState, isNull);
      expect(model.residenceLga, isNull);
      expect(model.addedAny, isTrue);
      expect(model.canSave, isFalse);
    });

    test('a refused save returns the database reason', () async {
      final (model, service) = await form();
      service.failWith = const SupabaseRefusal(TeamService.addRefused);
      model.firstName.text = 'Chinedu';
      model.lastName.text = 'Obi';
      model.pickJobTitle(StaffJobTitleOption.teacher);

      final result = await model.save();

      expect(result.staff, isNull);
      expect(result.error, TeamService.addRefused);
      expect(model.error, TeamService.addRefused);
    });
  });

  group('several roles', () {
    // Ngozi is an admin who also teaches: two active memberships, one person.
    final ngozi =
        _staff(
          id: 'ngo',
          firstName: 'Ngozi',
          lastName: 'Eze',
          jobTitle: 'Teacher',
          login: _login(
            id: 'm-admin-ngozi',
            role: OrganizationMemberRole.admin,
            status: OrganizationMemberStatus.active,
            code: null,
            joinedAt: DateTime(2026, 9, 3),
            clerkUserId: 'user-ngozi',
          ),
        ).copyWith(
          memberships: [
            _login(
              id: 'm-admin-ngozi',
              role: OrganizationMemberRole.admin,
              status: OrganizationMemberStatus.active,
              code: null,
              joinedAt: DateTime(2026, 9, 3),
              clerkUserId: 'user-ngozi',
            ),
            _login(
              id: 'm-teacher-ngozi',
              role: OrganizationMemberRole.teacher,
              status: OrganizationMemberStatus.active,
              code: null,
              joinedAt: DateTime(2026, 9, 3),
              clerkUserId: 'user-ngozi',
            ),
          ],
        );

    Future<(StaffDetailViewModel, _Team)> detail(
      StaffMember staff, {
      OrganizationMemberRole viewer = OrganizationMemberRole.owner,
    }) async {
      final service = _Team([staff]);
      final model = StaffDetailViewModel(
        school: _school(role: viewer),
        staffId: staff.id,
        team: service,
      );
      await model.load();
      return (model, service);
    }

    test('a person holds every role, the login first', () {
      expect(ngozi.roles, [
        OrganizationMemberRole.admin,
        OrganizationMemberRole.teacher,
      ]);
      expect(ngozi.rolesLabel, 'Admin · Teacher');
      expect(_teacher.rolesLabel, 'Teacher');
    });

    test('the list subtitle names them all', () async {
      final service = _Team([ngozi]);
      final model = TeamViewModel(
        school: _school(),
        team: service,
        now: () => _now,
      );
      await model.load();

      expect(model.subtitleFor(ngozi), 'Admin · Teacher · joined 3 Sep');
    });

    test('one card for each app their roles span', () async {
      final (model, _) = await detail(ngozi);

      final apps = model.accessApps();
      expect(apps.map((app) => app.appName), [
        'Hamrash Admin',
        'Hamrash Staff',
      ]);
      expect(apps.map((app) => app.roles), [
        ['Admin'],
        ['Teacher'],
      ]);
      expect(apps.map((app) => app.state), everyElement(AccessState.onApp));
    });

    test('two roles on one app share one card', () async {
      final both = ngozi.copyWith(
        memberships: [
          ngozi.logins.first,
          _login(
            id: 'm-bursar-ngozi',
            role: OrganizationMemberRole.bursar,
            status: OrganizationMemberStatus.active,
            code: null,
            clerkUserId: 'user-ngozi',
          ),
        ],
      );
      final (model, _) = await detail(both);

      final apps = model.accessApps();
      expect(apps, hasLength(1));
      expect(apps.single.roles, ['Admin', 'Bursar']);
    });

    test('someone not on the app gets one tappable app row, no role', () async {
      final (model, _) = await detail(_teacher);

      final apps = model.accessApps(onInvite: () {});
      expect(apps, hasLength(1));
      expect(apps.single.appName, 'Hamrash Staff');
      expect(apps.single.state, AccessState.notOnApp);
      expect(apps.single.roles, isEmpty);
      expect(apps.single.onTap, isNotNull);
    });

    test('Add role only shows for someone active on the app', () async {
      expect((await detail(ngozi)).$1.canAddRole, isTrue);
      expect((await detail(_teacher)).$1.canAddRole, isFalse); // not on app
      expect((await detail(_bursar)).$1.canAddRole, isFalse); // code ready
      final suspended = ngozi.copyWith(
        memberships: [
          for (final login in ngozi.logins)
            StaffLogin(
              id: login.id,
              role: login.role,
              status: OrganizationMemberStatus.suspended,
              createdAt: login.createdAt,
              clerkUserId: login.clerkUserId,
            ),
        ],
      );
      expect(
        (await detail(
          _with(suspended, login: suspended.logins.first),
        )).$1.canAddRole,
        isFalse,
      );
    });

    test('only roles they lack and the viewer may add are offered', () async {
      final (owner, _) = await detail(ngozi);
      expect(owner.addableRoles, [
        OrganizationMemberRole.principal,
        OrganizationMemberRole.vicePrincipal,
        OrganizationMemberRole.bursar,
        OrganizationMemberRole.staff,
      ]);

      // A principal can't give admin, and the person already holds it anyway:
      // use someone who is a teacher only.
      final teacherOnApp = _admin.copyWith(
        memberships: [
          StaffLogin(
            id: 'm-t',
            role: OrganizationMemberRole.teacher,
            status: OrganizationMemberStatus.active,
            createdAt: DateTime(2026, 9, 3),
            clerkUserId: 'user-t',
          ),
        ],
      );
      final (principal, _) = await detail(
        _with(teacherOnApp, login: teacherOnApp.logins.first),
        viewer: OrganizationMemberRole.principal,
      );
      expect(
        principal.addableRoles,
        isNot(contains(OrganizationMemberRole.admin)),
      );
      expect(
        principal.addableRoles,
        isNot(contains(OrganizationMemberRole.owner)),
      );
      expect(
        principal.addableRoles,
        isNot(contains(OrganizationMemberRole.teacher)),
      );
    });

    test('bursars and others who cannot run setup never add roles', () async {
      final (model, _) = await detail(
        ngozi,
        viewer: OrganizationMemberRole.bursar,
      );
      expect(model.canAddRole, isFalse);
    });

    test('adding a role calls the service and refreshes the page', () async {
      final (model, service) = await detail(ngozi);

      final error = await model.addRole(OrganizationMemberRole.bursar);

      expect(error, isNull);
      expect(service.addedRole, OrganizationMemberRole.bursar);
      expect(service.addedToMember, 'm-admin-ngozi');
      expect(model.changed, isTrue);
      expect(model.rolesLabel, 'Admin · Teacher · Bursar');
    });

    test('a refused add returns the database reason', () async {
      final (model, service) = await detail(ngozi);
      service.failWith = const SupabaseRefusal(
        'They already have the bursar role at this school',
      );

      final error = await model.addRole(OrganizationMemberRole.bursar);

      expect(error, 'They already have the bursar role at this school');
      expect(model.changed, isFalse);
    });

    test('the add-role copy follows the design', () async {
      final (model, _) = await detail(ngozi);

      expect(model.addRoleSubtitle, 'Ngozi Eze keeps Admin and Teacher.');
      expect(
        model.addRoleTitle(OrganizationMemberRole.bursar),
        'Make Ngozi a bursar too?',
      );
      expect(
        model.addRoleTitle(OrganizationMemberRole.admin),
        'Make Ngozi an admin too?',
      );
      expect(model.addRoleBullets(OrganizationMemberRole.bursar), [
        'They get fees and school records in Hamrash Admin',
        'They stay Admin and Teacher',
        'No new code. Their sign-in stays the same',
      ]);
      expect(
        model.addRoleConfirmLabel(OrganizationMemberRole.bursar),
        'Add bursar',
      );
      expect(
        model.addedTitle(OrganizationMemberRole.bursar),
        'Ngozi is a bursar too',
      );
      expect(
        model.addedMessage(OrganizationMemberRole.bursar),
        "Their roles are now Admin · Teacher · Bursar. They'll see fees and "
        'school records next time they open Hamrash Admin.',
      );
    });

    test('suspending changes every role together', () async {
      final (model, service) = await detail(ngozi);

      await model.setSuspended(true);

      expect(service.suspended, isTrue);
      expect(service.suspendedMemberIds, ['m-admin-ngozi', 'm-teacher-ngozi']);
    });

    test(
      'with several roles the details sheet has no single role to change',
      () async {
        expect((await detail(ngozi)).$1.canChangeRoleInSheet, isFalse);
        expect((await detail(_admin)).$1.canChangeRoleInSheet, isTrue);
      },
    );
  });
}
