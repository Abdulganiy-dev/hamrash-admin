import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Lucide icons used across Hamrash Admin.
///
/// Thin and heavy variants of the same glyph (for example the old `check600`
/// and `x500` SVGs) now share one Lucide icon: the line weight comes from the
/// icon font, so a name describes the shape, not the stroke.
abstract final class AppIcons {
  static const activity = LucideIcons.activity;
  static const arrowLeftRight = LucideIcons.arrowLeftRight;
  static const award = LucideIcons.award;
  static const bell = LucideIcons.bell;
  static const briefcase = LucideIcons.briefcase;
  static const bookOpen = LucideIcons.bookOpen;
  static const cake = LucideIcons.cake;
  static const calendar = LucideIcons.calendar;
  static const camera = LucideIcons.camera;
  static const check = LucideIcons.check;
  static const chevronDown = LucideIcons.chevronDown;
  static const chevronLeft = LucideIcons.chevronLeft;
  static const chevronRight = LucideIcons.chevronRight;
  static const chevronUp = LucideIcons.chevronUp;
  static const circleAlert = LucideIcons.circleAlert;
  static const circleCheck = LucideIcons.circleCheck;
  static const circleHelp = LucideIcons.circleHelp;
  static const circleMinus = LucideIcons.circleMinus;
  static const circlePause = LucideIcons.circlePause;
  static const circleX = LucideIcons.circleX;
  static const clipboardPaste = LucideIcons.clipboardPaste;
  static const clock = LucideIcons.clock;
  static const columns3 = LucideIcons.columns3;
  static const copy = LucideIcons.copy;
  static const ellipsis = LucideIcons.ellipsis;
  static const eye = LucideIcons.eye;
  static const eyeOff = LucideIcons.eyeOff;
  static const flag = LucideIcons.flag;
  static const graduationCap = LucideIcons.graduationCap;
  static const hash = LucideIcons.hash;
  static const house = LucideIcons.house;
  static const image = LucideIcons.image;
  static const info = LucideIcons.info;
  static const layers = LucideIcons.layers;
  static const layoutGrid = LucideIcons.layoutGrid;
  static const lock = LucideIcons.lock;
  static const lockOpen = LucideIcons.lockOpen;
  static const logOut = LucideIcons.logOut;
  static const mail = LucideIcons.mail;
  static const messageCircle = LucideIcons.messageCircle;
  static const messageSquare = LucideIcons.messageSquare;
  static const mapPin = LucideIcons.mapPin;
  static const minus = LucideIcons.minus;
  static const pencil = LucideIcons.pencil;
  static const phone = LucideIcons.phone;
  static const plus = LucideIcons.plus;
  static const refreshCw = LucideIcons.refreshCw;
  static const school = LucideIcons.school;
  static const search = LucideIcons.search;
  static const share = LucideIcons.share;
  static const shield = LucideIcons.shield;
  static const slidersHorizontal = LucideIcons.slidersHorizontal;
  static const smartphone = LucideIcons.smartphone;
  static const timer = LucideIcons.timer;
  static const toggleLeft = LucideIcons.toggleLeft;
  static const toggleRight = LucideIcons.toggleRight;
  static const trash2 = LucideIcons.trash2;
  static const triangleAlert = LucideIcons.triangleAlert;
  static const user = LucideIcons.user;
  static const userMinus = LucideIcons.userMinus;
  static const userPlus = LucideIcons.userPlus;
  static const users = LucideIcons.users;
  static const wallet = LucideIcons.wallet;
  static const wifiOff = LucideIcons.wifiOff;
  static const x = LucideIcons.x;
}

/// Draws a Lucide icon using the supplied size and color.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final IconData? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final iconTheme = IconTheme.of(context);
    final iconSize = size ?? iconTheme.size ?? 24;
    if (icon == null) return SizedBox.square(dimension: iconSize);

    // Center + widthFactor/heightFactor: the icon keeps its own size even when
    // a parent hands it tight constraints (e.g. Container(width: 28, height:
    // 28, child: AppIcon(AppIcons.check, size: 14))). Without this, the icon
    // is forced to fill the parent and every such icon renders at the
    // container's size.
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: Icon(
        icon,
        size: iconSize,
        color: color ?? iconTheme.color,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
