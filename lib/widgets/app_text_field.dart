import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/widgets/app_text.dart';


/// A modern, reusable text field widget with label above the field.
///
/// Features:
/// - Label displayed above the field
/// - Black border and text color on focus
/// - Support for validation, read-only mode, keyboard types, and focus nodes
/// - Modern design with rounded corners
///
/// Usage example:
/// ```dart
/// AppTextField(
///   controller: nameController,
///   label: 'Full Name',
///   hintText: 'Enter your full name',
///   validator: (value) {
///     if (value == null || value.isEmpty) {
///       return 'Please enter your name';
///     }
///     return null;
///   },
/// )
/// ```
class AppTextField extends StatefulWidget {
  /// The controller for the text field
  final TextEditingController? controller;

  /// The label text that floats above the field
  final String label;

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

  /// Maximum number of lines (null = single line)
  final int? maxLines;

  /// Minimum number of lines
  final int? minLines;

  /// Maximum length of input
  final int? maxLength;

  /// Whether to obscure text (for passwords)
  final bool obscureText;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Callback when field is submitted
  final void Function(String)? onSubmitted;

  /// Callback when field value changes
  final void Function(String)? onChanged;

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
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isFocused = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();

    // Listen to focus changes
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);

    // Validate initial value if validator exists
    if (widget.validator != null && _controller.text.isNotEmpty) {
      _validateField();
    }
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
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
    if (widget.errorText != oldWidget.errorText) {
      _hasError = widget.errorText != null;
      _errorMessage = widget.errorText;
    }
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChange() {
    if (widget.validator != null) {
      _validateField();
    }
    widget.onChanged?.call(_controller.text);
  }

  void _validateField() {
    final error = widget.validator?.call(_controller.text);
    setState(() {
      _hasError = error != null;
      _errorMessage = error;
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
      _controller.removeListener(_onTextChange);
    }
    super.dispose();
  }

  Color _getBorderColor(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    if (!widget.enabled) {
      return isLight
          ? LightColors.strokeColourStrokeSoft
          : DarkColors.strokeColourStrokeSoft;
    }

    if (_hasError || widget.errorText != null) {
      return isLight
          ? LightColors.errorErrorDefault
          : DarkColors.errorErrorDefault;
    }

    if (_isFocused) {
      return Colors.black.withOpacity(0.7);
    }

    return isLight
        ? LightColors.strokeColourStrokeMild
        : DarkColors.strokeColourStrokeMild;
  }

  Color _getTextColor(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    if (!widget.enabled) {
      return isLight
          ? LightColors.textTextDisabled
          : DarkColors.textTextDisabled;
    }

    if (_isFocused) {
      return Colors.black;
    }

    return isLight
        ? LightColors.textTextPrimary
        : DarkColors.textTextPrimary;
  }

  Color _getLabelColor(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    if (!widget.enabled) {
      return isLight
          ? LightColors.textTextDisabled
          : DarkColors.textTextDisabled;
    }

    if (_hasError || widget.errorText != null) {
      return isLight
          ? LightColors.errorErrorDefault
          : DarkColors.errorErrorDefault;
    }

    if (_isFocused) {
      return Colors.black;
    }

    return isLight
        ? LightColors.textTextMute
        : DarkColors.textTextMute;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = _getBorderColor(context);
    final textColor = _getTextColor(context);
    final labelColor = _getLabelColor(context);
    final errorMessage = widget.errorText ?? _errorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        AppText(
          widget.label,
          colorType: null,
          color: labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          style: widget.labelStyle,
        ),
        const SizedBox(height: 8),
        // Text field
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _isFocused = hasFocus;
            });
          },
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            obscureText: widget.obscureText,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            onChanged: (value) {
              if (widget.validator != null) {
                _validateField();
              }
              widget.onChanged?.call(value);
            },
            validator: widget.validator,
            enabled: widget.enabled,
            autofillHints: widget.autofillHints,
            textCapitalization: widget.textCapitalization,
            enableSuggestions: widget.enableSuggestions,
            autocorrect: widget.autocorrect,
            style: widget.textStyle ??
                TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: widget.hintStyle ??
                  TextStyle(
                    color: isLight
                        ? LightColors.textTextMute
                        : DarkColors.textTextMute,
                    fontSize: 16,
                  ),
              helperText: widget.helperText,
              helperStyle: widget.helperStyle ??
                  TextStyle(
                    color: isLight
                        ? LightColors.textTextMute
                        : DarkColors.textTextMute,
                    fontSize: 12,
                  ),
              errorText: errorMessage,
              errorStyle: widget.errorStyle ??
                  TextStyle(
                    color: isLight
                        ? LightColors.errorErrorDefault
                        : DarkColors.errorErrorDefault,
                    fontSize: 12,
                  ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              
              counterText: widget.showCounter ? null : '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              filled: true,
              fillColor: isLight
                  ? (widget.enabled
                      ? LightColors.backgroundSurfacePrimaryBG
                      : LightColors.backgroundSurfaceMild)
                  : (widget.enabled
                      ? DarkColors.backgroundSurfacePrimaryBG
                      : DarkColors.backgroundSurfaceMild),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: borderColor,
                  width: 1.3,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: borderColor,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:  BorderSide(
                  color: Colors.black,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isLight
                      ? LightColors.errorErrorDefault
                      : DarkColors.errorErrorDefault,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isLight
                      ? LightColors.errorErrorDefault
                      : DarkColors.errorErrorDefault,
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isLight
                      ? LightColors.strokeColourStrokeSoft
                      : DarkColors.strokeColourStrokeSoft,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

