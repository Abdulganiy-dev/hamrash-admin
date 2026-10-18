import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_field_style.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// Text field with the label above, helper or error text below.
///
/// Quiet at rest (soft fill, hairline border), white with a aubergine border when
/// focused, white with a red border on error. 48 tall, 12px corners.
/// Validator and [errorText] messages clear on tap or when focus returns.
///
/// Usage example:
/// ```dart
/// AppTextField(
///   controller: nameController,
///   label: 'Full name',
///   hintText: "Student's full name",
///   validator: (value) {
///     if (value == null || value.isEmpty) return 'Enter a name';
///     return null;
///   },
/// )
///
/// AppTextField(label: "Parent's phone", prefixText: '+234')
/// AppTextField(label: 'Password', obscureText: true) // eye toggle built in
/// ```

class AppTextField extends StatefulWidget {
  /// The controller for the text field
  final TextEditingController? controller;

  /// The label shown above the field
  final String label;

  /// Adds a muted "(optional)" after the label
  final bool isOptional;

  /// Fixed text before the input, split off by a divider (e.g. "+234", "₦")
  final String? prefixText;

  /// Optional hint text shown when field is empty
  final String? hintText;

  /// Optional helper text shown below the field
  final String? helperText;

  /// Optional error text (overrides validator)
  final String? errorText;

  /// Optional validator function
  final String? Function(String?)? validator;

  /// Whether the field is read-only
  final bool readOnly;

  /// The keyboard type for the field
  final TextInputType? keyboardType;

  /// The focus node for the field
  final FocusNode? focusNode;

  /// Optional text input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Maximum number of lines (1 = single line, null = grows)
  final int? maxLines;

  /// Minimum number of lines
  final int? minLines;

  /// Maximum length of input
  final int? maxLength;

  /// Whether to obscure text (for passwords). Adds a show/hide eye unless a
  /// [suffixIcon] is given.
  final bool obscureText;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Callback when field is submitted
  final void Function(String)? onSubmitted;

  /// Callback when field value changes
  final void Function(String)? onChanged;

  /// Called when the field gains focus (e.g. to clear submit-time error UI).
  final VoidCallback? onFocus;

  /// Called when the field is tapped (useful for read-only pickers).
  final VoidCallback? onTap;

  /// Whether to show the character counter
  final bool showCounter;

  /// Custom text style
  final TextStyle? textStyle;

  /// Custom label style
  final TextStyle? labelStyle;

  /// Custom hint style
  final TextStyle? hintStyle;

  /// Custom error style
  final TextStyle? errorStyle;

  /// Custom helper style
  final TextStyle? helperStyle;

  /// Whether the field is enabled
  final bool enabled;

  /// Optional prefix icon
  final Widget? prefixIcon;

  /// Optional suffix icon
  final Widget? suffixIcon;

  /// Autofill hints
  final Iterable<String>? autofillHints;

  /// Text capitalization
  final TextCapitalization textCapitalization;

  /// Whether to enable suggestions
  final bool enableSuggestions;

  /// Whether to enable autocorrect
  final bool autocorrect;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.isOptional = false,
    this.prefixText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.validator,
    this.readOnly = false,
    this.keyboardType,
    this.focusNode,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.onFocus,
    this.onTap,
    this.showCounter = false,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.errorStyle,
    this.helperStyle,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.enableSuggestions = true,
    this.autocorrect = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isFocused = false;
  bool _hadFocus = false;
  bool _hideExternalError = false;
  late bool _obscured = widget.obscureText;

  /// Latest validator message. The field's own error line is hidden so this
  /// can be drawn with an icon below the field.
  String? _validatorError;

  String? get _displayedExternalError =>
      _hideExternalError ? null : widget.errorText;

  String? get _errorMessage => _displayedExternalError ?? _validatorError;

