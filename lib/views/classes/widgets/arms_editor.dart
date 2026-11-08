import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_field_style.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/bouncy_button.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';

/// Picks a class's arms: the chosen ones as dark chips (tap to remove),
/// common names to add with one tap, and a field for anything else.
class ArmsEditor extends StatefulWidget {
  const ArmsEditor({
    super.key,
    required this.label,
    required this.arms,
    required this.onChanged,
    this.preview,
    this.note,
    this.locked = const {},
  });

  /// "Arms", or "Each class gets" when adding to many classes.
  final String label;

  final List<String> arms;
  final ValueChanged<List<String>> onChanged;

  /// Muted text across from the label, e.g. "Primary 1A, Primary 1B".
  final String? preview;

  /// Warning under the arms, e.g. what removing one takes with it.
  final String? note;

  /// Arms that can't be removed, by name, with the reason. Their chips show
  /// a lock, and tapping one shows the reason.
  final Map<String, String> locked;

  @override
  State<ArmsEditor> createState() => _ArmsEditorState();
}

class _ArmsEditorState extends State<ArmsEditor> {
  final _custom = TextEditingController();
  String? _customError;

  /// Why the last locked chip tapped can't go.
  String? _lockedReason;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];
  static const _words = ['Gold', 'Blue', 'Red'];

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  bool _has(String arm) =>
      widget.arms.any((each) => each.toLowerCase() == arm.toLowerCase());

  /// The next two free letters, then the colours not used yet.
  List<String> get _suggestions => [
    ..._letters.where((letter) => !_has(letter)).take(2),
    ..._words.where((word) => !_has(word)),
  ];

  void _add(String arm) {
    if (!_has(arm)) widget.onChanged([...widget.arms, arm]);
  }

  void _addCustom() {
    final name = _custom.text.trim();
    if (name.isEmpty) return;
    if (_has(name)) {
      setState(() => _customError = '$name is already an arm.');
      return;
    }
    widget.onChanged([...widget.arms, name]);
    _custom.clear();
  }

  void _remove(String arm) =>
      widget.onChanged([...widget.arms.where((each) => each != arm)]);

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AppText(
              widget.label,
              style: AppTypography.subtitle.copyWith(
                color: LightColors.textStrong,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                widget.preview ?? '',
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: LightColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.arms.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final arm in widget.arms)
                if (widget.locked[arm] case final why?)
                  Semantics(
                    button: true,
                    label: 'Arm $arm, in use',
                    excludeSemantics: true,
                    child: AppFilterChip(
                      label: arm,
                      selected: true,
                      locked: true,
                      onTap: () => setState(() => _lockedReason = why),
                    ),
                  )
                else
                  Semantics(
                    button: true,
                    label: 'Remove arm $arm',
                    excludeSemantics: true,
                    child: AppFilterChip(
                      label: arm,
                      selected: true,
                      onTap: () => _remove(arm),
                      onRemove: () => _remove(arm),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (_lockedReason case final why?) ...[
          AppText(
            '$why Switch the class off instead, or move what uses it first.',
            style: AppTypography.caption.copyWith(color: LightColors.textMuted),
          ),
          const SizedBox(height: 10),
        ],
        if (suggestions.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final arm in suggestions)
                Semantics(
                  button: true,
                  label: 'Add arm $arm',
                  excludeSemantics: true,
                  child: AppFilterChip(
                    label: arm,
                    suggestion: true,
                    onTap: () => _add(arm),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        _CustomArmField(
          controller: _custom,
          error: _customError,
          onChanged: () {
            if (_customError != null) setState(() => _customError = null);
          },
          onAdd: _addCustom,
        ),
        if (widget.note case final note?) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: AppIcon(
                  AppIcons.triangleAlert,
                  size: 14,
                  color: LightColors.warningWarningText,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppText(
                  note,
                  style: AppTypography.caption.copyWith(
                    color: LightColors.warningWarningText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "Add your own, e.g. Science" with a + button inside.
class _CustomArmField extends StatelessWidget {
  const _CustomArmField({
    required this.controller,
    required this.error,
    required this.onChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String? error;
  final VoidCallback onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        onSubmitted: (_) => onAdd(),
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.words,
        inputFormatters: [LengthLimitingTextInputFormatter(20)],
        style: AppTypography.body.copyWith(
          fontSize: 15,
          color: LightColors.textStrong,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Add your own, e.g. Science',
          hintStyle: AppTypography.body.copyWith(
            fontSize: 15,
            color: AppFieldStyle.placeholder(context),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          filled: true,
          fillColor: AppPalette.stone50,
          border: AppFieldStyle.border(AppFieldStyle.restBorder(context)),
          enabledBorder: AppFieldStyle.border(
            error == null
                ? AppFieldStyle.restBorder(context)
                : AppFieldStyle.errorBorder(context),
          ),
          focusedBorder: AppFieldStyle.border(
            error == null
                ? AppFieldStyle.focusBorder(context)
                : AppFieldStyle.errorBorder(context),
            width: 1.5,
          ),
          suffixIconConstraints: const BoxConstraints(),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Semantics(
              button: true,
              label: 'Add arm',
              excludeSemantics: true,
              child: BouncyButton(
                onPressed: onAdd,
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppPalette.stone100,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const AppIcon(
                    AppIcons.plus,
                    size: 16,
                    color: LightColors.primaryPrimaryDefault,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      if (error case final message?) ...[
        const SizedBox(height: 6),
        AppText(
          message,
          style: AppTypography.caption.copyWith(
            color: LightColors.errorErrorText,
          ),
        ),
      ],
    ],
  );
}
