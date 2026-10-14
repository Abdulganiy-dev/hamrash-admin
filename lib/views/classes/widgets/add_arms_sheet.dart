import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_rows.dart';
import 'package:hamrash_admin/views/classes/classes_view_model.dart';
import 'package:hamrash_admin/views/classes/widgets/arms_editor.dart';
import 'package:hamrash_admin/views/classes/widgets/sheet_error.dart';

/// 6.4 · The same arms for every class that has none yet, picked by
/// section. Pops the number of arms added.
class AddArmsSheet extends StatefulWidget {
  const AddArmsSheet({super.key, required this.model});

  final ClassesViewModel model;

  @override
  State<AddArmsSheet> createState() => _AddArmsSheetState();
}

class _AddArmsSheetState extends State<AddArmsSheet> {
  late final List<(SchoolSection, List<SchoolClass>)> _sections =
      widget.model.sectionsNeedingArms;
  late final Set<String> _picked = {
    for (final (section, _) in _sections) section.id,
  };
  List<String> _arms = ['A', 'B'];
  bool _saving = false;
  String? _error;

  List<SchoolClass> get _classes => [
    for (final (section, classes) in _sections)
      if (_picked.contains(section.id)) ...classes,
  ];

  int get _total => _arms.length * _classes.length;

  Future<void> _save() async {
    final total = _total;
    setState(() {
      _saving = true;
      _error = null;
    });
    final message = await widget.model.addArms(_arms, _picked);
    if (!mounted) return;
    if (message == null) {
      Navigator.of(context).pop(total);
      return;
    }
    setState(() {
      _saving = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final classes = _classes;
    final example = classes.isEmpty ? null : classes.first.name;

    return AppSheet(
      title: 'Add arms',
      subtitle: 'To every class that has none yet',
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArmsEditor(
            label: 'Each class gets',
            arms: _arms,
            preview: example == null || _arms.isEmpty
                ? null
                : 'e.g. ${_arms.take(2).map((arm) => fullArmName(example, arm)).join(', ')}',
            onChanged: (arms) => setState(() {
              _arms = arms;
              _error = null;
            }),
          ),
          const SizedBox(height: 20),
          AppText(
            'For these classes',
            style: AppTypography.subtitle.copyWith(
              color: LightColors.textStrong,
            ),
          ),
          const SizedBox(height: 10),
          AppRowGroup.inset(
            children: [
              for (final (section, classes) in _sections)
                AppCheckboxRow(
                  title: section.name,
                  subtitle: classes.length == 1
                      ? '1 class'
                      : '${classes.length} classes',
                  value: _picked.contains(section.id),
                  onChanged: (value) => setState(() {
                    value
                        ? _picked.add(section.id)
                        : _picked.remove(section.id);
                    _error = null;
                  }),
                ),
            ],
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error case final message?) SheetError(message),
          AppPrimaryButton(
            height: 52,
            isLoading: _saving,
            loadingText: 'Adding…',
            isDisabled: total == 0,
            onPressed: _save,
            child: Text(
              total == 0
                  ? 'Add arms'
                  : total == 1
                  ? 'Add 1 arm'
                  : 'Add $total arms',
            ),
          ),
        ],
      ),
    );
  }
}
