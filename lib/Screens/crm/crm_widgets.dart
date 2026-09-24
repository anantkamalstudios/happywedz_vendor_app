import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';

/// Small building blocks shared by the CRM screens, so every CRM form and
/// card looks the same.

InputDecoration crmInputDecoration({
  String? hint,
  String? prefix,
  Widget? suffix,
}) => InputDecoration(
  hintText: hint,
  prefixText: prefix,
  suffixIcon: suffix,
  isDense: true,
  counterText: '',
  filled: true,
  fillColor: AppColors.surface,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.border),
  ),
);

BoxDecoration crmCardDecoration() => BoxDecoration(
  color: AppColors.card,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: AppColors.border),
);

/// Label above an input, with an optional hint under it.
class CrmField extends StatelessWidget {
  final String label;
  final Widget child;
  final String? hint;

  const CrmField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          child,
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CrmTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final String? prefix;
  final int? maxLength;
  final int lines;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const CrmTextInput({
    super.key,
    required this.controller,
    this.hint,
    this.prefix,
    this.maxLength,
    this.lines = 1,
    this.keyboard,
    this.onChanged,
    this.autofocus = false,
  });

  /// A rupee amount box (digits, commas, one decimal point).
  const CrmTextInput.rupees({
    super.key,
    required this.controller,
    this.hint = '0',
    this.onChanged,
    this.autofocus = false,
  }) : prefix = '₹ ',
       maxLength = 15,
       lines = 1,
       keyboard = const TextInputType.numberWithOptions(decimal: true);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLength: maxLength,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 3,
      keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
      onChanged: onChanged,
      decoration: crmInputDecoration(hint: hint, prefix: prefix),
    );
  }
}

class CrmDropdown extends StatelessWidget {
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  const CrmDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      // Keyed on the value so a change made in code (not by tapping) shows.
      key: ValueKey(value),
      initialValue: options.containsKey(value) ? value : options.keys.first,
      isExpanded: true,
      decoration: crmInputDecoration(),
      items: options.entries
          .map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// A `YYYY-MM-DD` date box that opens the date picker.
class CrmDateInput extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool clearable;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CrmDateInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.clearable = true,
    this.placeholder = 'Select date',
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final first = firstDate ?? DateTime(2000);
        final last = lastDate ?? DateTime(2100);
        var initial = CrmFormat.parseDate(value) ?? DateTime.now();
        if (initial.isBefore(first)) initial = first;
        if (initial.isAfter(last)) initial = last;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: first,
          lastDate: last,
        );
        if (picked != null) onChanged(DateFormat('yyyy-MM-dd').format(picked));
      },
      child: InputDecorator(
        decoration: crmInputDecoration(
          suffix: value.isNotEmpty && clearable
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => onChanged(''),
                )
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value.isEmpty ? placeholder : CrmFormat.date(value),
          style: TextStyle(
            color: value.isEmpty
                ? AppColors.textTertiary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Coloured status pill, same tones as the web's `crm-badge`.
class CrmBadge extends StatelessWidget {
  final String status;
  final String label;

  const CrmBadge({super.key, required this.status, required this.label});

  static Color toneOf(String status) {
    switch (status) {
      case 'lead':
      case 'sent':
      case 'part_paid':
        return AppColors.info;
      case 'quoted':
        return const Color(0xFF6D28D9);
      case 'booked':
      case 'accepted':
      case 'paid':
        return AppColors.success;
      case 'lost':
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      case 'expired':
      case 'unpaid':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = toneOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tone,
        ),
      ),
    );
  }
}

class CrmNotice extends StatelessWidget {
  final String text;
  final bool warn;

  const CrmNotice(this.text, {super.key, this.warn = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warn ? AppColors.warningTint : AppColors.infoTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      ),
    );
  }
}

/// Primary + secondary buttons pinned under a form.
class CrmFormButtons extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool busy;
  final String busyLabel;

  const CrmFormButtons({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    required this.busy,
    this.busyLabel = 'Saving…',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: busy ? null : onPrimary,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(busy ? busyLabel : primaryLabel),
          ),
        ),
      ],
    );
  }
}

/// The web's confirm dialog: title, text, optional text input, and an async
/// action that returns true when it worked (the dialog then closes).
Future<void> showCrmConfirm(
  BuildContext context, {
  required String title,
  required String text,
  required String confirmLabel,
  required Future<bool> Function(String input) onConfirm,
  bool danger = false,
  String? inputLabel,
}) {
  final input = TextEditingController();
  var busy = false;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text),
            if (inputLabel != null) ...[
              const SizedBox(height: 14),
              CrmField(
                label: inputLabel,
                child: CrmTextInput(
                  controller: input,
                  maxLength: 500,
                  autofocus: true,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: danger ? AppColors.error : AppColors.primary,
            ),
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    final ok = await onConfirm(input.text);
                    if (!dialogContext.mounted) return;
                    if (ok) {
                      Navigator.pop(dialogContext);
                    } else {
                      setState(() => busy = false);
                    }
                  },
            child: Text(busy ? 'Please wait…' : confirmLabel),
          ),
        ],
      ),
    ),
  ).whenComplete(input.dispose);
}
