import 'package:hamrash_admin/core/haptic_helper.dart';
import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

/// Wraps any custom [child] in a tappable target with the same spring scale
/// animation used by [AppButton].
class BouncyButton extends StatefulWidget {
  const BouncyButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isDisabled = false,
    this.enableHaptic = true,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final bool enableHaptic;

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton> {
  /// Target scale; [SingleMotionBuilder] animates toward this when it changes.
  double _scaleTarget = 1.0;

  static const double _pressedScale = 0.95;
  static const Motion _scaleMotion = Motion.snappySpring();

  bool get _isEnabled => !widget.isDisabled && widget.onPressed != null;

  @override
  void didUpdateWidget(BouncyButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final blocked = widget.isDisabled || widget.onPressed == null;
    final wasBlocked = oldWidget.isDisabled || oldWidget.onPressed == null;
    if (blocked && !wasBlocked && _scaleTarget != 1.0) {
      setState(() => _scaleTarget = 1.0);
    }
  }

  void _handlePress() {
    if (!_isEnabled) return;
    if (widget.enableHaptic) {
      HapticHelpers.vibrate(VibrationType.light);
    }
    widget.onPressed?.call();
  }

  void _handlePressDown() {
    if (_isEnabled) {
      setState(() => _scaleTarget = _pressedScale);
    }
  }

  void _handlePressUp() {
    setState(() => _scaleTarget = 1.0);
  }

  void _handlePressCancel() {
    setState(() => _scaleTarget = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _isEnabled ? (_) => _handlePressDown() : null,
      onTapUp: _isEnabled ? (_) => _handlePressUp() : null,
      onTapCancel: _isEnabled ? _handlePressCancel : null,
      // onTap (not only onTapUp) so taps work inside scroll views.
      onTap: _isEnabled ? _handlePress : null,
      child: SingleMotionBuilder(
        motion: _scaleMotion,
        value: _scaleTarget,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
