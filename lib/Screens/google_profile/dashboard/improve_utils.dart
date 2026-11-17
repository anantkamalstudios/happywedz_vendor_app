// "Improve with AI" helpers (website dashboard/ImproveUtils.js and
// ImproveParts.jsx): a small loader, the hint for the error codes a vendor can
// act on, the photo categories, what each checklist "need:" means in plain
// words, one numbered step (done / to do / "Start here") and the server's
// error with its hint. Shapes: GrowthOS fixPlanSchema, keywordSchema.
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';

// ── Loading one thing (website useLoad) ───────────────────────────────────

/// Loads one thing when the tab opens: status loading | ready | error, data,
/// error, [reload] (quietly keeps what is shown when it fails) and [setData].
class ImproveLoader extends ChangeNotifier {
  final Future<dynamic> Function() fetcher;

  /// Called with every load error (the tab uses it for PLAN_MODULE_LOCKED).
  void Function(Object error)? onError;

  ImproveLoader(this.fetcher);

  String status = 'loading';
  dynamic data;
  Object? error;
  bool _disposed = false;

  bool get isLoading => status == 'loading';
  bool get isReady => status == 'ready';
  bool get isError => status == 'error';

  Future<dynamic> reload({bool quiet = false}) async {
    if (!quiet) {
      status = 'loading';
      error = null;
      _notify();
    }
    try {
      final next = await fetcher();
      status = 'ready';
      data = next;
      error = null;
      _notify();
      return next;
    } catch (e) {
      if (!(quiet && status == 'ready')) {
        status = 'error';
        error = e;
      }
      _notify();
      onError?.call(e);
      return null;
    }
  }

  void setData(dynamic Function(dynamic current) update) {
    data = update(data);
    status = 'ready';
    error = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

// ── Errors ────────────────────────────────────────────────────────────────

/// An error made here (not from the server): a message and its detail lines.
class ImproveLocalError {
  final String message;
  final List<String> details;
  const ImproveLocalError(this.message, [this.details = const []]);
}

/// A short extra line for the error codes the vendor can do something about.
const Map<String, String> _codeHints = {
  'ai_limit_reached':
      'The AI allowance is used up for now. You can still add these yourself.',
  'ai_unavailable': 'You can still add them yourself below.',
  'feature_disabled': 'This is switched off for your profile right now.',
  'rate_limited': 'Too many tries at once. Please wait a moment and try again.',
  'network': 'Check your internet connection and try again.',
};

String improveErrorHint(Object? error) {
  if (error == null || error is ImproveLocalError) return '';
  return _codeHints[gpErrorCode(error)] ?? '';
}

/// The server's field messages (validation_error → details.fields), each once.
List<String> improveFieldMessages(Object? error) {
  if (error is ImproveLocalError) return error.details;
  if (error is! GpException) return const [];
  final fields = mapOf(error.body['details'])['fields'];
  if (fields is! List) return const [];
  final seenPaths = <String>{};
  final out = <String>[];
  for (final f in fields) {
    if (f is! Map) continue;
    final path = f['path'];
    final message = f['message'];
    if (path is! String || message is! String) continue;
    if (!seenPaths.add(path)) continue;
    if (!out.contains(message)) out.add(message);
  }
  return out;
}

String improveErrorText(Object? error,
    [String fallback = 'Something went wrong. Please try again.']) {
  if (error is ImproveLocalError) return error.message;
  return gpErrorMessage(error, fallback);
}

/// The server's message in red (with its field messages) — website ErrorNote.
class ImproveErrorNote extends StatelessWidget {
  final Object? error;
  final String fallback;
  const ImproveErrorNote(this.error,
      {super.key, this.fallback = 'Something went wrong. Please try again.'});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    final details = improveFieldMessages(error);
    return GpCallout(
      tone: GpTone.bad,
      text: improveErrorText(error, fallback),
      child: details.isEmpty
          ? null
          : GpStack(gap: 2, children: [
              for (final d in details)
                Text('• $d',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary)),
            ]),
    );
  }
}

