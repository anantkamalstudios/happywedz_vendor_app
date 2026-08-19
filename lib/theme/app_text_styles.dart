import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ============================================================================
/// AppTextStyles — CENTRALISED POPPINS TYPOGRAPHY
/// ============================================================================
///
/// AUDIT NOTE:
/// The app previously had NO `theme:` on MaterialApp, so every `TextStyle`
/// inherited Flutter's default (Roboto). Poppins TTFs are now bundled under
/// `assets/fonts/` and declared in pubspec.yaml, and `AppTheme` sets
/// `fontFamily: AppTextStyles.fontFamily` globally.
///
/// That means EXISTING screens get Poppins automatically without editing
/// their individual TextStyle calls — a `TextStyle(fontSize: 16)` on any
/// screen now resolves to Poppins because it merges with the theme's default.
///
/// Use these named styles for anything new so weights stay consistent.
/// Weights available: w400 Regular, w500 Medium, w600 SemiBold, w700 Bold.
/// Bold (w700) is reserved for page titles and key figures only.
/// ----------------------------------------------------------------------------
class AppTextStyles {
  AppTextStyles._();

  /// The single font family for the whole application.
  static const String fontFamily = 'Poppins';

  // ==========================================================================
  // DISPLAY / PAGE TITLES
  // ==========================================================================

  /// Large screen header (e.g. "Enquirys", "My Reviews", "Statistics").
  static const TextStyle headerLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0.2,
    color: AppColors.textOnPrimary,
  );

  /// AppBar title on inner pages.
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textOnPrimary,
  );

  // ==========================================================================
  // HEADINGS
  // ==========================================================================

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// Section label above a group of cards / chart.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  // ==========================================================================
  // BODY
  // ==========================================================================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // ==========================================================================
  // SMALL / META
  // ==========================================================================

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  static const TextStyle captionMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  /// Status chips, badges, bottom-nav labels.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  // ==========================================================================
  // BUTTONS
  // ==========================================================================

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
  );

  // ==========================================================================
  // NUMERIC / STATS
  // ==========================================================================

  /// Big figures on the Statistics cards.
  static const TextStyle statValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle statLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.3,
    color: AppColors.textSecondary,
  );

  // ==========================================================================
  // INPUTS
  // ==========================================================================

  static const TextStyle input = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textTertiary,
  );

  static const TextStyle errorText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.error,
  );
}