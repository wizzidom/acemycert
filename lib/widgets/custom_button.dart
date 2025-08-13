import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isOutlined;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isOutlined = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? 
        (isOutlined ? Colors.transparent : AppTheme.primaryBlue);
    final effectiveTextColor = textColor ?? AppTheme.textPrimary;

    return SizedBox(
      width: width,
      height: height ?? AppConstants.minTouchTarget,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: effectiveBackgroundColor == Colors.transparent
                      ? AppTheme.primaryBlue
                      : effectiveBackgroundColor,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: _buildButtonContent(effectiveTextColor),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: effectiveBackgroundColor,
                foregroundColor: effectiveTextColor,
                disabledBackgroundColor: effectiveBackgroundColor.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                elevation: 2,
              ),
              child: _buildButtonContent(effectiveTextColor),
            ),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}

// Specialized button variants
class PrimaryButton extends CustomButton {
  const PrimaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height,
  }) : super(
          backgroundColor: AppTheme.primaryBlue,
          textColor: AppTheme.textPrimary,
        );
}

class SecondaryButton extends CustomButton {
  const SecondaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height,
  }) : super(
          backgroundColor: AppTheme.secondaryTeal,
          textColor: AppTheme.textPrimary,
        );
}

class AccentButton extends CustomButton {
  const AccentButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height,
  }) : super(
          backgroundColor: AppTheme.accentGreen,
          textColor: AppTheme.backgroundDark,
        );
}

class OutlinedCustomButton extends CustomButton {
  const OutlinedCustomButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height,
    Color? borderColor,
  }) : super(
          isOutlined: true,
          backgroundColor: borderColor ?? AppTheme.primaryBlue,
          textColor: borderColor ?? AppTheme.primaryBlue,
        );
}