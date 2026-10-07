import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  // Scale anchors
  static const double none = 0.0;
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double pill = 100.0;

  // Off-scale values — named by pixel value
  static const double r1 = 1.0;
  static const double r3 = 3.0;
  static const double r5 = 5.0;
  static const double r6 = 6.0;
  static const double r7 = 7.0;
  static const double r9 = 9.0;
  static const double r10 = 10.0;
  static const double r11 = 11.0;
  static const double r14 = 14.0;
  static const double r15 = 15.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double r30 = 30.0;
  static const double r32 = 32.0;
  static const double r40 = 40.0;
  static const double r50 = 50.0;
  static const double r200 = 200.0;

  // Pre-built BorderRadius — scale anchors
  static final BorderRadius brNone = BorderRadius.circular(none);
  static final BorderRadius brXs = BorderRadius.circular(xs);
  static final BorderRadius brSm = BorderRadius.circular(sm);
  static final BorderRadius brMd = BorderRadius.circular(md);
  static final BorderRadius brLg = BorderRadius.circular(lg);
  static final BorderRadius brXl = BorderRadius.circular(xl);
  static final BorderRadius brPill = BorderRadius.circular(pill);

  // Pre-built BorderRadius — off-scale
  static final BorderRadius brR6 = BorderRadius.circular(r6);
  static final BorderRadius brR10 = BorderRadius.circular(r10);
  static final BorderRadius brR11 = BorderRadius.circular(r11);
  static final BorderRadius brR20 = BorderRadius.circular(r20);
  static final BorderRadius brR24 = BorderRadius.circular(r24);
  static final BorderRadius brR30 = BorderRadius.circular(r30);
  static final BorderRadius brR32 = BorderRadius.circular(r32);
  static final BorderRadius brR40 = BorderRadius.circular(r40);
}
