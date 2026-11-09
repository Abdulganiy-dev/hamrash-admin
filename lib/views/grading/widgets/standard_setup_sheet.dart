import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';

/// 9.7 · What the standard setup puts in, and a button to use it. Pops `true`
/// once it's set up.
class StandardSetupSheet extends StatefulWidget {
  const StandardSetupSheet({super.key, required this.onConfirm});

  /// Sets it up; returns the reason it didn't work, or null.
  final Future<String?> Function() onConfirm;

  @override
  State<StandardSetupSheet> createState() => _StandardSetupSheetState();
}

class _StandardSetupSheetState extends State<StandardSetupSheet> {
  /// What `create_standard_grading` adds for the school's own set.
  static const _grades = [
    ('A', '70 to 100', 'Excellent'),
    ('B', '60 to 69', 'Very Good'),
    ('C', '50 to 59', 'Good'),
    ('D', '45 to 49', 'Fair'),
    ('E', '40 to 44', 'Pass'),
    ('F', '0 to 39', 'Fail'),
  ];

  bool _saving = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onConfirm();
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final note = AppTypography.body.copyWith(
      fontSize: 13,
      height: 18 / 13,
      color: LightColors.textBody,
    );
    final strong = note.copyWith(
      fontWeight: FontWeight.w700,
      color: LightColors.textStrong,
    );

    return PopScope(
      // No closing half way through setting up.
      canPop: !_saving,
      child: AppSheet(
        title: 'Use the standard setup?',
        subtitle:
            'A starting point for your school. You can change any column or '
            'grade afterwards.',
        showCloseButton: !_saving,
        bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppPalette.stone50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPalette.stone200),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _grades.length; i++) ...[
                    _GradeLine(
                      grade: _grades[i].$1,
                      range: _grades[i].$2,
                      remark: _grades[i].$3,
                    ),
                    if (i < _grades.length - 1) const AppDivider(onPage: true),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                style: note,
                children: [
                  TextSpan(text: 'Score columns: ', style: strong),
                  const TextSpan(
                    text:
                        'CA 1 (20), CA 2 (20) and Exam (60), 100 marks in all.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppText(
              'Secondary keeps its own WAEC grades, A1 to F9, if the school '
              'has a Secondary section.',
              style: note,
            ),
          ],
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error case final message?) AppSheetError(message),
            AppPrimaryButton(
              useGradient: true,
              height: 52,
              isLoading: _saving,
              loadingText: 'Setting up…',
              onPressed: _confirm,
              child: const Text('Use the standard setup'),
            ),
            const SizedBox(height: AppSpacing.md),
            BouncyButton(
              isDisabled: _saving,
              onPressed: () => Navigator.of(context).pop(false),
              child: SizedBox(
                height: 44,
                child: Center(
                  child: AppText(
                    'Not now',
                    style: AppTypography.button.copyWith(
                      color: _saving
                          ? AppPalette.stone400
                          : AppPalette.stone600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeLine extends StatelessWidget {
  const _GradeLine({
    required this.grade,
    required this.range,
    required this.remark,
  });

  final String grade;
  final String range;
  final String remark;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: AppText(
              grade,
              style: AppTypography.subtitle.copyWith(
                color: LightColors.textStrong,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppText(
              range,
              style: AppTypography.body.copyWith(color: LightColors.textStrong),
            ),
          ),
          AppText(
            remark,
            style: AppTypography.body.copyWith(
              fontSize: 13,
              height: 16 / 13,
              color: LightColors.textMuted,
            ),
          ),
        ],
      ),
    ),
  );
}
