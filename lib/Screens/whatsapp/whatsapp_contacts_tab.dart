import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_shimmer.dart';
import '../crm/crm_widgets.dart';
import 'whatsapp_common.dart';

/// The contacts held in the vendor's WhatsApp account. Anyone messaged is
/// added automatically; a contact can also be saved by hand.
class WhatsAppContactsTab extends ConsumerStatefulWidget {
  const WhatsAppContactsTab({super.key});

  @override
  ConsumerState<WhatsAppContactsTab> createState() =>
      _WhatsAppContactsTabState();
}

class _WhatsAppContactsTabState extends ConsumerState<WhatsAppContactsTab> {
  final _api = CrmApi();
  final _search = TextEditingController();
  Timer? _debounce;
  String _term = '';
  int _page = 1;
  Map? _pagination;
  List _rows = const [];
  bool _loading = true;
  String _error = '';

  /// Bumped per request so a slow answer for an old search is dropped.
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted || _search.text == _term) return;
        _term = _search.text;
        _page = 1;
        _load();
      });
    });
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final r = await _api.whatsappContacts(
        page: _page,
        limit: 25,
        search: _term,
      );
      if (!mounted || seq != _seq) return;
      setState(() {
        _rows = List.from(r['contacts'] ?? const []);
        _pagination = r['pagination'] as Map?;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      final msg = waHandleError(
        context,
        ref,
        e,
        'Could not read your contacts.',
      );
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const _ContactSheet(),
    );
    if (!mounted || saved == null) return;
    waToast(context, saved);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = _pagination;
    final pages = ((p?['pages'] as num?) ?? 1).toInt();
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'wa-new-contact',
        onPressed: _add,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add contact'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            const WaHint(
              'These are the contacts held in your WhatsApp account. Anyone you message is '
              'added automatically.',
            ),
            TextField(
              controller: _search,
              decoration: crmInputDecoration(
                hint: 'Search by name or number',
                suffix: const Icon(Icons.search, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            if (_error.isNotEmpty) WaErrorBox(_error, onRetry: _load),
            if (_loading)
              const SizedBox(
                height: 400,
                child: ListShimmer(itemHeight: 60, padding: EdgeInsets.zero),
              )
            else if (_rows.isEmpty)
              const WaEmpty('No contacts found.', icon: Icons.contacts_outlined)
            else ...[
              Container(
                decoration: crmCardDecoration(),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < _rows.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 64),
                      _row(_rows[i] as Map),
                    ],
                  ],
                ),
              ),
              if (pages > 1)
                WaPager(
                  page: ((p?['page'] as num?) ?? _page).toInt(),
                  pages: pages,
                  summary:
                      'Page ${p?['page'] ?? _page} of $pages · ${p?['total'] ?? ''} contacts',
                  onPage: (n) {
                    _page = n;
                    _load();
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(Map c) {
    final name = '${c['name'] ?? ''}';
    final status = '${c['status'] ?? ''}';
    return ListTile(
      leading: WaAvatar(name.isEmpty ? '${c['phone'] ?? ''}' : name, size: 38),
      // The name is what is being looked for, so it is the one in bold.
      title: name.isEmpty
          ? const Text(
              'Not named',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            )
          : Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${c['phone'] ?? ''}', style: AppTextStyles.caption),
      trailing: status.isEmpty
          ? const Text('—')
          : WaStatusBadge(status, small: true),
    );
  }
}

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet();

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  final _api = CrmApi();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final phone = _phone.text.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.replaceAll('+', '').length < 10) {
      setState(() => _error = 'Enter a phone number with at least 10 digits.');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      final r = await _api.saveWhatsappContact({
        'name': _name.text.trim(),
        'phone': phone,
      });
      if (!mounted) return;
      Navigator.pop(context, '${r['message'] ?? 'Contact saved.'}');
    } catch (e) {
      if (!mounted) return;
      final msg = waHandleError(
        context,
        ref,
        e,
        'Could not save this contact.',
      );
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add a contact', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              if (_error.isNotEmpty) WaErrorBox(_error),
              CrmField(
                label: 'Name',
                child: CrmTextInput(
                  controller: _name,
                  maxLength: 120,
                  autofocus: true,
                ),
              ),
              CrmField(
                label: 'WhatsApp number',
                hint: 'With the country code, e.g. 919876543210.',
                child: CrmTextInput(
                  controller: _phone,
                  keyboard: TextInputType.phone,
                  maxLength: 20,
                ),
              ),
              CrmFormButtons(
                primaryLabel: 'Save contact',
                onPrimary: _save,
                busy: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