/// The server's message and, for some codes, what the vendor can do — website ImproveError.
class ImproveError extends StatelessWidget {
  final Object? error;
  final String fallback;
  const ImproveError(this.error,
      {super.key, this.fallback = 'Something went wrong. Please try again.'});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    final hint = improveErrorHint(error);
    return GpStack(gap: 6, children: [
      ImproveErrorNote(error, fallback: fallback),
      if (hint.isNotEmpty) Text(hint, style: GpText.note),
    ]);
  }
}

/// A load failure inside a step: the error and "Try again".
class ImproveLoadFailed extends StatelessWidget {
  final Object? error;
  final String fallback;
  final VoidCallback onRetry;
  const ImproveLoadFailed(
      {super.key,
      required this.error,
      required this.fallback,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GpStack(gap: 10, children: [
      ImproveError(error, fallback: fallback),
      GpButton.ghost(label: 'Try again', icon: Icons.refresh, onPressed: onRetry),
    ]);
  }
}

/// A message with its tone ({ tone, text } on the website).
class ImproveMessage {
  final GpTone tone;
  final String text;
  const ImproveMessage(this.tone, this.text);
}

// ── Lists and fixes ───────────────────────────────────────────────────────

/// A list from a { data, meta } page ([GpPage] or Map) or a plain list.
List<dynamic> improveListOf(Object? value) {
  if (value is List) return value;
  if (value is GpPage) return value.list;
  if (value is Map && value['data'] is List) return value['data'] as List;
  return const [];
}

/// The AI's service ideas, whichever way the answer wraps them.
List<dynamic> improveSuggestionsOf(Object? value) {
  if (value is List) return value;
  if (value is Map) {
    if (value['suggestions'] is List) return value['suggestions'] as List;
    if (value['services'] is List) return value['services'] as List;
  }
  return const [];
}

bool improveIsOpenFix(Object? f) {
  final s = mapOf(f)['status'];
  return s == 'pending_approval' || s == 'escalated';
}

/// Same words, ignoring case and spaces at the ends.
bool improveSame(Object? a, Object? b) =>
    str(a).trim().toLowerCase() == str(b).trim().toLowerCase();

/// Keywords that count towards the 5 needed.
const int keywordsNeeded = 5;
List<dynamic> activeKeywords(List<dynamic> list) =>
    list.where((k) => mapOf(k)['status'] == 'active').toList();

/// At most this many storefront photos go to Google in one go (cover and logo included).
const int photosMax = 10;

/// GrowthOS PHOTO_CATEGORIES with GrowthOS's plain labels (Cover and Logo are picked separately).
const List<List<String>> improvePhotoCategories = [
  ['EXTERIOR', 'Exterior'],
  ['INTERIOR', 'Interior'],
  ['PRODUCT', 'Product'],
  ['AT_WORK', 'At work'],
  ['TEAMS', 'Team'],
  ['FOOD_AND_DRINK', 'Food and drink'],
  ['MENU', 'Menu'],
  ['COMMON_AREA', 'Common area'],
  ['ROOMS', 'Rooms'],
  ['ADDITIONAL', 'Other'],
];
const String defaultPhotoCategory = 'ADDITIONAL';

/// Website ProfileUtils GOOGLE_BLOCK_TEXT.
const Map<String, String> googleBlockText = {
  'google_not_connected': 'Your Google account is not connected yet.',
  'google_no_location': 'No Google Business Profile is chosen yet.',
  'google_not_configured':
      'Google is not set up on GrowthOS right now. Please try again later.',
  'google_unverified':
      'Your Google profile is not verified yet. This works once Google verifies it.',
};

List<dynamic> _checklist(Map<String, dynamic>? plan) =>
    listOf(plan?['checklist']);

/// The fix plan's checklist rows of one kind ("need", "fixed", "ok" …), as their reason keys.
List<String> checklistKeys(Map<String, dynamic>? plan, String kind) {
  final out = <String>[];
  for (final row in _checklist(plan)) {
    final result = mapOf(row)['result'];
    if (result is String && result.startsWith('$kind:')) {
      out.add(result.substring(kind.length + 1));
    }
  }
  return out;
}

/// One thing only the vendor can do, and where it is done (a tab or a step).
class ImproveNeed {
  final String key;
  final String title;
  final String body;
  final String action;
  final String? tab;
  final String? step;
  const ImproveNeed(
      {this.key = '',
      required this.title,
      required this.body,
      required this.action,
      this.tab,
      this.step});

