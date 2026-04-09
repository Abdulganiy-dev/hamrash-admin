import 'package:realm/realm.dart';

part 'app_role_realm.realm.dart';

/// Local cache for `public.roles` (named [AppRoleRealm] to avoid generator clashes with `Role`).
@RealmModel()
class _AppRoleRealm {
  @PrimaryKey()
  late String id;

  late String name;

  String? description;

  DateTime? createdAt;

  DateTime? lastUpdated;
}