  bool get _isMultiline => widget.maxLines != 1;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller ?? _controller;
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }
    if (widget.errorText != oldWidget.errorText) {
      _hideExternalError = false;
    }
    if (widget.obscureText != oldWidget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  void _onFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus && !_hadFocus) {
      _clearDisplayedError();
      widget.onFocus?.call();
    }
    _hadFocus = hasFocus;
    if (mounted) {
      setState(() => _isFocused = hasFocus);
    }
  }

  /// Drops the visible error so the user can edit. The next [FormState.validate]
  /// (submit) still runs the validator and can show a new message.
  void _clearDisplayedError() {
    _hideExternalError = true;
    _validatorError = null;
    _clearValidatorError();
  }

  void _clearValidatorError() {
    final state = _fieldKey.currentState;
    if (state == null || !state.hasError) return;
    state.clearError();
  }

  String? _runValidator(String? value) {
    final message = widget.validator?.call(value);
    if (message != _validatorError) {
      // Validation runs during build; update our error line afterwards.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _validatorError = message);
      });
    }
    return message;
  }

  void _handleTap() {
    _clearDisplayedError();
    setState(() {});
    widget.onTap?.call();
  }

  void _handleChanged(String value) {
    if (widget.showCounter) setState(() {});
    widget.onChanged?.call(value);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Widget? _buildPrefix(BuildContext context) {
    if (widget.prefixText != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              widget.prefixText!,
              style: AppTypography.bodyLarge.copyWith(
                color: AppFieldStyle.icon(context),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 24,
              color: AppFieldStyle.restBorder(context),
            ),
          ],
        ),
      );
    }
    if (widget.prefixIcon == null) return null;
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 12),
      child: widget.prefixIcon,
    );
  }

  Widget? _buildSuffix(BuildContext context) {
    Widget? icon = widget.suffixIcon;
    if (icon == null && widget.obscureText) {
      icon = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _obscured = !_obscured),
        child: AppSvgIcon(_obscured ? AppSvgIcons.eye : AppSvgIcons.eyeOff),
      );
    }
    if (icon == null) return null;
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 14),
      child: icon,
    );
  }

  Widget _buildLabel(BuildContext context) {
    final style = AppTypography.subtitle
        .copyWith(
          color: widget.enabled
              ? AppFieldStyle.text(context, enabled: true)
              : AppFieldStyle.text(context, enabled: false),
        )
        .merge(widget.labelStyle);
    if (!widget.isOptional) return AppText(widget.label, style: style);
    return Text.rich(
      TextSpan(
        text: widget.label,
        style: style,
        children: [
          TextSpan(
            text: '  (optional)',
            style: AppTypography.body.copyWith(
              color: Theme.of(context).brightness == Brightness.light
                  ? LightColors.textMuted
                  : DarkColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFooter(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final error = _errorMessage;
    final mutedColor = isLight ? LightColors.textMuted : DarkColors.textMuted;
    final counter = widget.showCounter && widget.maxLength != null
        ? '${_controller.text.characters.length} / ${widget.maxLength}'
        : null;

    Widget? message;
    if (error != null) {
      final errorColor = isLight
          ? LightColors.errorErrorText
          : DarkColors.errorErrorText;
      message = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSvgIcon(AppSvgIcons.circleAlert500, size: 16, color: errorColor),
          const SizedBox(width: 6),
          Expanded(
            child: AppText(
              error,
              style: AppTypography.caption
                  .copyWith(color: errorColor)
                  .merge(widget.errorStyle),
            ),
          ),
        ],
      );
    } else if (widget.helperText != null) {
      message = AppText(
        widget.helperText!,
        maxLines: 5,
        style: AppTypography.caption
            .copyWith(color: mutedColor)
            .merge(widget.helperStyle),
      );
    }

    if (message == null && counter == null) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: message ?? const SizedBox.shrink()),
          if (counter != null) ...[
            const SizedBox(width: 12),
            AppText(
              counter,
              style: AppTypography.caption.copyWith(color: mutedColor),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorMessage != null;
    final active = _isFocused || hasError;
    final restBorder = AppFieldStyle.restBorder(context);
    final errorBorder = AppFieldStyle.errorBorder(context);
    final footer = _buildFooter(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        const SizedBox(height: 8),
        IconTheme.merge(
          data: IconThemeData(
            size: AppFieldStyle.iconSize,
            color: AppFieldStyle.icon(context),
          ),
          child: TextFormField(
            key: _fieldKey,
            controller: _controller,
            focusNode: _focusNode,
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines ?? (_isMultiline ? 4 : null),
            maxLength: widget.maxLength,
            obscureText: _obscured,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            onTap: _handleTap,
            onTapAlwaysCalled: true,
            autovalidateMode: AutovalidateMode.disabled,
            textAlignVertical: _isMultiline
                ? TextAlignVertical.top
                : TextAlignVertical.center,
            onChanged: _handleChanged,
            validator: widget.validator == null ? null : _runValidator,
            errorBuilder: (_, _) => const SizedBox.shrink(),
            enabled: widget.enabled,
            autofillHints: widget.autofillHints,
            textCapitalization: widget.textCapitalization,
            enableSuggestions: widget.enableSuggestions,
            autocorrect: widget.autocorrect,
            style: AppTypography.bodyLarge
                .copyWith(
                  color: AppFieldStyle.text(context, enabled: widget.enabled),
                )
                .merge(widget.textStyle),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText,
              hintStyle: AppTypography.bodyLarge
                  .copyWith(color: AppFieldStyle.placeholder(context))
                  .merge(widget.hintStyle),
              // Errors draw the red border here; the message itself is
              // shown by the footer, with an icon.
              error: _displayedExternalError == null
                  ? null
                  : const SizedBox.shrink(),
              counterText: '',
              prefixIcon: _buildPrefix(context),
              prefixIconConstraints: const BoxConstraints(),
              suffixIcon: _buildSuffix(context),
              suffixIconConstraints: const BoxConstraints(),
              contentPadding: AppFieldStyle.contentPadding,
              filled: true,
              hoverColor: Colors.transparent,
              fillColor: AppFieldStyle.fill(
                context,
                enabled: widget.enabled,
                active: active,
              ),
              border: AppFieldStyle.border(restBorder),
              enabledBorder: AppFieldStyle.border(restBorder),
              disabledBorder: AppFieldStyle.border(restBorder),
              focusedBorder: AppFieldStyle.border(
                AppFieldStyle.focusBorder(context),
                width: 1.5,
              ),
              errorBorder: AppFieldStyle.border(errorBorder, width: 1.5),
              focusedErrorBorder: AppFieldStyle.border(errorBorder, width: 1.5),
            ),
          ),
        ),
        ?footer,
      ],
    );
  }
}
