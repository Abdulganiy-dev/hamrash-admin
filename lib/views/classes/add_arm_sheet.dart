import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/viewModel/classes_view_model.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/app_text_field.dart';
import 'package:hamrash_admin/widgets/button/app_button.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/glass_sheet.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

class AddArmSheet extends StatefulWidget {
  const AddArmSheet({super.key, required this.viewModel});

  final ClassesViewModel viewModel;

  static Future<bool?> openSheet(
    BuildContext context, {
    required ClassesViewModel viewModel,
  }) {
    return GlassSheet.show<bool>(
      context: context,
      title: 'New Section',
      snappingConfig: const SheetSnappingConfig([0.45, 0.65]),
      body: AddArmSheet(viewModel: viewModel),
    );
  }

  @override
  State<AddArmSheet> createState() => _AddArmSheetState();
}

class _AddArmSheetState extends State<AddArmSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;

  bool get _isDuplicate => widget.viewModel.arms.any(
        (a) =>
            a.name.trim().toLowerCase() ==
            _controller.text.trim().toLowerCase(),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _isDuplicate || _submitting) return;
    setState(() => _submitting = true);
    final success = await widget.viewModel.createArm(name);
    if (mounted) {
      setState(() => _submitting = false);
      if (success) NavigationService.popScreen(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final trimmed = value.text.trim();
        final isDuplicate = _isDuplicate;
        final canSubmit = trimmed.isNotEmpty && !isDuplicate && !_submitting;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _controller,
              label: 'Section Name',
              hintText: 'e.g. A, B, Gold',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => canSubmit ? _submit() : null,
            ),
            if (isDuplicate && trimmed.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              AppText(
                'Section "$trimmed" already exists.',
                color: LightColors.errorErrorDefault,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              type: AppButtonType.primary,
              text: 'Create Section',
              isDisabled: !canSubmit,
              onPressed: _submit,
              width: double.infinity,
            ),
          ],
        );
      },
    );
  }
}
