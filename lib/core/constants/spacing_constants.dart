import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Scale anchors
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Off-scale values — named by pixel value
  static const double s1 = 1.0;
  static const double s2 = 2.0;
  static const double s3 = 3.0;
  static const double s5 = 5.0;
  static const double s6 = 6.0;
  static const double s7 = 7.0;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s13 = 13.0;
  static const double s14 = 14.0;
  static const double s15 = 15.0;
  static const double s18 = 18.0;
  static const double s20 = 20.0;
  static const double s25 = 25.0;
  static const double s28 = 28.0;
  static const double s30 = 30.0;
  static const double s40 = 40.0;
  static const double s46 = 46.0;
  static const double s50 = 50.0;
  static const double s52 = 52.0;
  static const double s53 = 53.0;
  static const double s60 = 60.0;
  static const double s64 = 64.0;
  static const double s72 = 72.0;
  static const double s80 = 80.0;
  static const double s100 = 100.0;

  // EdgeInsets — all sides
  static final EdgeInsets allXs = EdgeInsets.all(xs);
  static final EdgeInsets allSm = EdgeInsets.all(sm);
  static final EdgeInsets allS10 = EdgeInsets.all(s10);
  static final EdgeInsets allS12 = EdgeInsets.all(s12);
  static final EdgeInsets allMd = EdgeInsets.all(md);
  static final EdgeInsets allS20 = EdgeInsets.all(s20);
  static final EdgeInsets allLg = EdgeInsets.all(lg);
  static final EdgeInsets allXl = EdgeInsets.all(xl);

  // EdgeInsets — horizontal
  static final EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static final EdgeInsets horizontalS12 = EdgeInsets.symmetric(horizontal: s12);
  static final EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static final EdgeInsets horizontalS20 = EdgeInsets.symmetric(horizontal: s20);
  static final EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  // EdgeInsets — vertical
  static final EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static final EdgeInsets verticalS12 = EdgeInsets.symmetric(vertical: s12);
  static final EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static final EdgeInsets verticalS20 = EdgeInsets.symmetric(vertical: s20);
  static final EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
}
