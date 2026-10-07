import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/app_theme.dart';
import 'package:hamrash_admin/core/utils/view_util.dart';
import 'package:hamrash_admin/services/error_logger_service.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

import 'env_config/flavor_config.dart';

void bootstrapApp() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final env = FlavorConfig.instance!.envConfig();

    return ClerkAuth(
      config: ClerkAuthConfig(publishableKey: env.clerkPublishableKey),

      child: ClerkErrorListener(
        handler: (context, error) =>
            ErrorLoggerService.logError(error, context: 'ClerkErrorListener'),
        child: MaterialApp(
          navigatorKey: ViewUtil.navigatorKey,
          debugShowCheckedModeBanner: env.enableVerboseLogs,
          title: 'Hamrash Admin',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          routes: const {},
          home: const Scaffold(
            body: Center(child: AppText('Hamrash Admin')),
          ),
        ),
      ),
    );
  }
}
