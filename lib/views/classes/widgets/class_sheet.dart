import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/app_sheet_link_action.dart';
import 'package:hamrash_admin/core/widgets/selection/app_selection_rows.dart';
import 'package:hamrash_admin/views/classes/classes_view_model.dart';
import 'package:hamrash_admin/views/classes/widgets/arms_editor.dart';
import 'package:hamrash_admin/views/classes/widgets/sheet_error.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 6.3 · Add a class to [section], or edit [schoolClass]: its name, arms
/// and whether it's the graduating class. Pops `true` once saved.
class ClassSheet extends StatefulWidget {
  const ClassSheet({
    super.key,
    required this.model,
    this.schoolClass,
    this.section,
    this.onToggleActive,
    this.onRemove,
  }) : assert(
         (schoolClass == null) != (section == null),
         'Pass schoolClass to edit, or section to add.',
       );

  final ClassesViewModel model;
  final SchoolClass? schoolClass;
  final SchoolSection? section;

  /// Run after this sheet closes, e.g. to ask for confirmation.
  final VoidCallback? onToggleActive;
  final VoidCallback? onRemove;

  @override
  State<ClassSheet> createState() => _ClassSheetState();
}

class _ClassSheetState extends State<ClassSheet> {
  late final SchoolClass? _saved = widget.schoolClass;
  late final _name = TextEditingController(text: _saved?.name ?? '');
  late List<String> _arms = [
    for (final arm in _saved?.arms ?? const <ClassArm>[]) arm.name,
  ];
  late bool _graduating = _saved?.isGraduating ?? false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _className => _name.text.trim();

  String? get _nameProblem => _className.isEmpty
      ? null
      : widget.model.classNameProblem(_className, except: _saved);

  bool get _hasChanges {
    final saved = _saved;
    if (saved == null) return true;
    return _className != saved.name ||
        _graduating != saved.isGraduating ||
        _arms.length != saved.arms.length ||
        [
          for (var i = 0; i < _arms.length; i++)
            if (_arms[i] != saved.arms[i].name) i,
        ].isNotEmpty;
  }

  /// Saved arms taken off in this sheet.
  List<String> get _removedArms {
    final kept = {for (final arm in _arms) arm.toLowerCase()};
    return [
      for (final arm in _saved?.arms ?? const <ClassArm>[])
        if (!kept.contains(arm.name.toLowerCase())) arm.name,
    ];
  }

  String? get _removalNote {
    final removed = _removedArms;
    if (removed.isEmpty) return null;
    final names = removed.join(', ');
    return removed.length == 1
        ? 'Saving removes arm $names, with its class teacher and subjects.'
        : 'Saving removes arms $names, with their class teachers and subjects.';
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = _saved;
    final message = saved == null
        ? await widget.model.addClass(
            widget.section!,
            name: _className,
            isGraduating: _graduating,
            arms: _arms,
          )
        : await widget.model.saveClass(
            saved,
            name: _className,
            isGraduating: _graduating,
            arms: _arms,
          );
    if (!mounted) return;
    if (message == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = message;
    });
  }

  void _closeThen(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    final name = _className.isEmpty ? (saved?.name ?? 'Class') : _className;
    final canSave =
        !_saving &&
        _className.isNotEmpty &&
        _nameProblem == null &&
        _hasChanges;

    return AppSheet(
      title: saved?.name ?? 'Add a class',
      subtitle: saved == null
          ? widget.model.placeOfNew(widget.section!)
          : widget.model.placeOf(saved),
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Name',
            hintText: 'e.g. Primary 1',
            controller: _name,
            errorText: _nameProblem,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 20),
          ArmsEditor(
            label: 'Arms',
            arms: _arms,
            preview: _arms.isEmpty
                ? 'None yet'
                : _arms.map((arm) => fullArmName(name, arm)).join(', '),
            note: _removalNote,
            onChanged: (arms) => setState(() {
              _arms = arms;
              _error = null;
            }),
          ),
          const SizedBox(height: 20),
          AppRowGroup.inset(
            children: [
              AppSwitchRow(
                title: 'Graduating class',
                subtitle: 'Students promoted out of this class graduate.',
                value: _graduating,
                onChanged: (value) => setState(() {
                  _graduating = value;
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
            loadingText: 'Saving…',
            isDisabled: !canSave,
            onPressed: _save,
            child: Text(saved == null ? 'Add class' : 'Save class'),
          ),
          if (saved != null) ...[
            const SizedBox(height: 12),
            AppSheetLinkAction(
              icon: saved.isActive ? LucideIcons.eyeOff : LucideIcons.eye,
              label: saved.isActive
                  ? 'Switch off this class'
                  : 'Switch on this class',
              onPressed: _saving || widget.onToggleActive == null
                  ? null
                  : () => _closeThen(widget.onToggleActive!),
            ),
            const SizedBox(height: 12),
            AppSheetLinkAction(
              icon: LucideIcons.trash2,
              label: 'Remove class',
              isDestructive: true,
              onPressed: _saving || widget.onRemove == null
                  ? null
                  : () => _closeThen(widget.onRemove!),
            ),
          ],
        ],
      ),
    );
  }
}
