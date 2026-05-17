import 'package:realm/realm.dart';

part 'section_realm.realm.dart';

/// Local cache row for `public.sections`.
@RealmModel()
class _SectionRealm {
  @PrimaryKey()
  late String id;

  late String name;

  DateTime? createdAt;

  DateTime? updatedAt;

  DateTime? lastUpdated;
}
