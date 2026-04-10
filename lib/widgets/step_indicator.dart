
import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/app_colors.dart';

enum CreateAccountStep { name, details, profileImage }

class CreateAccountStepIndicator extends StatefulWidget {
  const CreateAccountStepIndicator({super.key, required this.currentStep});

  final CreateAccountStep currentStep;

  @override
  State<CreateAccountStepIndicator> createState() =>
      _CreateAccountStepIndicatorState();
}

class _CreateAccountStepIndicatorState
    extends State<CreateAccountStepIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0.0;
  double _targetValue = 0.0;

  @override
  void initState() {
    super.initState();
    final steps = CreateAccountStep.values;
    _targetValue = (widget.currentStep.index + 1) / steps.length;
    _previousValue = _targetValue;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: _previousValue,
      end: _targetValue,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(CreateAccountStepIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      final steps = CreateAccountStep.values;
      _previousValue = _animation.value;
      _targetValue = (widget.currentStep.index + 1) / steps.length;

      _animation = Tween<double>(
        begin: _previousValue,
        end: _targetValue,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOutCubic,
        ),
      );

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return LinearProgressIndicator(
              backgroundColor: LightColors.primaryPrimaryDefault.withOpacity(0.1),
              color: LightColors.primaryPrimaryDefault,
              value: _animation.value,
              minHeight: 6,
              borderRadius: BorderRadius.circular(999),
            );
          },
        ),
        // const SizedBox(height: 12),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     // AppText(
        //     //   _titleForStep(currentStep),
        //     //   style: theme.textTheme.titleMedium?.copyWith(
        //     //     fontWeight: FontWeight.w600,
        //     //   ),
        //     // ),
        //     // AppText(
        //     //   '${currentStep.index + 1} / ${steps.length}',
        //     //   style: theme.textTheme.bodySmall,
        //     // ),
        //   ],
        // ),
      ],
    );
  }
}
