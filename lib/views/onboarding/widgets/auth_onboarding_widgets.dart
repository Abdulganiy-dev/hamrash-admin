import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

class AuthScreenFrame extends StatelessWidget {
  const AuthScreenFrame({
    super.key,
    required this.scrollContent,
    required this.footer,
    this.showBackButton = true,
    this.onBack,
  });

  final Widget scrollContent;
  final Widget footer;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppPalette.linen,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.md,
          AppSpacing.screen,
          AppSpacing.sm,
        ),
        child: Column(
          children: [
            if (showBackButton) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppPalette.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: LightColors.strokeColourStrokeMild,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F2A1712),
                        offset: Offset(0, 4),
                        blurRadius: 12,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed:
                        onBack ??
                        () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    color: AppPalette.stone900,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Expanded(
              child: LayoutBuilder(
                builder:
                    (context, constraints) => SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: scrollContent,
                      ),
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            footer,
          ],
        ),
      ),
    ),
  );
}

class AuthProviderLabel extends StatelessWidget {
  const AuthProviderLabel({
    super.key,
    required this.asset,
    required this.label,
    required this.labelColor,
    this.tint,
  });

  final String asset;
  final String label;
  final Color labelColor;
  final Color? tint;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SvgPicture.asset(
        asset,
        width: 20,
        height: 20,
        colorFilter:
            tint == null ? null : ColorFilter.mode(tint!, BlendMode.srcIn),
      ),
      const SizedBox(width: 10),
      Text(
        label,
        style: AppTypography.title.copyWith(color: labelColor, fontSize: 17),
      ),
    ],
  );
}

class AuthTermsCopy extends StatelessWidget {
  const AuthTermsCopy({super.key});

  @override
  Widget build(BuildContext context) => const AppText(
    'Only staff invited by a school can get in. By continuing you agree to our Terms and Privacy Policy.',
    variant: AppTextVariant.caption,
    colorType: AppTextColor.textMuted,
    textAlign: TextAlign.center,
    height: 1.5,
  );
}

class AuthAccountLine extends StatelessWidget {
  const AuthAccountLine({super.key, required this.email, this.onTap});

  final String email;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      AppText(
        email,
        variant: AppTextVariant.caption,
        colorType: AppTextColor.textMuted,
      ),
      const AppText(
        '  ·  ',
        variant: AppTextVariant.caption,
        colorType: AppTextColor.textMuted,
      ),
      TextButton(
        onPressed: onTap ?? _ignoreTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const AppText(
          'Use another account',
          variant: AppTextVariant.caption,
          colorType: AppTextColor.textBrand,
        ),
      ),
    ],
  );
}

class AuthTextLink extends StatelessWidget {
  const AuthTextLink({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap ?? _ignoreTap,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      foregroundColor: AppPalette.aubergine500,
    ),
    child: AppText(
      label,
      variant: AppTextVariant.subtitle,
      colorType: AppTextColor.textBrand,
      textAlign: TextAlign.center,
    ),
  );
}

void _ignoreTap() {}

class JoinCodeEntryField extends StatelessWidget {
  const JoinCodeEntryField({
    super.key,
    required this.controller,
    required this.enabled,
    this.errorMessage,
    this.helperMessage,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? errorMessage;
  final String? helperMessage;

  Future<void> _paste() async {
    final value = await Clipboard.getData(Clipboard.kTextPlain);
    if (value?.text != null) {
      controller.text = JoinCodeInputFormatter.format(value!.text!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isError = errorMessage != null;
    final border =
        isError
            ? LightColors.errorErrorDefault
            : LightColors.strokeColourStrokeMild;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText('Join code', variant: AppTextVariant.label),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: enabled ? AppPalette.white : AppPalette.stone100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: isError ? 1.5 : 1),
          ),
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (!enabled) ...[
                const Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: AppPalette.stone500,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  maxLength: 9,
                  keyboardType: TextInputType.visiblePassword,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [JoinCodeInputFormatter()],
                  style: AppTypography.title.copyWith(
                    color: enabled ? AppPalette.stone900 : AppPalette.stone500,
                    letterSpacing: 1.5,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    hintText: 'KQ7M-2X9B',
                  ),
                ),
              ),
              if (enabled)
                TextButton(
                  onPressed: _paste,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    foregroundColor: AppPalette.aubergine500,
                  ),
                  child: const AppText(
                    'Paste',
                    variant: AppTextVariant.subtitle,
                    colorType: AppTextColor.textBrand,
                  ),
                ),
            ],
          ),
        ),
        if (errorMessage case final message?) ...[
          const SizedBox(height: AppSpacing.sm),
          AppText(
            message,
            variant: AppTextVariant.caption,
            colorType: AppTextColor.error,
          ),
        ] else if (helperMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppText(
            helperMessage!,
            variant: AppTextVariant.caption,
            colorType: AppTextColor.textMuted,
          ),
        ],
      ],
    );
  }
}

class JoinCodeInputFormatter extends TextInputFormatter {
  static String format(String value) {
    final clean =
        value.toUpperCase().split('').where((character) {
          final code = character.codeUnitAt(0);
          return (code >= 48 && code <= 57) || (code >= 65 && code <= 90);
        }).join();
    final capped = clean.length > 8 ? clean.substring(0, 8) : clean;
    if (capped.length <= 4) return capped;
    return '${capped.substring(0, 4)}-${capped.substring(4)}';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final value = format(newValue.text);
    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

class AuthWarningBanner extends StatelessWidget {
  const AuthWarningBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final parts = message.split('\n');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: LightColors.warningWarningMute,
        border: Border.all(color: LightColors.warningWarningThin),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: LightColors.warningWarningText,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  parts.first,
                  variant: AppTextVariant.subtitle,
                  colorType: AppTextColor.warning,
                ),
                if (parts.length > 1) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  AppText(
                    parts.skip(1).join('\n'),
                    variant: AppTextVariant.body,
                    colorType: AppTextColor.textBody,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SchoolConfirmationCard extends StatelessWidget {
  const SchoolConfirmationCard({
    super.key,
    required this.name,
    required this.location,
    required this.role,
    this.code,
  });

  final String name;
  final String location;
  final String role;
  final String? code;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SchoolIdentity(name: name, location: location),
        const SizedBox(height: AppSpacing.lg),
        const Divider(height: 1, color: LightColors.strokeColourStrokeMild),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppText(
              "You'll join as",
              variant: AppTextVariant.caption,
              colorType: AppTextColor.textMuted,
            ),
            AppBadge(role, tone: AppBadgeTone.info),
          ],
        ),
        if (code != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'School code',
                variant: AppTextVariant.caption,
                colorType: AppTextColor.textMuted,
              ),
              AppText(
                code!,
                variant: AppTextVariant.label,
                colorType: AppTextColor.textStrong,
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class SchoolIdentity extends StatelessWidget {
  const SchoolIdentity({super.key, required this.name, required this.location});

  final String name;
  final String location;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppPalette.aubergine500,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.school_outlined,
          color: AppPalette.white,
          size: 26,
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(name, variant: AppTextVariant.title),
            const SizedBox(height: AppSpacing.xxs),
            AppText(
              location,
              variant: AppTextVariant.caption,
              colorType: AppTextColor.textMuted,
            ),
          ],
        ),
      ),
    ],
  );
}
