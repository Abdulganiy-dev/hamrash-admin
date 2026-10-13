import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/views/onboarding/join/join_view_model.dart';
import 'package:hamrash_admin/views/onboarding/widgets/auth_onboarding_widgets.dart';
import 'package:stacked/stacked.dart';

class JoinScreen extends StatelessWidget {
  const JoinScreen({
    super.key,
    this.initialPhase = JoinPhase.enterCode,
    this.email = 'amina.bello@gmail.com',
    this.schoolName = 'Kings College',
    this.location = 'Lekki, Lagos',
    this.role = 'Principal',
    this.schoolCode = 'HMR-7K2Q9P',
    this.targetApp = 'Teacher',
    this.initialCode,
    this.onContinue,
    this.onUseAnotherAccount,
    this.onJoin,
    this.onDifferentCode,
    this.onSignOut,
    this.onBack,
  });

  final JoinPhase initialPhase;
  final String email;
  final String schoolName;
  final String location;
  final String role;
  final String schoolCode;
  final String targetApp;
  final String? initialCode;
  final Future<JoinPhase?> Function(String code)? onContinue;
  final VoidCallback? onUseAnotherAccount;
  final VoidCallback? onJoin;
  final VoidCallback? onDifferentCode;
  final VoidCallback? onSignOut;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<JoinViewModel>.reactive(
        viewModelBuilder:
            () => JoinViewModel(
              phase: initialPhase,
              email: email,
              schoolName: schoolName,
              location: location,
              role: role,
              schoolCode: schoolCode,
              targetApp: targetApp,
              initialCode: initialCode,
              onContinue: onContinue,
              onUseAnotherAccount: onUseAnotherAccount,
              onJoin: onJoin,
              onDifferentCode: onDifferentCode,
              onSignOut: onSignOut,
            ),
        builder:
            (context, model, _) => _JoinContent(model: model, onBack: onBack),
      );
}

class _JoinContent extends StatelessWidget {
  const _JoinContent({required this.model, this.onBack});

  final JoinViewModel model;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => AuthScreenFrame(
    onBack: () => model.handleBack(context, onBack),
    scrollContent: switch (model.phase) {
      JoinPhase.enterCode ||
      JoinPhase.wrongCode ||
      JoinPhase.tooManyTries => _buildCodeEntry(),
      JoinPhase.confirmStaff => _buildStaffConfirmation(),
      JoinPhase.codeForAnotherApp => _buildWrongApp(),
      JoinPhase.confirmOwner => _buildOwnerConfirmation(),
    },
    footer: switch (model.phase) {
      JoinPhase.enterCode ||
      JoinPhase.wrongCode ||
      JoinPhase.tooManyTries => _buildCodeFooter(),
      JoinPhase.confirmStaff => _buildStaffFooter(),
      JoinPhase.codeForAnotherApp => _buildWrongAppFooter(),
      JoinPhase.confirmOwner => _buildOwnerFooter(),
    },
  );

