import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_fill.dart';

void main() {
  const colored = AppButtonFill(
    color: Color(0xFFE05A2B),
    border: Color(0xFFB8401A),
  );
  const clear = AppButtonFill(
    color: Colors.transparent,
    border: Colors.transparent,
  );

  test('colored to transparent fades alpha without darkening', () {
    final mid = AppButtonFill.lerp(colored, clear, 0.5);
    expect(mid.color.a, closeTo(colored.color.a / 2, 0.01));
    expect(mid.color.r, closeTo(colored.color.r, 0.001));
    expect(mid.color.g, closeTo(colored.color.g, 0.001));
  });

  test('transparent to colored fades in from the target hue', () {
    final mid = AppButtonFill.lerp(clear, colored, 0.5);
    expect(mid.color.r, closeTo(colored.color.r, 0.001));
  });

  test('gradient and flat fills blend instead of snapping', () {
    final mid = AppButtonFill.lerp(colored.withGradient(), clear, 0.5);
    expect(mid.gradient, isNotNull);
    expect(AppButtonFill.lerp(colored, clear, 1).gradient, isNull);
  });
}
