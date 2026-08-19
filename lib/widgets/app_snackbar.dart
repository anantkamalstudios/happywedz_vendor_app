import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// AppSnackbar — one feedback surface for the whole app
/// ============================================================================
///
/// AUDIT NOTE:
/// Every screen had its own private `_showSnack()` that produced Flutter's
/// stock dark-grey rectangle, and several of them passed a raw exception
/// string straight through (`"An error occurred: SocketException: Failed host
/// lookup: 'happywedz.com'"`). This gives success / error / info a consistent
/// look and keeps technical text out of the UI.
///
/// The existing per-screen `_showSnack` helpers are left in place; screens
/// touched by this audit route through here instead.
/// ----------------------------------------------------------------------------
class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message) => _show(
        context,
        message: message,
        background: AppColors.success,
        icon: Icons.check_circle_rounded,
      );

  static void error(BuildContext context, String message) => _show(
        context,
        message: message,
        background: AppColors.error,
        icon: Icons.error_rounded,
      );

  static void warning(BuildContext context, String message) => _show(
        context,
        message: message,
        background: AppColors.warning,
        icon: Icons.warning_rounded,
      );

  static void info(BuildContext context, String message) => _show(
        context,
        message: message,
        background: AppColors.textPrimary,
        icon: Icons.info_rounded,
      );

  static void _show(
    BuildContext context, {
    required String message,
    required Color background,
    required IconData icon,
  }) {
    // A screen may be popped between an await and this call; showing a
    // snackbar on a defunct context throws. Bail out quietly instead.
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar() // never stack snackbars on top of each other
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: background,
          elevation: 4,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(AppTheme.spaceLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }
}