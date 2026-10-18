import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/image_view.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// The school's logo, or a lit aubergine tile with a graduation cap until
/// it has one.
class SchoolLogo extends StatelessWidget {
  const SchoolLogo({
    super.key,
    required this.logoUrl,
    this.size = 56,
    this.radius = 16,
  });

  final String? logoUrl;
  final double size;

  /// Pass `size / 2` for a round logo.
  final double radius;

  static const _fill = LinearGradient(
    begin: Alignment(-0.35, -1),
    end: Alignment(0.35, 1),
    colors: [Color(0xFF4D2A4B), AppPalette.aubergine500, Color(0xFF2E172D)],
    stops: [0, 0.5, 1],
  );

  @override
  Widget build(BuildContext context) {
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: _fill,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox.square(
        dimension: size,
        child: AppSvgIcon(
          AppSvgIcons.graduationCap,
          color: AppPalette.white,
          size: size * 0.46,
        ),
      ),
    );

    final url = logoUrl;
    if (url == null || url.isEmpty) return placeholder;
    return CachedNetworkImageWidget(
      imageUrl: url,
      width: size,
      height: size,
      borderRadius: radius,
      placeholder: placeholder,
      errorWidget: placeholder,
    );
  }
}
