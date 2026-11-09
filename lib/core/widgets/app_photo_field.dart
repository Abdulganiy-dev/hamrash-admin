import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_spinner.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// Where an optional photo is (11.14).
enum AppPhotoStatus {
  /// Initials, "Add a photo".
  empty,

  /// The picked photo under a spinner; the form can carry on meanwhile.
  uploading,

  /// The photo, "Change photo".
  added,

  /// The photo faded with a red badge, "Try again".
  failed,
}

/// How big an [AppPhotoField] is: 80 on a page (11.3), 64 in a sheet (11.8).
/// [hero] is the 88 avatar at the top of a review (11.11).
enum AppPhotoFieldSize {
  large(80, 16, 26, 32, 30, 15),
  compact(64, 14, 20, 26, 26, 13),
  hero(88, 16, 28, 34, 30, 15);

  const AppPhotoFieldSize(
    this.avatar,
    this.gap,
    this.initialsSize,
    this.initialsHeight,
    this.badge,
    this.badgeIcon,
  );

  final double avatar;
  final double gap;
  final double initialsSize;
  final double initialsHeight;
  final double badge;
  final double badgeIcon;
}

/// An optional photo for a person: a round avatar (initials until a photo
/// is chosen) with a camera badge, and a link beside it. Tapping either opens
/// [onTap], usually the photo options sheet.
///
/// The field only shows [status]; whoever owns it picks, uploads and retries.
///
/// ```dart
/// AppPhotoField(
///   name: 'Chioma Okafor',
///   title: 'Chioma Okafor',
///   status: draft.status,
///   image: draft.preview,
///   emptyCaption: 'Optional. You can add it later.',
///   onTap: openPhotoOptions,
/// )
/// ```
class AppPhotoField extends StatelessWidget {
  const AppPhotoField({
    super.key,
    required this.name,
    required this.status,
    required this.onTap,
    this.image,
    this.title,
    this.emptyCaption = 'Optional',
    this.failedCaption = "Couldn't upload the photo. Check your connection.",
    this.size = AppPhotoFieldSize.large,
  });

  /// Gives the initials.
  final String name;
  final AppPhotoStatus status;

  /// The picked photo, shown while it uploads, once added and when it failed.
  final ImageProvider? image;

  /// Bold line above the link, e.g. the person's name on 11.3.
  final String? title;

  /// Under "Add a photo".
  final String emptyCaption;

  /// Under "Try again".
  final String failedCaption;
  final AppPhotoFieldSize size;
  final VoidCallback? onTap;

  String get _link => switch (status) {
    AppPhotoStatus.empty => 'Add a photo',
    AppPhotoStatus.uploading => 'Uploading photo…',
    AppPhotoStatus.added => 'Change photo',
    AppPhotoStatus.failed => 'Try again',
  };

  String? get _caption => switch (status) {
    AppPhotoStatus.empty => emptyCaption,
    AppPhotoStatus.uploading => 'Continue works while it uploads.',
    AppPhotoStatus.added => null,
    AppPhotoStatus.failed => failedCaption,
  };

  @override
  Widget build(BuildContext context) {
    final caption = _caption;
    return Semantics(
      button: true,
      label: _link,
      child: BouncyButton(
        onPressed: onTap,
        pressedScale: 0.98,
        child: Row(
          children: [
            AppPhotoAvatar(
              name: name,
              status: status,
              image: image,
              size: size,
            ),
            SizedBox(width: size.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title case final title?)
                    AppText(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading(20, lineHeight: 26).copyWith(
                        fontWeight: FontWeight.w800,
                        color: LightColors.textStrong,
                      ),
                    ),
                  if (title != null) const SizedBox(height: 2),
                  AppText(
                    _link,
                    style: AppTypography.subtitle.copyWith(
                      color: status == AppPhotoStatus.uploading
                          ? LightColors.textStrong
                          : LightColors.primaryPrimaryText,
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 2),
                    AppText(
                      caption,
                      style: AppTypography.body.copyWith(
                        fontSize: 13,
                        height: 18 / 13,
                        color: status == AppPhotoStatus.failed
                            ? LightColors.errorErrorText
                            : LightColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The round avatar of an [AppPhotoField] on its own: initials or the
/// photo, with the status overlay and, unless [showBadge] is off, the camera
/// or failed badge.
class AppPhotoAvatar extends StatelessWidget {
  const AppPhotoAvatar({
    super.key,
    required this.name,
    required this.status,
    this.image,
    this.size = AppPhotoFieldSize.large,
    this.showBadge = true,
  });

  final String name;
  final AppPhotoStatus status;
  final ImageProvider? image;
  final AppPhotoFieldSize size;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final photo = image;
    final Widget face = photo == null || status == AppPhotoStatus.empty
        ? _Initials(name: name, size: size)
        : ClipOval(
            child: Image(
              image: photo,
              width: size.avatar,
              height: size.avatar,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Initials(name: name, size: size),
            ),
          );

    return SizedBox.square(
      dimension: size.avatar,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: status == AppPhotoStatus.failed
                ? Opacity(opacity: 0.55, child: face)
                : face,
          ),
          if (status == AppPhotoStatus.uploading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppPalette.stone900.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: AppSpinner(size: 24, color: AppPalette.white),
                ),
              ),
            ),
          if (showBadge && status != AppPhotoStatus.uploading)
            Positioned(
              right: -4,
              bottom: -4,
              child: status == AppPhotoStatus.failed
                  ? _FailedBadge(size: size)
                  : _CameraBadge(size: size),
            ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size});

  final String name;
  final AppPhotoFieldSize size;

  String get _letters {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: LightColors.primaryPrimaryMute,
      shape: BoxShape.circle,
      border: Border.all(color: LightColors.primaryPrimaryThin),
    ),
    child: _letters.isEmpty
        ? AppIcon(
            AppIcons.user,
            size: size.initialsSize,
            color: LightColors.primaryPrimaryText,
          )
        : AppText(
            _letters,
            style:
                AppTypography.heading(
                  size.initialsSize,
                  lineHeight: size.initialsHeight,
                ).copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  color: LightColors.primaryPrimaryText,
                ),
          ),
  );
}

class _CameraBadge extends StatelessWidget {
  const _CameraBadge({required this.size});

  final AppPhotoFieldSize size;

  @override
  Widget build(BuildContext context) => Container(
    width: size.badge,
    height: size.badge,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppPalette.white,
      shape: BoxShape.circle,
      border: Border.all(color: LightColors.strokeColourStrokeCard),
      boxShadow: AppShadows.floating,
    ),
    child: AppIcon(
      AppIcons.camera,
      size: size.badgeIcon,
      color: AppPalette.stone700,
    ),
  );
}

class _FailedBadge extends StatelessWidget {
  const _FailedBadge({required this.size});

  final AppPhotoFieldSize size;

  @override
  Widget build(BuildContext context) => Container(
    width: size.badge,
    height: size.badge,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: LightColors.errorErrorDefault,
      shape: BoxShape.circle,
      border: Border.all(color: AppPalette.white, width: 2),
    ),
    child: AppText(
      '!',
      style: AppTypography.subtitle.copyWith(
        fontWeight: FontWeight.w800,
        color: AppPalette.white,
      ),
    ),
  );
}
