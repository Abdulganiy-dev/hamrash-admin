import 'package:flutter/material.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';

class DeleteResolutionDeleteButton extends StatelessWidget {
  const DeleteResolutionDeleteButton({
    super.key,
    required this.entityDisplayName,
    required this.enabled,
    required this.onPressed,
  });

  final String entityDisplayName;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(
      width: double.infinity,
      backgroundColorType: enabled
          ? AppButtonBackgroundColor.error
          : AppButtonBackgroundColor.errorMute,
      foregroundColor: Colors.white,
      onPressed: enabled ? onPressed : null,
      child: Text(
        'Delete "$entityDisplayName"',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