  ImproveNeed withKey(String k) => ImproveNeed(
      key: k, title: title, body: body, action: action, tab: tab, step: step);
}

// agent_on is left out: the AI helper switch at the top covers it.
const Map<String, ImproveNeed> _needWords = {
  'primary_category': ImproveNeed(
    title: 'Choose your main category on Google',
    body:
        'Google needs one main category for your business. Pick it in the Profile tab, under Categories.',
    action: 'Open Profile',
    tab: 'profile',
  ),
  'location_hours': ImproveNeed(
    title: 'Add your opening hours',
    body: 'Your opening hours are missing. Add them in the Profile tab.',
    action: 'Open Profile',
    tab: 'profile',
  ),
  'website': ImproveNeed(
    title: 'Add your website',
    body: 'No website is set for your business. Add it in the Profile tab.',
    action: 'Open Profile',
    tab: 'profile',
  ),
  'attribute_facts': ImproveNeed(
    title: "Answer Google's questions about your business",
    body:
        'Google asks things like payment options and wheelchair access. Answer them in the Profile tab, under Attributes.',
    action: 'Open Profile',
    tab: 'profile',
  ),
  'services': ImproveNeed(
    title: 'Add your services',
    body: 'The AI needs your services before it can list them on Google.',
    action: 'Go to Services',
    step: 'services',
  ),
  'keywords': ImproveNeed(
    title: 'Add keywords',
    body: 'The AI uses your keywords in your description and posts.',
    action: 'Go to Keywords',
    step: 'keywords',
  ),
  'logo': ImproveNeed(
    title: 'Pick your logo',
    body: 'Choose your logo from your storefront photos.',
    action: 'Go to Photos',
    step: 'photos',
  ),
  'cover': ImproveNeed(
    title: 'Pick your cover photo',
    body: 'Choose a cover photo from your storefront photos.',
    action: 'Go to Photos',
    step: 'photos',
  ),
  'library_photos': ImproveNeed(
    title: 'Add real photos of your business',
    body:
        'Pick photos from your storefront to send to Google. AI never makes fake photos.',
    action: 'Go to Photos',
    step: 'photos',
  ),
};

const Map<String, String> _fixedWords = {
  'primary_category': 'Main category',
  'location_hours': 'Opening hours',
  'website': 'Website',
  'attribute_facts': "Google's questions",
  'services': 'Services',
  'keywords': 'Keywords',
  'logo': 'Logo',
  'cover': 'Cover photo',
  'library_photos': 'Photos',
};

class ImproveNeeds {
  final List<ImproveNeed> needs;
  final List<String> fixed;
  const ImproveNeeds(this.needs, this.fixed);
}

/// What only the vendor can do, from the fix plan: the checklist's need: rows,
/// low-rated reviews, review replies that wait to be published, and photos.
/// Plus what was fixed since the check.
ImproveNeeds vendorNeeds(Map<String, dynamic>? plan) {
  if (plan == null) return const ImproveNeeds([], []);
  final seen = <String>{};
  final needs = <ImproveNeed>[];
  void add(String key, ImproveNeed item) {
    if (!seen.add(key)) return;
    needs.add(item.withKey(key));
  }

  for (final reason in checklistKeys(plan, 'need')) {
    final words = _needWords[reason];
    if (words == null) continue;
    // Logo, cover and library photos are all picked in the Photos step.
    add(words.step == 'photos' ? 'photos' : reason, words);
  }
  for (final raw in listOf(plan['needs_you'])) {
    final n = mapOf(raw);
    final count = numOf(n['count'])?.toInt() ?? 0;
    if (n['key'] == 'photos') {
      add(
          'photos',
          ImproveNeed(
            title:
                'Add $count real ${count == 1 ? 'photo' : 'photos'} of your business',
            body:
                'Profiles with 10 or more photos look trusted. AI never makes fake photos.',
            action: 'Go to Photos',
            step: 'photos',
          ));
    } else if (n['key'] == 'low_reviews') {
      add(
          'low_reviews',
          ImproveNeed(
            title:
                '$count low-rated ${count == 1 ? 'review waits' : 'reviews wait'} for your reply',
            body:
                'Replies to 1–3★ reviews always need you. The AI prepares a draft you can use.',
            action: 'Open Reviews',
            tab: 'reviews',
          ));
    }
  }
  final replies =
      listOf(plan['reviews']).where((r) => mapOf(r)['blocked'] != true).length;
  if (replies > 0) {
    add(
        'replies',
        ImproveNeed(
          title:
              '$replies ${replies == 1 ? 'reply is' : 'replies are'} ready for 4–5★ reviews',
          body: 'The AI drafted them. Check each reply and publish it in Reviews.',
          action: 'Open Reviews',
          tab: 'reviews',
        ));
  }
  final fixed = <String>[];
  for (final reason in checklistKeys(plan, 'fixed')) {
    final w = _fixedWords[reason];
    if (w != null && !fixed.contains(w)) fixed.add(w);
  }
  return ImproveNeeds(needs, fixed);
}

// ── One numbered step (website ImproveStep) ───────────────────────────────

/// One next step. The heading opens or closes the step; the body stays
/// mounted while closed, so ticks and typed text are kept. [state] is "done",
/// "todo" or "unknown" (still loading); [current] marks "Start here".
class ImproveStep extends StatelessWidget {
  final int number;
  final int total;
  final String title;
  final String state;
  final bool current;
  final bool open;
  final VoidCallback onToggle;
  final String summary;
  final Widget child;

