import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/organization_models/claim_code_check.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/organization_member_service.dart';
import 'package:hamrash_admin/views/onboarding/join/join_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ClaimCodeService extends OrganizationMemberService {
  _ClaimCodeService(this.checkResult)
    : super(SupabaseClient('https://example.supabase.co', 'test-key'));

  ClaimCodeCheck checkResult;
  OrganizationMember? redeemResult;
  int redeemCalls = 0;
  String? firstName;
  String? lastName;
  String? phone;

  @override
  Future<ClaimCodeCheck> checkClaimCode(String code) async => checkResult;

  @override
  Future<OrganizationMember?> redeemClaimCode({
    required String code,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    redeemCalls++;
    this.firstName = firstName;
    this.lastName = lastName;
    this.phone = phone;
    return redeemResult;
  }
}

ClaimCodeCheck _check({
  ClaimCodeStatus status = ClaimCodeStatus.ok,
  OrganizationMemberRole? role = OrganizationMemberRole.principal,
  String? app = 'admin',
  bool needsName = false,
  int triesLeft = 5,
}) => ClaimCodeCheck(
  status: status,
  organizationId: 'org-1',
  schoolName: 'Kings College',
  schoolCode: 'HMR-123456',
  schoolState: 'Lagos',
  role: role,
  app: app,
  needsName: needsName,
  triesLeft: triesLeft,
);

OrganizationMember _member() => OrganizationMember(
  id: 'member-1',
  organizationId: 'org-1',
  clerkUserId: 'user-1',
  role: OrganizationMemberRole.principal,
  status: OrganizationMemberStatus.active,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  test('checks a code, confirms the school, then redeems on Join', () async {
    final service = _ClaimCodeService(_check())..redeemResult = _member();
    var joined = false;
    final model = JoinViewModel(service: service, onJoin: () => joined = true);
    addTearDown(model.dispose);

    model.code.text = 'KQ7M-2X9B';
    await model.continueWithCode();

    expect(model.phase, JoinPhase.confirmStaff);
    expect(model.schoolName, 'Kings College');
    expect(model.role, 'Principal');
    expect(service.redeemCalls, 0);

    await model.joinSchool();
    expect(service.redeemCalls, 1);
    expect(joined, isTrue);
  });

  test('uses the returned attempt count and blocks a wrong-app code', () async {
    final service = _ClaimCodeService(
      _check(status: ClaimCodeStatus.notFound, triesLeft: 3),
    );
    final model = JoinViewModel(service: service);
    addTearDown(model.dispose);
    model.code.text = 'KQ7M-2X9B';

    await model.continueWithCode();
    expect(model.phase, JoinPhase.wrongCode);
    expect(model.triesLeft, 3);

    service.checkResult = _check(
      role: OrganizationMemberRole.teacher,
      app: 'staff',
    );
    await model.continueWithCode();
    expect(model.phase, JoinPhase.codeForAnotherApp);
    expect(model.targetApp, 'Teacher');
    await model.joinSchool();
    expect(service.redeemCalls, 0);
  });

  test('owner redemption validates the full name and phone number', () async {
    final service = _ClaimCodeService(
      _check(role: OrganizationMemberRole.owner, needsName: true),
    )..redeemResult = _member();
    final model = JoinViewModel(service: service);
    addTearDown(model.dispose);
    model.code.text = 'KQ7M-2X9B';

    await model.continueWithCode();
    expect(model.phase, JoinPhase.confirmOwner);
    await model.joinSchool();
    expect(model.nameError, 'Full name is required');
    expect(model.phoneError, 'Phone number is required');
    expect(service.redeemCalls, 0);

    model.fullName.text = 'Amina';
    model.phoneNumber.text = '8030000000';
    await model.joinSchool();
    expect(model.nameError, 'Enter your first and last name');
    expect(model.phoneError, 'Enter a valid Nigerian phone number');
    expect(service.redeemCalls, 0);

    model.fullName.text = 'Amina Bello';
    model.phoneNumber.text = '08030000000';
    await model.joinSchool();
    expect(service.firstName, 'Amina');
    expect(service.lastName, 'Bello');
    expect(service.phone, '+2348030000000');
    expect(service.redeemCalls, 1);
  });

  for (final phone in ['+2348030000000', '2348030000000']) {
    test('owner redemption accepts $phone', () async {
      final service = _ClaimCodeService(
        _check(role: OrganizationMemberRole.owner, needsName: true),
      )..redeemResult = _member();
      final model = JoinViewModel(service: service);
      addTearDown(model.dispose);
      model.code.text = 'KQ7M-2X9B';
      await model.continueWithCode();

      model.fullName.text = 'Amina Bello';
      model.phoneNumber.text = phone;
      await model.joinSchool();

      expect(model.phoneError, isNull);
      expect(service.phone, '+2348030000000');
      expect(service.redeemCalls, 1);
    });
  }

  test('a locked result disables code submission until retry time', () async {
    final service = _ClaimCodeService(
      _check(status: ClaimCodeStatus.locked, triesLeft: 0),
    );
    final model = JoinViewModel(service: service);
    addTearDown(model.dispose);
    model.code.text = 'KQ7M-2X9B';

    await model.continueWithCode();
    expect(model.phase, JoinPhase.tooManyTries);
    expect(model.canContinue, isFalse);
    expect(model.codeAttemptsMessage, contains('Too many tries'));
  });
}
