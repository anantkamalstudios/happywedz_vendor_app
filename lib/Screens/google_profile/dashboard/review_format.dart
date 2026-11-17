// Small helpers shared by the Overview and Reviews tabs (website
// dashboard/ReviewFormat.js and ReviewStars.jsx). Shapes are GrowthOS's own
// (Review, ReviewsStatus, REVIEW_FILTERS, MAX_REPLY_LENGTH).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';

/// Same as GrowthOS's MAX_REPLY_LENGTH.
const int rvMaxReplyLength = 1500;

const int rvPageSize = 20;

class RvFilter {
  final String id;
  final String label;
  const RvFilter(this.id, this.label);
}

/// GrowthOS's REVIEW_FILTERS, in its order, with plain labels.
const List<RvFilter> rvFilters = [
  RvFilter('all', 'All'),
  RvFilter('positive', 'Positive'),
  RvFilter('neutral', 'Neutral'),
  RvFilter('negative', 'Negative'),
  RvFilter('unanswered', 'Need a reply'),
  RvFilter('answered', 'Replied'),
];

class RvStatusWords {
  final String label;

  /// warn | pink | ok
  final String tone;
  const RvStatusWords(this.label, this.tone);
}

const Map<String, RvStatusWords> rvReplyStatusWords = {
  'none': RvStatusWords('Needs a reply', 'warn'),
  'draft': RvStatusWords('Draft saved', 'pink'),
  'approved': RvStatusWords('Ready, not on Google yet', 'pink'),
  'published': RvStatusWords('Replied on Google', 'ok'),
};

/// GrowthOS's policy flags, in plain words.
const Map<String, String> rvPolicyWords = {
  'personal_data':
      'Remove phone numbers and email addresses. Replies on Google are public.',
  'forbidden_claim': "Remove the claim that isn't allowed in a reply.",
  'promises_compensation':
      'The reply promises a refund, discount or compensation. Check you agree to it.',
  'admits_liability':
      'The reply may admit legal responsibility. Check the wording.',
  'argues_with_reviewer':
      'The reply may sound like an argument with the reviewer.',
};

/// A short extra line for the error codes a reviewer can do something about.
const Map<String, String> _codeHints = {
  'ai_limit_reached': 'You can still write the reply yourself.',
  'ai_unavailable':
      'You can write the reply yourself, or try the AI again in a moment.',
  'google_unverified':
      'Google must verify your profile before replies can go on Google.',
  'review_reply_blocked': 'Change the reply and try again.',
};

/// The server's message, its code, a hint, and any policy flags it sent with
/// the refusal (website errorInfo).
class RvErrorInfo {
  final String code;
  final String message;
  final String hint;
  final List<String> flags;
  const RvErrorInfo(this.code, this.message, this.hint, this.flags);
}

RvErrorInfo rvErrorInfo(Object? error,
    [String fallback = 'Something went wrong. Please try again.']) {
  final code = gpErrorCode(error);
  List<String> flags = const [];
  if (error is GpException) {
    final details = error.body['details'];
    final raw = details is Map ? details['policy_flags'] : null;
    if (raw is List) {
      flags = raw
          .map((f) => '$f')
          .where((f) => rvPolicyWords.containsKey(f))
          .toList();
    }
  }
  return RvErrorInfo(
    code,
    gpErrorMessage(error, fallback),
    _codeHints[code] ?? '',
    flags,
  );
}

/// A GrowthOS Review: has an id and a reply_status.
bool rvIsReview(Object? value) =>
    value is Map &&
    (value['id'] is String || value['id'] is num) &&
    value['reply_status'] is String;

DateTime? _toDate(Object? iso) {
  if (iso == null) return null;
  final s = iso.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

/// "12 Oct 2026", in the vendor's own time.
String rvFormatDate(Object? iso) {
  final d = _toDate(iso)?.toLocal();
  return d == null ? '' : DateFormat('d MMM yyyy').format(d);
}

/// A business day "2026-10-12" from Google (already the business's own day)
/// → "12 Oct" (or "12 Oct 2026").
String rvFormatDay(Object? day, [bool withYear = false]) {
  final s = day?.toString() ?? '';
  final d = DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s);
  if (d == null) return s;
  return DateFormat(withYear ? 'd MMM yyyy' : 'd MMM').format(d);
}

/// "21 Oct, 14:05" in the vendor's own time.
String rvFormatWhen(Object? iso) => formatWhen(iso);

final NumberFormat _inNumber = NumberFormat.decimalPattern('en_IN');

/// 12,34,567 (Indian grouping), rounded.
String rvNumber(num n) => _inNumber.format(n.round());

String rvPlural(num count, String one, String many) =>
    '${rvNumber(count)} ${count == 1 ? one : many}';

bool rvIsNumber(Object? n) => n is num && n.isFinite;

/// Star rating (1–5, halves for an average) — website ReviewStars.
class ReviewStars extends StatelessWidget {
  final Object? rating;
  final double size;
  const ReviewStars({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final raw = numOf(rating)?.toDouble() ?? 0;
    final value = (raw.isNaN ? 0.0 : raw).clamp(0.0, 5.0);
    final rounded = (value * 2).round() / 2;
    final label =
        '${value == value.roundToDouble() ? value.toInt() : value.toStringAsFixed(1)} out of 5 stars';
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var n = 1; n <= 5; n++)
            Icon(
              rounded >= n
                  ? Icons.star_rounded
                  : rounded >= n - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_border_rounded,
              size: size,
              color: AppColors.rating,
            ),
        ]),
      ),
    );
  }
}

/// A row of pill buttons, one chosen (website `.gp-ov-seg`).
class RvSegments extends StatelessWidget {
  final List<String> ids;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelect;
  const RvSegments({
    super.key,
    required this.ids,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < ids.length; i++)
          _Seg(
            label: labels[i],
            on: ids[i] == selected,
            onTap: () => onSelect(ids[i]),
          ),
      ],
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Seg({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? AppColors.primary : Colors.white,
        shape: StadiumBorder(
            side: BorderSide(
                color: on ? AppColors.primary : AppColors.borderStrong)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: on ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
