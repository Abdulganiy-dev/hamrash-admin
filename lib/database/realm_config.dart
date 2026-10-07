import 'package:hamrash_admin/resources/app_logger.dart';
import 'package:realm/realm.dart';

class RealmConfig {
  /// Bump when adding or changing Realm models (see Supabase_Realm_Architecture_Guide.md).
  static const int _currentSchemaVersion = 7;
  static const String _databaseName = 'hamrash_admin.realm';

  static Configuration getConfiguration() {
    AppLogger.info('Initializing Realm with schema version $_currentSchemaVersion');

    return Configuration.local(
      [
        // Register Realm model schemas here, e.g. `ExampleRealm.schema`.
      ],
      schemaVersion: _currentSchemaVersion,
      migrationCallback: _migrationCallback,
    );
  }

  static void _migrationCallback(Migration migration, int oldSchemaVersion) {
    AppLogger.info(
      'Running Realm migration from version $oldSchemaVersion to $_currentSchemaVersion',
    );

    if (oldSchemaVersion < 7) {
      AppLogger.info('Schema 7: all models removed (fresh start)');
    }
  }

  /// Get the database file path
  static String get databasePath => _databaseName;
}
