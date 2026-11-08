import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/utils/phone_format.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';

/// The staff record in four cells: staff number and type, then phone and
/// email. Name, role and record status live in the identity row above.
class StaffDetailsCard extends StatelessWidget {
  const StaffDetailsCard({
    super.key,
    required this.staffNumber,
    required this.staffType,
    this.phone,
    this.email,
  });

  /// Empty when the record has none: shown as "Not set".
  final String? staffNumber;

  /// "Teaching" or "Non-teaching".
  final String staffType;
  final String? phone;
  final String? email;

  static const _border = AppPalette.stone200;
  static const _bandHeight = 56.0;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadius.brCard,
    child: Container(
      decoration: BoxDecoration(
        color: AppPalette.white,
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _band(
            band: 1,
            left: _Cell(
              label: 'Staff no.',
              value: staffNumber,
              fallback: 'Not set',
            ),
            right: _Cell(label: 'Staff type', value: staffType),
          ),
          _hairline(1),
          _band(
            band: 2,
            left: _Cell(
              label: 'Phone',
              value: PhoneFormat.nationalDisplay(phone),
              fallback: 'Not added',
            ),
            right: _Cell(label: 'Email', value: email, fallback: 'Not added'),
          ),
        ],
      ),
    ),
  );

  Widget _band({
    required int band,
    required Widget left,
    required Widget right,
  }) => SizedBox(
    key: ValueKey('details-band-$band'),
    height: _bandHeight,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: left),
        Container(
          key: ValueKey('details-divider-$band'),
          width: 1,
          color: _border,
        ),
        Expanded(child: right),
      ],
    ),
  );

  Widget _hairline(int band) => Container(
    key: ValueKey('details-hairline-$band'),
    height: 1,
    color: _border,
  );
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, this.value, this.fallback = 'Not added'});

  final String label;
  final String? value;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim() ?? '';
    final empty = text.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              height: 16 / 12,
              color: LightColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          AppText(
            empty ? fallback : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              height: 20 / 14,
              fontWeight: empty ? FontWeight.w600 : FontWeight.w700,
              color: empty ? LightColors.textMuted : LightColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}
