import 'dart:async';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/utils/view_util.dart';
import 'package:hamrash_admin/resources/app_theme.dart';
import 'package:hamrash_admin/services/error_logger_service.dart';
import 'package:hamrash_admin/views/onboarding/join/join_screen.dart';
import 'package:hamrash_admin/views/onboarding/member_access_view_model.dart';
import 'package:hamrash_admin/views/onboarding/sign_in/sign_in_screen.dart';
import 'package:hamrash_admin/views/template.dart/template.dart';
import 'package:stacked/stacked.dart';

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
          themeMode: ThemeMode.light,
          routes: const {},
          home: const _OnboardingAuthGate(),
        ),
      ),
    );
  }
}

class _OnboardingAuthGate extends StatelessWidget {
  const _OnboardingAuthGate();

  @override
  Widget build(BuildContext context) => ClerkAuthBuilder(
    signedOutBuilder: (context, _) => const SignInScreen(),
    signedInBuilder: (context, auth) {
      final user = auth.user!;
      void signOut() => unawaited(auth.signOut());

      return ViewModelBuilder<MemberAccessViewModel>.reactive(
        key: ValueKey(user.id),
        viewModelBuilder: () => MemberAccessViewModel(user.id),
        onViewModelReady: (model) => model.check(),
        builder: (context, model, _) {
          if (!model.checked) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppPalette.aubergine500,
                ),
              ),
            );
          }

          if (model.error != null) {
            return _MembershipCheckError(
              onRetry: model.check,
              onSignOut: signOut,
            );
          }

          if (model.hasMembership) {
            return const Template();
          }

          return JoinScreen(
            email: user.email ?? '',
            initialName: user.name,
            onUseAnotherAccount: signOut,
            onSignOut: signOut,
            onBack: signOut,
          );
        },
      );
    },
  );
}

class _MembershipCheckError extends StatelessWidget {
  const _MembershipCheckError({required this.onRetry, required this.onSignOut});

  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppText(
              'Couldn’t check your school membership',
              variant: AppTextVariant.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const AppText(
              'Check your connection and try again.',
              variant: AppTextVariant.body,
              colorType: AppTextColor.textBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
            TextButton(onPressed: onSignOut, child: const Text('Sign out')),
          ],
        ),
      ),
    ),
  );
}
