import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_shimmer.dart';
import '../crm/crm_widgets.dart';
import 'whatsapp_common.dart';

/// Sent: messages sent to one client at a time. Broadcasts live on their own
/// tab.
class WhatsAppHistoryTab extends ConsumerStatefulWidget {
  const WhatsAppHistoryTab({super.key});

  @override
  ConsumerState<WhatsAppHistoryTab> createState() => _WhatsAppHistoryTabState();
}

class _WhatsAppHistoryTabState extends ConsumerState<WhatsAppHistoryTab> {
  final _api = CrmApi();
  String _status = '';
  int _page = 1;
  Map? _meta;
  List _rows = const [];
  bool _loading = true;
  String _error = '';
  int _seq = 0;

  static const _kindLabel = {
    'quotation': 'Quotation',
    'invoice': 'Invoice',
    'receipt': 'Receipt',
    'reply': 'Message',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final r = await _api.whatsappHistory(
        page: _page,
        limit: 25,
        status: _status,
      );
      if (!mounted || seq != _seq) return;
      setState(() {
        _rows = List.from(r['messages'] ?? const []);
        _meta = r;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      final msg = waHandleError(
        context,
        ref,
        e,
        'Could not read your WhatsApp history.',
      );
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = ((_meta?['totalPages'] as num?) ?? 1).toInt();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const WaHint(
            'Messages you sent to one client at a time. Broadcasts are not listed here — '
            'they are campaigns, and they live on the Broadcasts tab. Client replies are on '
            'the Chats tab.',
          ),
          WaFilterChips(
            options: const [
              ('', 'All'),
              ('sent', 'Delivered to WhatsApp'),
              ('failed', 'Failed'),
            ],
            selected: _status,
            onSelected: (s) {
              _status = s;
              _page = 1;
              _load();
            },
          ),
          const SizedBox(height: 12),
          if (_error.isNotEmpty) WaErrorBox(_error, onRetry: _load),
          if (_loading)
            const SizedBox(
              height: 400,
              child: ListShimmer(
                showAvatar: false,
                itemHeight: 76,
                padding: EdgeInsets.zero,
              ),
            )
          else if (_rows.isEmpty)
            WaEmpty(
              _status == 'failed'
                  ? 'Nothing has failed.'
                  : _status == 'sent'
                  ? 'Nothing delivered yet.'
                  : 'Nothing sent yet.',
              icon: Icons.history,
            )
          else ...[
            for (final m in _rows.whereType<Map>()) _row(m),
            if (pages > 1)
              WaPager(
                page: ((_meta?['page'] as num?) ?? _page).toInt(),
                pages: pages,
                summary:
                    'Page ${_meta?['page'] ?? _page} of $pages · ${_meta?['total'] ?? ''} messages',
                onPage: (n) {
                  _page = n;
                  _load();
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(Map m) {
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
                  _kindLabel[m['kind']] ?? '${m['kind'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              WaStatusBadge('${m['status'] ?? ''}', small: true),
            ],
          ),
          if ('${m['template'] ?? ''}'.isNotEmpty)
            Text('${m['template']}', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          // The same two lines in every row: who, then the number under it.
          Text(
            '${m['client'] ?? ''}'.isNotEmpty
                ? '${m['client']}'
                : 'Not a client yet',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text('${m['to'] ?? ''}', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sent by ${'${m['sentBy'] ?? ''}'.isNotEmpty ? m['sentBy'] : '—'}',
                  style: AppTextStyles.caption,
                ),
              ),
              Text(waWhen(m['at']), style: AppTextStyles.caption),
            ],
          ),
          if ('${m['error'] ?? ''}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${m['error']}',
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}
