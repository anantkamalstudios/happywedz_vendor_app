// Parts shared by the Profile tab's screens (website dashboard/ProfileShared.jsx):
// the server's error with its field messages, and a date box.
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'profile_utils.dart';

/// The server's message (and its field messages), in red (website ErrorNote).
class ProfileErrorNote extends StatelessWidget {
  final Object? error;
  final String fallback;
  const ProfileErrorNote(
      {super.key,
      required this.error,
      this.fallback = 'Something went wrong. Please try again.'});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    final details = profileFieldMessages(error);
    return GpCallout(
      tone: GpTone.bad,
      text: gpMessageOf(error, fallback),
      child: details.isEmpty
          ? null
          : GpStack(gap: 2, children: [
              for (final m in details)
                Text('• $m',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary)),
            ]),
    );
  }
}

/// A date box that opens the date picker; [value] and the result are
/// "YYYY-MM-DD" ("" when empty).
class ProfileDateField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? helper;
  final String? error;
  final bool clearable;

  const ProfileDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
    this.error,
    this.clearable = false,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final current = DateTime.tryParse(value);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10, 12, 31),
    );
    if (picked == null) return;
    onChanged(profileIsoDay(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label.isNotEmpty) ...[
        Text(label, style: GpText.label),
        const SizedBox(height: 6),
      ],
      InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          isEmpty: value.isEmpty,
          decoration: gpInputDecoration(
            hint: 'Choose a date',
            error: error,
            helper: helper,
            suffixIcon: clearable && value.isNotEmpty
                ? IconButton(
                    tooltip: 'Clear the date',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onChanged(''),
                  )
                : const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          child: Text(value.isEmpty ? '' : formatDay(value),
              style: const TextStyle(fontSize: 14)),
        ),
      ),
    ]);
  }
}

/// A removable tag (categories, service areas, summaries).
class ProfileTag extends StatelessWidget {
  final String label;
  final bool main;
  final VoidCallback? onRemove;
  final String? removeTooltip;
  const ProfileTag(this.label,
      {super.key, this.main = false, this.onRemove, this.removeTooltip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          left: 10, right: onRemove == null ? 10 : 2, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: main ? AppColors.primaryTint : AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: main ? AppColors.primary : AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textPrimary)),
        ),
        if (main) ...[
          const SizedBox(width: 6),
          const Text('Main',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ],
        if (onRemove != null)
          InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close,
                  size: 15,
                  color: AppColors.textSecondary,
                  semanticLabel: removeTooltip),
            ),
          ),
      ]),
    );
  }
}
