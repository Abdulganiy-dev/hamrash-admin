import 'package:realm/realm.dart';

part 'admin_profile_realm.realm.dart';

/// Local cache for `public.admin_profiles`.
/// `stateText` holds the address state column (`state` in Postgres — avoid name `state` in Realm).
@RealmModel()
class _AdminProfileRealm {
  @PrimaryKey()
  late String id;

  String? clerkId;

  late String fullName;

  late String email;

  String? phoneNumber;

  String? gender;

  String? avatarUrl;

  String? avatarUrlId;

  String? address;

  String? stateText;

  String? fcmToken;

  String? role;

  late bool isActive;

  DateTime? lastLoginAt;

  DateTime? createdAt;

  DateTime? updatedAt;

  DateTime? lastUpdated;
}
