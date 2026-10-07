import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class StepIndicator extends StatefulWidget {
  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor,
    this.backgroundColor,
    this.height = 6,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOutCubic,
  }) : assert(currentStep >= 0 && currentStep <= totalSteps),
       assert(totalSteps > 0);

  final int currentStep;
  final int totalSteps;
  final Color? activeColor;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final Duration animationDuration;
  final Curve curve;

  @override
  State<StepIndicator> createState() => _StepIndicatorState();
}

class _StepIndicatorState extends State<StepIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0.0;
  double _targetValue = 0.0;

  double get _progress => (widget.currentStep ) / widget.totalSteps;

  @override
  void initState() {
    super.initState();
    _targetValue = _progress;
    _previousValue = _targetValue;

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: _previousValue,
      end: _targetValue,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _controller.forward();
  }

  @override
  void didUpdateWidget(StepIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep ||
        oldWidget.totalSteps != widget.totalSteps) {
      _previousValue = _animation.value;
      _targetValue = _progress;

      _animation = Tween<double>(
        begin: _previousValue,
        end: _targetValue,
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = LightColors.primaryPrimaryDefault;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LinearProgressIndicator(
          backgroundColor:
              widget.backgroundColor ?? primary.withOpacity(0.1),
          color: widget.activeColor ?? primary,
          value: _animation.value,
          minHeight: widget.height,
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(999),
        );
      },
    );
  }
}
