import 'package:hamrash_admin/resources/app_logger.dart';
import 'package:hamrash_admin/services/error_logger_service.dart';
import 'package:realm/realm.dart';

import 'realm_config.dart';

/// Single shared Realm connection for the app. Call [initialize] once after DI setup.
class RealmService {
  late Realm _realm;

  Realm get realm => _realm;

  void initialize() {
    try {
      AppLogger.info('Initializing Realm database');
      final config = RealmConfig.getConfiguration();
      _realm = Realm(config);
      AppLogger.info('Realm database initialized successfully');
    } catch (e, stackTrace) {
      ErrorLoggerService.logError(
        e,
        context: 'RealmService.initialize',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void close() {
    try {
      AppLogger.info('Closing Realm database');
      _realm.close();
      AppLogger.info('Realm database closed successfully');
    } catch (e, stackTrace) {
      ErrorLoggerService.logError(
        e,
        context: 'RealmService.close',
        stackTrace: stackTrace,
      );
    }
  }
}
