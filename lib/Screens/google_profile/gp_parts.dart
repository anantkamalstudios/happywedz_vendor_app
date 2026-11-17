// Shared building blocks of the Google Profile screens (website GpParts.jsx),
// in the app's own look (AppColors / AppTextStyles).
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Storefront/StoreFront.dart';
import '../../api_services/google_profile_api.dart';
import '../../providers/vendor_access_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/plan_module_lock.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/plan_feature_guard.dart';
import 'gp_format.dart';

/// The plan module id the website gates this page with.
const String gpModule = 'google_profile';

// ── Text ──────────────────────────────────────────────────────────────────

class GpText {
  GpText._();
  static const TextStyle h2 = AppTextStyles.h2;
  static const TextStyle h3 = AppTextStyles.h3;
  static const TextStyle lead =
      TextStyle(fontSize: 14, height: 1.45, color: AppColors.textPrimary);
  static const TextStyle note =
      TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textSecondary);
  static const TextStyle label = TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle error =
      TextStyle(fontSize: 12, height: 1.35, color: AppColors.error);
  static const TextStyle muted =
      TextStyle(fontSize: 13, color: AppColors.textTertiary);
}

// ── Layout ────────────────────────────────────────────────────────────────

/// A white rounded card (website `.gp-card`); [tint] gives the pale brand tint.
class GpCard extends StatelessWidget {
  final Widget child;
  final bool tint;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const GpCard({
    super.key,
    required this.child,
    this.tint = false,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: tint ? AppColors.primaryTint : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// A column with [gap] between children (null children are skipped).
class GpStack extends StatelessWidget {
  final List<Widget?> children;
  final double gap;
  final CrossAxisAlignment cross;

  const GpStack(
      {super.key,
      required this.children,
      this.gap = 12,
      this.cross = CrossAxisAlignment.start});

  @override
  Widget build(BuildContext context) {
    final items = children.whereType<Widget>().toList();
    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          items[i],
        ],
      ],
    );
  }
}

/// A row of buttons that wraps on narrow screens (website `.gp-btns`).
class GpButtons extends StatelessWidget {
  final List<Widget?> children;
  const GpButtons({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children.whereType<Widget>().toList(),
    );
  }
}

/// A side card (website AsideCard): a heading and its content.
class GpAsideCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const GpAsideCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return GpCard(
      child: GpStack(gap: 10, children: [Text(title, style: GpText.h3), ...children]),
    );
  }
}

/// A numbered list (website `ol.gp-next`).
class GpNumbered extends StatelessWidget {
  final List<String> items;
  final bool bullets;
  const GpNumbered(this.items, {super.key, this.bullets = false});

  @override
  Widget build(BuildContext context) {
    return GpStack(
      gap: 8,
      children: [
        for (var i = 0; i < items.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(right: 10, top: 1),
                decoration: const BoxDecoration(
                    color: AppColors.primaryTint, shape: BoxShape.circle),
                child: bullets
                    ? const Icon(Icons.circle, size: 6, color: AppColors.primary)
                    : Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
              ),
              Expanded(child: Text(items[i], style: GpText.lead)),
            ],
          ),
      ],
    );
  }
}

// ── Callout / chips ───────────────────────────────────────────────────────

enum GpTone { ok, warn, bad, alert, info }

Color gpToneColor(GpTone tone) {
  switch (tone) {
    case GpTone.ok:
      return AppColors.success;
    case GpTone.warn:
      return AppColors.warning;
    case GpTone.bad:
      return AppColors.error;
    case GpTone.alert:
      return AppColors.warning;
    case GpTone.info:
      return AppColors.info;
  }
}

Color gpToneTint(GpTone tone) {
  switch (tone) {
    case GpTone.ok:
      return AppColors.successTint;
    case GpTone.warn:
      return AppColors.warningTint;
    case GpTone.bad:
      return AppColors.errorTint;
    case GpTone.alert:
      return AppColors.warningTint;
    case GpTone.info:
      return AppColors.infoTint;
  }
}

