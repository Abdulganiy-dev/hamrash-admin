import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/widgets/cached_network_image_widget.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

class TeacherStepPhoto extends StatelessWidget {
  const TeacherStepPhoto({
    super.key,
    required this.onPickImagePressed,
    this.selectedImage,
    this.existingAvatarUrl,
  });

  final VoidCallback onPickImagePressed;
  final XFile? selectedImage;
  final String? existingAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = ScaffoldInsets.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: top.bodyTopInset),
        AppText(
          'Add a profile photo',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ).padding(bottom: AppSpacing.xs),
        AppText(
          'Optional — you can add a photo later.',
          colorType: AppTextColor.textMute,
          fontSize: 13,
        ).padding(bottom: AppSpacing.lg),
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_buildImageWidget(context)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    if (selectedImage != null) {
      return GestureDetector(
        onTap: onPickImagePressed,
        child: ClipOval(
          child: Image.file(
            File(selectedImage!.path),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, err, stack) => _placeholder(context),
          ),
        ),
      ).hapticFeedback(VibrationType.light);
    }

    if (existingAvatarUrl != null) {
      return GestureDetector(
        onTap: onPickImagePressed,
        child: CachedNetworkImageWidget(
          imageUrl: existingAvatarUrl!,
          width: 200,
          height: 200,
          borderRadius: 100,
          fit: BoxFit.cover,
        ),
      ).hapticFeedback(VibrationType.light);
    }

    return AppHugeIconButton(
      hugeIcon: HugeIcons.strokeRoundedImageAdd02,
      hugeIconStrokeWidth: 2,
      hugeIconRasterSize: 150,
      foregroundColorType: AppButtonForegroundColor.iconInverted,
      onPressed: onPickImagePressed,
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedImageAdd02,
        size: 80,
        strokeWidth: 2,
        color: LightColors.textTextInverted,
      ),
    );
  }
}
