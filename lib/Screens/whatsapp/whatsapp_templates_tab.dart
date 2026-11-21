import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_shimmer.dart';
import '../crm/crm_widgets.dart';
import 'whatsapp_common.dart';
import 'whatsapp_template_form_screen.dart';

/// Templates: what the account holds and where Meta's approval stands.
///
/// Templates are normally written and approved in Wapzio and HappyWedz shows
/// and sends them. The app also offers what the API allows beyond the
/// website's screen: submitting a new one for approval, and copying a
/// template's wording across so its preview works.
class WhatsAppTemplatesTab extends ConsumerStatefulWidget {
  const WhatsAppTemplatesTab({super.key});

  @override
  ConsumerState<WhatsAppTemplatesTab> createState() =>
      _WhatsAppTemplatesTabState();
}

class _WhatsAppTemplatesTabState extends ConsumerState<WhatsAppTemplatesTab> {
  final _api = CrmApi();
  List _templates = WaLastSeen.templates ?? const [];
  String _wordingReport = WaLastSeen.wordingReport ?? '';
  bool _loading = WaLastSeen.templates == null;
  String _error = '';
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // A spinner only the first time; a refresh behind content on screen is
    // better than replacing it.
    setState(() {
      _loading = WaLastSeen.templates == null;
      _error = '';
    });
    try {
      final list = await _api.whatsappTemplates();
      if (!mounted) return;
      final templates = List.from(list['templates'] ?? const []);
      WaLastSeen.templates = templates;
      WaLastSeen.wordingReport = '${list['wordingReport'] ?? ''}';
      setState(() {
        _templates = templates;
        _wordingReport = WaLastSeen.wordingReport!;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = waHandleError(
        context,
        ref,
        e,
        'Could not read your templates.',
      );
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Map? wordingFor}) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => wordingFor == null
            ? const WhatsAppTemplateFormScreen()
            : WhatsAppTemplateFormScreen.wording(template: wordingFor),
      ),
    );
    if (!mounted || result == null) return;
    if (result.isNotEmpty) waToast(context, result);
    _load();
  }

  void _view(Map t) {
    final count = waVariableCount(t);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${t['name']}', style: AppTextStyles.h3),
              const SizedBox(height: 4),
              Text(
                '${waLanguageName(t['language'])} · '
                '${'${t['category'] ?? '—'}'.toLowerCase()} · '
                '${count > 0 ? '$count ${count == 1 ? 'value' : 'values'} to fill in' : 'no values to fill in'}',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              WaTemplateBubble(template: t),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _openForm(wordingFor: t);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit wording'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{'all': _templates.length};
    for (final t in _templates.whereType<Map>()) {
      counts['${t['status']}'] = (counts['${t['status']}'] ?? 0) + 1;
    }
    final shown = _filter == 'all'
        ? _templates.whereType<Map>().toList()
        : _templates
              .whereType<Map>()
              .where((t) => t['status'] == _filter)
              .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'wa-new-template',
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New template'),
      ),
      body: _loading
          ? const ListShimmer(showAvatar: false, itemHeight: 120)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  if (_error.isNotEmpty) WaErrorBox(_error, onRetry: _load),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: crmCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const WaChip('Managed in Wapzio'),
                        const SizedBox(height: 6),
                        const Text(
                          'Templates are created and approved in Wapzio. HappyWedz shows them '
                          'here and sends them. A template you submit here goes to Meta for '
                          'approval the same way.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Refresh from Wapzio'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_wordingReport.isNotEmpty)
                    CrmNotice(
                      'The message text could not be read from Wapzio, so previews are '
                      'empty. Sending is unaffected.\n$_wordingReport',
                    ),
                  if (_templates.length > 6)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: WaFilterChips(
                        options: [
                          for (final f in const [
                            ('all', 'All'),
                            ('approved', 'Approved'),
                            ('pending', 'Pending'),
                            ('rejected', 'Rejected'),
                          ])
                            (f.$1, '${f.$2} (${counts[f.$1] ?? 0})'),
                        ],
                        selected: _filter,
                        onSelected: (f) => setState(() => _filter = f),
                      ),
                    ),
                  if (_templates.isEmpty)
                    const WaEmpty(
                      'No templates on this account yet.',
                      icon: Icons.description_outlined,
                    )
                  else if (shown.isEmpty)
                    WaEmpty(
                      'Nothing ${_filter == 'all' ? 'here' : 'is $_filter'} right now.',
                      icon: Icons.filter_alt_off_outlined,
                    )
                  else
                    for (final t in shown) _card(t),
                ],
              ),
            ),
    );
  }

  Widget _card(Map t) {
    final body = '${t['body'] ?? ''}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: crmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${t['name']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              WaStatusBadge('${t['status'] ?? ''}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body.isNotEmpty
                ? body
                : "Wapzio did not return this one's wording.",
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: body.isNotEmpty
                  ? AppColors.textPrimary
                  : AppColors.textTertiary,
              fontStyle: body.isNotEmpty ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          if (t['status'] == 'pending')
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Waiting on Meta${'${t['submittedBy'] ?? ''}'.isNotEmpty ? ' · submitted by ${t['submittedBy']}' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.warning),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              WaChip('${t['category'] ?? '—'}'.toLowerCase()),
              const SizedBox(width: 8),
              Text(waLanguageName(t['language']), style: AppTextStyles.caption),
              const Spacer(),
              if (body.isEmpty)
                TextButton(
                  onPressed: () => _openForm(wordingFor: t),
                  child: const Text('Add wording'),
                ),
              TextButton(
                onPressed: body.isEmpty ? null : () => _view(t),
                child: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
