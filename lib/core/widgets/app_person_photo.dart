import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/image_view.dart';

/// A person's photo as a round picture of [size], or [fallback] (their
/// initials circle) when there is no photo, while it loads, or if it fails.
///
/// For avatars that keep their own look without a photo (the tinted circles
/// on staff and parent rows); use `AppLeadingPicture` for a bordered picture
/// with the standard initials.
class AppPersonPhoto extends StatelessWidget {
  const AppPersonPhoto({
    super.key,
    required this.url,
    required this.size,
    required this.fallback,
  });

  final String? url;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final photo = url?.trim();
    if (photo == null || photo.isEmpty) return fallback;
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: CachedNetworkImageWidget(
          imageUrl: photo,
          width: size,
          height: size,
          placeholder: fallback,
          errorWidget: fallback,
        ),
      ),
    );
  }
}
