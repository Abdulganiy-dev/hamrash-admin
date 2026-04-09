
import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/utils/view_util.dart';
import 'package:hamrash_admin/services/error_logger_service.dart';

class NavigationService {
  static PageRouteBuilder<T> generalPageRouteBuilder<T>({
    required Widget screen,
    PageTransition transition = PageTransition.slide,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        return screen;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (transition) {
          case PageTransition.scale:
            return ScaleTransition(
              scale: animation.drive(CurveTween(curve: Curves.ease)),
              child: child,
            );
          case PageTransition.fade:
            return FadeTransition(
              opacity: animation.drive(CurveTween(curve: Curves.ease)),
              child: child,
            );
          case PageTransition.slide:
            final offset = Tween(
              begin: Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.ease));
            return SlideTransition(position: offset, child: child);
        }
      },
      transitionDuration: Duration(milliseconds: 500),
    );
  }

  static Future<T?> animatedNavigation<T>({
    required Widget screen,
    PageTransition transition = PageTransition.slide,
  }) {
    ErrorLoggerService.logInfo(
      "Navigating to ${_lowercaseFirstLetter(screen.toString())}",
    );
    final ctx = ViewUtil.navigatorKey.currentContext;
    if (ctx == null) {
      ErrorLoggerService.logError(
        "Navigation context is null",
        context: "NavigationService.animatedNavigation",
      );
      return Future.value(null);
    }

    return Navigator.push<T>(
      ctx,
      NavigationService.generalPageRouteBuilder(
        screen: screen,
        transition: transition,
      ),
    );
  }

  static void popScreen<T extends Object?>([T? result]) {
    final ctx = ViewUtil.navigatorKey.currentContext;
    if (ctx == null) {
      ErrorLoggerService.logError(
        "Navigation context is null",
        context: "NavigationService.popScreen",
      );
      return;
    }
    Navigator.pop<T>(ctx, result);
  }

  static String _lowercaseFirstLetter(String str) {
    if (str.isEmpty) return str;
    return str[0].toLowerCase() + str.substring(1);
  }
}

enum PageTransition { scale, fade, slide }
