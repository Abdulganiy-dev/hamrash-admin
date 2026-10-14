import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/app_sheet_link_action.dart';
import 'package:hamrash_admin/views/classes/classes_view_model.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Add a section, or rename, switch off or remove [section]. Pops `true`
/// once saved.
class SectionSheet extends StatefulWidget {
  const SectionSheet({
    super.key,
    required this.model,
    this.section,
    this.onToggleActive,
    this.onRemove,
  });

  final ClassesViewModel model;

  /// Null to add a new section.
  final SchoolSection? section;

  /// Run after this sheet closes, e.g. to ask for confirmation.
  final VoidCallback? onToggleActive;
  final VoidCallback? onRemove;

  @override
  State<SectionSheet> createState() => _SectionSheetState();
}

class _SectionSheetState extends State<SectionSheet> {
  late final SchoolSection? _saved = widget.section;
  late final _name = TextEditingController(text: _saved?.name ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _sectionName => _name.text.trim();

  String? get _nameProblem => _sectionName.isEmpty
      ? null
      : widget.model.sectionNameProblem(_sectionName, except: _saved);

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = _saved;
    final message = saved == null
        ? await widget.model.addSection(_sectionName)
        : await widget.model.renameSection(saved, _sectionName);
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
    final classes = saved?.classes.length ?? 0;
    final canSave =
        !_saving &&
        _sectionName.isNotEmpty &&
        _nameProblem == null &&
        _sectionName != saved?.name;
    final removeBlocked = saved == null
        ? null
        : widget.model.removeSectionBlockedReason(saved);

    return AppSheet(
      title: saved?.name ?? 'Add a section',
      subtitle: saved == null
          ? 'A part of the school with its own classes, e.g. Primary'
          : classes == 1
          ? '1 class'
          : '$classes classes',
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: AppTextField(
        label: 'Name',
        hintText: 'e.g. Primary',
        controller: _name,
        errorText: _nameProblem,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() => _error = null),
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error case final message?) AppSheetError(message),
          AppPrimaryButton(
            height: 52,
            isLoading: _saving,
            loadingText: 'Saving…',
            isDisabled: !canSave,
            onPressed: _save,
            child: Text(saved == null ? 'Add section' : 'Save section'),
          ),
          if (saved != null) ...[
            const SizedBox(height: 12),
            AppSheetLinkAction(
              icon: saved.isActive ? LucideIcons.eyeOff : LucideIcons.eye,
              label: saved.isActive
                  ? 'Switch off this section'
                  : 'Switch on this section',
              onPressed: _saving || widget.onToggleActive == null
                  ? null
                  : () => _closeThen(widget.onToggleActive!),
            ),
            const SizedBox(height: 12),
            AppSheetLinkAction(
              icon: LucideIcons.trash2,
              label: 'Remove section',
              isDestructive: true,
              helper: removeBlocked,
              onPressed:
                  _saving || removeBlocked != null || widget.onRemove == null
                  ? null
                  : () => _closeThen(widget.onRemove!),
            ),
          ],
        ],
      ),
    );
  }
}
