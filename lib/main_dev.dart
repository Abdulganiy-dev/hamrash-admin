
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/app.dart';
import 'package:hamrash_admin/database/realm_service.dart';
import 'package:hamrash_admin/resources/app_logger.dart';
import 'package:hamrash_admin/resources/utils/view_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env_config/env.dart';
import 'env_config/flavor_config.dart';

import 'singleton_locator/locator.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
  
    FlavorConfig(flavor: Flavor.dev, values: DevEnv());

    final env = FlavorConfig.instance!.envConfig();

    // Initialize Supabase BEFORE setting up locator
    // This ensures Supabase is available when services are registered
    await Supabase.initialize(
      url: env.supabaseUrl,
      anonKey: env.supabaseAnonKey,
      debug: true,
      accessToken: () async {
        final context = ViewUtil.navigatorKey.currentContext;
        if (context == null) {
          AppLogger.info('getCurrentJWT: context is null');
          return null;
        }

        try {
          final token = await ClerkAuth.of(context).sessionToken();
          // AppLogger.info('getCurrentJWT: ${token.jwt}');
          return token.jwt;
        } catch (e) {
          AppLogger.error('getCurrentJWT error: $e');
          return null;
        }
      },
    );

    // Initialize dependency injection after Supabase is initialized
    setupLocator();

       final realmService = locator<RealmService>();
    realmService.initialize();

    AppLogger.info('[${FlavorConfig.instance!.name}] baseUrl=${env.baseUrl}');

    runApp(const MyApp());
  } catch (e, stackTrace) {
    // Log initialization errors before app starts
    AppLogger.error('Initialization error: $e\n$stackTrace');
    rethrow;
  }
}
