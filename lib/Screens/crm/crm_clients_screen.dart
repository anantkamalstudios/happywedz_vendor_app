import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api_services/crm_api.dart';
import '../../auth/session_manager.dart';
import '../../theme/app_colors.dart';
import '../../utils/common_app_bar.dart';
import '../../utils/plan_module_lock.dart';
import '../../widgets/plan_feature_guard.dart';
import '../Login.dart';
import 'crm_business_details_screen.dart';
import 'crm_analytics_view.dart';
import 'crm_calendar_view.dart';
import 'crm_client_detail_screen.dart';
import 'crm_pipeline_view.dart';
import 'crm_team_view.dart';
import 'crm_client_form_screen.dart';

/// CRM → Clients, mirroring the web CRM's Clients view (CrmPage.jsx):
/// summary cards, follow-ups / overdue payments, events in the next 30 days,
/// and the searchable, filterable, paginated client list — same API, so the
/// same vendor sees the same numbers on web and app.
class CrmClientsScreen extends ConsumerStatefulWidget {
  const CrmClientsScreen({super.key});

  @override
  ConsumerState<CrmClientsScreen> createState() => _CrmClientsScreenState();
}

class _CrmClientsScreenState extends ConsumerState<CrmClientsScreen> {
  final CrmApi _api = CrmApi();
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  // Filters — ids as the web sends them.
  String _query = '';
  String _status = 'all';
  String _source = 'all';
  String _payment = 'all';
  String _sort = 'newest';
  String? _followup;
  int _page = 1;

  bool _loading = true;
  bool _exporting = false;
  String? _error;
  bool _sessionExpired = false;
  Map<String, dynamic>? _summary;
  List<dynamic> _clients = [];
  int _total = 0;

  /// Which view is showing: list, board, calendar, analytics or team — the
  /// web's view switcher. Remembered between visits, like the web.
  static const _viewKey = 'crm.view';
  static const _views = ['list', 'board', 'calendar', 'analytics', 'team'];
  String _view = 'list';

  /// `{role, canAssign, canManageTeam}` for whoever is signed in.
  Map? _viewer;
  List _owners = [];

  /// Bumped to make the pipeline reload after a pull-to-refresh.
  int _boardVersion = 0;

  bool get _hasFilters =>
      _query.isNotEmpty ||
      _status != 'all' ||
      _source != 'all' ||
      _payment != 'all' ||
      _followup != null;

  int get _pages => (_total / CrmApi.pageSize).ceil().clamp(1, 1 << 30);

  @override
  void initState() {
    super.initState();
    _restoreView();
    _api
        .owners()
        .then((r) {
          if (mounted) {
            setState(() => _owners = List.from(r['owners'] ?? const []));
          }
        })
        .catchError((_) {});
  }