  Widget _buildCodeEntry() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: AppSpacing.lg),
      const AppText(
        'Join your school',
        variant: AppTextVariant.h1,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.sm),
      const AppText(
        'Enter the 8-character code you were given. Owners get theirs from Hamrash; everyone else from their school.',
        variant: AppTextVariant.body,
        colorType: AppTextColor.textBody,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xl),
      JoinCodeEntryField(
        controller: model.code,
        enabled: !model.isCodeLocked,
        errorMessage: model.codeError,
        helperMessage:
            model.codeError == null && !model.isCodeLocked
                ? 'Letters and numbers only. The dash is added for you.'
                : null,
      ),
      if (model.phase == JoinPhase.wrongCode) ...[
        const SizedBox(height: AppSpacing.sm),
        const AppText(
          '3 more tries this hour.',
          variant: AppTextVariant.caption,
          colorType: AppTextColor.textMuted,
        ),
      ],
      if (model.isCodeLocked) ...[
        const SizedBox(height: AppSpacing.md),
        AuthWarningBanner(message: model.codeAttemptsMessage!),
      ],
    ],
  );

  Widget _buildCodeFooter() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppPrimaryButton(
        size: AppButtonSize.large,
        isDisabled: !model.canContinue,
        onPressed: model.continueWithCode,
        child: const AppText('Continue', variant: AppTextVariant.button),
      ),
      const SizedBox(height: AppSpacing.md),
      AuthAccountLine(email: model.email, onTap: model.useAnotherAccount),
    ],
  );

  Widget _buildStaffConfirmation() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: AppSpacing.lg),
      const AppText(
        'Is this your school?',
        variant: AppTextVariant.h1,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.sm),
      const AppText(
        'Check the details before you join. Your code is only used once you tap Join.',
        variant: AppTextVariant.body,
        colorType: AppTextColor.textBody,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xl),
      SchoolConfirmationCard(
        name: model.schoolName,
        location: model.location,
        role: model.role,
        code: model.schoolCode,
      ),
    ],
  );

  Widget _buildStaffFooter() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppPrimaryButton(
        size: AppButtonSize.large,
        onPressed: model.joinSchool,
        child: AppText(
          'Join ${model.schoolName}',
          variant: AppTextVariant.button,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      AuthTextLink(
        label: 'Not your school? Use a different code',
        onTap: model.useDifferentCode,
      ),
    ],
  );

  Widget _buildWrongApp() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: AppSpacing.lg),
      AppText(
        'This code is for the ${model.targetApp} app',
        variant: AppTextVariant.h1,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.sm),
      AppText(
        "Hamrash Admin is for owners, admins, principals, vice principals and bursars. We haven't used your code, so it still works in the ${model.targetApp} app.",
        variant: AppTextVariant.body,
        colorType: AppTextColor.textBody,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xl),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SchoolIdentity(name: model.schoolName, location: model.location),
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1, color: LightColors.strokeColourStrokeMild),
            const SizedBox(height: AppSpacing.md),
            const AppText(
              'Code is for',
              variant: AppTextVariant.caption,
              colorType: AppTextColor.textMuted,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppBadge(model.targetApp, tone: AppBadgeTone.info),
          ],
        ),
      ),
    ],
  );

  Widget _buildWrongAppFooter() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppSecondaryButton(
        size: AppButtonSize.large,
        onPressed: model.useDifferentCode,
        child: const AppText(
          'Use a different code',
          variant: AppTextVariant.button,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextButton(
        onPressed: model.signOut,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          foregroundColor: AppPalette.stone500,
        ),
        child: const AppText(
          'Sign out',
          variant: AppTextVariant.button,
          colorType: AppTextColor.textMuted,
        ),
      ),
    ],
  );

  Widget _buildOwnerConfirmation() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: AppSpacing.lg),
      const AppText(
        'Welcome, owner',
        variant: AppTextVariant.h1,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.sm),
      const AppText(
        "Hamrash set up your school. Check it's right and tell us your name for the staff list.",
        variant: AppTextVariant.body,
        colorType: AppTextColor.textBody,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xl),
      SchoolConfirmationCard(
        name: model.schoolName,
        location: model.location,
        role: 'Owner',
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        controller: model.fullName,
        label: 'Your full name',
        hintText: 'Amina Bello',
        helperText: 'From your Apple account. Shown to your staff.',
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        controller: model.phoneNumber,
        label: 'Phone number',
        isOptional: true,
        prefixText: '+234',
        hintText: '803 000 0000',
        keyboardType: TextInputType.phone,
      ),
    ],
  );

  Widget _buildOwnerFooter() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppPrimaryButton(
        size: AppButtonSize.large,
        onPressed: model.joinSchool,
        child: const AppText('Join as owner', variant: AppTextVariant.button),
      ),
      const SizedBox(height: AppSpacing.md),
      AuthTextLink(
        label: 'Not your school? Use a different code',
        onTap: model.useDifferentCode,
      ),
    ],
  );
}