IconData _toneIcon(GpTone tone) {
  switch (tone) {
    case GpTone.ok:
      return Icons.check_circle_outline;
    case GpTone.warn:
      return Icons.schedule;
    case GpTone.bad:
      return Icons.error_outline;
    case GpTone.alert:
      return Icons.warning_amber_rounded;
    case GpTone.info:
      return Icons.info_outline;
  }
}

/// A coloured message line (website Callout). Give [text] or [child].
class GpCallout extends StatelessWidget {
  final GpTone tone;
  final String? text;
  final String? title;
  final Widget? child;

  const GpCallout(
      {super.key, this.tone = GpTone.ok, this.text, this.title, this.child});

  @override
  Widget build(BuildContext context) {
    final color = gpToneColor(tone);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: gpToneTint(tone),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_toneIcon(tone), size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: GpStack(gap: 4, children: [
              if (title != null)
                Text(title!,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              if (text != null)
                Text(text!,
                    style: const TextStyle(
                        fontSize: 13.5, height: 1.4, color: AppColors.textPrimary)),
              child,
            ]),
          ),
        ],
      ),
    );
  }
}

/// A small rounded label (website `.gp-chip`).
class GpChip extends StatelessWidget {
  final String text;
  final GpTone? tone;
  final Color? color;
  final IconData? icon;

  const GpChip(this.text, {super.key, this.tone, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (tone != null ? gpToneColor(tone!) : AppColors.primary);
    final bg = tone != null ? gpToneTint(tone!) : c.withValues(alpha: 0.1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(text,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: c)),
        ),
      ]),
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────

/// The website's `.gp-btn` (primary / ghost), with a spinner while [busy].
class GpButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool primary;
  final bool danger;
  final bool small;
  final bool expand;

  const GpButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.busy = false,
    this.primary = true,
    this.danger = false,
    this.small = false,
    this.expand = false,
  });

  const GpButton.ghost({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.busy = false,
    this.danger = false,
    this.small = false,
    this.expand = false,
  }) : primary = false;

  @override
  Widget build(BuildContext context) {
    final fg = primary
        ? Colors.white
        : (danger ? AppColors.error : AppColors.primary);
    final bg = primary ? (danger ? AppColors.error : AppColors.primary) : Colors.white;
    final enabled = onPressed != null && !busy;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: small ? 16 : 18, color: enabled ? fg : null),
        if (busy || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: small ? 12.5 : 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    final padding = EdgeInsets.symmetric(
        horizontal: small ? 12 : 16, vertical: small ? 8 : 12);
    final button = primary
        ? ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              disabledBackgroundColor: bg.withValues(alpha: busy ? 0.75 : 0.4),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              padding: padding,
              minimumSize: Size(0, small ? 36 : 44),
              shape: shape,
            ),
            child: content,
          )
        : OutlinedButton(
            onPressed: enabled ? onPressed : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: fg,
              backgroundColor: bg,
              side: BorderSide(
                  color: danger
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.borderStrong),
              padding: padding,
              minimumSize: Size(0, small ? 36 : 44),
              shape: shape,
            ),
            child: content,
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A text link (website `.gp-link`).
class GpLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  const GpLink(this.label, {super.key, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary)),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 15, color: AppColors.primary),
          ],
        ]),
      ),
    );
  }
}

/// A spinner with a line of text (website `Loading` / `.gp-setup-inline`).
class GpLoadingLine extends StatelessWidget {
  final String label;
  const GpLoadingLine(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: GpText.note)),
      ]),
    );
  }
}

/// A skeleton for a tab or card that is loading.
class GpCardsShimmer extends StatelessWidget {
  final int count;
  final double height;
  const GpCardsShimmer({super.key, this.count = 3, this.height = 96});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            ShimmerBox(
                height: height,
                radius: 14,
                margin: const EdgeInsets.only(bottom: 12)),
        ],
      ),
    );
  }
}

/// A load failure with "Try again" (website OverviewLoadError and friends).
class GpLoadError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  const GpLoadError(
      {super.key,
      required this.message,
      this.onRetry,
      this.retryLabel = 'Try again'});

  @override
  Widget build(BuildContext context) {
    return GpStack(gap: 10, children: [
      GpCallout(tone: GpTone.bad, text: message),
      if (onRetry != null)
        GpButton.ghost(label: retryLabel, icon: Icons.refresh, onPressed: onRetry),
    ]);
  }
}

