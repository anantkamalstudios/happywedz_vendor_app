import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import 'leaddetails_screen.dart';

/// CRM "Total Leads" list — mirrors the web VendorLeadsPage.jsx:
/// summary stats, search, status badges, CSV export and Send Quotation.
class LeadsListScreen extends StatefulWidget {
  final List<dynamic> leads;

  /// Label of the dashboard filter these leads were selected with.
  final String? periodLabel;

  const LeadsListScreen({super.key, required this.leads, this.periodLabel});

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  static const _avatarColors = [
    Color(0xFF4A90E2),
    Color(0xFF7B68EE),
    Color(0xFFFF6B9D),
    Color(0xFF20C997),
    Color(0xFFFFA500),
    Color(0xFFE74C3C),
    Color(0xFF9B59B6),
    Color(0xFF3498DB),
  ];

  String _query = '';
  bool _exporting = false;

  List<dynamic> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.leads;
    return widget.leads.where((lead) {
      return _name(lead).toLowerCase().contains(q) ||
          '${lead["email"] ?? ""}'.toLowerCase().contains(q) ||
          '${lead["phone"] ?? ""}'.contains(q);
    }).toList();
  }

  String _name(dynamic lead) =>
      "${lead["firstName"] ?? ""} ${lead["lastName"] ?? ""}".trim();

  String _status(dynamic lead) {
    final s = '${lead["status"] ?? ""}'.trim();
    return s.isEmpty ? 'pending' : s.toLowerCase();
  }

  String _formatDate(dynamic value) {
    final d = value == null ? null : DateTime.tryParse(value.toString());
    return d == null ? "-" : DateFormat("dd MMM yyyy").format(d.toLocal());
  }

  String _initials(dynamic lead) {
    final f = '${lead["firstName"] ?? ""}';
    final l = '${lead["lastName"] ?? ""}';
    final i = '${f.isNotEmpty ? f[0] : ""}${l.isNotEmpty ? l[0] : ""}'.toUpperCase();
    return i.isEmpty ? '?' : i;
  }

  Color _avatarColor(dynamic lead) {
    final id = int.tryParse('${lead["id"] ?? 0}') ?? 0;
    return _avatarColors[id % _avatarColors.length];
  }

  // ==================== CSV export ====================
  Future<void> _exportCsv() async {
    final messenger = ScaffoldMessenger.of(context);
    if (widget.leads.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text("No leads to export")));
      return;
    }
    setState(() => _exporting = true);
    try {
      const headers = ["firstName", "lastName", "email", "phone", "eventDate", "status", "message"];
      String escape(dynamic v) {
        final s = '${v ?? ""}'.replaceAll('"', '""');
        return s.contains(',') || s.contains('\n') || s.contains('"') ? '"$s"' : s;
      }

      final rows = [
        headers.join(','),
        ...widget.leads.map((r) => headers.map((h) => escape(r[h])).join(',')),
      ];
      final ts = DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now());
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/leads-$ts.csv');
      await file.writeAsString(rows.join('\r\n'));

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Leads export',
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Export failed: $e")));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leads = widget.leads;
    final filtered = _filtered;
    final pending = leads.where((l) => _status(l) == 'pending').length;
    final responseRate =
        leads.isEmpty ? 0 : (((leads.length - pending) / leads.length) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.listBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Leads"),
            if (widget.periodLabel != null)
              Text(widget.periodLabel!,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Export CSV",
            onPressed: _exporting || leads.isEmpty ? null : _exportCsv,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: ListView(
        // Edge to edge (targetSdk 36): keeps the last item clear of the
        // 3-button navigation bar.
        padding: EdgeInsets.fromLTRB(12, 12, 12,
            12 + MediaQuery.of(context).padding.bottom),
        children: [
          Row(
            children: [
              Expanded(child: _summaryTile("Total Leads", '${leads.length}', "Active leads", Icons.people_alt_outlined)),
              const SizedBox(width: 8),
              Expanded(child: _summaryTile("Pending", '$pending', "Awaiting response", Icons.timer_outlined)),
              const SizedBox(width: 8),
              Expanded(child: _summaryTile("Response", '$responseRate%', "Replied leads", Icons.insights_outlined)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: "Search leads...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surface,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  const Icon(Icons.inbox_outlined, size: 56, color: AppColors.textTertiary),
                  const SizedBox(height: 10),
                  Text(
                    leads.isEmpty ? "No leads found" : "No matching leads",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    leads.isEmpty
                        ? "You don't have any leads for this period yet."
                        : "Try a different name, email or phone.",
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...filtered.map(_leadCard),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value, String caption, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
              Icon(icon, size: 18, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          Text(caption,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _leadCard(dynamic lead) {
    final name = _name(lead);
    final status = _status(lead);
    final statusColor = AppColors.statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _avatarColor(lead),
                child: Text(_initials(lead),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? "Unknown User" : name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text('${lead["email"] ?? "-"}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.phone, '${lead["phone"] ?? "-"}'),
          _infoRow(Icons.event, "Event: ${_formatDate(lead["eventDate"])}"),
          _infoRow(Icons.calendar_today, "Created: ${_formatDate(lead["createdAt"])}"),
          const SizedBox(height: 6),
          Text(
            '${lead["message"] ?? "-"}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LeadDetailScreen(
                      lead: lead,
                      conversationId: lead['conversationId']?.toString(),
                      openQuotation: true,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Send Quotation"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
