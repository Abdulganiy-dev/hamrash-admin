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
    this.textShadows = const [],
  });

  final List<Color> colors;
  final List<double>? stops;
  final Color border;
  final List<BoxShadow> shadows;

  /// Light along the top inside edge.
  final Color highlight;

  /// Shade along the bottom inside edge.
  final Color rim;

  final List<Shadow> textShadows;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: colors,
    stops: stops,
  );

  LinearGradient get sheen => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [highlight, highlight.withAlpha(0), rim.withAlpha(0), rim],
    stops: const [0, 0.14, 0.62, 1],
  );

  // Shared pieces
  static const _aubergineText = [
    Shadow(color: Color(0x400D050C), offset: Offset(0, 1), blurRadius: 1),
  ];
  static const _rustText = [
    Shadow(color: Color(0x405A160A), offset: Offset(0, 1), blurRadius: 1),
  ];

  /// Default fill for a button type. Returns flat transparent for types that
  /// aren't filled (outline, text, icon).
  static AppButtonFill forType(AppButtonType type, {required bool isLight}) {
    switch (type) {
      case AppButtonType.primary:
        return _primary;
      case AppButtonType.destructive:
        return _destructive;
      case AppButtonType.secondary:
        return isLight ? _secondary : _secondaryDark;
      case AppButtonType.tertiary:
        return isLight ? _tinted : _tintedDark;
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
  static AppButtonFill flat(Color color) {
    return AppButtonFill(
      colors: [color, color],
      border: Colors.transparent,
      highlight: const Color(0x2EFFFFFF),
      rim: const Color(0x1F000000),
    );
  }

  /// A caller-supplied gradient, still lit from above.
  static AppButtonFill fromGradient(LinearGradient gradient) {
    return AppButtonFill(
      colors: gradient.colors,
      stops: gradient.stops,
      border: Colors.transparent,
      highlight: const Color(0x47FFFFFF),
      rim: const Color(0x38000000),
    );
  }

  // Primary — aubergine
  static const _primary = AppButtonFill(
    colors: [Color(0xFF4D2A4B), Color(0xFF3B1F3A), Color(0xFF2E172D)],
    stops: [0, 0.45, 1],
    border: Color(0xFF3B1F3A),
    highlight: Color(0x4DFFFFFF),
    rim: Color(0x660D050C),
    textShadows: _aubergineText,
  );

  // Destructive — rust
  static const _destructive = AppButtonFill(
    colors: [Color(0xFFC44A2C), Color(0xFFB23A1E), Color(0xFF962F17)],
    stops: [0, 0.45, 1],
    border: Color(0xFF962F17),
    highlight: Color(0x66FFFFFF),
    rim: Color(0x4D5A160A),
    textShadows: _rustText,
  );

  // Secondary — cream to stone
  static const _secondary = AppButtonFill(
    colors: [Color(0xFFFFFDF8), Color(0xFFF3EEE4)],
    border: Color(0xFFD3C9B8),
    rim: Color(0x0F2A1712),
  );
  static const _secondaryDark = AppButtonFill(
    colors: [Color(0xFF26334A), Color(0xFF1E293B)],
    border: Color(0xFF334155),
    highlight: Color(0x14FFFFFF),
    rim: Color(0x33000000),
  );

  // Tinted — pale aubergine
  static const _tinted = AppButtonFill(
    colors: [Color(0xFFFAF4F8), Color(0xFFEBDCE7)],
    border: Color(0xFFD5B9CF),
    highlight: Color(0xE6FFFFFF),
    rim: Color(0x1A3B1F3A),
  );
  static const _tintedDark = AppButtonFill(
    colors: [Color(0xFF14305A), Color(0xFF10264A)],
    border: Color(0xFF053A85),
    highlight: Color(0x1AFFFFFF),
    rim: Color(0x33000000),
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
