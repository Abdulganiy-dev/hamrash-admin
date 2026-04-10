import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/app_theme.dart';
import 'package:hamrash_admin/resources/utils/view_util.dart';
import 'package:hamrash_admin/services/error_logger_service.dart';
import 'package:hamrash_admin/views/create_account/create_account.dart';
import 'package:hamrash_admin/views/home/home.dart';
import 'package:hamrash_admin/views/sign_in/auth_router.dart';
import 'package:hamrash_admin/views/sign_in/sign_in.dart';

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
          routes: {
            SignIn.routeName: (_) => const SignIn(),
            Home.routeName: (_) => const Home(),
            CreateAccount.routeName: (_) => const CreateAccount(),
          },
          home: Scaffold(
            body: Scaffold(
              body: ClerkAuthBuilder(
                builder: (context, authState) =>
                    const Center(child: SizedBox()),
                signedInBuilder: (context, authState) {
                  // return const AuthRouterContent();
                  return const AuthRouter();
                },
                signedOutBuilder: (context, authState) {
                  return const SignIn();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
