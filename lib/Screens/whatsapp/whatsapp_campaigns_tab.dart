import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_shimmer.dart';
import '../crm/crm_widgets.dart';
import 'whatsapp_broadcast_screen.dart';
import 'whatsapp_common.dart';

/// Broadcasts: one approved template to many clients at once.
class WhatsAppCampaignsTab extends ConsumerStatefulWidget {
  const WhatsAppCampaignsTab({super.key});

  @override
  ConsumerState<WhatsAppCampaignsTab> createState() =>
      _WhatsAppCampaignsTabState();
}

class _WhatsAppCampaignsTabState extends ConsumerState<WhatsAppCampaignsTab> {
  final _api = CrmApi();
  List _campaigns = WaLastSeen.campaigns ?? const [];
  List<Map> _templates = const [];
  bool _loading = WaLastSeen.campaigns == null;
  String _error = '';
  String _notice = '';
  Timer? _poll;

  /// Something is still going out, so the numbers need to keep moving.
  bool get _working => _campaigns.whereType<Map>().any(
    (c) => c['status'] == 'queued' || c['status'] == 'sending',
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = WaLastSeen.campaigns == null;
      _error = '';
    });
    try {
      final results = await Future.wait([
        _api.whatsappCampaigns().catchError(
          (_) => <String, dynamic>{'campaigns': []},
        ),
        _api.whatsappTemplates(),
      ]);
      if (!mounted) return;
      final campaigns = List.from(results[0]['campaigns'] ?? const []);
      WaLastSeen.campaigns = campaigns;
      setState(() {
        _campaigns = campaigns;
        // Only an approved template can be broadcast, so the rest are not
        // offered — choosing one that cannot send is a wasted journey.
        _templates = waApproved(List.from(results[1]['templates'] ?? const []));
      });
    } catch (e) {
      if (!mounted) return;
      final msg = waHandleError(
        context,
        ref,
        e,
        'Could not load your campaigns.',
      );
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    _syncPoll();
  }

  /// A broadcast goes one message at a time, so "3 of 180" changes while the
  /// vendor watches. Refreshed quietly every few seconds while anything is
  /// queued or sending.
  void _syncPoll() {
    if (!mounted) return;
    if (_working && _poll == null) {
      _poll = Timer.periodic(const Duration(seconds: 4), (_) async {
        try {
          final r = await _api.whatsappCampaigns();
          if (!mounted) return;
          final campaigns = List.from(r['campaigns'] ?? const []);
          WaLastSeen.campaigns = campaigns;
          setState(() => _campaigns = campaigns);
          if (!_working) {
            _poll?.cancel();
            _poll = null;
          }
        } catch (_) {}
      });
    } else if (!_working) {
      _poll?.cancel();
      _poll = null;
    }
  }

  Future<void> _compose() async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => WhatsAppBroadcastScreen(templates: _templates),
      ),
    );
    if (!mounted || message == null) return;
    setState(() => _notice = message);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              heroTag: 'wa-new-broadcast',
              onPressed: _compose,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('New broadcast'),
            ),
      body: _loading
          ? const ListShimmer(showAvatar: false, itemHeight: 84)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  if (_error.isNotEmpty) WaErrorBox(_error, onRetry: _load),
                  if (_notice.isNotEmpty) CrmNotice(_notice, warn: false),
                  if (_campaigns.isEmpty)
                    const WaEmpty(
                      'No broadcasts yet.',
                      icon: Icons.campaign_outlined,
                    )
                  else
                    for (final c in _campaigns.whereType<Map>()) _row(c),
                ],
              ),
            ),
    );
  }

  Widget _row(Map c) {
    final ours = c['source'] == 'happywedz';
    final sent = c['sent'];
    final recipients = c['recipients'];
    final failed = ((c['failed'] as num?) ?? 0).toInt();
    final String count;
    if (ours) {
      count =
          '${sent ?? 0}${recipients != null && '$recipients' != '0' ? ' of $recipients' : ''}';
    } else {
      // Wapzio reports no count for its own campaigns. "—" reads as missing
      // data; "not reported" is the fact.
      count = recipients == null ? 'not reported' : '$recipients';
    }

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
                child: Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${c['name'] ?? '—'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (c['source'] == 'wapzio') const WaChip('Wapzio'),
                  ],
                ),
              ),
              WaStatusBadge('${c['status'] ?? ''}'),
            ],
          ),
          if ('${c['error'] ?? ''}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${c['error']}',
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                count,
                style: AppTextStyles.caption.copyWith(
                  fontStyle: !ours && recipients == null
                      ? FontStyle.italic
                      : null,
                ),
              ),
              if (ours && failed > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '· $failed failed',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ],
              const Spacer(),
              Text(
                waWhen(c['scheduledAt'] ?? c['sentAt'] ?? c['createdAt']),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
