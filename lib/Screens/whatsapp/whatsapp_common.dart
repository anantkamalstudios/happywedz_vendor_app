import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/plan_module_lock.dart';
import '../../widgets/plan_feature_guard.dart';
import '../crm/crm_widgets.dart';

/// Shared pieces of the WhatsApp workspace — a port of the website's
/// `WhatsAppWorkspace.jsx` helpers, in the app's theme.

/// What each tab last had, kept while the app is running.
///
/// Every tab rebuilds from nothing when it is left and come back to, so the
/// last answer is shown at once and the fetch happens behind it — exactly the
/// website's `lastSeen`. Deliberately not persisted anywhere: it is worth one
/// session, and stale WhatsApp data is worse than none.
class WaLastSeen {
  WaLastSeen._();

  static List? templates;
  static String? wordingReport;
  static List? campaigns;
  static List? threads;

  /// After a disconnect nothing cached belongs to the account any more.
  static void clear() {
    templates = null;
    wordingReport = null;
    campaigns = null;
    threads = null;
  }
}

/// The message the server sent, otherwise [fallback] (the web's `errorMessage`).
String waErrorMessage(Object e, String fallback) =>
    e is CrmException ? e.message : fallback;

/// Handles a failed call: a plan lock opens the locked page and returns null;
/// anything else returns the line to show.
String? waHandleError(
  BuildContext context,
  WidgetRef ref,
  Object e,
  String fallback,
) {
  if (e is PlanModuleLockedException) {
    showPlanModuleLocked(
      context,
      ref,
      module: e.module.isEmpty ? 'crm' : e.module,
      message: e.message,
    );
    return null;
  }
  return waErrorMessage(e, fallback);
}

