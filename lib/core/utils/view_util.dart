import 'package:hamrash_admin/core/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class ViewUtil {

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void showSnackBar(
    String? message, {
    BuildContext? translationContext,
    Color? bgColor,
    Color? textColor,
    int? durationSeconds,
  }) {
    if (message == null || message.isEmpty) return;

    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;

    ScaffoldMessenger.of(navContext).hideCurrentMaterialBanner();

    final int duration = durationSeconds ?? _calculateSnackBarDuration(message);

    ScaffoldMessenger.of(navContext).showMaterialBanner(
      MaterialBanner(
        content: Text(
          message,
          style: TextStyle(color: textColor ?? Colors.white),
        ),
        backgroundColor: bgColor ?? Colors.red,

        actions: [
          GestureDetector(
            child: Icon(Icons.close, color: Colors.white),
            onTap: () {
              ScaffoldMessenger.of(navContext).hideCurrentMaterialBanner();
            },
          ).hapticFeedback(),
        ],
      ),
    );
    Future.delayed(Duration(seconds: duration), () {
      // Add a safety check to ensure the screen is still visible
      if (navContext.mounted) {
        ScaffoldMessenger.of(navContext).hideCurrentMaterialBanner();
      }
    });
  }


  static void showErrorSnackBar(
    String? message, {
    BuildContext? translationContext,
    int? durationSeconds,
  }) {
    showSnackBar(
      message,
      translationContext: translationContext,
      bgColor: Colors.red,
      textColor: Colors.white,
      durationSeconds: durationSeconds,
    );
  }

  static void showWarningSnackBar(
    String? message, {
    BuildContext? translationContext,
    int? durationSeconds,
  }) {
    showSnackBar(
      message,
      translationContext: translationContext,
      bgColor: Colors.orange,
      textColor: Colors.white,
      durationSeconds: durationSeconds,
    );
  }

  static void showSuccessSnackBar(
    String? message, {
    BuildContext? translationContext,
    int? durationSeconds,
  }) {
    showSnackBar(
      message,
      translationContext: translationContext,
      bgColor: Colors.green,
      textColor: Colors.white,
      durationSeconds: durationSeconds,
    );
  }

  static int _calculateSnackBarDuration(String message) {
    final int characterCount = message.length;

    final int calculatedDuration = 10 + (characterCount / 20).ceil();

    return calculatedDuration.clamp(7, 8);
  }

  static final blackGradient = LinearGradient(
  colors: [Color(0xFF3A3A3C), Color(0xFF1C1C1E)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);


static Widget svgPictureAsset({
    required String assetName,
    Color? color,
    double? width,
    double? height,
    double scale = 1,
  }) {
    return Transform.scale(
      scale: scale,
      child: SvgPicture.asset(
        assetName,
        colorFilter:
            color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
        width: width,
        height: height,
      ),
    );
  }

}
