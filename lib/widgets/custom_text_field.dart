import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.7),
              fontSize: 16,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: AppTheme.textSecondary,
                    size: 20,
                  )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled 
                ? AppTheme.surfaceCharcoal 
                : AppTheme.surfaceCharcoal.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              borderSide: BorderSide(
                color: AppTheme.surfaceCharcoal,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              borderSide: const BorderSide(
                color: AppTheme.accentGreen,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              borderSide: const BorderSide(
                color: AppTheme.errorRed,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              borderSide: const BorderSide(
                color: AppTheme.errorRed,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            errorStyle: const TextStyle(
              color: AppTheme.errorRed,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// Specialized text field variants
class EmailTextField extends CustomTextField {
  EmailTextField({
    super.key,
    required super.controller,
    super.hint = 'Enter your email address',
    super.validator,
    super.onChanged,
  }) : super(
          label: 'Email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        );
}

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint = 'Enter your password',
    this.validator,
    this.onChanged,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      prefixIcon: Icons.lock_outline,
      obscureText: _obscureText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppTheme.textSecondary,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}

class SearchTextField extends CustomTextField {
  SearchTextField({
    super.key,
    required super.controller,
    super.hint = 'Search...',
    super.onChanged,
    VoidCallback? onClear,
  }) : super(
          label: 'Search',
          prefixIcon: Icons.search,
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: onClear,
                )
              : null,
        );
}