void waToast(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

// ---------------------------------------------------------------- language

/// Meta's language codes in the words a vendor uses. Anything else keeps its
/// code, which is better than guessing at a name.
const _languageNames = {
  'en': 'English',
  'en_US': 'English',
  'en_GB': 'English',
  'hi': 'Hindi',
  'mr': 'Marathi',
  'gu': 'Gujarati',
  'ta': 'Tamil',
  'te': 'Telugu',
  'kn': 'Kannada',
  'ml': 'Malayalam',
  'bn': 'Bengali',
  'pa': 'Punjabi',
};

String waLanguageName(dynamic code) {
  final c = '${code ?? ''}';
  if (c.isEmpty) return '—';
  return _languageNames[c] ?? _languageNames[c.split('_').first] ?? c;
}

// ------------------------------------------------------------------- dates

DateTime? waParse(dynamic v) =>
    v == null ? null : DateTime.tryParse('$v')?.toLocal();

/// 7:48 pm — the time alone, because the day is a divider above it.
String waTimeOf(dynamic v) {
  final d = v is DateTime ? v : waParse(v);
  return d == null ? '' : DateFormat('h:mm a').format(d).toLowerCase();
}

/// 18 Nov — the day divider.
String waDayOf(dynamic v) {
  final d = v is DateTime ? v : waParse(v);
  return d == null ? '' : DateFormat('d MMM').format(d);
}

/// In a list: the time today, the date before that.
String waShortWhen(dynamic v) {
  final d = waParse(v);
  if (d == null) return '';
  final now = DateTime.now();
  final today = d.year == now.year && d.month == now.month && d.day == now.day;
  return today ? waTimeOf(d) : waDayOf(d);
}

/// 18 Nov 2026, 7:48 pm — or a dash.
String waWhen(dynamic v) {
  final d = waParse(v);
  return d == null
      ? '—'
      : '${DateFormat('d MMM yyyy').format(d)}, ${waTimeOf(d)}';
}

// ------------------------------------------------------------------ status

/// The website's tones mapped onto the app's: green → success, blue → info,
/// amber → warning, grey → tertiary text, red → error.
enum WaTone { green, blue, amber, grey, red }

const _statusTone = {
  'completed': WaTone.green,
  'delivered': WaTone.green,
  'read': WaTone.green,
  'received': WaTone.blue,
  'lead': WaTone.amber,
  'customer': WaTone.green,
  'draft': WaTone.grey,
  'queued': WaTone.blue,
  'processing': WaTone.blue,
  'paused': WaTone.amber,
  'cancelled': WaTone.grey,
  'sending': WaTone.blue,
  'scheduled': WaTone.amber,
  'approved': WaTone.green,
  'pending': WaTone.amber,
  'rejected': WaTone.red,
  'sent': WaTone.green,
  'failed': WaTone.red,
};

(Color, Color) waToneColors(WaTone? tone) => switch (tone) {
  WaTone.green => (AppColors.success, AppColors.successTint),
  WaTone.blue => (AppColors.info, AppColors.infoTint),
  WaTone.amber => (AppColors.warning, AppColors.warningTint),
  WaTone.red => (AppColors.error, AppColors.errorTint),
  WaTone.grey || null => (AppColors.textTertiary, AppColors.inputFill),
};

/// A status pill in the website's tone for [status].
class WaStatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const WaStatusBadge(this.status, {super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = waToneColors(_statusTone[status]);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 7 : 9, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.isEmpty ? '—' : status,
        style: TextStyle(
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

/// A grey label chip ("Managed in Wapzio", a template's category …).
class WaChip extends StatelessWidget {
  final String text;
  const WaChip(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
    ),
  );
}

// --------------------------------------------------------------- templates

/// Approved templates, one per name: the send APIs take a name and no
/// language, so listing a name twice gave two options that could not be told
/// apart.
List<Map> waUniqueByName(Iterable templates) {
  final seen = <String, Map>{};
  for (final t in templates) {
    if (t is Map) seen.putIfAbsent('${t['name']}', () => t);
  }
  return seen.values.toList();
}

List<Map> waApproved(Iterable templates) =>
    templates.whereType<Map>().where((t) => t['status'] == 'approved').toList();

int waVariableCount(Map? t) => ((t?['variableCount'] as num?) ?? 0).toInt();

// ------------------------------------------------------------------ window

/// The 24-hour rule as a sentence, so it is shown rather than discovered by a
/// message bouncing.
String? waWindowLine(Map? w) {
  if (w == null) return null;
  final closesAt = waParse(w['closesAt']);
  if (closesAt == null) {
    return 'They have never written to you, so only a template can be sent.';
  }
  if (w['open'] != true) {
    return 'More than 24 hours since they wrote, so only a template can be sent.';
  }
  final now = DateTime.now();
  final tomorrow =
      closesAt.year != now.year ||
      closesAt.month != now.month ||
      closesAt.day != now.day;
  return 'You can write freely until ${waTimeOf(closesAt)}${tomorrow ? ' tomorrow' : ''}.';
}

/// A tick for each thing WhatsApp reports about a message we sent.
const waTick = {
  'queued': '· sending',
  'sent': '✓ sent',
  'delivered': '✓✓ delivered',
  'read': '✓✓ read',
  'failed': '✕ failed',
};

// ---------------------------------------------------------- shared widgets

/// The web's red error line.
class WaErrorBox extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;

  const WaErrorBox(this.text, {super.key, this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
    decoration: BoxDecoration(
      color: AppColors.errorTint,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, size: 18, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}

/// A muted line of help under or above something.
class WaHint extends StatelessWidget {
  final String text;
  final Color color;
  const WaHint(this.text, {super.key, this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: AppTextStyles.caption.copyWith(color: color)),
  );
}

/// A centred empty state that still pulls to refresh.
class WaEmpty extends StatelessWidget {
  final String text;
  final IconData icon;
  const WaEmpty(this.text, {super.key, this.icon = Icons.chat_bubble_outline});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
    child: Column(
      children: [
        Icon(icon, size: 40, color: AppColors.textTertiary),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      ],
    ),
  );
}

/// A row of filter chips (All / Unread, status filters …).
class WaFilterChips extends StatelessWidget {
  final List<(String, String)> options; // (key, label)
  final String selected;
  final ValueChanged<String> onSelected;

  const WaFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final o in options)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(o.$2),
              selected: selected == o.$1,
              onSelected: (_) => onSelected(o.$1),
              selectedColor: AppColors.primaryTint,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: selected == o.$1 ? AppColors.primary : AppColors.border,
              ),
              labelStyle: TextStyle(
                fontSize: 13,
                color: selected == o.$1
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: selected == o.$1
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              showCheckmark: false,
            ),
          ),
      ],
    ),
  );
}

/// Previous / Next under a paged list.
class WaPager extends StatelessWidget {
  final int page;
  final int pages;
  final String summary;
  final ValueChanged<int> onPage;
  final bool busy;

  const WaPager({
    super.key,
    required this.page,
    required this.pages,
    required this.summary,
    required this.onPage,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Expanded(child: Text(summary, style: AppTextStyles.caption)),
        OutlinedButton(
          onPressed: busy || page <= 1 ? null : () => onPage(page - 1),
          child: const Text('Previous'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: busy || page >= pages ? null : () => onPage(page + 1),
          child: const Text('Next'),
        ),
      ],
    ),
  );
}

