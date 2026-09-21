import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// NoInternetView — offline state for a screen body
/// ============================================================================
///
/// AUDIT NOTE:
/// This component already existed. It is kept and moved onto the shared design
/// tokens so it matches `AppErrorState` and `AppEmptyState` — previously it
/// used `Colors.grey[400]` / `Colors.grey[600]` and its own hard-coded
/// `Color(0xFF00509D)` button, so an offline screen looked visually unrelated
/// to an errored one.
///
/// It is currently referenced from nowhere in lib/ — connectivity is surfaced
/// globally by `ConnectivityOverlay` (mounted in main.dart's builder). Kept per
/// the audit rules, and now consistent if a screen ever adopts it.
/// ----------------------------------------------------------------------------
class NoInternetView extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.warningTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 40,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXl),
              Text(
                "No Internet Connection",
                textAlign: TextAlign.center,
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                "Please check your internet connection\nand try again",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: AppTheme.spaceXl),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
