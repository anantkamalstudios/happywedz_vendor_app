import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/common_app_bar.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/whatsapp_icon.dart';
import 'whatsapp_campaigns_tab.dart';
import 'whatsapp_chats_tab.dart';
import 'whatsapp_common.dart';
import 'whatsapp_connect_screen.dart';
import 'whatsapp_contacts_tab.dart';
import 'whatsapp_history_tab.dart';
import 'whatsapp_templates_tab.dart';

/// WhatsApp as a section of its own — the website's `WhatsAppPage` /
/// `WhatsAppWorkspace`: Chats, Templates, Broadcasts, Contacts and Sent.
///
/// Opened through `FeatureGuard(module: crm)`. The connection is checked
/// first: without a connected provider none of the tabs has anything to
/// show, so the screen leads to the connection page instead. The settings
/// action in the bar opens that page at any time.
class WhatsAppWorkspaceScreen extends ConsumerStatefulWidget {
  const WhatsAppWorkspaceScreen({super.key});

  @override
  ConsumerState<WhatsAppWorkspaceScreen> createState() =>
      _WhatsAppWorkspaceScreenState();
}

class _WhatsAppWorkspaceScreenState
    extends ConsumerState<WhatsAppWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  final _api = CrmApi();

  static const _tabs = ['Chats', 'Templates', 'Broadcasts', 'Contacts', 'Sent'];

  // The website opens on Templates.
  late final TabController _tab = TabController(
    length: _tabs.length,
    vsync: this,
    initialIndex: 1,
  );

  bool _checking = true;
  Map? _state;
  String _error = '';

  /// Bumped after the connection changes, so every tab starts over.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _checking = _state == null;
      _error = '';
    });
    try {
      final r = await _api.whatsapp();
      if (!mounted) return;
      setState(() => _state = r['whatsapp'] as Map? ?? const {});
    } catch (e) {
      if (!mounted) return;
      final msg = waHandleError(
        context,
        ref,
        e,
        'Could not check your WhatsApp connection.',
      );
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openSettings() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const WhatsAppConnectScreen()),
    );
    if (!mounted) return;
    if (changed == true) {
      WaLastSeen.clear();
      setState(() => _generation++);
    }
    _check();
  }

  bool get _connected => _state?['connected'] == true;

  @override
  Widget build(BuildContext context) {
    final showTabs = !_checking && _connected;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: 'WhatsApp',
        actions: [
          IconButton(
            tooltip: 'WhatsApp connection',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
        bottom: showTabs
            ? TabBar(
                controller: _tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [for (final t in _tabs) Tab(text: t)],
              )
            : null,
      ),
      body: _checking
          ? const ListShimmer(itemHeight: 72)
          : _error.isNotEmpty && _state == null
          ? _problem()
          : !_connected
          ? _notConnected()
          : TabBarView(
              key: ValueKey(_generation),
              controller: _tab,
              children: [
                WhatsAppChatsTab(onOpenSettings: _openSettings),
                const WhatsAppTemplatesTab(),
                const WhatsAppCampaignsTab(),
                const WhatsAppContactsTab(),
                const WhatsAppHistoryTab(),
              ],
            ),
    );
  }

  Widget _problem() => RefreshIndicator(
    onRefresh: _check,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [WaErrorBox(_error, onRetry: _check)],
    ),
  );

  /// Not connected, or connected once and since broken.
  Widget _notConnected() {
    final s = _state;
    final broken = s != null && '${s['baseUrl'] ?? ''}'.isNotEmpty;
    return RefreshIndicator(
      onRefresh: _check,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.listBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const WhatsAppIcon(size: 36),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            broken
                ? 'Your WhatsApp connection stopped working'
                : 'Connect WhatsApp',
            textAlign: TextAlign.center,
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 8),
          Text(
            broken
                ? '${'${s['lastError'] ?? ''}'.isNotEmpty ? '${s['lastError']}. ' : ''}'
                      'Paste your API key again to reconnect.'
                : 'Talk to your clients on WhatsApp from here: their replies, your templates '
                      'and your broadcasts. Connect your WhatsApp provider once and HappyWedz '
                      'sends for you.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _openSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(broken ? 'Reconnect WhatsApp' : 'Connect WhatsApp'),
          ),
        ],
      ),
    );
  }
}
