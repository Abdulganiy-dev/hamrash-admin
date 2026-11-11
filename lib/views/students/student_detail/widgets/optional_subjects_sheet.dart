import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_rows.dart';

/// 9.16 · The student's optional subjects: the ones everyone takes, then a
/// tick for each optional one they take. Choosing none is fine. `onSave`
/// returns the reason it failed, or null when saved; the sheet then pops
/// `true`.
class OptionalSubjectsSheet extends StatefulWidget {
  const OptionalSubjectsSheet({
    super.key,
    required this.firstName,
    required this.placement,
    required this.onSave,
  });

  final String firstName;
  final StudentPlacement placement;
  final Future<String?> Function(Set<String> subjectIds) onSave;

  static Future<bool?> show(
    BuildContext context, {
    required String firstName,
    required StudentPlacement placement,
    required Future<String?> Function(Set<String> subjectIds) onSave,
  }) => Navigator.of(context).push<bool>(
    AppSheetRoute<bool>(
      size: AppSheetSize.floating,
      child: OptionalSubjectsSheet(
        firstName: firstName,
        placement: placement,
        onSave: onSave,
      ),
    ),
  );

  @override
  State<OptionalSubjectsSheet> createState() => _OptionalSubjectsSheetState();
}

class _OptionalSubjectsSheetState extends State<OptionalSubjectsSheet> {
  late final Set<String> _chosen = {...widget.placement.chosenOptionalIds};
  bool _saving = false;
  String? _error;

  bool get _changed => !(_chosen.length ==
          widget.placement.chosenOptionalIds.length &&
      _chosen.containsAll(widget.placement.chosenOptionalIds));

  Future<void> _save() async {
    if (!_changed || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(_chosen);
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
    final placement = widget.placement;
    final core = placement.core.toList();
    final optional = placement.optional.toList();
    final first = widget.firstName;
    return AppSheet(
      title: '$first’s subjects',
      subtitle:
          '${placement.armLabel} has ${optional.length} optional '
          '${optional.length == 1 ? 'subject' : 'subjects'}. Tick the ones '
          '$first takes.',
      bodyPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFlatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Heading(
                  title: 'Included for everyone',
                  trailing: '${core.length} subjects',
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  core.map((offer) => offer.name).join(', '),
                  style: AppTypography.caption.copyWith(
                    height: 18 / 12,
                    color: LightColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Heading(
            title: 'Optional subjects',
            trailing: '${_chosen.length} of ${optional.length} chosen',
          ),
          for (final offer in optional)
            AppCheckboxRow(
              key: ValueKey('optional-${offer.subjectId}'),
              title: offer.name,
              subtitle: offer.code,
              value: _chosen.contains(offer.subjectId),
              onChanged: (_) => setState(() {
                _error = null;
                if (!_chosen.add(offer.subjectId)) _chosen.remove(offer.subjectId);
              }),
            ),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            'Choosing none is fine.',
            style: AppTypography.caption.copyWith(color: LightColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            '${core.length + _chosen.length} subjects in total · '
            '${core.length} compulsory + ${_chosen.length} optional',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: LightColors.textBody,
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
            loadingText: 'Saving…',
            isDisabled: !_changed,
            onPressed: _changed ? _save : null,
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AppText(
          title,
          style: AppTypography.subtitle.copyWith(color: LightColors.textStrong),
        ),
      ),
      AppText(
        trailing,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: LightColors.textMuted,
        ),
      ),
    ],
  );
}
