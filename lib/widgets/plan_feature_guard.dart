import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Screens/ViewPlanScreen.dart';
import '../providers/vendor_access_provider.dart';
import '../theme/app_colors.dart';
import '../utils/common_app_bar.dart';

/// Shows [child] only when the vendor's plan includes [module]; otherwise the
/// locked notice. The screen-level check behind the hidden menu entries, for
/// when a gated screen is reached some other way (deep link, notification, a
/// screen left open while the plan lapsed). Mirrors the web's `FeatureGuard`.
class FeatureGuard extends ConsumerWidget {
  final String module;
  final Widget child;

  const FeatureGuard({super.key, required this.module, required this.child});

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
          : PlanFeatureNotice(module: module),
    );
  }
}

/// The single "not in your plan" screen: the feature's label and description
/// from `allModules`, the server's [message] when there is one, reassurance
/// that nothing is deleted, and one button to the plans screen.
class PlanFeatureNotice extends ConsumerWidget {
  final String module;
  final String? message;

  const PlanFeatureNotice({super.key, required this.module, this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(vendorAccessProvider).value?.moduleInfo(module);
    final label = info?.label ?? 'This feature';

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
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_outlined,
                      size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  '$label is not part of your current plan',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                if (info != null && info.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(info.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ],
                if (message != null && message!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Your saved data is safe and comes back as soon as you upgrade.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
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
