import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/radius_containers.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/utils/phone_format.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

/// 8.12 · Call, message or email a staff member. Each row closes the sheet
/// first, then asks the phone to open its own app; a missing phone or email
/// greys the row out instead of hiding it.
class ContactSheet extends StatelessWidget {
  const ContactSheet({
    super.key,
    required this.firstName,
    required this.subtitle,
    this.phone,
    this.email,
  });

  final String firstName;

  /// "{Job title} · {Staff app|Admin app}".
  final String subtitle;
  final String? phone;
  final String? email;

  static const _border = AppPalette.stone200;

  String? get _phone {
    final value = phone?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get _email {
    final value = email?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String get _phoneDisplay => switch (_phone) {
    final value? => PhoneFormat.nationalDisplay(value),
    null => 'Not added',
  };

  String get _emailDisplay => _email ?? 'Not added';

  String get _e164 => PhoneFormat.stored(_phone ?? '') ?? _phone!;

  Future<void> _launch(BuildContext context, Uri uri, String failure) async {
    // Close first: the caller should land back on the staff page, then in
    // the phone's own call, message or email app.
    Navigator.of(context).pop();
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) AppToast.show(failure, type: AppToastType.error);
    } catch (_) {
      AppToast.show(failure, type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = _phone;
    final email = _email;

    return AppSheet(
      title: 'Contact $firstName',
      subtitle: subtitle,
      bodyPadding: const EdgeInsets.fromLTRB(
        AppSpacing.ml,
        AppSpacing.ms,
        AppSpacing.ml,
        AppSpacing.ml,
      ),
      body: ClipRRect(
        borderRadius: AppRadius.brLg,
        child: ColoredBox(
          color: AppPalette.stone50,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ContactRow(
                icon: AppSvgIcons.phone,
                title: 'Call',
                value: _phoneDisplay,
                enabled: phone != null,
                semanticLabel: _semanticLabel('Call', _phoneDisplay),
                onTap: phone == null
                    ? null
                    : () => _launch(
                        context,
                        Uri(scheme: 'tel', path: _e164),
                        "Couldn't open the phone app.",
                      ),
              ),
              const _RowDivider(color: _border),
              _ContactRow(
                icon: AppSvgIcons.messageCircle,
                title: 'Message',
                value: _phoneDisplay,
                enabled: phone != null,
                semanticLabel: _semanticLabel('Message', _phoneDisplay),
                onTap: phone == null
                    ? null
                    : () => _launch(
                        context,
                        Uri(scheme: 'sms', path: _e164),
                        "Couldn't open Messages.",
                      ),
              ),
              const _RowDivider(color: _border),
              _ContactRow(
                icon: AppSvgIcons.mail,
                title: 'Email',
                value: _emailDisplay,
                enabled: email != null,
                semanticLabel: _semanticLabel('Email', _emailDisplay),
                onTap: email == null
                    ? null
                    : () => _launch(
                        context,
                        Uri(scheme: 'mailto', path: email),
                        "Couldn't open your email app.",
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _semanticLabel(String action, String value) =>
      '$action $firstName, $value';
}

class _ContactRow extends StatefulWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.enabled,
    required this.semanticLabel,
    required this.onTap,
  });

  final AppSvgIconData icon;
  final String title;
  final String value;
  final bool enabled;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  State<_ContactRow> createState() => _ContactRowState();
}

class _ContactRowState extends State<_ContactRow> {
  bool _pressed = false;

  bool get _enabled => widget.enabled;

  void _pressDown(TapDownDetails _) {
    if (_enabled && !_pressed) setState(() => _pressed = true);
  }

  void _pressUp([TapUpDetails? _]) {
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final foreground = _enabled
        ? LightColors.textStrong
        : LightColors.textDisabled;
    final valueColor = _enabled
        ? LightColors.textBody
        : LightColors.textDisabled;
    final iconColor = _enabled
        ? LightColors.primaryPrimaryDefault
        : LightColors.textDisabled;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _pressDown,
        onTapUp: _pressUp,
        onTapCancel: _pressUp,
        onTap: _enabled ? widget.onTap : null,
        child: SizedBox(
          height: 64,
          child: ColoredBox(
            color: _pressed && _enabled
                ? AppPalette.stone100
                : Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _enabled
                          ? LightColors.primaryPrimaryMute
                          : AppPalette.stone100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AppSvgIcon(
                        widget.icon,
                        size: 20,
                        color: iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title.copyWith(
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        AppText(
                          widget.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                            color: valueColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_enabled) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const AppSvgIcon(
                      AppSvgIcons.chevronRight500,
                      size: 20,
                      color: LightColors.textDisabled,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 1px divider between contact rows, inset past the tile so it reads as
/// one grouped card.
class _RowDivider extends StatelessWidget {
  const _RowDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 70),
    child: Container(height: 1, color: color),
  );
}
