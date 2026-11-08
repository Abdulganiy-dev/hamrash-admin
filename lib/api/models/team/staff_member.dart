import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/models/team/staff_private_details.dart';

/// How a staff member's record reads at a glance. The owner's row, a claimed
/// login, an invite nobody has used yet, no login at all, and a suspended
/// login each get their own badge.
enum StaffAccess {
  owner('Owner', 'Owner'),
  onApp('On app', 'On app'),
  invitePending('Code ready', 'Invite pending'),
  notOnApp('Not on app', 'Not on app'),
  suspended('Suspended', 'Suspended');

  const StaffAccess(this.label, this.detailLabel);

  /// The short badge on the team list.
  final String label;

  /// The pill on the staff detail page, where "invite pending" says more
  /// than "code ready".
  final String detailLabel;
}

/// `public.gender` as the app stores it.
enum StaffGender {
  male('male', 'Male'),
  female('female', 'Female');

  const StaffGender(this.value, this.label);

  final String value;
  final String label;

  static StaffGender fromJson(String value) => StaffGender.values.firstWhere(
    (gender) => gender.value == value,
    orElse: () => throw FormatException('Unknown staff gender: $value'),
  );
}

/// The staff record's own status, separate from the login.
enum StaffRecordStatus {
  active('active', 'Active'),
  onLeave('on_leave', 'On leave'),
  exited('exited', 'Exited');

  const StaffRecordStatus(this.value, this.label);

  final String value;

  /// How the app writes it.
  final String label;

  static StaffRecordStatus fromJson(String value) =>
      StaffRecordStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => throw FormatException('Unknown staff status: $value'),
      );
}

/// A login attached to a staff record, embedded from `organization_members`.
class StaffLogin {
  const StaffLogin({
    required this.id,
    required this.role,
    required this.status,
    this.claimCode,
    this.joinedAt,
    required this.createdAt,
    this.clerkUserId,
  });

  final String id;
  final OrganizationMemberRole role;
  final OrganizationMemberStatus status;

  /// The raw 8 characters. Shown as `K7M2-QX9P`.
  final String? claimCode;
  final DateTime? joinedAt;
  final DateTime createdAt;
  final String? clerkUserId;

  static const columns =
      'id,role,status,claim_code,joined_at,created_at,clerk_user_id';

  factory StaffLogin.fromJson(Map<String, dynamic> json) => StaffLogin(
    id: json['id'] as String,
    role: OrganizationMemberRole.fromJson(json['role'] as String),
    status: OrganizationMemberStatus.fromJson(json['status'] as String),
    claimCode: json['claim_code'] as String?,
    joinedAt: switch (json['joined_at']) {
      final String value => DateTime.parse(value),
      _ => null,
    },
    createdAt: DateTime.parse(json['created_at'] as String),
    clerkUserId: json['clerk_user_id'] as String?,
  );
}

