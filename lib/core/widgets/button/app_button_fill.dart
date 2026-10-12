import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';

/// Paint recipe for a filled button: a vertical gradient lit from above,
/// a bright top edge and a deeper rim. No outer shadow.
///
/// Flutter has no inset box-shadow, so the top highlight and bottom rim are
/// drawn as a translucent overlay ([sheen]) on top of the gradient.
@immutable
class AppButtonFill {
  const AppButtonFill({
    required this.colors,
    this.stops,
    required this.border,
    this.shadows = const [],
    this.highlight = const Color(0x00FFFFFF),
    this.rim = const Color(0x00000000),
    this.pressed = false,
    this.textShadows = const [],
  });

  final List<Color> colors;
  final List<double>? stops;
  final Color border;
  final List<BoxShadow> shadows;

  /// Light along the top inside edge.
  final Color highlight;

  /// Shade along the bottom inside edge (or the top, when [pressed]).
  final Color rim;

  /// Pressed fills are shaded from the top, so the button looks pushed in.
  final bool pressed;

  final List<Shadow> textShadows;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: colors,
    stops: stops,
  );

  LinearGradient get sheen => pressed
      ? LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rim, rim.withAlpha(0)],
          stops: const [0, 0.35],
        )
      : LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [highlight, highlight.withAlpha(0), rim.withAlpha(0), rim],
          stops: const [0, 0.14, 0.62, 1],
        );

  // Shared pieces
  static const _navyText = [
    Shadow(color: Color(0x400A2F66), offset: Offset(0, 1), blurRadius: 1),
  ];
  static const _redText = [
    Shadow(color: Color(0x406E1010), offset: Offset(0, 1), blurRadius: 1),
  ];

  /// Default fill for a button type. Returns flat transparent for types that
  /// aren't filled (outline, text, icon).
  static AppButtonFill forType(
    AppButtonType type, {
    required bool isLight,
    required bool pressed,
  }) {
    switch (type) {
      case AppButtonType.primary:
        return pressed ? _primaryPressed : _primary;
      case AppButtonType.destructive:
        return pressed ? _destructivePressed : _destructive;
      case AppButtonType.secondary:
        if (isLight) return pressed ? _secondaryPressed : _secondary;
        return pressed ? _secondaryDarkPressed : _secondaryDark;
      case AppButtonType.tertiary:
        if (isLight) return pressed ? _tintedPressed : _tinted;
        return pressed ? _tintedDarkPressed : _tintedDark;
      case AppButtonType.outline:
      case AppButtonType.text:
      case AppButtonType.icon:
        return const AppButtonFill(
          colors: [Colors.transparent, Colors.transparent],
          border: Colors.transparent,
        );
    }
  }

  /// Flat, shadowless fill for disabled and loading buttons.
  static AppButtonFill disabled({required bool isLight}) {
    final color = isLight
        ? LightColors.backgroundSurfaceMild
        : DarkColors.backgroundSurfaceMild;
    return AppButtonFill(colors: [color, color], border: color);
  }

  /// A caller-supplied solid color, still lit from above.
  static AppButtonFill flat(Color color, {required bool pressed}) {
    return AppButtonFill(
      colors: [color, color],
      border: Colors.transparent,
      highlight: const Color(0x2EFFFFFF),
      rim: const Color(0x1F000000),
      pressed: pressed,
    );
  }

  /// A caller-supplied gradient, still lit from above.
  static AppButtonFill fromGradient(
    LinearGradient gradient, {
    required bool pressed,
  }) {
    return AppButtonFill(
      colors: gradient.colors,
      stops: gradient.stops,
      border: Colors.transparent,
      highlight: const Color(0x47FFFFFF),
      rim: const Color(0x38000000),
      pressed: pressed,
    );
  }

  // Primary — brand blue
  static const _primary = AppButtonFill(
    colors: [Color(0xFF4590F7), Color(0xFF0F6EF1), Color(0xFF0156C8)],
    stops: [0, 0.45, 1],
    border: Color(0xFF014CB3),
    highlight: Color(0x73FFFFFF),
    rim: Color(0x5204245C),
    textShadows: _navyText,
  );
  static const _primaryPressed = AppButtonFill(
    colors: [Color(0xFF0F6EF1), Color(0xFF0157CC), Color(0xFF01459E)],
    stops: [0, 0.5, 1],
    border: Color(0xFF013F91),
    rim: Color(0x6604245C),
    pressed: true,
    textShadows: _navyText,
  );

  // Destructive — red
  static const _destructive = AppButtonFill(
    colors: [Color(0xFFF26363), Color(0xFFE02D2D), Color(0xFFBE1E1E)],
    stops: [0, 0.45, 1],
    border: Color(0xFFA81B1B),
    highlight: Color(0x66FFFFFF),
    rim: Color(0x4D6E1010),
    textShadows: _redText,
  );
  static const _destructivePressed = AppButtonFill(
    colors: [Color(0xFFE02D2D), Color(0xFFC42020), Color(0xFFA11A1A)],
    stops: [0, 0.5, 1],
    border: Color(0xFF931717),
    rim: Color(0x666E1010),
    pressed: true,
    textShadows: _redText,
  );

  // Secondary — white to slate
  static const _secondary = AppButtonFill(
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
    border: Color(0xFFCBD5E1),
    rim: Color(0x0F0F172A),
  );
  static const _secondaryPressed = AppButtonFill(
    colors: [Color(0xFFEEF2F6), Color(0xFFE2E8F0)],
    border: Color(0xFFCBD5E1),
    rim: Color(0x1A0F172A),
    pressed: true,
  );
  static const _secondaryDark = AppButtonFill(
    colors: [Color(0xFF26334A), Color(0xFF1E293B)],
    border: Color(0xFF334155),
    highlight: Color(0x14FFFFFF),
    rim: Color(0x33000000),
  );
  static const _secondaryDarkPressed = AppButtonFill(
    colors: [Color(0xFF1E293B), Color(0xFF172234)],
    border: Color(0xFF334155),
    rim: Color(0x40000000),
    pressed: true,
  );

  // Tinted — pale brand blue
  static const _tinted = AppButtonFill(
    colors: [Color(0xFFF5F9FF), Color(0xFFD9E8FE)],
    border: Color(0xFFB3D1FD),
    highlight: Color(0xE6FFFFFF),
    rim: Color(0x140147A6),
  );
  static const _tintedPressed = AppButtonFill(
    colors: [Color(0xFFD9E8FE), Color(0xFFB3D1FD)],
    border: Color(0xFF7AB0F9),
    rim: Color(0x260147A6),
    pressed: true,
  );
  static const _tintedDark = AppButtonFill(
    colors: [Color(0xFF14305A), Color(0xFF10264A)],
    border: Color(0xFF053A85),
    highlight: Color(0x1AFFFFFF),
    rim: Color(0x33000000),
  );
  static const _tintedDarkPressed = AppButtonFill(
    colors: [Color(0xFF10264A), Color(0xFF0B1D3A)],
    border: Color(0xFF053A85),
    rim: Color(0x40000000),
    pressed: true,
  );
}

/// Paints an [AppButtonFill] behind [child]. Fills the available width unless
/// [width] is given (or the parent is unbounded, in which case it hugs).
class AppButtonSurface extends StatelessWidget {
  const AppButtonSurface({
    super.key,
    required this.fill,
    required this.borderRadius,
    required this.height,
    required this.padding,
    required this.child,
    this.width,
  });

  final AppButtonFill fill;
  final BorderRadius borderRadius;
  final double height;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final innerRadius = borderRadius - BorderRadius.circular(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth =
            width ?? (constraints.hasBoundedWidth ? double.infinity : null);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: resolvedWidth,
          height: height,
          decoration: BoxDecoration(
            gradient: fill.gradient,
            borderRadius: borderRadius,
            border: Border.all(color: fill.border),
            boxShadow: fill.shadows,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: innerRadius,
                      gradient: fill.sheen,
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        );
      },
    );
  }
}
