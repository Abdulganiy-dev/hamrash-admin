import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:hamrash_admin/database/realm_service.dart';
import 'package:hamrash_admin/core/utils/view_util.dart';
import 'package:hamrash_admin/services/error_logger_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'env_config/env.dart';
import 'env_config/flavor_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
   
    FlavorConfig(flavor: Flavor.prod, values: ProdEnv());

    final env = FlavorConfig.instance!.envConfig();

    // Initialize Supabase BEFORE setting up locator
    // This ensures Supabase is available when services are registered
    await Supabase.initialize(
      url: env.supabaseUrl,
      anonKey: env.supabaseAnonKey,
      debug: false,
      accessToken: () async {
        final context = ViewUtil.navigatorKey.currentContext;
        if (context == null) return null;

        try {
          final token = await ClerkAuth.of(context).sessionToken();
          return token.jwt;
        } catch (e) {
          await ErrorLoggerService.logError(e, context: 'Supabase.accessToken');
          return null;
        }
      },
    );

    setupLocator();

    final realmService = locator<RealmService>();
    realmService.initialize();

    await ErrorLoggerService.logInfo(
      '[${FlavorConfig.instance!.name}] baseUrl=${env.baseUrl}',
      context: 'main',
    );

    runApp(const MyApp());
  } catch (e, stackTrace) {
    // Log initialization errors before app starts
    await ErrorLoggerService.logError(
      e,
      stackTrace: stackTrace,
      context: 'main.initialization',
      fatal: true,
    );
    rethrow;
  }
}
