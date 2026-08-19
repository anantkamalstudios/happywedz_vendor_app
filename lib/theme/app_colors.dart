import 'package:flutter/material.dart';

/// ============================================================================
/// AppColors — CENTRALISED COLOR SYSTEM (HappyWedz Business)
/// ============================================================================
///
/// AUDIT NOTE:
/// Every value below was harvested from the EXISTING screens of this app.
/// The brand identity (French Blue #003F88 / Steel Azure #00509D / Steel Blue
/// #4682B4) is UNCHANGED — this file only gives the already-used colors a
/// single home so the same shade is reused everywhere instead of being
/// re-typed as a raw hex literal on every screen.
///
/// Where a screen previously used a slightly different ad-hoc shade for the
/// same semantic role, it is mapped onto the nearest existing brand token.
///
/// DO NOT introduce new brand hues here. Add semantic aliases instead.
/// ----------------------------------------------------------------------------
class AppColors {
  AppColors._();

  // ==========================================================================
  // BRAND (verbatim from the existing app)
  // ==========================================================================

  /// French Blue — used as the dark end of every header gradient and as the
  /// HomeTab AppBar background in the existing app.
  static const Color primaryDark = Color(0xFF003F88);

  /// Steel Azure — the app's dominant action color (buttons, FAB, chips,
  /// selected bottom-nav item, progress bars, avatars).
  static const Color primary = Color(0xFF00509D);

  /// Steel Blue — used for drawer/storefront leading icons and chart lines.
  static const Color secondary = Color(0xFF4682B4);

  /// Lighter azure used by the existing lead "pending" status chip.
  static const Color primaryLight = Color(0xFF4A90E2);

  /// Pale brand tints already present in the existing UI.
  static const Color primaryTint = Color(0xFFE8F3FA); // upload/review cards
  static const Color primarySurface = Color(0xFFBFD7ED); // default status chip
  static const Color primaryMuted = Color(0xFF89C2D9); // "declined" status

  // ==========================================================================
  // BACKGROUNDS & SURFACES
  // ==========================================================================

  /// Default page background for content screens.
  static const Color background = Color(0xFFF7F8FA); // was 0xffF7F8FA

  /// Cards, sheets, dialogs, app bar-less scaffolds.
  static const Color surface = Colors.white;

  /// Card surface (kept separate so it can diverge from `surface` later).
  static const Color card = Colors.white;

  /// Subtle filled input background (was Colors.grey[100] on every form).
  static const Color inputFill = Color(0xFFF5F5F5);

  /// Scaffold background used by list screens (was Colors.grey[100]).
  static const Color listBackground = Color(0xFFF5F5F5);

  // ==========================================================================
  // TEXT
  // ==========================================================================

  static const Color textPrimary = Color(0xFF1A1A1A); // was Colors.black / black87
  static const Color textSecondary = Color(0xFF667085); // was Colors.black54 / grey.600
  static const Color textTertiary = Color(0xFF98A2B3); // was Colors.grey
  static const Color textOnPrimary = Colors.white;

  // ==========================================================================
  // BORDERS & DIVIDERS
  // ==========================================================================

  static const Color border = Color(0xFFE4E7EC); // was Colors.grey.shade300
  static const Color borderStrong = Color(0xFFD0D5DD);
  static const Color divider = Color(0xFFEAECF0);

  // ==========================================================================
  // FEEDBACK / STATUS
  // ==========================================================================

  static const Color success = Color(0xFF2E7D32); // already used by stats card
  static const Color successTint = Color(0xFFE8F5E9);

  static const Color error = Color(0xFFD32F2F); // Colors.red.shade700 equivalent
  static const Color errorTint = Color(0xFFFDECEA);

  static const Color warning = Color(0xFFED6C02);
  static const Color warningTint = Color(0xFFFFF4E5);

  static const Color info = Color(0xFF1565C0); // already used by stats card
  static const Color infoTint = Color(0xFFE3F2FD);

  /// Star / rating colour already used across reviews.
  static const Color rating = Color(0xFFFFC107); // Colors.amber

  /// Impressions accent already used on the Statistics screen.
  static const Color accentPink = Color(0xFFC2185B);
  static const Color accentPinkTint = Color(0xFFFCE4EC);

  // ==========================================================================
  // SHIMMER (skeleton loading)
  // ==========================================================================

  static const Color shimmerBase = Color(0xFFE9EDF2);
  static const Color shimmerHighlight = Color(0xFFF7F9FC);

  // ==========================================================================
  // GRADIENTS (the existing header gradient, centralised)
  // ==========================================================================

  /// The exact gradient already used by Enquirys / Reviews / Statistics
  /// headers in the existing app.
  static const LinearGradient headerGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  /// Resolves the brand colour for a lead/enquiry status string.
  /// Mirrors the switch that already exists in LeadsScreen so every screen
  /// renders the same status in the same colour.
  static Color statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'booked':
        return primaryDark;
      case 'pending':
        return primaryLight;
      case 'declined':
        return primaryMuted;
      default:
        return primarySurface;
    }
  }
}