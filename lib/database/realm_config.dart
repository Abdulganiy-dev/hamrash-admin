import 'package:hamrash_admin/resources/app_logger.dart';
import 'package:realm/realm.dart';

import 'models/state_realm.dart';

class RealmConfig {
  /// Bump when adding or changing Realm models (see Supabase_Realm_Architecture_Guide.md).F
  static const int _currentSchemaVersion = 1; 
  static const String _databaseName = 'hamrash_admin.realm';


    static Configuration getConfiguration() {
    AppLogger.info('Initializing Realm with schema version $_currentSchemaVersion');
    
    return Configuration.local(
      [
        StateRealm.schema
      ],
      schemaVersion: _currentSchemaVersion,
      migrationCallback: _migrationCallback,
    );
  }


  static void _migrationCallback(Migration migration, int oldSchemaVersion) {
    AppLogger.info(
      'Running Realm migration from version $oldSchemaVersion to $_currentSchemaVersion',
    );

    // Migration logic for schema version 1
    // This is the initial schema, so no migration needed
    // Future migrations can be added here as the schema evolves
    
    if (oldSchemaVersion < 1) {
      // Initial schema - no migration needed
      AppLogger.info('Initial schema version - no migration required');
    }

  }

  /// Get the database file path
  static String get databasePath => _databaseName;
}

