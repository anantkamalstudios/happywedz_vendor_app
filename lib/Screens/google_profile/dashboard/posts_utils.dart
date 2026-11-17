// Helpers shared by the Posts and Photos tabs (website dashboard/ProfileUtils.js
// and ProfileShared.jsx): Google's post limits and labels, the image checks,
// the server's field messages, the error box and the in-place "are you sure?".
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_parts.dart';

// Google's limits (POST_LIMITS in GrowthOS).
class PostsLimits {
  PostsLimits._();
  static const int topic = 150;
  static const int description = 1500;
  static const int offer = 200;
  static const int coupon = 60;
}

// GrowthOS POST_TYPES and POST_CTAS, with GrowthOS's own English labels.
const Map<String, String> postsTypeLabels = {
  'update': 'Update',
  'offer': 'Offer',
  'event': 'Event',
};

const Map<String, String> postsCtaLabels = {
  'book': 'Book',
  'order_online': 'Order online',
  'buy': 'Buy',
  'learn_more': 'Learn more',
  'sign_up': 'Sign up',
  'call': 'Call now',
};

/// Why Google data is not available (GrowthOS GOOGLE_BLOCKS), in plain words.
const Map<String, String> postsGoogleBlockText = {
  'google_not_connected': 'Your Google account is not connected yet.',
  'google_no_location': 'No Google Business Profile is chosen yet.',
  'google_not_configured':
      'Google is not set up on GrowthOS right now. Please try again later.',
  'google_unverified':
      'Your Google profile is not verified yet. This works once Google verifies it.',
};

// Images: PNG, JPEG or WebP up to 5 MB (the HappyWedz server and GrowthOS check again).
const List<String> postsImageTypes = ['image/png', 'image/jpeg', 'image/webp'];
const int postsImageMaxBytes = 5 * 1024 * 1024;

/// Why a picked file can't be sent, or null when it is fine (website imageFileProblem).
Future<String?> postsImageProblem(File? file) async {
  if (file == null) return 'Choose an image.';
  String? type;
  try {
    final head = await file
        .openRead(0, 16)
        .fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
    type = lookupMimeType(file.path, headerBytes: head);
  } catch (_) {
    type = lookupMimeType(file.path);
  }
  if (type == null || !postsImageTypes.contains(type)) {
    return 'Use a PNG, JPEG or WebP image.';
  }
  int size;
  try {
    size = await file.length();
  } catch (_) {
    return 'Choose an image.';
  }
  if (size > postsImageMaxBytes) {
    return 'The image is larger than 5 MB. Choose a smaller one.';
  }
  return null;
}

/// A web address starting with http:// or https://.
bool postsIsHttpUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

/// The server's field messages (validation_error → details.fields), as { path: message }.
Map<String, String> postsFieldErrorsOf(Object? error) {
  if (error is! GpException) return {};
  final details = error.body['details'];
  final fields = details is Map ? details['fields'] : null;
  if (fields is! List) return {};
  final out = <String, String>{};
  for (final f in fields) {
    if (f is! Map || f['message'] is! String) continue;
    final p = f['path'];
    final path = p is List ? p.join('.') : (p is String ? p : null);
    if (path == null || out.containsKey(path)) continue;
    out[path] = f['message'] as String;
  }
  return out;
}

/// Every distinct field message the server sent (shown under the main error line).
List<String> postsFieldMessagesOf(Object? error) =>
    postsFieldErrorsOf(error).values.toSet().toList();

/// "YYYY-MM-DD" of a local date.
String postsDayString(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Local "YYYY-MM-DD" and "HH:MM" of an ISO time (website localParts).
({String date, String time}) postsLocalParts(Object? iso) {
  final s = iso?.toString() ?? '';
  final d = s.isEmpty ? null : DateTime.tryParse(s)?.toLocal();
  if (d == null) return (date: '', time: '');
  return (
    date: postsDayString(d),
    time:
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
  );
}

/// A local date and time → ISO time (null when either is missing or invalid).
String? postsToIsoTime(String date, String time) {
  if (date.isEmpty || time.isEmpty) return null;
  final value = DateTime.tryParse('${date}T$time:00');
  return value?.toUtc().toIso8601String();
}

/// The server's message (and its field messages), in red (website ErrorNote).
class PostsErrorNote extends StatelessWidget {
  final Object? error;
  final String? fallback;
  const PostsErrorNote({super.key, required this.error, this.fallback});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    final details = postsFieldMessagesOf(error);
    final message = gpErrorCode(error) == 'network'
        ? gpNetworkMessage
        : gpErrorMessage(error,
            fallback ?? 'Something went wrong. Please try again.');
    return GpCallout(
      tone: GpTone.bad,
      text: message,
      child: details.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in details)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('• $m',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textPrimary)),
                  ),
              ],
            ),
    );
  }
}

/// "Are you sure?" shown in place (website ConfirmBox): a title, a line,
/// the server's error and the two buttons. [danger] is the website's tone "bad".
class PostsConfirmBox extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmLabel;
  final bool busy;
  final bool danger;
  final Object? error;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PostsConfirmBox({
    super.key,
    required this.title,
    this.message,
    required this.confirmLabel,
    this.busy = false,
    this.danger = false,
    this.error,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: danger ? AppColors.errorTint : AppColors.warningTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: GpStack(gap: 10, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        if (message != null) Text(message!, style: GpText.note),
        if (error != null) PostsErrorNote(error: error),
        GpButtons(children: [
          GpButton(
              label: confirmLabel,
              danger: danger,
              busy: busy,
              small: true,
              onPressed: onConfirm),
          GpButton.ghost(
              label: 'Cancel', small: true, onPressed: busy ? null : onCancel),
        ]),
      ]),
    );
  }
}

/// A labelled date box ("YYYY-MM-DD") that opens the date picker.
class PostsDateField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String>? onChanged;
  final String? error;
  final String? helper;
  final String? min;

  const PostsDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.error,
    this.helper,
    this.min,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final first = (min != null && min!.isNotEmpty)
        ? (DateTime.tryParse(min!) ?? DateTime(now.year - 5))
        : DateTime(now.year - 5);
    var initial = DateTime.tryParse(value) ?? now;
    if (initial.isBefore(first)) initial = first;
    final last = DateTime(now.year + 10, 12, 31);
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) return;
    onChanged?.call(postsDayString(picked));
  }

  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(value);
    final shown = d == null
        ? value
        : '${d.day} ${const [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ][d.month - 1]} ${d.year}';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GpText.label),
      const SizedBox(height: 6),
      InkWell(
        onTap: onChanged == null ? null : () => _pick(context),
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          isEmpty: value.isEmpty,
          decoration: gpInputDecoration(
            hint: 'dd mmm yyyy',
            error: error,
            helper: helper,
            suffixIcon: value.isNotEmpty && onChanged != null
                ? IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onChanged!(''),
                  )
                : const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          child: Text(shown, style: const TextStyle(fontSize: 14)),
        ),
      ),
    ]);
  }
}
