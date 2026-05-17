import 'package:realm/realm.dart';

part 'teacher_realm.realm.dart';

/// Local cache row for `public.teachers`.
@RealmModel()
class _TeacherRealm {
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

  String? homeroomClassId;

  String? homeroomRole;

  DateTime? createdAt;

  DateTime? updatedAt;

  DateTime? lastUpdated;
}