  Future<void> _restoreView() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_viewKey);
      if (saved != null && _views.contains(saved)) _view = saved;
    } catch (_) {}
    _load();
  }

  void _setView(String view) {
    setState(() => _view = view);
    SharedPreferences.getInstance()
        .then((p) => p.setString(_viewKey, view))
        .catchError((_) => false);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final wantsList = _view == 'list';
      final results = await Future.wait([
        _api.summary(),
        if (wantsList)
          _api.clients(
            q: _query,
            status: _status,
            source: _source,
            payment: _payment,
            sort: _sort,
            followup: _followup,
            page: _page,
          ),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0]['summary'] as Map<String, dynamic>?;
        _viewer = results[0]['viewer'] as Map?;
        if (wantsList) {
          _clients = List<dynamic>.from(results[1]['clients'] ?? const []);
          _total = (results[1]['total'] as num?)?.toInt() ?? 0;
        }
        // The Team view is only for whoever can manage the team.
        if (_view == 'team' && _viewer?['canManageTeam'] != true) {
          _view = 'list';
        }
        _sessionExpired = false;
        _boardVersion++;
      });
    } on PlanModuleLockedException catch (e) {
      if (mounted) {
        showPlanModuleLocked(
          context,
          ref,
          module: e.module.isEmpty ? 'crm' : e.module,
          message: e.message,
        );
      }
    } on CrmException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _sessionExpired = e.isUnauthorized;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your clients.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _query = value.trim();
      _page = 1;
      _load();
    });
  }

  void _setFilter(VoidCallback change) {
    change();
    _page = 1;
    _load();
  }

  /// "Show all" on the follow-ups / overdue panels, as on the web.
  void _showOnly({String? followup, String? payment}) {
    _search.clear();
    _view = 'list';
    _setFilter(() {
      _query = '';
      _status = 'all';
      _source = 'all';
      _followup = followup;
      _payment = payment ?? 'all';
    });
  }

  // ==========================================================================
  // Header actions (same three as the web)
  // ==========================================================================

  void _openBusinessDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrmBusinessDetailsScreen()),
    );
  }

  Future<void> _addClient() async {
    final created = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const CrmClientFormScreen()),
    );
    if (created == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Client added.')));
    _page = 1;
    _load();
    if (created['id'] != null) _openClient(created['id']);
  }

  /// Opens a client's details; refreshes the list and summary if anything
  /// was changed there.
  Future<void> _openClient(dynamic id) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CrmClientDetailScreen(clientId: id)),
    );
    if (changed == true && mounted) _load();
  }

  /// Downloads the Excel file for the current filters (as on the web) and
  /// hands it to the share sheet so it can be saved, emailed or opened.
  Future<void> _exportExcel() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      final bytes = await _api.exportClients(
        CrmApi.filters(
          q: _query,
          status: _status,
          source: _source,
          payment: _payment,
          sort: _sort,
          followup: _followup,
        ),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/clients-${CrmFormat.today()}.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(
          file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ], subject: 'Clients export');
    } on PlanModuleLockedException catch (e) {
      if (mounted) {
        showPlanModuleLocked(
          context,
          ref,
          module: e.module.isEmpty ? 'crm' : e.module,
          message: e.message,
        );
      }
    } on CrmException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not export your clients.')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _headerActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _openBusinessDetails,
          icon: const Icon(Icons.tune, size: 16),
          label: const Text('Business details'),
        ),
        OutlinedButton.icon(
          onPressed: _exporting || _total == 0 ? null : _exportExcel,
          icon: _exporting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined, size: 16),
          label: Text(_exporting ? 'Exporting…' : 'Export Excel'),
        ),
        ElevatedButton.icon(
          onPressed: _addClient,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add client'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: 'CRM'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            14,
            14,
            14,
            20 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            const Text(
              'Clients',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Every booking in one place: events, quotations, invoices and payments.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _headerActions(),
            const SizedBox(height: 14),
            if (_error != null && _summary == null && _clients.isEmpty)
              _errorView()
            else ...[
              // Cards and panels, as on the web, except on Analytics / Team.
              if (_summary != null && _view != 'analytics' && _view != 'team')
                ..._summarySection(_summary!, cards: true),
              _viewSwitcher(),
              const SizedBox(height: 12),
              ..._viewContent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _viewSwitcher() {
    final views = <(String, String, IconData)>[
      ('list', 'Clients', Icons.list_alt),
      ('board', 'Pipeline', Icons.view_kanban_outlined),
      ('calendar', 'Calendar', Icons.calendar_month_outlined),
      ('analytics', 'Analytics', Icons.insights_outlined),
      if (_viewer?['canManageTeam'] == true)
        ('team', 'Team', Icons.groups_outlined),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final v in views) ...[
            ChoiceChip(
              avatar: Icon(
                v.$3,
                size: 16,
                color: _view == v.$1
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              label: Text(v.$2),
              selected: _view == v.$1,
              showCheckmark: false,
              selectedColor: AppColors.primaryTint,
              labelStyle: TextStyle(
                color: _view == v.$1
                    ? AppColors.primary
                    : AppColors.textPrimary,
                fontWeight: _view == v.$1 ? FontWeight.w700 : FontWeight.w500,
              ),
              onSelected: (_) {
                if (_view != v.$1) _setView(v.$1);
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  List<Widget> _viewContent() {
    switch (_view) {
      case 'board':
        return [
          _filters(showStatus: false),
          const SizedBox(height: 12),
          CrmPipelineView(
            key: ValueKey('board-$_boardVersion'),
            filters: CrmApi.filters(
              q: _query,
              source: _source,
              payment: _payment,
              sort: _sort,
              followup: _followup,
            )..remove('status'),
            owners: _owners,
            canAssign: _viewer?['canAssign'] == true && _owners.isNotEmpty,
            onOpenClient: _openClient,
            onMoved: _refreshSummary,
          ),
        ];
      case 'calendar':
        return [CrmCalendarView(onOpenClient: _openClient)];
      case 'analytics':
        return [const CrmAnalyticsView()];
      case 'team':
        return [const CrmTeamView()];
      default:
        return [
          if (_summary != null) ..._summarySection(_summary!, upcoming: true),
          _filters(),
          const SizedBox(height: 10),
          ..._clientList(),
        ];
    }
  }

  /// Summary cards only (after a pipeline move), without reloading the board.
  Future<void> _refreshSummary() async {
    try {
      final res = await _api.summary();
      if (mounted) {
        setState(() => _summary = res['summary'] as Map<String, dynamic>?);
      }
    } catch (_) {}
  }

  Widget _errorView() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 52,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (_sessionExpired)
            ElevatedButton(
              onPressed: () => SessionManager.logout(
                context,
                loginPageBuilder: (_) => const Login(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Log in again'),
            )
          else
            OutlinedButton(onPressed: _load, child: const Text('Try again')),
        ],
      ),
    );
  }

  BoxDecoration get _card => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.border),
  );

  /// [cards]: stat cards + follow-ups / overdue panels. [upcoming]: the
  /// "Events in the next 30 days" strip (Clients view only).
  List<Widget> _summarySection(
    Map<String, dynamic> s, {
    bool cards = false,
    bool upcoming = false,
  }) {
    final showCards = cards;
    final showUpcoming = upcoming;
    int n(String k) => (s[k] as num?)?.toInt() ?? 0;
    String plural(int count, String word) =>
        '$count $word${count == 1 ? '' : 's'}';

    final followUps = List<dynamic>.from(s['followUps'] ?? const []);
    final overdue = List<dynamic>.from(s['overdue'] ?? const []);
    final upcomingEvents = List<dynamic>.from(s['upcoming'] ?? const []);

    return [
      if (showCards) ...[
        // Two rows of two, each row as tall as its tallest card — no fixed
        // aspect ratio, so large fonts or long amounts cannot overflow.
        ..._statRows([
          _stat(
            'Booked value',
            CrmFormat.rupees(s['bookedValuePaise']),
            plural(n('booked'), 'booked client'),
            AppColors.textPrimary,
          ),
          _stat(
            'Collected',
            CrmFormat.rupees(s['collectedPaise']),
            '${CrmFormat.rupees(s['collectedThisMonthPaise'])} this month',
            AppColors.success,
          ),
          _stat(
            'Payment pending',
            CrmFormat.rupees(s['pendingPaise']),
            'from ${plural(n('pendingClients'), 'client')}',
            n('pendingPaise') > 0 ? AppColors.warning : AppColors.textPrimary,
          ),
          _stat(
            'Open leads',
            '${n('newLeads')}',
            '${plural(n('clients'), 'client')} in total',
            AppColors.textPrimary,
          ),
        ]),
        const SizedBox(height: 14),
        if (followUps.isNotEmpty)
          _panel(
            icon: Icons.schedule,
            iconColor: AppColors.info,
            title: 'Follow-ups due',
            onShowAll: () => _showOnly(followup: 'due'),
            rows: followUps.map((f) {
              final date = '${f['date'] ?? ''}';
              final late =
                  date.isNotEmpty && date.compareTo(CrmFormat.today()) < 0;
              return _panelRow(
                '${f['clientName'] ?? ''}',
                f['note'] == null ? null : '${f['note']}',
                late ? 'since ${CrmFormat.date(date)}' : 'today',
                late,
              );
            }).toList(),
          ),
        if (overdue.isNotEmpty)
          _panel(
            icon: Icons.error_outline,
            iconColor: AppColors.error,
            title: 'Payments overdue',
            count: n('overdueCount') > overdue.length
                ? n('overdueCount')
                : null,
            onShowAll: () => _showOnly(payment: 'overdue'),
            rows: overdue
                .map(
                  (o) => _panelRow(
                    '${o['clientName'] ?? ''}',
                    null,
                    '${CrmFormat.rupees(o['amountPaise'])} · due ${CrmFormat.date(o['dueDate'])}',
                    true,
                  ),
                )
                .toList(),
          ),
      ],
      if (showUpcoming && upcomingEvents.isNotEmpty) ...[
        const Text(
          'Events in the next 30 days',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        // Sized by the cards themselves (no fixed height): the tallest card
        // sets the row height and the rest stretch to match, so a long
        // client/venue line or a larger system font can never overflow.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < upcomingEvents.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Builder(
                    builder: (_) {
                      final e = upcomingEvents[i];
                      final venue = '${e['venue'] ?? ''}';
                      return Container(
                        width: 220,
                        padding: const EdgeInsets.all(12),
                        decoration: _card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CrmFormat.date(e['eventDate']),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${e['name'] ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                e['clientName'],
                                venue.isEmpty ? null : venue,
                              ].where((x) => x != null).join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    ];
  }

  List<Widget> _statRows(List<Widget> cards) {
    return [
      for (var i = 0; i < cards.length; i += 2) ...[
        if (i > 0) const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[i]),
              const SizedBox(width: 10),
              Expanded(
                child: i + 1 < cards.length ? cards[i + 1] : const SizedBox(),
              ),
            ],
          ),
        ),
      ],
    ];
  }

  Widget _stat(String label, String value, String note, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onShowAll,
    required List<Widget> rows,
    int? count,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: _card,
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '($count)',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              const Spacer(),
              TextButton(onPressed: onShowAll, child: const Text('Show all')),
            ],
          ),
          ...rows,
        ],
      ),
    );
  }

  Widget _panelRow(String name, String? note, String trailing, bool urgent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 6, 6),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (note != null && note.isNotEmpty)
                    TextSpan(
                      text: ' · $note',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 12,
              color: urgent ? AppColors.error : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters({bool showStatus = true}) {
    Widget dropdown(
      String value,
      String allLabel,
      Map<String, String> options,
      void Function(String) onChanged,
    ) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            items: [
              if (allLabel.isNotEmpty)
                DropdownMenuItem(value: 'all', child: Text(allLabel)),
              ...options.entries.map(
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
              ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _search,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search name, phone, email or event',
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (showStatus) ...[
                dropdown(
                  _status,
                  'All statuses',
                  CrmOptions.statuses,
                  (v) => _setFilter(() => _status = v),
                ),
                const SizedBox(width: 8),
              ],
              dropdown(
                _source,
                'All sources',
                CrmOptions.leadSources,
                (v) => _setFilter(() => _source = v),
              ),
              const SizedBox(width: 8),
              dropdown(
                _payment,
                'Any payment',
                CrmOptions.payments,
                (v) => _setFilter(() => _payment = v),
              ),
              const SizedBox(width: 8),
              dropdown(
                _sort,
                '',
                CrmOptions.sorts,
                (v) => _setFilter(() => _sort = v),
              ),
            ],
          ),
        ),
        if (_followup == 'due')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InputChip(
              label: const Text('Showing follow-ups due'),
              onDeleted: () => _setFilter(() => _followup = null),
            ),
          ),
      ],
    );
  }

  List<Widget> _clientList() {
    if (_loading && _clients.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_error != null) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Column(
            children: [
              Text(
                _error!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              TextButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      ];
    }
    if (_clients.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              const Icon(
                Icons.people_outline,
                size: 40,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 10),
              Text(
                _hasFilters
                    ? 'No clients match these filters'
                    : 'No clients yet',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _hasFilters
                    ? 'Try a different search or status.'
                    : 'Add clients on the website, or use “Add to CRM” on any HappyWedz enquiry.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      if (_loading) const LinearProgressIndicator(minHeight: 2),
      ..._clients.asMap().entries.map(
        (e) => _clientCard(e.value, (_page - 1) * CrmApi.pageSize + e.key + 1),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(
              '$_total client${_total == 1 ? '' : 's'}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const Spacer(),
            if (_pages > 1) ...[
              IconButton(
                onPressed: _page <= 1 || _loading
                    ? null
                    : () {
                        _page--;
                        _load();
                      },
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Page $_page of $_pages'),
              IconButton(
                onPressed: _page >= _pages || _loading
                    ? null
                    : () {
                        _page++;
                        _load();
                      },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  static const Map<String, Color> _statusTones = {
    'lead': AppColors.info,
    'quoted': Color(0xFF6D28D9),
    'booked': AppColors.success,
    'completed': AppColors.textSecondary,
    'lost': AppColors.error,
    'cancelled': AppColors.error,
  };

  Widget _clientCard(dynamic c, int number) {
    final money = (c['money'] as Map?) ?? const {};
    final finalPaise = (money['finalPaise'] as num?) ?? 0;
    final receivedPaise = (money['receivedPaise'] as num?) ?? 0;
    final status = '${c['status'] ?? ''}';
    final tone = _statusTones[status] ?? AppColors.textSecondary;
    final events = List<dynamic>.from(c['events'] ?? const []);
    final dueDate = c['dueDate']?.toString();
    final overdue =
        dueDate != null &&
        dueDate.compareTo(CrmFormat.today()) < 0 &&
        !['lost', 'cancelled'].contains(status);
    final subtitle = [
      c['phone'],
      c['location'],
    ].where((x) => x != null && '$x'.isNotEmpty).join(' · ');

    Widget amount(String label, String value, {Color? color}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );

    final Widget balance;
    if (finalPaise == 0 && receivedPaise == 0) {
      balance = amount('Balance', '—');
    } else if (money['isPending'] == true) {
      balance = Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Balance',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
            Text(
              CrmFormat.rupees(money['balancePaise']),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
              ),
            ),
            if (dueDate != null)
              Text(
                '${overdue ? 'overdue since' : 'due'} ${CrmFormat.date(dueDate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: overdue ? AppColors.error : AppColors.textTertiary,
                ),
              ),
          ],
        ),
      );
    } else {
      balance = amount('Balance', 'Paid', color: AppColors.success);
    }

    return InkWell(
      onTap: () => _openClient(c['id']),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: _card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number',
                  style: const TextStyle(color: AppColors.textTertiary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c['name'] ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    CrmOptions.statuses[status] ?? status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tone,
                    ),
                  ),
                ),
              ],
            ),
            if (events.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: events.map((ev) {
                  final date = CrmFormat.date(ev['eventDate']);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${ev['name'] ?? ''}${date.isEmpty ? '' : ' · $date'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Source: ${CrmOptions.leadSources[c['leadSource']] ?? c['leadSource'] ?? '—'}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                amount(
                  'Final amount',
                  finalPaise == 0 ? '—' : CrmFormat.rupees(finalPaise),
                ),
                amount(
                  'Received',
                  receivedPaise == 0 ? '—' : CrmFormat.rupees(receivedPaise),
                ),
                balance,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
