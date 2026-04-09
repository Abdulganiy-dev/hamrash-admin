import 'package:realm/realm.dart';

part 'state_realm.realm.dart';

/// Local cache row for `public.states`. [id] matches Supabase `id` (uuid).
@RealmModel()
class _StateRealm {
  @PrimaryKey()
  late String id;

  late String name;

  /// Local only — not persisted to Supabase.
  DateTime? lastUpdated;
}
