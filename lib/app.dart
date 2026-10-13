import 'dart:async';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/utils/view_util.dart';
import 'package:hamrash_admin/resources/app_theme.dart';
import 'package:hamrash_admin/services/error_logger_service.dart';
import 'package:hamrash_admin/views/onboarding/join/join_screen.dart';
import 'package:hamrash_admin/views/onboarding/member_access_view_model.dart';
import 'package:hamrash_admin/views/onboarding/sign_in/sign_in_screen.dart';
import 'package:hamrash_admin/views/home/home_shell.dart';
import 'package:hamrash_admin/views/schools/confirm_school/confirm_school_screen.dart';
import 'package:hamrash_admin/views/schools/pick_school_screen.dart';
import 'package:hamrash_admin/views/schools/school_paused_screen.dart';
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
            return const DefaultScaffold(
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

          final email = user.email ?? '';
          final school = model.selected;

          if (model.hasMembership && school == null) {
            return PickSchoolScreen(
              schools: model.schools,
              email: email,
              onPick: model.selectSchool,
              onSignOut: signOut,
              onJoinAnother: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (route) => JoinScreen(
                    email: email,
                    initialName: user.name,
                    memberships: model.memberships,
                    canLeave: true,
                    onUseAnotherAccount: signOut,
                    onSignOut: signOut,
                    onBack: () => Navigator.of(route).pop(),
                    onJoin: () {
                      Navigator.of(route).pop();
                      model.check();
                    },
                  ),
                ),
              ),
            );
          }

          if (school != null) {
            final switchSchool = model.canSwitchSchool
                ? model.switchSchool
                : null;

            if (school.isPaused) {
              return SchoolPausedScreen(
                school: school,
                onSwitchSchool: switchSchool,
                onSignOut: signOut,
              );
            }

            if (school.needsDetailsCheck) {
              return ConfirmSchoolScreen(
                key: ValueKey('confirm/${school.id}'),
                organization: school.organization,
                firstName: user.firstName,
                memberIds: school.memberIds,
                onConfirmed: model.updateSchool,
              );
            }

            return HomeShell(
              key: ValueKey('home/${school.id}'),
              school: school,
              userName: user.name,
              email: email,
              userImageUrl: user.imageUrl,
              onSwitchSchool: switchSchool,
              onSignOut: signOut,
              onOpenSchoolDetails: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (route) => ConfirmSchoolScreen(
                    organization: school.organization,
                    firstName: user.firstName,
                    memberIds: school.memberIds,
                    onBack: () => Navigator.of(route).pop(),
                    onConfirmed: (organization) {
                      Navigator.of(route).pop();
                      model.updateSchool(organization);
                    },
                  ),
                ),
              ),
            );
          }

          return JoinScreen(
            email: email,
            initialName: user.name,
            memberships: model.memberships,
            onUseAnotherAccount: signOut,
            onJoin: model.check,
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
  Widget build(BuildContext context) => DefaultScaffold(
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
