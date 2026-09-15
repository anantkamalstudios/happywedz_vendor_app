import 'package:flutter/material.dart';
import '../api_services/vendor_access_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The strip at the top of Business Details telling the vendor exactly where
/// they stand. Copy comes from the server's access resolver (`access.headline`
/// / `access.message`) so the app says the same thing the website and any
/// verification emails say. Ported from `kyc/VerificationStatusBanner.jsx`.
class VerificationStatusBanner extends StatelessWidget {
  final VendorAccess? access;
  final VoidCallback? onAction;

  const VerificationStatusBanner({super.key, this.access, this.onAction});

  ({Color bg, Color border, IconData icon}) _tone(String? stage) {
    switch (stage) {
      case 'kyc_pending':
      case 'expired':
        return (bg: AppColors.warningTint, border: AppColors.warning, icon: Icons.hourglass_top_rounded);
      case 'kyc_rejected':
        return (bg: AppColors.errorTint, border: AppColors.error, icon: Icons.error_outline_rounded);
      case 'payment_required':
      case 'active':
        return (bg: AppColors.successTint, border: AppColors.success, icon: Icons.check_circle_outline_rounded);
      case 'legacy_grace':
      case 'kyc_required':
      default:
        return (bg: AppColors.infoTint, border: AppColors.info, icon: Icons.info_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = access;
    if (a == null || a.headline == null) return const SizedBox.shrink();

    final tone = _tone(a.stage);
    final action = a.nextAction;
    final showButton = action != null && action['label'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: tone.border, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: tone.border,
            child: Icon(tone.icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.headline!, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                if (a.message != null) ...[
                  const SizedBox(height: 4),
                  Text(a.message!, style: AppTextStyles.bodySecondary),
                ],
                if (a.stage == 'kyc_rejected' && a.reviewedAt != null) ...[
                  const SizedBox(height: 6),
                  Text('Reviewed on ${a.reviewedAt}', style: AppTextStyles.caption),
                ],
                if (a.stage == 'kyc_pending' && a.submittedAt != null) ...[
                  const SizedBox(height: 6),
                  Text('Submitted on ${a.submittedAt}', style: AppTextStyles.caption),
                ],
                if (showButton) ...[
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tone.border,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(action['label'] as String),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
