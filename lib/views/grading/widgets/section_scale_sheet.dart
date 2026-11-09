import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_controls.dart';
import 'package:hamrash_admin/views/grading/grading_view_model.dart';

/// 9.11 · Give a section its own scale: pick a section that uses the school
/// default and start it as a copy of that. Pops `true` once created.
class SectionScaleSheet extends StatefulWidget {
  const SectionScaleSheet({
    super.key,
    required this.sections,
    required this.ownScaleNames,
    required this.onCreate,
  });

  /// Sections without their own scale. The first is picked to begin with.
  final List<SchoolSection> sections;

  /// Names of sections that already have their own scale, for the note.
  final List<String> ownScaleNames;

  /// Creates the scale; returns the reason it didn't work, or null.
  final Future<String?> Function(SchoolSection section) onCreate;

  @override
  State<SectionScaleSheet> createState() => _SectionScaleSheetState();
}

class _SectionScaleSheetState extends State<SectionScaleSheet> {
  late SchoolSection _picked = widget.sections.first;
  bool _saving = false;
  String? _error;

  Future<void> _create() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onCreate(_picked);
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

  String get _note {
    final names = widget.ownScaleNames;
    const rest =
        'Other sections keep using the school default until you give them one.';
    if (names.isEmpty) return rest;
    final already = names.length == 1
        ? '${names.first} already has its own.'
        : '${GradingViewModel.joinNames(names)} already have their own.';
    return '$already $rest';
  }

  @override
  Widget build(BuildContext context) => PopScope(
    // No closing half way through creating it.
    canPop: !_saving,
    child: AppSheet(
      title: 'Give a section its own scale',
      subtitle:
          'It starts as a copy of the school default. You can change any grade '
          'afterwards.',
      showCloseButton: !_saving,
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppPalette.stone50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.stone200),
            ),
            child: Column(
              children: [
                for (final (i, section) in widget.sections.indexed) ...[
                  _SectionRow(
                    name: section.name,
                    picked: section.id == _picked.id,
                    onTap: _saving
                        ? null
                        : () => setState(() => _picked = section),
                  ),
                  if (i < widget.sections.length - 1)
                    const AppDivider(onPage: true),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppText(
            _note,
            style: AppTypography.body.copyWith(
              fontSize: 13,
              height: 18 / 13,
              color: LightColors.textMuted,
            ),
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
            loadingText: 'Creating…',
            onPressed: _create,
            child: Text('Create ${_picked.name} scale'),
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
                    color: _saving ? AppPalette.stone400 : AppPalette.stone600,
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

/// A section's name with a radio on the left; the whole row picks it.
class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.name,
    required this.picked,
    required this.onTap,
  });

  final String name;
  final bool picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => BouncyButton(
    pressedScale: 0.98,
    onPressed: onTap,
    child: SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            AppRadio<bool>(value: true, groupValue: picked),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title.copyWith(
                  color: LightColors.textStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
