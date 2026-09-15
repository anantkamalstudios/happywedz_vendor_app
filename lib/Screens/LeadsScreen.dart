import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'new_screens/leaddetails_screen.dart';

class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});
  static List<dynamic> latestLeads = [];

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _sort = 'Newest';
  String _selectedFilter = 'All Enquiries';
  bool _isLoading = true;

  /// 🔥 SERVER inbox list
  List<dynamic> _leads = [];

  /// 🔥 read helper (local only)
  Set<String> _openedLeadIds = {};

  Map<String, String> _conversationMap = {};

  final List<String> _filters = [
    'All Enquiries',
    'Unread',
    'Archived',
    'Pending',
    'Booked',
    'Declined',
  ];

  @override
  void initState() {
    super.initState();
    _loadReadLeads();
    _loadInitialData();
    _searchCtrl.addListener(() {
      setState(() {});
    });
  }

  // ================= ARCHIVE =================

  Future<bool> _archiveLeadOnServer(String inboxId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('authToken');

      if (token == null || token.isEmpty) return false;

      final res = await http.patch(
        Uri.parse('https://happywedz.com/api/inbox/$inboxId/archive'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint("🔥 ARCHIVE ERROR => $e");
      return false;
    }
  }

  // ================= MARK AS READ (SERVER) =================

  Future<void> _markAsReadOnServer(String inboxId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('authToken');

      if (token == null || token.isEmpty) return;

      await http.patch(
        Uri.parse('https://happywedz.com/api/inbox/$inboxId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      debugPrint("🔥 READ API ERROR => $e");
    }
  }

  // ================= DELETE =================

  Future<bool> _deleteLeadOnServer(String inboxId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('authToken');

      if (token == null || token.isEmpty) return false;

      final res = await http.delete(
        Uri.parse('https://happywedz.com/api/inbox/$inboxId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint("🔥 DELETE ERROR => $e");
      return false;
    }
  }
  Future<void> _confirmDelete(String inboxId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Color(0xFF00509D), // dark red border
            width: 2.5,
          ),
        ),
        title: const Text("Delete Lead"),
        content: const Text(
          "Are you sure you want to delete this enquiry?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.black),),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _deleteLeadOnServer(inboxId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lead deleted successfully")),
      );
      await _fetchLeads(); // 🔥 refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete lead")),
      );
    }
  }


  Future<void> _toggleArchive(String inboxId) async {
    final success = await _archiveLeadOnServer(inboxId);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update archive status")),
      );
      return;
    }

    /// 🔥 Always refresh from server (web + mobile sync)
    await _fetchLeads();
  }

  // ================= READ / UNREAD =================

  Future<void> _loadReadLeads() async {
    final prefs = await SharedPreferences.getInstance();
    _openedLeadIds = (prefs.getStringList('read_leads') ?? []).toSet();
  }

  Future<void> _markAsRead(String inboxId) async {
    // 🔥 1. server ko update
    await _markAsReadOnServer(inboxId);

    // 🔥 2. local helper (fast UI)
    final prefs = await SharedPreferences.getInstance();
    _openedLeadIds.add(inboxId);
    await prefs.setStringList('read_leads', _openedLeadIds.toList());

    // 🔥 3. unread count refresh
    await _updateUnreadCount();
  }

  Future<void> _updateUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();

    final unreadCount = _leads.where((item) {
      return item['isRead'] == false && item['isArchived'] == false;
    }).length;

    await prefs.setInt('unread_leads_count', unreadCount);
  }

  // ================= LOAD =================

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _fetchLeads(),
      _fetchConversations(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _fetchLeads() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token') ?? prefs.getString('authToken');

      if (token == null || token.isEmpty) return;

      final res = await http.get(
        Uri.parse('https://happywedz.com/api/inbox'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        setState(() {
          _leads = data["inbox"] ?? [];
        });

        LeadsPage.latestLeads = _leads;
        await _updateUnreadCount();
      }
    } catch (e) {
      debugPrint("🔥 Leads error: $e");
    }
  }

  Future<void> _fetchConversations() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token') ?? prefs.getString('authToken');

      if (token == null) return;

      final res = await http.get(
        Uri.parse("https://happywedz.com/api/messages/vendor/conversations"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);

        for (var c in list) {
          final requestId = c['requestId']?.toString();
          final conversationId = c['id']?.toString();
          print("🟢 Found => requestId: $requestId | conversationId: $conversationId");

          if (requestId != null && conversationId != null) {
            _conversationMap[requestId] = conversationId;
          }
        }
        print("📦 Conversation Map => $_conversationMap");
      }
    } catch (e) {
      debugPrint("🔥 Conversation error: $e");
    }
  }

  // List<dynamic> get _filteredLeads {
  //   final query = _searchCtrl.text.toLowerCase().trim();
  //
  //   List<dynamic> leads = _leads;
  //
  //   switch (_selectedFilter) {
  //     case 'Unread':
  //       leads = leads
  //           .where((l) => l['isRead'] == false && l['isArchived'] == false)
  //           .toList();
  //       break;
  //
  //     case 'Archived':
  //       leads = leads.where((l) => l['isArchived'] == true).toList();
  //       break;
  //
  //     case 'Pending':
  //       leads = leads
  //           .where((l) =>
  //       l['isArchived'] == false &&
  //           (l['request']?['status'] ?? '').toLowerCase() == 'pending')
  //           .toList();
  //       break;
  //
  //     case 'Booked':
  //       leads = leads
  //           .where((l) =>
  //       l['isArchived'] == false &&
  //           (l['request']?['status'] ?? '').toLowerCase() == 'booked')
  //           .toList();
  //       break;
  //
  //     case 'Declined':
  //       leads = leads
  //           .where((l) =>
  //       l['isArchived'] == false &&
  //           (l['request']?['status'] ?? '').toLowerCase() == 'declined')
  //           .toList();
  //       break;
  //
  //     default:
  //       leads = leads.where((l) => l['isArchived'] == false).toList();
  //   }
  //
  //   if (query.isNotEmpty) {
  //     leads = leads.where((l) {
  //       final r = l['request'];
  //       final name =
  //       "${r['firstName'] ?? ''} ${r['lastName'] ?? ''}".toLowerCase();
  //       return name.contains(query);
  //     }).toList();
  //   }
  //
  //   return leads;
  // }
  List<dynamic> get _filteredLeads {
    final query = _searchCtrl.text.toLowerCase().trim();

    // 🔥 STEP 1: SEARCH FIRST (NO FILTER)
    List<dynamic> leads = query.isNotEmpty
        ? _leads.where((l) {
      final r = l['request'];
      final name =
      "${r['firstName'] ?? ''} ${r['lastName'] ?? ''}".toLowerCase();
      return name.contains(query);
    }).toList()
        : List.from(_leads);

    // 🔥 STEP 2: FILTER ONLY WHEN SEARCH IS EMPTY
    if (query.isEmpty) {
      switch (_selectedFilter) {
        case 'Unread':
          leads = leads
              .where((l) => l['isRead'] == false && l['isArchived'] == false)
              .toList();
          break;

        case 'Archived':
          leads = leads.where((l) => l['isArchived'] == true).toList();
          break;

        case 'Pending':
          leads = leads
              .where((l) =>
          l['isArchived'] == false &&
              (l['request']?['status'] ?? '')
                  .toLowerCase() ==
                  'pending')
              .toList();
          break;

        case 'Booked':
          leads = leads
              .where((l) =>
          l['isArchived'] == false &&
              (l['request']?['status'] ?? '')
                  .toLowerCase() ==
                  'booked')
              .toList();
          break;

        case 'Declined':
          leads = leads
              .where((l) =>
          l['isArchived'] == false &&
              (l['request']?['status'] ?? '')
                  .toLowerCase() ==
                  'declined')
              .toList();
          break;

        default:
          leads = leads.where((l) => l['isArchived'] == false).toList();
      }
    }

    return leads;
  }


  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ================= UI (100% SAME) =================

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF003F88),
                  Color(0xFF00509D),
                ],
              ),
            ),
            padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enquirys',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSearch(),
                const SizedBox(height: 10),
                SizedBox(height: 40, child: _buildFilterChips()),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchLeads,
              color: const Color(0xFFFF4D79),
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFFF4D79)),
              )
                  : _filteredLeads.isEmpty
                  ? const Center(
                child: Text(
                  "No leads found",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                itemCount: _filteredLeads.length,
                itemBuilder: (context, index) {
                  return _buildLeadCard(_filteredLeads[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadCard(dynamic item) {
    final lead = item['request'];
    final inboxId = item['id'].toString();

    final name =
    "${lead['firstName'] ?? ''} ${lead['lastName'] ?? ''}".trim();
    final date = lead['eventDate'] ?? 'N/A';
    final status = lead['status'] ?? 'N/A';
    final msg =
    (lead['message'] ?? '').isEmpty ? 'No message' : lead['message'];

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'booked':
        statusColor = const Color(0xFF003F88);
        break;
      case 'pending':
        statusColor = const Color(0xFF4A90E2);
        break;
      case 'declined':
        statusColor = const Color(0xFF89C2D9);
        break;
      default:
        statusColor = const Color(0xFFBFD7ED);
    }

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeadDetailScreen(
              lead: lead,
              conversationId: _conversationMap[inboxId],
            ),
          ),
        );

        await _markAsRead(inboxId);
        await _fetchLeads();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Stack(
          children: [
            ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF00509D),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style:
                  const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Event Date: $date",
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 3),
                    Text(
                      msg.length > 20 ? '${msg.substring(0, 20)}...' : msg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // PopupMenuButton<String>(
                  //   onSelected: (value) async {
                  //     if (value == 'archive') {
                  //       await _toggleArchive(inboxId);
                  //     }
                  //   },
                  //   itemBuilder: (context) => [
                  //     PopupMenuItem(
                  //       value: 'archive',
                  //       child: Text(
                  //         item['isArchived'] ? 'Unarchive' : 'Archive',
                  //       ),
                  //     ),
                  //   ],
                  //   icon:
                  //   const Icon(Icons.more_horiz, color: Colors.grey),
                  // ),
                  PopupMenuButton<String>(
                    color: Colors.white,
                    onSelected: (value) async {
                      if (value == 'archive') {
                        await _toggleArchive(inboxId);
                      } else if (value == 'delete') {
                        await _confirmDelete(inboxId);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                        Icon(
                        item['isArchived']
                        ? Icons.unarchive
                          : Icons.archive,
                          color: Colors.blueGrey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                         Text(
                          item['isArchived'] ? 'Unarchive' : 'Archive',
                        ),
                          ]
                      ),),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  ),

                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchCtrl,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by name, city, event…',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: _filters.map((label) {
        final bool isSelected = _selectedFilter == label;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF00509D)
                    : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: isSelected,
            backgroundColor: Colors.white,
            selectedColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF00509D)
                  : Colors.grey.shade300,
            ),
            onSelected: (_) =>
                setState(() => _selectedFilter = label),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }).toList(),
    );
  }
}
