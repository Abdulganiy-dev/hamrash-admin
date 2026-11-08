import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// The unused invite as one tappable card: its code and that it never
/// expires. Opening it shows the full invite-ready sheet.
class StaffInviteCard extends StatelessWidget {
  const StaffInviteCard({super.key, required this.code, required this.onTap});

  /// Formatted as `K7M2-QX9P`.
  final String code;
  final VoidCallback onTap;

  static const _border = AppPalette.stone200;
  static const _labelStyle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.88,
  );

  @override
  Widget build(BuildContext context) => BouncyButton(
    onPressed: onTap,
    pressedScale: 0.98,
    child: ClipRRect(
      borderRadius: AppRadius.brCard,
      child: Container(
        decoration: BoxDecoration(
          color: AppPalette.white,
          border: Border.all(color: _border),
        ),
        child: Column(
          // Both bands span the card and start at the same left edge.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _band(
              child: Row(
                children: [
                  Expanded(
                    child: _labelValue(
                      label: 'INVITE CODE',
                      value: code,
                      valueStyle: AppTypography.body.copyWith(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: LightColors.textStrong,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const AppSvgIcon(
                    AppSvgIcons.chevronRight500,
                    size: 20,
                    color: LightColors.textDisabled,
                  ),
                ],
              ),
            ),
            Container(height: 1, color: _border),
            _band(
              child: _labelValue(
                label: 'EXPIRES',
                value: 'Never',
                valueStyle: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: LightColors.textStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _band({required Widget child}) => SizedBox(
    height: 56,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: child,
    ),
  );

  Widget _labelValue({
    required String label,
    required String value,
    required TextStyle valueStyle,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AppText(label, style: _labelStyle.copyWith(color: LightColors.textMuted)),
      AppText(value, style: valueStyle),
    ],
  );
}
