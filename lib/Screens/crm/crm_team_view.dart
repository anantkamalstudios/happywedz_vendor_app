import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import 'crm_widgets.dart';

/// CRM → Team, as on the web (`va`): the studio's members with role, status
/// and client count; invite (with a copyable link), resend, switch off/on and
/// remove. Only shown to the account owner (`viewer.canManageTeam`).
class CrmTeamView extends StatefulWidget {
  const CrmTeamView({super.key});

  @override
  State<CrmTeamView> createState() => _CrmTeamViewState();
}

class _CrmTeamViewState extends State<CrmTeamView> {
  static const _roleHelp = {
    'manager':
        'Sees every client and works on all of them. Cannot change the team, the plan or your business details.',
    'staff':
        'Sees only the clients given to them, and does everything with those — quotations, invoices and payments included.',
  };

  final _api = CrmApi();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  dynamic _busyId;

  // Invite form.
  bool _inviting = false;
  bool _sending = false;
  String? _inviteError;
  String? _inviteLink;
  bool _resent = false;
  final _name = TextEditingController();
  final _email = TextEditingController();
  String _role = 'staff';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.team();
      if (mounted) setState(() => _data = res);
    } on CrmException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your team.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _update(Map m, Map<String, dynamic> body) async {
    setState(() => _busyId = m['id']);
    try {
      final res = await _api.updateTeamMember(m['id'], body);
      if (res['message'] != null) _toast('${res['message']}');
      await _load();
    } on CrmException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not save that.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _resend(Map m) async {
    setState(() => _busyId = m['id']);
    try {
      final res = await _api.inviteTeamMember({
        'name': m['name'],
        'email': m['email'],
        'role': m['role'],
      });
      if (res['message'] != null) _toast('${res['message']}');
      setState(() {
        _inviting = true;
        _resent = true;
        _inviteLink = res['link']?.toString();
      });
      await _load();
    } on CrmException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not send it again.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _invite() async {
    setState(() {
      _inviteError = null;
      _sending = true;
    });
    try {
      final res = await _api.inviteTeamMember({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'role': _role,
      });
      if (res['message'] != null) _toast('${res['message']}');
      setState(() {
        _inviteLink = res['link']?.toString();
        _resent = false;
      });
      _load();
    } on CrmException catch (e) {
      setState(() => _inviteError = e.message);
    } catch (_) {
      setState(() => _inviteError = 'Could not invite them.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _closeInvite() {
    setState(() {
      _inviting = false;
      _inviteLink = null;
      _resent = false;
      _inviteError = null;
      _name.clear();
      _email.clear();
      _role = 'staff';
    });
    _load();
  }

  Future<void> _remove(Map m) async {
    final clients = ((m['clients'] as num?) ?? 0).toInt();
    await showCrmConfirm(
      context,
      title: 'Remove ${m['name']}?',
      text: clients > 0
          ? 'Their $clients client${clients == 1 ? '' : 's'} will go back to unassigned.'
          : 'They will no longer be able to sign in.',
      confirmLabel: 'Remove',
      danger: true,
      onConfirm: (_) async {
        try {
          final res = await _api.removeTeamMember(m['id']);
          if (res['message'] != null) _toast('${res['message']}');
          await _load();
          return true;
        } on CrmException catch (e) {
          _toast(e.message);
          return false;
        } catch (_) {
          _toast('Could not remove them.');
          return false;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    if (_loading && d == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (d == null) return const SizedBox();

    final used = ((d['seatsUsed'] as num?) ?? 0).toInt();
    final limit = ((d['seatLimit'] as num?) ?? 0).toInt();
    final full = used >= limit;
    final roles = {
      for (final r in List.from(d['roles'] ?? const []))
        '${r['id']}': '${r['label']}',
    };
    final members = List.from(d['members'] ?? const []);
    final unassigned = ((d['unassigned'] as num?) ?? 0).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        const Text(
          'Your team',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          'People from your studio who work on clients with you. $used of $limit places used.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        if (!_inviting)
          ElevatedButton.icon(
            onPressed: full ? null : () => setState(() => _inviting = true),
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: const Text('Invite someone'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        if (full && !_inviting)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CrmNotice(
              'Your plan includes $limit team members. Remove someone before inviting another.',
              warn: false,
            ),
          ),
        if (_inviting) _inviteCard(roles),
        const SizedBox(height: 12),
        for (final m in members) _member(m as Map, roles),
        if (unassigned > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Text(
              '$unassigned client${unassigned == 1 ? ' is' : 's are'} not assigned to anyone yet. '
              'Give them out from the pipeline board.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        const CrmNotice(
          'Everyone you invite signs in at happywedz.com/vendor-team/login with their own email '
          'and password. They only ever see the CRM — never your plan, your payouts or your storefront.',
          warn: false,
        ),
      ],
    );
  }

  Widget _inviteCard(Map<String, String> roles) {
    if (_inviteLink != null) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: crmCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _resent ? 'Invitation sent again' : 'Invitation sent',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'They have an email with a link to set their password. You can also send them this link yourself:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            SelectableText(
              _inviteLink!,
              style: const TextStyle(color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _inviteLink!));
                    _toast('Link copied.');
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _closeInvite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: crmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invite someone',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          CrmField(
            label: 'Name *',
            child: CrmTextInput(controller: _name, autofocus: true),
          ),
          CrmField(
            label: 'Email *',
            child: CrmTextInput(
              controller: _email,
              keyboard: TextInputType.emailAddress,
            ),
          ),
          CrmField(
            label: 'What can they do?',
            hint: _roleHelp[_role],
            child: CrmDropdown(
              value: _role,
              options: roles.isEmpty
                  ? const {'manager': 'Manager', 'staff': 'Staff'}
                  : roles,
              onChanged: (v) => setState(() => _role = v),
            ),
          ),
          if (_inviteError != null) CrmNotice(_inviteError!),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _sending ? null : _closeInvite,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sending ? null : _invite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(_sending ? 'Sending…' : 'Send invitation'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _member(Map m, Map<String, String> roles) {
    final isOwner = m['isOwner'] == true;
    final busy = _busyId == m['id'];
    final status = '${m['status']}';
    final (statusLabel, statusTone) = switch (status) {
      'active' => ('Active', 'paid'),
      'invited' => ('Invited', 'unpaid'),
      _ => ('Switched off', 'completed'),
    };

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${m['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (isOwner)
                              const TextSpan(
                                text: ' (you)',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${m['email'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${m['clients'] ?? 0} client${m['clients'] == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isOwner)
              const CrmBadge(status: 'quoted', label: 'Owner')
            else ...[
              CrmDropdown(
                value: '${m['role']}',
                options: roles.isEmpty
                    ? {'${m['role']}': '${m['role']}'}
                    : roles,
                onChanged: (v) {
                  if (!busy && v != m['role']) _update(m, {'role': v});
                },
              ),
              if (_roleHelp[m['role']] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _roleHelp[m['role']]!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CrmBadge(status: statusTone, label: statusLabel),
                if (status == 'invited' && m['inviteExpiresAt'] != null)
                  Text(
                    'Link works until ${CrmFormat.date(m['inviteExpiresAt'])}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                if (m['lastLoginAt'] != null)
                  Text(
                    'Last in ${CrmFormat.date(m['lastLoginAt'])}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
            if (!isOwner) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (status == 'invited')
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => _resend(m),
                      icon: const Icon(Icons.mail_outline, size: 16),
                      label: const Text('Resend'),
                    ),
                  if (status == 'active')
                    OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => _update(m, {'status': 'disabled'}),
                      child: const Text('Switch off'),
                    ),
                  if (status == 'disabled')
                    OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => _update(m, {'status': 'active'}),
                      child: const Text('Switch on'),
                    ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => _remove(m),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
