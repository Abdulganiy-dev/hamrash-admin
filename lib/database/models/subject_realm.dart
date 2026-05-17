import 'package:realm/realm.dart';

part 'subject_realm.realm.dart';

/// Local cache row for `public.subjects`.
@RealmModel()
class _SubjectRealm {
  @PrimaryKey()
  late String id;

  late String name;

  String? description;

  late bool isActive;

  DateTime? createdAt;

  DateTime? updatedAt;

  DateTime? lastUpdated;
}
