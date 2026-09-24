import 'package:flutter/material.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import 'crm_widgets.dart';

/// CRM → Pipeline, the web's board (`oa`) laid out for a phone: the stages
/// are chips (with count and value) and the chosen stage's clients are listed
/// below. Each card moves by a menu instead of drag-and-drop; Lost/Cancelled
/// asks why, exactly like the web.
class CrmPipelineView extends StatefulWidget {
  /// List filters (q, source, payment, sort, followup) — status is the column.
  final Map<String, String> filters;
  final List owners;
  final bool canAssign;
  final void Function(dynamic clientId) onOpenClient;

  /// Called after a move, so the summary cards refresh.
  final VoidCallback onMoved;

  const CrmPipelineView({
    super.key,
    required this.filters,
    required this.owners,
    required this.canAssign,
    required this.onOpenClient,
    required this.onMoved,
  });

  @override
  State<CrmPipelineView> createState() => _CrmPipelineViewState();
}

class _CrmPipelineViewState extends State<CrmPipelineView> {
  final _api = CrmApi();
  List _columns = [];
  Map<String, String> _lostReasons = CrmOptions.lostReasons;
  bool _loading = true;
  String? _error;
  String _stage = 'lead';
  String _owner = 'all';
  dynamic _busyId;

  static const _stageTones = {
    'lead': AppColors.info,
    'quoted': Color(0xFF6D28D9),
    'booked': AppColors.success,
    'completed': AppColors.textSecondary,
    'closed': AppColors.error,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CrmPipelineView old) {
    super.didUpdateWidget(old);
    if (old.filters.toString() != widget.filters.toString()) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.board({...widget.filters, 'owner': _owner});
      if (!mounted) return;
      final reasons = List.from(res['lostReasons'] ?? const []);
      setState(() {
        _columns = List.from(res['columns'] ?? const []);
        if (reasons.isNotEmpty) {
          _lostReasons = {
            for (final r in reasons) '${r['id']}': '${r['label']}',
          };
        }
      });
    } on CrmException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your pipeline.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<bool> _setStatus(
    Map c,
    String status, [
    Map<String, dynamic> extra = const {},
  ]) async {
    setState(() => _busyId = c['id']);
    try {
      final res = await _api.setClientStatus(c['id'], {
        'status': status,
        ...extra,
      });
      if (res['moved'] == true && res['message'] != null) {
        _toast('${res['message']}');
      }
      await _load();
      widget.onMoved();
      return true;
    } on CrmException catch (e) {
      _toast(e.message);
      return false;
    } catch (_) {
      _toast('Could not move the client.');
      return false;
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _assign(Map c, String? ownerId) async {
    setState(() => _busyId = c['id']);
    try {
      final res = await _api.setClientOwner(
        c['id'],
        ownerId == null ? null : int.tryParse(ownerId),
      );
      if (res['message'] != null) _toast('${res['message']}');
      await _load();
      widget.onMoved();
    } on CrmException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not change who this client belongs to.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _move(Map c, String status) {
    if (status == c['status']) return;
    if (status == 'lost' || status == 'cancelled') {
      _askWhy(c, status);
    } else {
      _setStatus(c, status);
    }
  }

  /// The web's "Move … out of the pipeline" dialog.
  Future<void> _askWhy(Map c, String initial) async {
    var status = initial == 'cancelled' ? 'cancelled' : 'lost';
    String? reason;
    var tried = false;
    var saving = false;
    final note = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move ${c['name']} out of the pipeline',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CrmFormat.rupees((c['money'] as Map?)?['finalPaise'] ?? 0),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                const Text(
                  'What happened?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Lost — they went elsewhere'),
                      selected: status == 'lost',
                      onSelected: (_) => setSheet(() => status = 'lost'),
                    ),
                    ChoiceChip(
                      label: const Text('Cancelled — the booking is off'),
                      selected: status == 'cancelled',
                      onSelected: (_) => setSheet(() => status = 'cancelled'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Why? *',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in _lostReasons.entries)
                      ChoiceChip(
                        label: Text(r.value),
                        selected: reason == r.key,
                        onSelected: (_) => setSheet(() => reason = r.key),
                      ),
                  ],
                ),
                if (tried && reason == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Pick a reason so you can see later why work is lost.',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 14),
                CrmField(
                  label: 'Note (optional)',
                  child: CrmTextInput(
                    controller: note,
                    lines: 2,
                    maxLength: 300,
                    hint: 'Asked for 1.8L against our 2.4L quote.',
                  ),
                ),
                const Text(
                  "This goes on the client's timeline, and into the reasons chart. You can "
                  'move the client back at any time.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: saving
                            ? null
                            : () => Navigator.pop(sheetContext),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: saving
                            ? null
                            : () async {
                                setSheet(() => tried = true);
                                if (reason == null) return;
                                setSheet(() => saving = true);
                                final ok = await _setStatus(c, status, {
                                  'reason': reason,
                                  'note': note.text.trim(),
                                });
                                if (!sheetContext.mounted) return;
                                if (ok) {
                                  Navigator.pop(sheetContext);
                                } else {
                                  setSheet(() => saving = false);
                                }
                              },
                        child: Text(
                          saving
                              ? 'Moving…'
                              : 'Move to ${status == 'lost' ? 'Lost' : 'Cancelled'}',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    note.dispose();
  }

  // ==========================================================================
  // UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    if (_loading && _columns.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
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
      );
    }
    if (_columns.every((c) => ((c['count'] as num?) ?? 0) == 0)) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Text(
              'No clients match these filters',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Clear the search or filters to see your whole pipeline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final column = _columns.firstWhere(
      (c) => c['id'] == _stage,
      orElse: () => _columns.first,
    );
    final clients = List.from(column['clients'] ?? const []);
    final more = ((column['more'] as num?) ?? 0).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (widget.canAssign && widget.owners.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CrmDropdown(
              value: _owner,
              options: {
                'all': "Everyone's clients",
                'mine': 'Only mine',
                'unassigned': 'Unassigned',
                for (final o in widget.owners) '${o['id']}': '${o['name']}',
              },
              onChanged: (v) {
                setState(() => _owner = v);
                _load();
              },
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in _columns) ...[
                _stageChip(c, selected: c['id'] == column['id']),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${CrmFormat.rupees(column['valuePaise'])}'
          '${((column['pendingPaise'] as num?) ?? 0) > 0 && (column['id'] == 'booked' || column['id'] == 'completed') ? ' · ${CrmFormat.rupees(column['pendingPaise'])} to collect' : ''}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        if (clients.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                'No clients in this stage.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        for (final c in clients) _card(c as Map),
        if (more > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$more more — use the list to see them all',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _stageChip(Map c, {required bool selected}) {
    final id = '${c['id']}';
    final tone = _stageTones[id] ?? AppColors.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _stage = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tone.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? tone : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 4, backgroundColor: tone),
            const SizedBox(width: 6),
            Text(
              id == 'closed' ? 'Lost / cancelled' : '${c['label']}',
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${c['count'] ?? 0}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String? name) {
    final parts = (name ?? '').split(' ').where((p) => p.isNotEmpty).take(2);
    final s = parts.map((p) => p[0]).join().toUpperCase();
    return s.isEmpty ? '—' : s;
  }

  Widget _chip(String text, Color tone, {IconData? icon}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: tone.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: tone),
          const SizedBox(width: 3),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: tone,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _card(Map c) {
    final money = (c['money'] as Map?) ?? const {};
    final finalPaise = ((money['finalPaise'] as num?) ?? 0).toInt();
    final received = ((money['receivedPaise'] as num?) ?? 0).toInt();
    final today = CrmFormat.today();
    final followUp = '${c['followUpDate'] ?? ''}';
    final due = '${c['dueDate'] ?? ''}';
    final closed = c['status'] == 'lost' || c['status'] == 'cancelled';
    final overdue =
        due.isNotEmpty &&
        due.compareTo(today) < 0 &&
        money['isPending'] == true;
    final events = List.from(c['events'] ?? const []);
    final busy = _busyId == c['id'];
    final days = ((c['daysInStage'] as num?) ?? 0).toInt();

    return Opacity(
      opacity: busy ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: crmCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onOpenClient(c['id']),
                    child: Text(
                      '${c['name']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                if (c['ownerName'] != null || widget.canAssign)
                  Tooltip(
                    message: '${c['ownerName'] ?? 'Unassigned'}',
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: c['ownerId'] == null
                          ? AppColors.inputFill
                          : AppColors.primaryTint,
                      child: Text(
                        _initials(c['ownerName']?.toString()),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  enabled: !busy,
                  tooltip: 'Move or assign',
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) {
                    if (v.startsWith('move:')) _move(c, v.substring(5));
                    if (v.startsWith('owner:')) {
                      final id = v.substring(6);
                      _assign(c, id.isEmpty ? null : id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(enabled: false, child: Text('Move to')),
                    for (final s in CrmOptions.statuses.entries)
                      CheckedPopupMenuItem(
                        value: 'move:${s.key}',
                        checked: c['status'] == s.key,
                        child: Text(s.value),
                      ),
                    if (widget.canAssign && widget.owners.isNotEmpty) ...[
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        enabled: false,
                        child: Text('Assign to'),
                      ),
                      CheckedPopupMenuItem(
                        value: 'owner:',
                        checked: c['ownerId'] == null,
                        child: const Text('Unassigned'),
                      ),
                      for (final o in widget.owners)
                        CheckedPopupMenuItem(
                          value: 'owner:${o['id']}',
                          checked: '${c['ownerId']}' == '${o['id']}',
                          child: Text(
                            o['isMe'] == true
                                ? '${o['name']} (me)'
                                : '${o['name']}',
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ),
            if (events.isNotEmpty || c['firstEventDate'] != null)
              Text(
                '${events.isNotEmpty ? events.first['name'] : 'Event'}'
                '${c['firstEventDate'] != null ? ' · ${CrmFormat.date(c['firstEventDate'])}' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  CrmFormat.rupees(finalPaise),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                _chip(
                  CrmOptions.leadSources[c['leadSource']] ??
                      '${c['leadSource'] ?? ''}',
                  AppColors.textSecondary,
                ),
              ],
            ),
            if (finalPaise > 0 && received > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (received / finalPaise).clamp(0, 1).toDouble(),
                    minHeight: 5,
                    backgroundColor: AppColors.inputFill,
                    color: AppColors.success,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (closed && c['lostReasonLabel'] != null)
                  _chip('${c['lostReasonLabel']}', AppColors.error),
                if (!closed && overdue)
                  _chip(
                    '${CrmFormat.rupees(money['balancePaise'])} overdue',
                    AppColors.error,
                  ),
                if (!closed &&
                    !overdue &&
                    money['isPending'] == true &&
                    due.isNotEmpty)
                  _chip(
                    '${CrmFormat.rupees(money['balancePaise'])} due ${CrmFormat.date(due)}',
                    AppColors.warning,
                  ),
                if (!closed && followUp.isNotEmpty)
                  _chip(
                    'Follow up ${CrmFormat.date(followUp)}',
                    followUp.compareTo(today) <= 0
                        ? AppColors.error
                        : AppColors.info,
                    icon: Icons.schedule,
                  ),
              ],
            ),
            if (c['readyToComplete'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => _setStatus(c, 'completed'),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Event is over — mark completed'),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              days == 0
                  ? 'Moved today'
                  : '$days day${days == 1 ? '' : 's'} here',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