/// The round initial used in chat lists and headers.
class WaAvatar extends StatelessWidget {
  final String name;
  final double size;
  const WaAvatar(this.name, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final t = name.trim();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primaryTint,
      child: Text(
        t.isEmpty ? '?' : t[0].toUpperCase(),
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- template bubble

/// A template as the client will see it, values dropped into their places as
/// they are typed. A slot still empty keeps its {{n}} and is marked, because
/// a blank gap in a sentence reads as finished.
class WaTemplateBubble extends StatelessWidget {
  final Map? template;
  final Map<String, String> values;

  /// The client's own name, used for `{name}` (as in a broadcast).
  final String? name;

  const WaTemplateBubble({
    super.key,
    required this.template,
    this.values = const {},
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    final t = template;
    final body = '${t?['body'] ?? ''}';
    final spans = <InlineSpan>[];
    if (body.isNotEmpty) {
      final re = RegExp(r'\{\{\s*(\d+)\s*\}\}');
      var last = 0;
      for (final m in re.allMatches(body)) {
        if (m.start > last) {
          spans.add(TextSpan(text: body.substring(last, m.start)));
        }
        final n = m.group(1)!;
        final typed = (values[n] ?? '').replaceAll(
          RegExp(r'\{name\}', caseSensitive: false),
          name ?? 'their name',
        );
        spans.add(
          typed.trim().isNotEmpty
              ? TextSpan(
                  text: typed,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                )
              : TextSpan(
                  text: '{{$n}}',
                  style: const TextStyle(
                    color: AppColors.warning,
                    backgroundColor: AppColors.warningTint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        );
        last = m.end;
      }
      if (last < body.length) spans.add(TextSpan(text: body.substring(last)));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.listBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(
              children: [
                CircleAvatar(radius: 12, backgroundColor: Colors.white24),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your business',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'WhatsApp Business',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: t == null
                ? const Text(
                    'Choose a template to see it here.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ('${t['header'] ?? ''}'.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${t['header']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (body.isNotEmpty)
                            Text.rich(
                              TextSpan(
                                children: spans,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            )
                          else
                            const Text(
                              "Wapzio did not return this template's wording, so we "
                              'cannot show it. The message still sends correctly.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          if ('${t['footer'] ?? ''}'.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${t['footer']}',
                                style: AppTextStyles.caption,
                              ),
                            ),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'now',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------- template fields

/// Which template is chosen and the values typed for it, shared by the chat
/// composer, a client's page and a broadcast.
class WaTemplateDraft extends ChangeNotifier {
  /// Put into {{1}} whenever a template is chosen. {{1}} is the client's name
  /// in almost every template, so it goes in as a real value that can be seen
  /// and changed (a client's page passes their name).
  final String? firstValue;

  WaTemplateDraft({this.firstValue});

  String name = '';
  final Map<int, TextEditingController> _controllers = {};

  TextEditingController controller(int n) => _controllers.putIfAbsent(
    n,
    () => TextEditingController()..addListener(notifyListeners),
  );

  void choose(String value) {
    name = value;
    for (final c in _controllers.values) {
      c.clear();
    }
    final first = firstValue ?? '';
    if (value.isNotEmpty && first.isNotEmpty) controller(1).text = first;
    notifyListeners();
  }

  void reset() => choose('');

  /// `{"1": …, "2": …}` — the shape the server takes.
  Map<String, String> get values => {
    for (final e in _controllers.entries)
      if (e.value.text.isNotEmpty) '${e.key}': e.value.text,
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}

/// The template dropdown, its wording, and a box per value it takes. Where
/// the count is unknown (a template made outside HappyWedz) three boxes and a
/// word about why.
class WaTemplateFields extends StatelessWidget {
  final List<Map> templates; // approved, unique by name
  final WaTemplateDraft draft;
  final bool showBody;
  final String unknownHint;
  final String emptyText;

  const WaTemplateFields({
    super.key,
    required this.templates,
    required this.draft,
    this.showBody = true,
    this.unknownHint =
        "Wapzio did not return this template's wording, so we cannot show how many "
        'values it takes. Fill in the ones it uses and leave the rest blank.',
    this.emptyText =
        'You have no approved templates yet. Meta has to approve a template '
        'before it can be sent.',
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        if (templates.isEmpty) return WaHint(emptyText);
        final chosen = templates
            .where((t) => t['name'] == draft.name)
            .cast<Map?>()
            .firstWhere((_) => true, orElse: () => null);
        final count = waVariableCount(chosen);
        final slots = count > 0
            ? List.generate(count, (i) => i + 1)
            : draft.name.isNotEmpty
            ? const [1, 2, 3]
            : const <int>[];
        final options = {
          '': 'Choose an approved template',
          for (final t in templates) '${t['name']}': '${t['name']}',
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CrmDropdown(
              value: draft.name,
              options: options,
              onChanged: draft.choose,
            ),
            const SizedBox(height: 8),
            if (showBody && '${chosen?['body'] ?? ''}'.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${chosen!['body']}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            for (final n in slots)
              CrmField(
                label: '{{$n}}',
                // No placeholder: grey text in an empty box reads as filled.
                child: CrmTextInput(controller: draft.controller(n)),
              ),
            if (draft.name.isNotEmpty && count == 0) WaHint(unknownHint),
          ],
        );
      },
    );
  }
}