/// One person on the school's staff list, with their login when they have
/// one. The staff record and the login are separate: most records start with
/// no login, and an invite can be cancelled without touching the record.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.jobTitle,
    this.phone,
    this.email,
    this.middleName,
    this.gender,
    this.photoId,
    this.photoUrl,
    this.staffNumber,
    required this.staffType,
    required this.status,
    required this.createdAt,
    this.memberId,
    this.login,
    this.privateDetails,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? jobTitle;
  final String? phone;
  final String? email;

  /// Read only for the edit form, which must send the whole record back.
  final String? middleName;
  final StaffGender? gender;
  final String? photoId;
  final String? photoUrl;

  /// The school's own number, e.g. `KCL/STF/0001`. Null when it wasn't read
  /// or the record has none.
  final String? staffNumber;

  /// `teaching` or `non_teaching`.
  final String staffType;
  final StaffRecordStatus status;
  final DateTime createdAt;

  /// The membership this record points at, set only by `invite_staff`.
  final String? memberId;

  /// The embedded `organization_members` row, or null when there's no login.
  final StaffLogin? login;

  /// The private details row, read separately for leaders. Null outside the
  /// edit sheet or when the caller can't read it.
  final StaffPrivateDetails? privateDetails;

  /// Their date of birth, from the private details leaders can read.
  DateTime? get dateOfBirth => privateDetails?.dateOfBirth;

  /// The staff row plus its login, embedded through the member FK.
  static const columns =
      'id,first_name,middle_name,last_name,job_title,gender,phone,email,'
      'photo_url,staff_number,staff_type,status,created_at,member_id,'
      'member:organization_members!staff_member_fkey(${StaffLogin.columns})';

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final member = json['member'];
    final private = json['private_details'];
    return StaffMember(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      jobTitle: json['job_title'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      middleName: json['middle_name'] as String?,
      gender: switch (json['gender']) {
        final String value => StaffGender.fromJson(value),
        _ => null,
      },
      photoId: json['photo_id'] as String?,
      photoUrl: json['photo_url'] as String?,
      staffNumber: json['staff_number'] as String?,
      staffType: json['staff_type'] as String,
      status: StaffRecordStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      memberId: json['member_id'] as String?,
      login: member is Map
          ? StaffLogin.fromJson(Map<String, dynamic>.from(member))
          : null,
      privateDetails: switch (private) {
        final Map value => StaffPrivateDetails.fromJson(
          Map<String, dynamic>.from(value),
        ),
        final List value when value.isNotEmpty && value.first is Map =>
          StaffPrivateDetails.fromJson(
            Map<String, dynamic>.from(value.first as Map),
          ),
        _ => null,
      },
    );
  }

  StaffMember copyWith({StaffPrivateDetails? privateDetails}) => StaffMember(
    id: id,
    firstName: firstName,
    lastName: lastName,
    jobTitle: jobTitle,
    phone: phone,
    email: email,
    middleName: middleName,
    gender: gender,
    photoId: photoId,
    photoUrl: photoUrl,
    staffNumber: staffNumber,
    staffType: staffType,
    status: status,
    createdAt: createdAt,
    memberId: memberId,
    login: login,
    privateDetails: privateDetails ?? this.privateDetails,
  );

  String get fullName => '$firstName $lastName'.trim();

  /// "First Middle Last" (middle omitted when blank), for the detail header.
  String get fullNameWithMiddle {
    final middle = middleName?.trim() ?? '';
    return [firstName, if (middle.isNotEmpty) middle, lastName].join(' ');
  }

  String get firstNameOnly => firstName;

  bool get hasLogin => login != null;

  /// Staff who have left can't be given a login; the database refuses it.
  bool get canBeInvited => status != StaffRecordStatus.exited;

  StaffAccess get access {
    final login = this.login;
    if (login == null) return StaffAccess.notOnApp;
    return switch (login.status) {
      OrganizationMemberStatus.invited => StaffAccess.invitePending,
      OrganizationMemberStatus.suspended => StaffAccess.suspended,
      OrganizationMemberStatus.active =>
        login.role == OrganizationMemberRole.owner
            ? StaffAccess.owner
            : StaffAccess.onApp,
    };
  }

  /// The role the record is, or would be: the login's role when it has one,
  /// otherwise the job title's usual role.
  OrganizationMemberRole get role => login?.role ?? roleForJobTitle(jobTitle);

  /// "Teacher" from "Teacher", "Maths Teacher" or "Senior Teacher".
  static OrganizationMemberRole roleForJobTitle(String? jobTitle) {
    final title = (jobTitle ?? '').toLowerCase();
    if (title.contains('owner')) return OrganizationMemberRole.owner;
    if (title.contains('vice') && title.contains('principal')) {
      return OrganizationMemberRole.vicePrincipal;
    }
    if (title.contains('principal')) return OrganizationMemberRole.principal;
    if (title.contains('admin')) return OrganizationMemberRole.admin;
    if (title.contains('bursar')) return OrganizationMemberRole.bursar;
    if (title.contains('teacher')) return OrganizationMemberRole.teacher;
    return OrganizationMemberRole.staff;
  }
}