/// An empty list (icon, title, line).
class GpEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  const GpEmpty(
      {super.key,
      this.icon = Icons.inbox_outlined,
      required this.title,
      this.message,
      this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
              color: AppColors.primaryTint, shape: BoxShape.circle),
          child: Icon(icon, size: 30, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: GpText.h3),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(message!, textAlign: TextAlign.center, style: GpText.note),
        ],
        if (action != null) ...[const SizedBox(height: 14), action!],
      ]),
    );
  }
}

/// The 5-step strip above the setup screens. [done] = finished steps.
class GpStepStrip extends StatelessWidget {
  final int done;
  const GpStepStrip({super.key, required this.done});

  @override
  Widget build(BuildContext context) {
    final now = done < gpSteps.length ? gpSteps[done] : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            for (var i = 0; i < gpSteps.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i < done
                        ? AppColors.success
                        : i == done
                            ? AppColors.primary
                            : AppColors.border,
                  ),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 6),
          Text(
            now == null
                ? 'All steps done'
                : 'Step ${done + 1} of ${gpSteps.length}: $now',
            style: GpText.note,
          ),
        ],
      ),
    );
  }
}

/// Business initials in a tile, the name and a line (website ProfileHead).
class GpProfileHead extends StatelessWidget {
  final String name;
  final String? line;
  final List<Widget> chips;
  const GpProfileHead(
      {super.key, required this.name, this.line, this.chips = const []});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
        child: Text(initials(name),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: GpStack(gap: 4, children: [
          Text(name, style: GpText.h2),
          if (line != null && line!.isNotEmpty) Text(line!, style: GpText.note),
          if (chips.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: chips),
        ]),
      ),
    ]);
  }
}

// ── Form fields ───────────────────────────────────────────────────────────

InputDecoration gpInputDecoration({
  String? hint,
  String? error,
  String? helper,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? counter,
}) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: GpText.muted,
    errorText: (error == null || error.isEmpty) ? null : error,
    errorMaxLines: 3,
    helperText: helper,
    helperMaxLines: 4,
    helperStyle: GpText.note,
    counterText: counter,
    filled: true,
    fillColor: Colors.white,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: border(AppColors.borderStrong),
    enabledBorder: border(AppColors.borderStrong),
    focusedBorder: border(AppColors.primary),
    errorBorder: border(AppColors.error),
    focusedErrorBorder: border(AppColors.error),
    disabledBorder: border(AppColors.border),
  );
}

/// A labelled text box (label above, like the website's `.gp-field`).
class GpTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final String? error;
  final bool optional;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onBlur;
  final bool showCounter;

  const GpTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.error,
    this.optional = false,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
    this.enabled = true,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.onBlur,
    this.showCounter = false,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType ??
          (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 14),
      decoration: gpInputDecoration(
          hint: hint,
          error: error,
          helper: helper,
          counter: showCounter ? null : ''),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text.rich(TextSpan(text: label, style: GpText.label, children: [
        if (optional)
          const TextSpan(
              text: ' (optional)',
              style: TextStyle(
                  fontWeight: FontWeight.w400, color: AppColors.textTertiary)),
      ])),
      const SizedBox(height: 6),
      onBlur == null
          ? field
          : Focus(
              onFocusChange: (has) {
                if (!has) onBlur!();
              },
              child: field,
            ),
    ]);
  }
}

/// A radio-style choice row (website `.gp-choice-item`).
class GpChoice extends StatelessWidget {
  final bool selected;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool checkbox;

  const GpChoice({
    super.key,
    required this.selected,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.checkbox = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.primaryTint : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(
                checkbox
                    ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
                    : (selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked),
                size: 20,
                color: onTap == null
                    ? AppColors.textTertiary
                    : (selected ? AppColors.primary : AppColors.textTertiary),
              ),
              const SizedBox(width: 10),
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: GpStack(gap: 2, children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(subtitle!, style: GpText.note),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A checkbox with a wrapped label (website `.gp-consent`).
class GpCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget label;
  const GpCheck(
      {super.key, required this.value, required this.onChanged, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            value: value,
            onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.only(top: 4), child: label)),
      ]),
    );
  }
}

