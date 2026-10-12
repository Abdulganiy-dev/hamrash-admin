import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_field_style.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Search input in the shared field style: search icon on the left, a clear
/// button on the right once there's text. 48 tall, 12px corners.

class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search…',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onTextChange);
      _controller = widget.controller ?? _controller;
      _controller.addListener(_onTextChange);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode = widget.focusNode ?? _focusNode;
      _focusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  /// Rebuild so the clear button appears and disappears with the text.
  void _onTextChange() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChange);
    if (widget.focusNode == null) _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = AppFieldStyle.icon(context);
    final restBorder = AppFieldStyle.border(AppFieldStyle.restBorder(context));

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      textAlignVertical: TextAlignVertical.center,
      style: AppTypography.bodyLarge.copyWith(
        color: AppFieldStyle.text(context, enabled: true),
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hintText,
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: AppFieldStyle.placeholder(context),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 12),
          child: Icon(
            LucideIcons.search,
            size: AppFieldStyle.iconSize,
            color: iconColor,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: _controller.text.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 12, right: 10),
                child: AppHugeIconButton(
                  lucidIcon: LucideIcons.x,
                  lucidIconSize: 18,
                  foregroundColor: iconColor,
                  onPressed: _clear,
                ),
              ),
        suffixIconConstraints: const BoxConstraints(),
        contentPadding: AppFieldStyle.contentPadding,
        filled: true,
        hoverColor: Colors.transparent,
        fillColor: AppFieldStyle.fill(
          context,
          enabled: true,
          active: _isFocused,
        ),
        border: restBorder,
        enabledBorder: restBorder,
        focusedBorder: AppFieldStyle.border(
          AppFieldStyle.focusBorder(context),
          width: 1.5,
        ),
        counterText: '',
      ),
    );
  }
}
