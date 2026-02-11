import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum GlassButtonVariant { primary, secondary, outline, danger }

class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final bool isLarge;
  final bool isSmall;
  final bool isFullWidth;
  final Widget? icon;
  final bool isLoading;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.isLarge = false,
    this.isSmall = false,
    this.isFullWidth = true,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final double bgOpacity;

    switch (variant) {
      case GlassButtonVariant.primary:
        bgColor = AppColors.primary;
        textColor = Colors.white;
        bgOpacity = 0.9;
      case GlassButtonVariant.secondary:
        bgColor = Colors.white;
        textColor = Colors.white;
        bgOpacity = 0.1;
      case GlassButtonVariant.outline:
        bgColor = Colors.white;
        textColor = AppColors.textSecondary;
        bgOpacity = 0.05;
      case GlassButtonVariant.danger:
        bgColor = AppColors.error;
        textColor = AppColors.error;
        bgOpacity = 0.1;
    }

    final button = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: bgColor.withValues(alpha: bgOpacity),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 16 : 24,
                vertical: isSmall ? 10 : (isLarge ? 18 : 14),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: variant == GlassButtonVariant.primary
                      ? Colors.transparent
                      : AppColors.glassBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 12),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: isSmall ? 14 : (isLarge ? 18 : 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return isFullWidth ? button : button;
  }
}