/// The seven day toggles (website `.gp-days`). [selected] are pressed.
class GpDayPicker extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<String>? onToggle;

  /// Pressed days are shown as closed (red) instead of open (blue).
  final bool closedStyle;

  const GpDayPicker(
      {super.key,
      required this.selected,
      required this.onToggle,
      this.closedStyle = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final d in gpWeekdays)
        Semantics(
          button: true,
          selected: selected.contains(d.id),
          label: d.long,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle == null ? null : () => onToggle!(d.id),
            child: Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: selected.contains(d.id)
                    ? (closedStyle ? AppColors.errorTint : AppColors.primary)
                    : Colors.white,
                border: Border.all(
                  color: selected.contains(d.id)
                      ? (closedStyle ? AppColors.error : AppColors.primary)
                      : AppColors.borderStrong,
                ),
              ),
              child: Text(
                d.short,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  decoration: selected.contains(d.id) && closedStyle
                      ? TextDecoration.lineThrough
                      : null,
                  color: selected.contains(d.id)
                      ? (closedStyle ? AppColors.error : Colors.white)
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

/// A time box that opens the time picker; [value] and the result are "HH:MM".
class GpTimeField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String>? onChanged;
  final String? error;
  final bool clearable;

  const GpTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.error,
    this.clearable = false,
  });

  Future<void> _pick(BuildContext context) async {
    final parts = value.split(':');
    final initial = parts.length == 2
        ? TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: int.tryParse(parts[1]) ?? 0)
        : const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    onChanged?.call(
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label.isNotEmpty) ...[
        Text(label, style: GpText.label),
        const SizedBox(height: 6),
      ],
      InkWell(
        onTap: onChanged == null ? null : () => _pick(context),
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          isEmpty: value.isEmpty,
          decoration: gpInputDecoration(
            hint: '--:--',
            error: error,
            suffixIcon: clearable && value.isNotEmpty && onChanged != null
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onChanged!(''),
                  )
                : const Icon(Icons.schedule, size: 18),
          ),
          child: Text(value.isEmpty ? '' : formatTime12(value),
              style: const TextStyle(fontSize: 14)),
        ),
      ),
    ]);
  }
}

/// "18:30" → "6:30 PM".
String formatTime12(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return hhmm;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return hhmm;
  final suffix = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $suffix';
}

/// A dropdown with the website's select look.
class GpDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? error;
  final String? helper;

  const GpDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.error,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label.isNotEmpty) ...[
        Text(label, style: GpText.label),
        const SizedBox(height: 6),
      ],
      DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        hint: hint == null ? null : Text(hint!, style: GpText.muted),
        decoration: gpInputDecoration(error: error, helper: helper),
      ),
    ]);
  }
}

/// "Are you sure?" inline box (website ConfirmBox).
class GpConfirmBox extends StatelessWidget {
  final String text;
  final String confirmLabel;
  final String cancelLabel;
  final bool busy;
  final bool danger;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const GpConfirmBox({
    super.key,
    required this.text,
    required this.onConfirm,
    required this.onCancel,
    this.confirmLabel = 'Yes',
    this.cancelLabel = 'Not now',
    this.busy = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: danger ? AppColors.errorTint : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: danger
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.border),
      ),
      child: GpStack(gap: 10, children: [
        Text(text, style: GpText.lead),
        GpButtons(children: [
          GpButton(
              label: confirmLabel,
              danger: danger,
              busy: busy,
              small: true,
              onPressed: onConfirm),
          GpButton.ghost(
              label: cancelLabel, small: true, onPressed: busy ? null : onCancel),
        ]),
      ]),
    );
  }
}

