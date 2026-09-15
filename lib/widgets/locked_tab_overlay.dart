import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Screens/ViewPlanScreen.dart';
import '../Storefront/BusinessDetailScreen.dart';
import '../api_services/vendor_access_api.dart';
import '../providers/vendor_access_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Makes a storefront tab read-only without touching the tab screen itself.
///
/// The lock notice is a bar pinned to the BOTTOM of the screen, not an overlay
/// on top of the form: the wrapped screen keeps the whole area above it, so
/// nothing of its content is ever covered or cut off.
///
/// Not a security boundary — the server refuses the write regardless of what
/// this shows. This exists so an honest vendor does not fill in a long form
/// that was never going to save. Ported from `LockedTabOverlay.jsx`.
class LockedTabOverlay extends ConsumerWidget {
  final String tabId;
  final Widget child;

  const LockedTabOverlay({super.key, required this.tabId, required this.child});

  /// Tones come from the app's own palette (the brand blues), NOT the
  /// website's pink — only the semantics are shared, not the colours.
  ({Color bg, Color accent}) _tone(String? stage, bool notInPlan) {
    if (notInPlan) {
      return (bg: AppColors.primaryTint, accent: AppColors.primary);
    }
    switch (stage) {
      case 'kyc_pending':
      case 'expired':
        return (bg: AppColors.warningTint, accent: AppColors.warning);
      case 'kyc_rejected':
        return (bg: AppColors.errorTint, accent: AppColors.error);
      default:
        return (bg: AppColors.primaryTint, accent: AppColors.primary);
    }
  }

  void _handleAction(
    BuildContext context,
    VendorAccess access,
    bool notInPlan,
  ) {
    if (access.stage == 'kyc_required' || access.stage == 'kyc_rejected') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BusinessDetailsPage()),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ViewPlansScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(vendorAccessProvider);

    return accessAsync.when(
      // While access is loading or errored, render normally — the real
      // enforcement is server-side, so failing open here costs nothing.
      loading: () => child,
      error: (_, __) => child,
      data: (access) {
        if (access.canEditTab(tabId)) return child;

        final notInPlan = access.tabNotInPlan(tabId);
        final tabLabel = access.tabLabels[tabId] ?? 'This section';

        final String headline;
        final String message;
        if (notInPlan) {
          final planName = access.subscription?['planName'] ?? 'current';
          headline = '$tabLabel is not in your $planName plan';
          message =
              'Editing this section needs a higher plan. '
              'Your existing content stays exactly as it is.';
        } else {
          headline = access.headline ?? '$tabLabel is locked';
          message =
              access.message ?? 'Complete your setup to edit this section.';
        }

        final tone = _tone(access.stage, notInPlan);
        final buttonLabel =
            access.stage == 'kyc_required' || access.stage == 'kyc_rejected'
            ? 'Complete business details'
            : 'View plans';

        // The app bar belongs to the wrapped screen and stays fully usable
        // (title, back button). Only the body below it is dimmed and inert.
        final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // The wrapped screen keeps its own bottom padding out of the
                  // way — the lock bar below already sits in that space.
                  MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: child,
                  ),
                  Positioned(
                    top: topInset,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AbsorbPointer(
                      absorbing: true,
                      child: Container(
                        color: AppColors.surface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _LockBar(
              headline: headline,
              message: message,
              buttonLabel: buttonLabel,
              bg: tone.bg,
              accent: tone.accent,
              onAction: () => _handleAction(context, access, notInPlan),
            ),
          ],
        );
      },
    );
  }
}

class _LockBar extends StatelessWidget {
  final String headline;
  final String message;
  final String buttonLabel;
  final Color bg;
  final Color accent;
  final VoidCallback onAction;

  const _LockBar({
    required this.headline,
    required this.message,
    required this.buttonLabel,
    required this.bg,
    required this.accent,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // A Material ancestor is required: this bar is a sibling of the wrapped
    // screen's Scaffold, so without one every Text renders with Flutter's
    // yellow "no Material" underline.
    return Material(
      color: bg,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      headline,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: AppTextStyles.buttonSmall,
                ),
                child: Text(
                  buttonLabel == 'Complete business details'
                      ? 'Complete'
                      : 'View plans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
