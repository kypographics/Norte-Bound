import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.helperText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final String? helperText;
  final bool enabled;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FormField<String>(
      initialValue: widget.controller.text,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) {
        final hasError = field.hasError;
        final isFocused = _focusNode.hasFocus;
        final borderColor = hasError
            ? AppColors.danger
            : isFocused
            ? AppColors.terracotta
            : AppColors.hairline;
        final borderWidth = hasError || isFocused ? 1.2 : 0.5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              decoration: ShapeDecoration(
                color: widget.enabled
                    ? AppColors.ivorySand
                    : AppColors.warmSand.withValues(alpha: 0.7),
                shape: ContinuousRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                  side: BorderSide(color: borderColor, width: borderWidth),
                ),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                textCapitalization: widget.textCapitalization,
                autofillHints: widget.autofillHints,
                enableSuggestions: !widget.obscureText,
                autocorrect: !widget.obscureText,
                onChanged: (value) {
                  field.didChange(value);
                  widget.onChanged?.call(value);
                },
                onSubmitted: widget.onFieldSubmitted,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                style: textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: Icon(
                    widget.icon,
                    size: 19,
                    color: hasError ? AppColors.danger : AppColors.mutedForest,
                  ),
                  suffixIcon: widget.suffixIcon,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 7, left: 4),
                child: Text(
                  field.errorText!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else if (widget.helperText != null)
              Padding(
                padding: const EdgeInsets.only(top: 7, left: 4),
                child: Text(
                  widget.helperText!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForest,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