/// A modal confirm dialog; resolves true when confirmed.
Future<bool> gpConfirm(BuildContext context,
    {required String title,
    String? message,
    String confirmLabel = 'Yes',
    String cancelLabel = 'Cancel',
    bool danger = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title, style: GpText.h3),
      content: message == null ? null : Text(message, style: GpText.lead),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false), child: Text(cancelLabel)),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          style: TextButton.styleFrom(
              foregroundColor: danger ? AppColors.error : AppColors.primary),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

// ── Images ────────────────────────────────────────────────────────────────

/// An image that may be served by HappyWedz (`/vendor/google-profile/images/…`,
/// which needs the vendor's token — website `loadImage`) or by Google.
class GpImage extends StatefulWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const GpImage(
      {super.key,
      required this.url,
      this.width,
      this.height,
      this.fit = BoxFit.cover,
      this.borderRadius});

  @override
  State<GpImage> createState() => _GpImageState();
}

class _GpImageState extends State<GpImage> {
  static String? _token;

  @override
  void initState() {
    super.initState();
    if (_token == null && GoogleProfileApi.needsAuth(widget.url)) {
      GoogleProfileApi.token().then((t) {
        if (!mounted) return;
        setState(() => _token = t ?? '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    if (!GoogleProfileApi.needsAuth(url)) {
      return AppNetworkImage(
          url: url,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          borderRadius: widget.borderRadius);
    }
    if (_token == null) {
      return AppShimmer(
        child: ShimmerBox(
            width: widget.width, height: widget.height ?? 80, radius: 8),
      );
    }
    final child = CachedNetworkImage(
      imageUrl: GoogleProfileApi.absoluteUrl(url!),
      httpHeaders: {'Authorization': 'Bearer $_token'},
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (_, __) => AppShimmer(
          child: ShimmerBox(
              width: widget.width, height: widget.height ?? 80, radius: 0)),
      errorWidget: (_, __, ___) => AppNetworkImage(
          url: null, width: widget.width, height: widget.height),
    );
    if (widget.borderRadius == null) return child;
    return ClipRRect(borderRadius: widget.borderRadius!, child: child);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

/// A short message at the bottom (website addToast).
void gpToast(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  if (error) {
    AppSnackbar.error(context, message);
  } else {
    AppSnackbar.success(context, message);
  }
}

/// Opens an outside link in the browser (website target="_blank").
Future<void> gpOpenUrl(BuildContext context, String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  var ok = false;
  if (uri != null) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
  }
  if (!ok && context.mounted) gpToast(context, 'Could not open the link.', error: true);
}

/// Opens the Storefront, where the vendor fixes their details (website FixLink
/// to /vendor-dashboard/vendor-store-front).
Future<void> gpOpenStorefront(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final vendorId = prefs.getInt('vendorId');
  if (!context.mounted) return;
  if (vendorId == null) {
    gpToast(context, 'Vendor ID not found. Please login again.', error: true);
    return;
  }
  Navigator.push(context,
      MaterialPageRoute(builder: (_) => Storefront(vendorId: vendorId)));
}

/// Handles PLAN_MODULE_LOCKED from any Google Profile call: shows the locked
/// notice in place of the page. Returns true when [error] was that.
bool gpHandleLocked(BuildContext context, Object? error) {
  if (error is! PlanModuleLockedException) return false;
  if (!context.mounted) return true;
  try {
    ProviderScope.containerOf(context, listen: false)
        .invalidate(vendorAccessProvider);
  } catch (_) {}
  Navigator.of(context).pushReplacement(MaterialPageRoute(
    builder: (_) => PlanFeatureNotice(
        module: error.module.isEmpty ? gpModule : error.module,
        message: error.message),
  ));
  return true;
}

/// A small loaded-value holder (website ImproveUtils `useLoad`).
class GpLoad<T> {
  final String status; // loading | ready | error
  final T? data;
  final Object? error;
  const GpLoad._(this.status, this.data, this.error);
  const GpLoad.loading() : this._('loading', null, null);
  const GpLoad.ready(T? data) : this._('ready', data, null);
  const GpLoad.failed(Object error) : this._('error', null, error);
  bool get isLoading => status == 'loading';
  bool get isReady => status == 'ready';
  bool get isError => status == 'error';
}