  const ImproveStep({
    super.key,
    required this.number,
    required this.total,
    required this.title,
    required this.state,
    required this.current,
    required this.open,
    required this.onToggle,
    required this.summary,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final done = state == 'done';
    final stateText = done ? 'Done' : (state == 'unknown' ? 'Checking' : 'To do');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: current ? AppColors.accentPink : AppColors.border,
          width: current ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          button: true,
          expanded: open,
          label:
              'Step $number of $total: $title ($stateText${current ? ', start here' : ''})',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? AppColors.success
                        : (current ? AppColors.accentPink : AppColors.primaryTint),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text('$number',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: current ? Colors.white : AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GpStack(gap: 6, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: done
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary)),
                    ),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      if (current)
                        const GpChip('Start here', color: AppColors.accentPink),
                      done
                          ? GpChip(stateText, tone: GpTone.ok)
                          : GpChip(stateText, color: AppColors.textSecondary),
                    ]),
                  ]),
                ),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(50, 2, 12, 12),
          child: summary.isEmpty
              ? const SizedBox.shrink()
              : Text(summary, style: GpText.note),
        ),
        Visibility(
          visible: open,
          maintainState: true,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: child,
          ),
        ),
      ]),
    );
  }
}

/// An empty box with an icon, title and line (website EmptyBox).
class ImproveEmptyBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? text;
  const ImproveEmptyBox(
      {super.key, required this.icon, required this.title, this.text});

  @override
  Widget build(BuildContext context) =>
      GpEmpty(icon: icon, title: title, message: text);
}

/// The light-blue box around AI ideas (website `.gp-e-ai-box`).
class ImproveAiBox extends StatelessWidget {
  final String? label;
  final List<Widget?> children;
  const ImproveAiBox({super.key, this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primarySurface),
      ),
      child: GpStack(gap: 10, children: [
        if (label != null) Text(label!, style: GpText.label),
        ...children,
      ]),
    );
  }
}
