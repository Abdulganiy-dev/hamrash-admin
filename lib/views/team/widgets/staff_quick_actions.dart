import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/views/team/widgets/quick_action_pill.dart';
import 'package:url_launcher/url_launcher.dart';

/// Call, Message and Email in one 44 tall row. All three always show; the
/// phone decides Call and Message, the address decides Email. Opening the
/// phone's own apps happens outside Hamrash, so failures only get a toast.
class StaffQuickActions extends StatelessWidget {
  const StaffQuickActions({
    super.key,
    required this.firstName,
    this.phone,
    this.email,
  });

  final String firstName;
  final String? phone;
  final String? email;

  String? get _phone {
    final value = phone?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get _email {
    final value = email?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _open(
    BuildContext context,
    Uri uri,
    String failure,
  ) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        AppToast.show(failure, type: AppToastType.error);
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.show(failure, type: AppToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = _phone;
    final email = _email;

    return Row(
      children: [
        Expanded(
          child: QuickActionPill(
            icon: AppSvgIcons.phone,
            label: 'Call',
            semanticLabel: 'Call $firstName',
            onTap: phone == null
                ? null
                : () => _open(
                    context,
                    Uri(scheme: 'tel', path: phone),
                    "Couldn't open the phone app.",
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: QuickActionPill(
            icon: AppSvgIcons.messageCircle,
            label: 'Message',
            semanticLabel: 'Message $firstName',
            onTap: phone == null
                ? null
                : () => _open(
                    context,
                    Uri(scheme: 'sms', path: phone),
                    "Couldn't open Messages.",
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: QuickActionPill(
            icon: AppSvgIcons.mail,
            label: 'Email',
            semanticLabel: 'Email $firstName',
            onTap: email == null
                ? null
                : () => _open(
                    context,
                    Uri(scheme: 'mailto', path: email),
                    "Couldn't open your email app.",
                  ),
          ),
        ),
      ],
    );
  }
}
