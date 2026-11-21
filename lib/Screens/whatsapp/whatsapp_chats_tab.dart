import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_shimmer.dart';
import '../crm/crm_widgets.dart';
import 'whatsapp_common.dart';
import 'whatsapp_thread_screen.dart';

/// What clients have said, beside what was sent them: every conversation,
/// newest first. A conversation opens as its own screen (on the website it is
/// a panel beside the list).
class WhatsAppChatsTab extends ConsumerStatefulWidget {
  /// Opens the connection screen (the empty state points there).
  final VoidCallback onOpenSettings;

  const WhatsAppChatsTab({super.key, required this.onOpenSettings});

  @override
  ConsumerState<WhatsAppChatsTab> createState() => _WhatsAppChatsTabState();
}

class _WhatsAppChatsTabState extends ConsumerState<WhatsAppChatsTab> {
  final _api = CrmApi();
  final _search = TextEditingController();
  List _threads = WaLastSeen.threads ?? const [];
  bool _loading = WaLastSeen.threads == null;
  String _error = '';
  bool _unreadOnly = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
    // Messages arrive by webhook, not by anything done here, so the list
    // looks for itself. Quietly: a failed poll must not throw an error over
    // what the vendor is reading.
    _poll = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _load(quiet: true),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _error = '');
    try {
      final data = await _api.whatsappConversations();
      if (!mounted) return;
      final threads = List.from(data['conversations'] ?? const []);
      WaLastSeen.threads = threads;
      setState(() => _threads = threads);
    } catch (e) {
      if (!mounted || quiet) return;
      final msg = waHandleError(
        context,
        ref,
        e,
        'Could not read your conversations.',
      );
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Map t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WhatsAppThreadScreen(
          conversationKey: '${t['key']}',
          title: '${t['name'] ?? t['number'] ?? ''}',
        ),
      ),
    );
    if (!mounted) return;
    _load(quiet: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ListShimmer(itemHeight: 72);

    final term = _search.text.trim().toLowerCase();
    final shown = _threads.whereType<Map>().where((t) {
      if (_unreadOnly && ((t['unread'] as num?) ?? 0) == 0) return false;
      if (term.isEmpty) return true;
      return '${t['name'] ?? ''} ${t['number'] ?? ''}'.toLowerCase().contains(
        term,
      );
    }).toList();
    final unreadTotal = _threads.whereType<Map>().fold<int>(
      0,
      (n, t) => n + ((t['unread'] as num?) ?? 0).toInt(),
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (_error.isNotEmpty) WaErrorBox(_error, onRetry: _load),
          if (_threads.isEmpty) ...[
            const WaEmpty(
              'No conversations yet. They appear here as soon as a client writes to your '
              'WhatsApp number. If you have been getting replies in Wapzio and nothing shows '
              'here, check the WhatsApp connection, under Replies and delivery reports.',
              icon: Icons.forum_outlined,
            ),
            Center(
              child: OutlinedButton.icon(
                onPressed: widget.onOpenSettings,
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('WhatsApp connection'),
              ),
            ),
          ] else ...[
            TextField(
              controller: _search,
              decoration: crmInputDecoration(
                hint: 'Search by name or number',
                suffix: const Icon(Icons.search, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            WaFilterChips(
              options: [
                ('all', 'All'),
                (
                  'unread',
                  unreadTotal > 0 ? 'Unread ($unreadTotal)' : 'Unread',
                ),
              ],
              selected: _unreadOnly ? 'unread' : 'all',
              onSelected: (k) => setState(() => _unreadOnly = k == 'unread'),
            ),
            const SizedBox(height: 8),
            if (shown.isEmpty)
              const WaEmpty('Nothing matches.', icon: Icons.search_off)
            else
              Container(
                decoration: crmCardDecoration(),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < shown.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 68),
                      _row(shown[i]),
                    ],
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(Map t) {
    final unread = ((t['unread'] as num?) ?? 0).toInt();
    final who = '${t['name'] ?? ''}'.isNotEmpty
        ? '${t['name']}'
        : '${t['number'] ?? ''}';
    return InkWell(
      onTap: () => _open(t),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            WaAvatar(who),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    who,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: unread > 0
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t['lastDirection'] == 'out' ? 'You: ' : ''}${t['lastMessage'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: unread > 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  waShortWhen(t['lastAt']),
                  style: AppTextStyles.caption.copyWith(
                    color: unread > 0
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
