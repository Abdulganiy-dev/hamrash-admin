import 'package:realm/realm.dart';

part 'student_realm.realm.dart';

/// Local cache row for `public.students`.
@RealmModel()
class _StudentRealm {
  @PrimaryKey()
  late String id;

  late String firstName;
  late String lastName;

  String? email;
  String? phone;
  String? gender;
  DateTime? dateOfBirth;
  String? admissionNumber;
  DateTime? admissionDate;
  String? address;
  String? state;
  String? avatarUrl;
  String? avatarUrlId;
  String? fcmToken;

  late bool isActive;

  String? classId;

  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? lastUpdated;
}

/// Local cache row for `public.parents`.
@RealmModel()
class _ParentRealm {
  @PrimaryKey()
  late String id;

  late String firstName;
  late String lastName;

  String? email;
  String? phone;
  String? gender;
  String? address;
  String? state;
  String? avatarUrl;
  String? avatarUrlId;
  String? fcmToken;

  late bool isActive;

  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? lastUpdated;
}

/// Local cache row for `public.student_parents`.
///
/// Holds the join + relationship metadata so we can navigate
/// student ↔ parent offline.
@RealmModel()
class _StudentParentLinkRealm {
  @PrimaryKey()
  late String id;

  late String studentId;
  late String parentId;
  late String relationship; // 'mother' | 'father' | 'guardian' | 'other'
  late bool isPrimary;

  DateTime? createdAt;
  DateTime? lastUpdated;
}
