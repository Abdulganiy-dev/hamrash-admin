import 'package:hamrash_admin/resources/app_logger.dart';
import 'package:realm/realm.dart';

import 'models/admin_profile_realm.dart';
import 'models/app_role_realm.dart';
import 'models/class_realm.dart';
import 'models/state_realm.dart';
import 'models/section_realm.dart';
import 'models/subject_realm.dart';

class RealmConfig {
  /// Bump when adding or changing Realm models (see Supabase_Realm_Architecture_Guide.md).
  static const int _currentSchemaVersion = 4;
  static const String _databaseName = 'hamrash_admin.realm';

  static Configuration getConfiguration() {
    AppLogger.info('Initializing Realm with schema version $_currentSchemaVersion');

    return Configuration.local(
      [
        StateRealm.schema,
        AppRoleRealm.schema,
        AdminProfileRealm.schema,
        ClassRealm.schema,
        SectionRealm.schema,
        SubjectRealm.schema,
      ],
      schemaVersion: _currentSchemaVersion,
      migrationCallback: _migrationCallback,
    );
  }

  static void _migrationCallback(Migration migration, int oldSchemaVersion) {
    AppLogger.info(
      'Running Realm migration from version $oldSchemaVersion to $_currentSchemaVersion',
    );

    if (oldSchemaVersion < 1) {
      AppLogger.info('Initial schema version - no migration required');
    }

    if (oldSchemaVersion < 2) {
      AppLogger.info('Schema 2: AppRoleRealm + AdminProfileRealm added');
    }

    if (oldSchemaVersion < 3) {
      AppLogger.info('Schema 3: ClassRealm + SubjectRealm added');
    }

    if (oldSchemaVersion < 4) {
      AppLogger.info('Schema 4: SectionRealm added');
    }
  }

  /// Get the database file path
  static String get databasePath => _databaseName;
}

