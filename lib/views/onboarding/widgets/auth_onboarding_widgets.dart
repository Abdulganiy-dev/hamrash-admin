import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_field_style.dart';
import 'package:hamrash_admin/core/widgets/app_keyboard_bar.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/blur_transition.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

class AuthScreenFrame extends StatelessWidget {
  const AuthScreenFrame({
    super.key,
    required this.scrollContent,
    required this.footer,
    this.showBackButton = true,
    this.onBack,
    this.shouldShowKeyBoardDone = true,
  });

  final Widget scrollContent;
  final Widget footer;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool shouldShowKeyBoardDone;
  static const _footerKey = ValueKey('footer');

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = AppKeyboardBar.isKeyboardOpen(context);

    return DefaultScaffold(
      backgroundColor: AppPalette.linen,
      showBackButton: showBackButton,
      onBackPressed: onBack,
      // The keyboard and its Done bar float over the page; it doesn't move.
      extendBody: keyboardOpen,
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => BlurTransition(
          animation: animation,
          maxBlur: 4,
          child: child.key == _footerKey
              ? SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                )
              : child,
        ),
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.bottomCenter,
          children: [...previousChildren, ?currentChild],
        ),
        child: keyboardOpen && shouldShowKeyBoardDone
            ? const AppKeyboardBar(key: ValueKey('keyboard-bar'))
            : SafeArea(
                key: _footerKey,
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    0,
                    AppSpacing.screen,
                    AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [footer],
                  ),
                ),
              ),
      ),
      body: Builder(
        builder: (context) {
          final topInset = ScaffoldInsets.bodyTopInsetOf(context);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topInset,
                    bottom: AppSpacing.md,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          (constraints.maxHeight - topInset - AppSpacing.md)
                              .clamp(0.0, double.infinity),
                    ),
                    child: scrollContent,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Apple's artwork is bottom-heavy: the apple body sits low in the 814 × 1000
/// box and the leaf above it is light, so its visual mass sits below the
/// bounding-box centre. Lifting the paint puts the body level with the label;
/// the slot and the row are untouched.
const double kAppleMarkOffsetY = -2;

class AuthProviderLabel extends StatelessWidget {
  const AuthProviderLabel({
    super.key,
    required this.asset,
    required this.label,
    required this.labelColor,
    this.tint,
    this.iconSize = 22,
    this.markOffsetY = 0,
  });

  final String asset;
  final String label;
  final Color labelColor;
  final Color? tint;

  /// Size of the square slot the mark is centred in, e.g. 22. The artwork
  /// keeps its own aspect ratio inside it — see the note in [build].
  final double iconSize;

  /// Optical correction for a mark whose visual mass is not centred in its
  /// box, e.g. Apple's leaf-over-body silhouette. Moves only the paint, not
  /// the slot, so the label never shifts.
  final double markOffsetY;

  @override
  Widget build(BuildContext context) {
    // The mark sits in a shared square slot so both rows have the same layout
    // width, and the artwork keeps its own aspect ratio inside it. [markOffsetY]
    // moves only the paint, so a bottom-heavy mark can be centred optically
    // without shifting the slot, the 10px gap or the label.
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: iconSize,
          child: Transform.translate(
            offset: Offset(0, markOffsetY),
            child: SvgPicture.asset(
              asset,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              colorFilter: tint == null
                  ? null
                  : ColorFilter.mode(tint!, BlendMode.srcIn),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.title.copyWith(
            color: labelColor,
            fontSize: 17,
            height: 24 / 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
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
  const AuthAccountLine({
    super.key,
    required this.email,
    this.onTap,
    this.actionLabel = 'Use another account',
  });

  final String email;
  final VoidCallback? onTap;
  final String actionLabel;

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
        child: AppText(
          actionLabel,
          variant: AppTextVariant.caption,
          fontWeight: FontWeight.bold,
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap ?? _ignoreTap,

    child: AppText(
      label,
      variant: AppTextVariant.subtitle,
      colorType: AppTextColor.textBrand,
      textAlign: TextAlign.center,
      fontWeight: FontWeight.bold,
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
    final restBorder = isError
        ? AppFieldStyle.errorBorder(context)
        : AppFieldStyle.restBorder(context);
    final focusedBorder = isError
        ? AppFieldStyle.errorBorder(context)
        : AppFieldStyle.focusBorder(context);
    final codeStyle = AppTypography.title.copyWith(
      color: enabled
          ? AppFieldStyle.text(context, enabled: true)
          : AppFieldStyle.text(context, enabled: false),
      fontSize: 24,
      fontWeight: FontWeight.w800,
      height: 32 / 24,
      letterSpacing: 3.84,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText('Join code', variant: AppTextVariant.subtitle),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 64,
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLength: 9,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [JoinCodeInputFormatter()],
            style: codeStyle,
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              hintText: 'KQ7M-2X9B',
              hintStyle: codeStyle.copyWith(
                color: AppFieldStyle.placeholder(context),
              ),
              prefixIcon: enabled
                  ? null
                  : AppSvgIcon(
                      AppSvgIcons.lock,
                      size: AppFieldStyle.iconSize,
                      color: AppFieldStyle.icon(context),
                    ),
              prefixIconConstraints: const BoxConstraints(minWidth: 48),
              suffixIcon: enabled
                  ? Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: TextButton(
                        onPressed: _paste,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.ms,
                          ),
                          foregroundColor: AppPalette.aubergine500,
                          backgroundColor: LightColors.primaryPrimaryMute,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppSvgIcon(AppSvgIcons.clipboardPaste, size: 16),
                            SizedBox(width: 6),
                            AppText(
                              'Paste',
                              variant: AppTextVariant.subtitle,
                              colorType: AppTextColor.textBrand,
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 40,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              filled: true,
              fillColor: AppFieldStyle.fill(
                context,
                enabled: enabled,
                active: false,
              ),
              border: AppFieldStyle.border(restBorder),
              enabledBorder: AppFieldStyle.border(restBorder),
              disabledBorder: AppFieldStyle.border(restBorder),
              focusedBorder: AppFieldStyle.border(focusedBorder, width: 1.5),
            ),
          ),
        ),
        if (errorMessage case final message?) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSvgIcon(
                AppSvgIcons.circleAlert500,
                size: 14,
                color: LightColors.errorErrorDefault,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppText(
                  message,
                  variant: AppTextVariant.caption,
                  colorType: AppTextColor.error,
                ),
              ),
            ],
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
    final clean = value.toUpperCase().split('').where((character) {
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
          AppSvgIcon(
            parts.first == 'Too many tries'
                ? AppSvgIcons.timer
                : AppSvgIcons.info,
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
    this.role,
    this.code,
    this.roleLabel = "You'll join as",
    this.additionalRole,
    this.additionalRoleLabel = 'This code adds',
    this.additionalRoleTone = AppBadgeTone.success,
    this.codeRole,
    this.codeRoleLabel = 'Code is for',
  });

  final String name;
  final String location;
  final String? role;
  final String? code;
  final String roleLabel;
  final String? additionalRole;
  final String additionalRoleLabel;
  final AppBadgeTone additionalRoleTone;
  final String? codeRole;
  final String codeRoleLabel;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.ml),
          child: SchoolIdentity(name: name, location: location),
        ),
        const Divider(height: 1, thickness: 1, color: AppPalette.stone200),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.ml,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: [
              if (role != null)
                _ConfirmationRow(label: roleLabel, value: role!),
              if (role != null &&
                  (code != null || additionalRole != null || codeRole != null))
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppPalette.stone100,
                ),
              if (additionalRole != null)
                _ConfirmationRow(
                  label: additionalRoleLabel,
                  value: additionalRole!,
                  tone: additionalRoleTone,
                  showPlus: true,
                ),
              if (codeRole != null)
                _ConfirmationRow(
                  label: codeRoleLabel,
                  value: codeRole!,
                  tone: codeRole == 'Teacher'
                      ? AppBadgeTone.info
                      : AppBadgeTone.neutral,
                ),
              if (code != null)
                _ConfirmationRow(
                  label: 'School code',
                  value: code!,
                  isPlainValue: true,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({
    required this.label,
    required this.value,
    this.tone = AppBadgeTone.info,
    this.showPlus = false,
    this.isPlainValue = false,
  });

  final String label;
  final String value;
  final AppBadgeTone tone;
  final bool showPlus;
  final bool isPlainValue;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: AppText(
            label,
            variant: AppTextVariant.body,
            colorType: AppTextColor.textMuted,
          ),
        ),
        if (isPlainValue)
          AppText(
            value,
            variant: AppTextVariant.subtitle,
            colorType: AppTextColor.textStrong,
            letterSpacing: 0.56,
          )
        else
          _RolePill(label: value, tone: tone, showPlus: showPlus),
      ],
    ),
  );
}

class _RolePill extends StatelessWidget {
  const _RolePill({
    required this.label,
    required this.tone,
    this.showPlus = false,
  });

  final String label;
  final AppBadgeTone tone;
  final bool showPlus;

  @override
  Widget build(BuildContext context) => Container(
    height: 28,
    padding: EdgeInsets.only(left: showPlus ? 9 : 12, right: 12),
    decoration: BoxDecoration(
      color: tone.mute,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: tone.thin),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPlus) ...[
          AppSvgIcon(AppSvgIcons.plus, size: 14, color: tone.strong),
          const SizedBox(width: AppSpacing.xs),
        ],
        AppText(
          label,
          style: AppTypography.body.copyWith(
            fontSize: 13,
            height: 16 / 13,
            fontWeight: FontWeight.w700,
            color: tone.strong,
          ),
        ),
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: const AppSvgIcon(
          AppSvgIcons.school,
          color: AppPalette.white,
          size: 26,
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              name,
              style: AppTypography.h3.copyWith(
                fontSize: 22,
                height: 28 / 22,
                letterSpacing: -0.22,
                color: AppPalette.stone900,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            AppText(
              location,
              variant: AppTextVariant.body,
              colorType: AppTextColor.textMuted,
            ),
          ],
        ),
      ),
    ],
  );
}
