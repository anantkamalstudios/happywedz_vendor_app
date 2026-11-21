import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Screens/ViewPlanScreen.dart';
import '../providers/vendor_access_provider.dart';
import '../theme/app_colors.dart';
import '../utils/common_app_bar.dart';

/// Shows [child] only when the vendor's plan includes [module]; otherwise the
/// locked notice. Gated menu entries are listed for everyone with a padlock,
/// so this is the ordinary way a vendor learns what a feature does — and it
/// also covers a gated screen reached some other way (deep link, a screen left
/// open while the plan lapsed). Mirrors the web's `FeatureGuard`.
class FeatureGuard extends ConsumerWidget {
  final String module;
  final Widget child;

  /// Optional wording for the locked page, for a screen that shares another
  /// feature's module (WhatsApp is part of the CRM plan, as on the website).
  final String? title;
  final String? description;

  const FeatureGuard({
    super.key,
    required this.module,
    required this.child,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(vendorAccessProvider);
    return access.when(
      // Nothing gated is shown until access is known — no flash.
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      // The server still enforces the rule, so failing open here is safe.
      error: (_, __) => child,
      data: (a) => a.hasModule(module)
          ? child
          : PlanFeatureNotice(
              module: module,
              title: title,
              description: description,
            ),
    );
  }
}

/// The single "not in your plan" screen: the feature's label and description
/// from `allModules`, the server's [message] when there is one, reassurance
/// that nothing is deleted, and one button to the plans screen.
class PlanFeatureNotice extends ConsumerWidget {
  final String module;
  final String? message;

  /// Override the module's label / description (see [FeatureGuard.title]).
  final String? title;
  final String? description;

  const PlanFeatureNotice({
    super.key,
    required this.module,
    this.message,
    this.title,
    this.description,
  });

  /// The website's titles and descriptions for these notices (Main.jsx), used
  /// when the server sends none for the module.
  static const Map<String, (String, String)> _websiteCopy = {
    'instagram': (
      'Instagram Connect',
      'Connect your Instagram account and show your posts and stories on your listing.',
    ),
    'crm': (
      'CRM',
      'Keep your clients, quotations, invoices and payments in one place.',
    ),
    'google_profile': (
      'Google Profile',
      'Show up when couples search on Google and Maps. Available on plans that include Google Profile.',
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(vendorAccessProvider).value?.moduleInfo(module);
    final copy = _websiteCopy[module];
    final label = (title != null && title!.isNotEmpty)
        ? title!
        : (info != null && info.label.isNotEmpty)
        ? info.label
        : copy?.$1 ?? 'This feature';
    final description = this.description != null
        ? this.description!
        : (info != null && info.description.isNotEmpty)
        ? info.description
        : copy?.$2 ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(title: label),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Same wording as the website's PlanFeatureNotice, in the app's theme.
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline,
                      size: 28, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  '$label is not part of your plan',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  '${description.isEmpty ? '' : '$description '}'
                  'Your saved data is safe — upgrade and it comes straight back.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                if (message != null && message!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ViewPlansScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View plans'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the locked notice after a gated call answered `PLAN_MODULE_LOCKED`,
/// and re-reads access so the navigation catches up with the server.
void showPlanModuleLocked(BuildContext context, WidgetRef ref,
    {required String module, String? message}) {
  ref.invalidate(vendorAccessProvider);
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => PlanFeatureNotice(module: module, message: message),
    ),
  );
}
