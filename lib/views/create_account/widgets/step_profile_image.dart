import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

/// Placeholder for [AdminProfileModel.avatarUrl] — picker to be wired later.
class CreateAccountStepProfileImage extends StatelessWidget {
  const CreateAccountStepProfileImage({
    super.key,
    required this.onPickImagePressed,
    this.selectedImage,
  });

  final VoidCallback onPickImagePressed;
  final XFile? selectedImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = ScaffoldInsets.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: top.bodyTopInset),
        AppText(
          'Add a friendly profile photo',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ).headerBottomPadding(),
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  selectedImage != null
                      ? GestureDetector(
                          onTap: onPickImagePressed,
                          child: ClipOval(
                            child: Image.file(
                              File(selectedImage!.path),
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedImageAdd02,
                                    size: 150,
                                    strokeWidth: 2,
                                    color: LightColors.textTextInverted,
                                  ),
                                );
                              },
                            ),
                          ),
                        ).hapticFeedback(VibrationType.light)
                      : AppHugeIconButton(
                          hugeIcon: HugeIcons.strokeRoundedImageAdd02,
                          hugeIconStrokeWidth: 2,
                          hugeIconRasterSize: 150,
                          foregroundColorType:
                              AppButtonForegroundColor.iconInverted,
                          onPressed: onPickImagePressed,
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
