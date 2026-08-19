import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// AppButton — one button, four states: idle / loading / disabled / (success)
/// ============================================================================
///
/// AUDIT NOTE:
/// Every screen previously rolled its own `ElevatedButton` with a hand-typed
/// `backgroundColor: Color(0xFF00509D)`, its own vertical padding (12/14/16)
/// and its own radius (8/10/12/30). Several submit buttons stayed tappable
/// while their request was in flight, so a double tap fired the API twice
/// (observed on Login, SignUp and the Storefront save buttons).
///
/// [AppButton] fixes both: a single visual spec, and `onPressed` is forced to
/// null while [isLoading] is true so the request cannot be re-submitted.
///
/// Existing buttons are NOT removed — this is available for new work and is
/// adopted incrementally on the screens touched by this audit.
/// ----------------------------------------------------------------------------

enum AppButtonVariant { primary, secondary, outline, text, danger }

enum AppButtonSize { regular, small }

class AppButton extends StatelessWidget {
  final String label;

  /// Async action. While the returned future is pending the button shows its
  /// spinner and refuses further taps.
  final VoidCallback? onPressed;

  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
  });

  double get _height =>
      size == AppButtonSize.small ? 40 : AppTheme.controlHeight;

  TextStyle get _textStyle => size == AppButtonSize.small
      ? AppTextStyles.buttonSmall
      : AppTextStyles.button;

  Color get _background {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.primaryTint;
      case AppButtonVariant.danger:
        return AppColors.error;
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color get _foreground {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return AppColors.textOnPrimary;
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // A loading button is never tappable — this is the double-submit guard.
    final bool disabled = isLoading || onPressed == null;

    final Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(_foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: size == AppButtonSize.small ? 16 : 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle,
                ),
              ),
            ],
          );

    final Widget button;

    switch (variant) {
      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: _foreground,
            minimumSize: Size(0, _height),
            side: BorderSide(
              color: disabled ? AppColors.border : AppColors.primary,
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          child: child,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: disabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: _foreground,
            minimumSize: Size(0, _height),
          ),
          child: child,
        );
        break;

      default:
        button = ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _background,
            foregroundColor: _foreground,
            disabledBackgroundColor: _background.withValues(alpha: 0.45),
            disabledForegroundColor: _foreground.withValues(alpha: 0.8),
            elevation: 0,
            minimumSize: Size(0, _height),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          child: child,
        );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _height,
      child: button,
    );
  }
}

/// A pill-shaped outline button matching the "Ask for Reviews" / "Upload
/// Reviews" pair already on the Home screen, kept as its own component so both
/// stay identical.
class AppPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
        minimumSize: const Size(0, 0),
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
    );
  }
}