import 'package:realm/realm.dart';

part 'class_realm.realm.dart';

/// Local cache row for `public.classes`.
@RealmModel()
class _ClassRealm {
  @PrimaryKey()
  late String id;

  late String name;

  String? section;

  late bool isActive;

  DateTime? createdAt;

  DateTime? updatedAt;

  DateTime? lastUpdated;
}
