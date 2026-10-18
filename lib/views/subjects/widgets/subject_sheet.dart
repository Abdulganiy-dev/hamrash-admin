import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/api/models/subjects/subject.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/widgets/app_text_field.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/button/app_sheet_link_action.dart';
import 'package:hamrash_admin/core/widgets/app_sheet_error.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// 7.7 · Add a subject, or change one's name and code. Pops the subject's
/// id once saved.
class SubjectSheet extends StatefulWidget {
  const SubjectSheet({
    super.key,
    required this.subtitle,
    required this.nameProblem,
    required this.codeProblem,
    required this.onSave,
    this.subject,
    this.removeBlockedReason,
    this.onToggleActive,
    this.onRemove,
  });

  /// Null to add a new subject.
  final Subject? subject;

  /// "Optional in SS 1 – SS 3", or what adding does.
  final String subtitle;

  final String? Function(String name) nameProblem;
  final String? Function(String code) codeProblem;

  /// Saves; returns the subject's id, or the reason it wasn't saved.
  final Future<({String? id, String? error})> Function(String name, String code)
  onSave;

  /// Shown under a greyed-out "Remove subject".
  final String? removeBlockedReason;

  /// Run after this sheet closes, e.g. to ask for confirmation. Without
  /// them the sheet only edits the name and code.
  final VoidCallback? onToggleActive;
  final VoidCallback? onRemove;

  @override
  State<SubjectSheet> createState() => _SubjectSheetState();
}

class _SubjectSheetState extends State<SubjectSheet> {
  late final Subject? _saved = widget.subject;
  late final _name = TextEditingController(text: _saved?.name ?? '');
  late final _code = TextEditingController(text: _saved?.code ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  String get _subjectName => _name.text.trim();
  String get _subjectCode => _code.text.trim().toUpperCase();

  String? get _nameProblem =>
      _subjectName.isEmpty ? null : widget.nameProblem(_subjectName);
  String? get _codeProblem => widget.codeProblem(_subjectCode);

  bool get _hasChanges {
    final saved = _saved;
    return saved == null ||
        _subjectName != saved.name ||
        _subjectCode != (saved.code ?? '');
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.onSave(_subjectName, _subjectCode);
    if (!mounted) return;
    if (result.id case final id?) {
      Navigator.of(context).pop(id);
      return;
    }
    setState(() {
      _saving = false;
      _error = result.error;
    });
  }

  void _closeThen(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    final canSave =
        !_saving &&
        _subjectName.isNotEmpty &&
        _nameProblem == null &&
        _codeProblem == null &&
        _hasChanges;
    final hasActions = widget.onToggleActive != null || widget.onRemove != null;

    return AppSheet(
      title: saved?.name ?? 'Add a subject',
      subtitle: widget.subtitle,
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Name',
            hintText: 'e.g. Further Mathematics',
            controller: _name,
            errorText: _nameProblem,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Short code',
            isOptional: true,
            hintText: 'e.g. FMT',
            controller: _code,
            errorText: _subjectCode.isEmpty ? null : _codeProblem,
            helperText:
                'Shows on timetables and report cards. 2 to 10 letters or '
                'numbers.',
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (_) => setState(() => _error = null),
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
            isDisabled: !canSave,
            onPressed: _save,
            child: Text(saved == null ? 'Add subject' : 'Save subject'),
          ),
          if (saved != null && hasActions) ...[
            const SizedBox(height: 12),
            if (widget.onToggleActive case final toggle?)
              AppSheetLinkAction(
                icon: saved.isActive ? AppSvgIcons.eyeOff : AppSvgIcons.eye,
                label: saved.isActive
                    ? 'Switch off this subject'
                    : 'Switch on this subject',
                onPressed: _saving ? null : () => _closeThen(toggle),
              ),
            if (widget.onRemove case final remove?) ...[
              const SizedBox(height: 12),
              AppSheetLinkAction(
                icon: AppSvgIcons.trash2,
                label: 'Remove subject',
                isDestructive: true,
                helper: widget.removeBlockedReason,
                onPressed: _saving || widget.removeBlockedReason != null
                    ? null
                    : () => _closeThen(remove),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
