import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/widgets/cached_network_image_widget.dart';
import 'package:hugeicons/hugeicons.dart';

/// Wraps [children] in a surface card with consistent vertical spacing.
class DeleteResolutionItemList extends StatelessWidget {
  const DeleteResolutionItemList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == children.length - 1 ? 0 : AppSpacing.sm,
              ),
              child: children[i],
            ),
        ],
      ),
    );
  }
}

class DeleteResolutionTextActionRow extends StatelessWidget {
  const DeleteResolutionTextActionRow({
    super.key,
    required this.title,
    required this.onRemove,
  });

  final String title;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AppElevatedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              title,
              colorType: AppTextColor.textInverted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppHugeIconButton(
            hugeIcon: HugeIcons.strokeRoundedDelete02,
            hugeIconStrokeWidth: 2,
            hugeIconRasterSize: 18,
            foregroundColor: LightColors.errorErrorDefault,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class DeleteResolutionPersonRow extends StatelessWidget {
  const DeleteResolutionPersonRow({
    super.key,
    required this.avatarUrl,
    required this.title,
    this.subtitle,
    this.onRemove,
  });

  final String avatarUrl;
  final String title;
  final String? subtitle;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return AppElevatedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          CachedNetworkImageWidget(
            imageUrl: avatarUrl,
            width: 35,
            height: 35,
            borderRadius: 40,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  colorType: AppTextColor.textInverted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  AppText(
                    subtitle!,
                    colorType: AppTextColor.textMute,
                    fontSize: 12,
                  ),
                ],
              ],
            ),
          ),
          if (onRemove != null)
            AppHugeIconButton(
              hugeIcon: HugeIcons.strokeRoundedDelete02,
              hugeIconStrokeWidth: 2,
              hugeIconRasterSize: 18,
              foregroundColor: LightColors.errorErrorDefault,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
