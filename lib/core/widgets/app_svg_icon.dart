import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Identifies one of Hamrash Admin's bundled, tintable SVG icons.
class AppSvgIconData {
  const AppSvgIconData(this.assetPath);

  final String assetPath;
}

/// The SVG icons used across Hamrash Admin.
abstract final class AppSvgIcons {
  static const arrowLeftRight = AppSvgIconData(
    'assets/svg/icons/arrow-left-right.svg',
  );
  static const award = AppSvgIconData('assets/svg/icons/award.svg');
  static const bell = AppSvgIconData('assets/svg/icons/bell.svg');
  static const bookOpen = AppSvgIconData('assets/svg/icons/book-open.svg');
  static const calendar = AppSvgIconData('assets/svg/icons/calendar.svg');
  static const camera = AppSvgIconData('assets/svg/icons/camera.svg');
  static const check = AppSvgIconData('assets/svg/icons/check.svg');
  static const check600 = AppSvgIconData('assets/svg/icons/check600.svg');
  static const chevronDown = AppSvgIconData(
    'assets/svg/icons/chevron-down.svg',
  );
  static const chevronLeft = AppSvgIconData(
    'assets/svg/icons/chevron-left.svg',
  );
  static const chevronLeft500 = AppSvgIconData(
    'assets/svg/icons/chevron-left500.svg',
  );
  static const chevronRight = AppSvgIconData(
    'assets/svg/icons/chevron-right.svg',
  );
  static const chevronRight500 = AppSvgIconData(
    'assets/svg/icons/chevron-right500.svg',
  );
  static const chevronUp = AppSvgIconData('assets/svg/icons/chevron-up.svg');
  static const circleAlert = AppSvgIconData(
    'assets/svg/icons/circle-alert.svg',
  );
  static const circleAlert300 = AppSvgIconData(
    'assets/svg/icons/circle-alert300.svg',
  );
  static const circleAlert500 = AppSvgIconData(
    'assets/svg/icons/circle-alert500.svg',
  );
  static const circleCheck300 = AppSvgIconData(
    'assets/svg/icons/circle-check300.svg',
  );
  static const circleCheck500 = AppSvgIconData(
    'assets/svg/icons/circle-check500.svg',
  );
  static const circleHelp = AppSvgIconData('assets/svg/icons/circle-help.svg');
  static const circleMinus = AppSvgIconData(
    'assets/svg/icons/circle-minus.svg',
  );
  static const circlePause = AppSvgIconData(
    'assets/svg/icons/circle-pause.svg',
  );
  static const circleX300 = AppSvgIconData('assets/svg/icons/circle-x300.svg');
  static const circleX500 = AppSvgIconData('assets/svg/icons/circle-x500.svg');
  static const clipboardPaste = AppSvgIconData(
    'assets/svg/icons/clipboard-paste.svg',
  );
  static const clock = AppSvgIconData('assets/svg/icons/clock.svg');
  static const copy = AppSvgIconData('assets/svg/icons/copy.svg');
  static const ellipsis = AppSvgIconData('assets/svg/icons/ellipsis.svg');
  static const eye = AppSvgIconData('assets/svg/icons/eye.svg');
  static const eyeOff = AppSvgIconData('assets/svg/icons/eye-off.svg');
  static const graduationCap = AppSvgIconData(
    'assets/svg/icons/graduation-cap.svg',
  );
  static const house = AppSvgIconData('assets/svg/icons/house.svg');
  static const house500 = AppSvgIconData('assets/svg/icons/house500.svg');
  static const image = AppSvgIconData('assets/svg/icons/image.svg');
  static const info = AppSvgIconData('assets/svg/icons/info.svg');
  static const layers = AppSvgIconData('assets/svg/icons/layers.svg');
  static const layoutGrid = AppSvgIconData('assets/svg/icons/layout-grid.svg');
  static const lock = AppSvgIconData('assets/svg/icons/lock.svg');
  static const lockOpen = AppSvgIconData('assets/svg/icons/lock-open.svg');
  static const logOut = AppSvgIconData('assets/svg/icons/log-out.svg');
  static const messageSquare = AppSvgIconData(
    'assets/svg/icons/message-square.svg',
  );
  static const minus600 = AppSvgIconData('assets/svg/icons/minus600.svg');
  static const pencil = AppSvgIconData('assets/svg/icons/pencil.svg');
  static const plus = AppSvgIconData('assets/svg/icons/plus.svg');
  static const plus600 = AppSvgIconData('assets/svg/icons/plus600.svg');
  static const refreshCw500 = AppSvgIconData(
    'assets/svg/icons/refresh-cw500.svg',
  );
  static const school = AppSvgIconData('assets/svg/icons/school.svg');
  static const search = AppSvgIconData('assets/svg/icons/search.svg');
  static const search300 = AppSvgIconData('assets/svg/icons/search300.svg');
  static const timer = AppSvgIconData('assets/svg/icons/timer.svg');
  static const toggleLeft = AppSvgIconData('assets/svg/icons/toggle-left.svg');
  static const toggleRight = AppSvgIconData(
    'assets/svg/icons/toggle-right.svg',
  );
  static const trash2 = AppSvgIconData('assets/svg/icons/trash2.svg');
  static const triangleAlert = AppSvgIconData(
    'assets/svg/icons/triangle-alert.svg',
  );
  static const triangleAlert300 = AppSvgIconData(
    'assets/svg/icons/triangle-alert300.svg',
  );
  static const triangleAlert500 = AppSvgIconData(
    'assets/svg/icons/triangle-alert500.svg',
  );
  static const userPlus = AppSvgIconData('assets/svg/icons/user-plus.svg');
  static const users = AppSvgIconData('assets/svg/icons/users.svg');
  static const wallet = AppSvgIconData('assets/svg/icons/wallet.svg');
  static const wifiOff300 = AppSvgIconData('assets/svg/icons/wifi-off300.svg');
  static const x = AppSvgIconData('assets/svg/icons/x.svg');
  static const x500 = AppSvgIconData('assets/svg/icons/x500.svg');
  static const x600 = AppSvgIconData('assets/svg/icons/x600.svg');
}

/// Draws a bundled SVG icon using the supplied size and color.
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final AppSvgIconData? icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    if (icon == null) return SizedBox.square(dimension: size);

    final resolvedColor = color ?? IconTheme.of(context).color;
    return SvgPicture.asset(
      icon.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: resolvedColor == null
          ? null
          : ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}
