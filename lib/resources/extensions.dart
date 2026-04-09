

import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/helpers/haptic_helper.dart';

extension WidgetExtension on Widget {
  Widget padding(
      {double left = 0, double right = 0, double top = 0, double bottom = 0}) {
    return Padding(
        padding:
            EdgeInsets.only(bottom: bottom, top: top, left: left, right: right),
        child: this);
  }

  Widget headerBottomPadding() {
    return Padding(
        padding: EdgeInsets.only(
          bottom: 40,
        ),
        child: this);
  }

  Widget paddingBtwButtonsFromBelow() {
    return Padding(
        padding: EdgeInsets.only(
          top: 16,
        ),
        child: this);
  }

  Widget buttonTopPadding() {
    return Padding(
        padding: EdgeInsets.only(
          top: 32,
        ),
        child: this);
  }

  Widget underFormFieldPadding(){
     return Padding(
        padding: EdgeInsets.only(
          bottom: 16,
        ),
        child: this);

  }

    Widget underListItemPadding(){
     return Padding(
        padding: EdgeInsets.only(
          bottom: 8,
        ),
        child: this);

  }

  Widget paddingAll(double value) {
    return Padding(padding: EdgeInsets.all(value), child: this);
  }

  Widget paddingSymmetric({double vertical = 0, double horizontal = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: this,
    );
  }

  Widget addSpace({double x = 0, double y = 0}) {
    return SizedBox(width: x, height: y);
  }

  Widget replace(Widget widget, bool when) {
    return when ? widget : this;
  }

  Widget hideIf(bool when) {
    return when ? const SizedBox() : this;
  }

  Widget center() {
    return Center(child: this);
  }

  Widget greyOut() {
    return AbsorbPointer(
      child: Opacity(
        opacity: 0.5,
        child: this,
      ),
    );
  }

  Widget hapticFeedback(VibrationType type) {
    return GestureDetector(
      onTap: () => HapticHelpers.vibrate(type),
      child: this,
    );
  }

  Widget blurredFrosted({double blur = 1}) {
    return Blur(
      blur: blur,
      child: this,
    ).frosted(blur: blur, frostColor: Colors.white.withOpacity(0.1));
  }
}

extension GestureDetectorExtension on GestureDetector {
  GestureDetector hapticFeedback([VibrationType type = VibrationType.light]) {
    final originalOnTap = onTap;
    return GestureDetector(
      onTap: originalOnTap != null
          ? () {
              HapticHelpers.vibrate(type);
              originalOnTap();
            }
          : () => HapticHelpers.vibrate(type),
      behavior: behavior,
      excludeFromSemantics: excludeFromSemantics,
      dragStartBehavior: dragStartBehavior,
      child: child,
    );
  }
}
