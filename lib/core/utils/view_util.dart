import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ViewUtil {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Shows [message] as an [AppToast] (dark pill above the tab bar).
  static void showSnackBar(
    String? message, {
    AppToastType type = AppToastType.info,
    BuildContext? translationContext,
    int? durationSeconds,
  }) {
    if (message == null || message.isEmpty) return;
    AppToast.show(
      message,
      type: type,
      duration: durationSeconds == null
          ? null
          : Duration(seconds: durationSeconds),
    );
  }

  static void showErrorSnackBar(
    String? message, {
    BuildContext? translationContext,
    int? durationSeconds,
  }) => showSnackBar(
    message,
    type: AppToastType.error,
    durationSeconds: durationSeconds,
  );

  static void showWarningSnackBar(
    String? message, {
    BuildContext? translationContext,
    int? durationSeconds,
  }) => showSnackBar(
    message,
    type: AppToastType.warning,
    durationSeconds: durationSeconds,
  );

  static void showSuccessSnackBar(
    String? message, {
    BuildContext? translationContext,
    int? durationSeconds,
  }) => showSnackBar(
    message,
    type: AppToastType.success,
    durationSeconds: durationSeconds,
  );

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
        colorFilter: color != null
            ? ColorFilter.mode(color, BlendMode.srcIn)
            : null,
        width: width,
        height: height,
      ),
    );
  }
}
