import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  // ✅ Shared static list to access from HomeTab
  static List<dynamic> latestLeads = [];

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _sort = 'Newest';
  String _selectedFilter = 'All Enquiries';
  bool _isLoading = true;
  List<dynamic> _leads = [];

  final List<String> _filters = [
    'All Enquiries',
    'Unread',
    'Archived',
    'Pending',
    'Booked',
    'Declined',
  ];

  Set<String> _openedLeadIds = {};
  Set<String> _archivedLeadIds = {};

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token') ?? prefs.getString('authToken');

      if (token == null || token.isEmpty) {
        print("🔴 No token found.");
        setState(() => _isLoading = false);
        return;
      }

      final uri = Uri.parse('https://happywedz.com/api/inbox');
      final res = await http.get(
        uri,
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      print("🟣 API ${res.statusCode}");
      print(res.body);

      dynamic data = json.decode(res.body);
      if (res.statusCode == 200 && data is Map) {
        setState(() {
          _leads = data["inbox"] ?? data["data"] ?? [];
          LeadsPage.latestLeads = _leads; // ✅ store globally
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("🔥 Exception: $e");
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredLeads {
    final leads = _leads.map((l) => l['request'] ?? l).toList();

    switch (_selectedFilter) {
      case 'Unread':
        return leads
            .where((l) => !_openedLeadIds.contains((l['_id'] ?? l['id']).toString()))
            .toList();
      case 'Archived':
        return leads
            .where((l) => _archivedLeadIds.contains((l['_id'] ?? l['id']).toString()))
            .toList();
      case 'Pending':
        return leads
            .where((l) => (l['status'] ?? '').toString().toLowerCase() == 'pending')
            .toList();
      case 'Booked':
        return leads
            .where((l) => (l['status'] ?? '').toString().toLowerCase() == 'booked')
            .toList();
      case 'Declined':
        return leads
            .where((l) => (l['status'] ?? '').toString().toLowerCase() == 'declined')
            .toList();
      default:
        return leads
            .where((l) => !_archivedLeadIds.contains((l['_id'] ?? l['id']).toString()))
            .toList();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
                  Color(0xFF003F88), // French Blue
                  Color(0xFF00509D), // Steel Azure
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Leads',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                  ],
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
                child: CircularProgressIndicator(color: Color(0xFFFF4D79)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _filteredLeads.length,
                itemBuilder: (context, index) {
                  final lead = _filteredLeads[index];
                  return _buildLeadCard(lead);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadCard(dynamic lead) {
    final name = "${lead['firstName'] ?? ''} ${lead['lastName'] ?? ''}".trim();
    final date = lead['eventDate'] ?? 'N/A';
    final status = lead['status'] ?? 'N/A';
    final msg = (lead['message'] ?? '').isEmpty ? 'No message' : lead['message'];
    final id = (lead['_id'] ?? lead['id'] ?? '').toString();

    // 🔵 BLUE THEME STATUS COLORS
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'booked':
        statusColor = const Color(0xFF003F88); // Dark Steel Blue
        break;
      case 'pending':
        statusColor = const Color(0xFF4A90E2); // Medium Blue
        break;
      case 'declined':
        statusColor = const Color(0xFF89C2D9); // Light Blue
        break;
      default:
        statusColor = const Color(0xFFBFD7ED); // Very Light Blue
    }

    return InkWell(
      onTap: () async {
        _openedLeadIds.add(id);
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)),
        );
        if (updated == true) _fetchLeads();
        setState(() {});
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

              // 🔵 Avatar blue color
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF00509D),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),

              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black,
                        decoration: _archivedLeadIds.contains(id)
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
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

            // ⋮ Menu + Status Badge
            Positioned(
              right: 10,
              top: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'archive') {
                        setState(() {
                          if (_archivedLeadIds.contains(id)) {
                            _archivedLeadIds.remove(id);
                          } else {
                            _archivedLeadIds.add(id);
                          }
                        });
                      }

                      if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Delete Lead"),
                            content: const Text(
                                "Are you sure you want to delete this lead?"),
                            actions: [
                              TextButton(
                                child: const Text("Cancel"),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextButton(
                                child: const Text("Delete",
                                    style: TextStyle(color: Colors.red)),
                                onPressed: () {
                                  setState(() {
                                    _leads.removeWhere((item) =>
                                    (item['_id'] ?? item['id'])
                                        .toString() ==
                                        id);
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(
                          _archivedLeadIds.contains(id)
                              ? 'Unarchive'
                              : 'Archive',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  ),

                  const SizedBox(height: 4),

                  // 🔵 BLUE STATUS BADGE
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
                    ? const Color(0xFF00509D)  // Steel Azure text
                    : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),

            selected: isSelected,

            // Always white background
            backgroundColor: Colors.white,
            selectedColor: Colors.white,

            // Border becomes Steel Azure when selected
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF00509D)
                  : Colors.grey.shade300,
            ),

            onSelected: (_) => setState(() => _selectedFilter = label),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }).toList(),
    );
  }



}


class LeadDetailScreen extends StatefulWidget {
  final dynamic lead;
  const LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen>
    with SingleTickerProviderStateMixin {
  late String currentStatus;
  late AnimationController _controller;
  late Animation<double> fadeAnim;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.lead['status'] ?? 'Pending';

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ✅ PATCH API to update status
  Future<void> _updateStatus(String newStatus) async {
    try {
      setState(() => _isLoading = true);

      // ✅ Load auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('authToken');

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No auth token found. Please log in.")),
        );
        return;
      }

      // ✅ Use correct ID — adjust if your API returns nested data
      final leadId = widget.lead['_id'] ?? widget.lead['id'] ?? widget.lead['requestId'];
      if (leadId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lead ID missing.")),
        );
        return;
      }

      final url = Uri.parse("https://happywedz.com/api/inbox/request/$leadId/status");
      print("🟢 PATCH -> $url");

      final body = jsonEncode({"newStatus": newStatus.toLowerCase()});
      print("📦 Body: $body");

      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      print("🟣 Response ${response.statusCode}: ${response.body}");

      if (response.statusCode == 200) {
        setState(() => currentStatus = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Status updated to $newStatus")),
        );

        Navigator.pop(context, true); // ✅ trigger refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Failed to update status (${response.statusCode})"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("🔥 Exception while updating status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendQuotation({
    required String leadId,
    required String price,
    required String validTill,
    required String services,
    required String message,
  }) async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('authToken');

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No auth token found. Please log in.")),
        );
        return;
      }

      final url = Uri.parse("https://happywedz.com/api/request-pricing/requests/$leadId/quotation");

      final servicesList = services
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final body = jsonEncode({
        "price": int.tryParse(price) ?? 0,
        "validTill": validTill,
        "servicesIncluded": servicesList,
        "message": message,
      });

      print("📤 Sending POST request to: $url");
      print("📦 Request body: $body");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      print("📥 Response status: ${response.statusCode}");
      print("📥 Raw response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          print("✅ Parsed JSON response:");
          print(const JsonEncoder.withIndent('  ').convert(responseData));
        } catch (e) {
          print("⚠️ Could not parse JSON response: $e");
        }

        Navigator.of(context).pop(); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Quotation sent successfully!")),
        );
      } else {
        print("❌ Error from API (${response.statusCode}): ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Failed to send quotation (${response.statusCode})"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stack) {
      print("⚠️ Exception while sending quotation: $e");
      print(stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }




  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;

    final name = "${lead['firstName'] ?? ''} ${lead['lastName'] ?? ''}".trim();
    final email = lead['email'] ?? 'N/A';
    final phone = lead['phone'] ?? lead['phoneNumber'] ?? 'N/A';
    final eventDate = lead['eventDate'] ?? 'N/A';
    final receivedDate = lead['createdAt'] ?? 'N/A';
    final message = lead['message'] ?? 'No message';

    Color statusColor = _getStatusColor(currentStatus);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lead Details'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0072BB),
        foregroundColor: Colors.white,


      ),

      body: Stack(
        children: [
          FadeTransition(
            opacity: fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Hero(
                    tag: lead['_id'].toString(),
                    child: _buildProfileCard(name),
                  ),
                  const SizedBox(height: 20),
                  _buildAnimatedBox("Email", email),
                  _buildAnimatedBox("Phone", phone),
                  _buildAnimatedBox("Event Date", eventDate),
                  _buildAnimatedBox("Received", receivedDate),
                  const SizedBox(height: 20),
                  _buildStatus(currentStatus, statusColor),
                  const SizedBox(height: 20),
                  _buildMessageCard(message),
                  const SizedBox(height: 25),
                  _buildStatusButtons(),
                  const SizedBox(height: 40),
                  _replyButton(),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4682B4), // Steel Azure
                ),
              ),
            ),

        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {

      case 'booked':
        return const Color(0xFF003F88); // Deep Steel Blue (Primary)

      case 'pending':
        return const Color(0xFF4A90E2); // Medium Sky Blue

      case 'declined':
        return const Color(0xFF89C2D9); // Light Desaturated Blue

      default:
        return const Color(0xFFBFD7ED); // Very light blue
    }
  }


  Widget _buildProfileCard(String name) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF00509D), // ← UPDATED CARD COLOR
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white, // ← text unchanged
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }


  Widget _buildAnimatedBox(String title, String value) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(fadeAnim),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              offset: const Offset(0, 3),
              color: Colors.black12,
            )
          ],
        ),
        child: Row(
          children: [
            Text(
              "$title: ",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(String status, Color color) {
    return Chip(
      backgroundColor: color.withOpacity(0.15),
      label: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildMessageCard(String message) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildStatusButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statusButton("Pending", const Color(0xFF4A90E2)),   // Medium Blue
        _statusButton("Booked", const Color(0xFF003F88)),    // Dark Steel Blue
        _statusButton("Declined", const Color(0xFF89C2D9)),  // Light Blue
      ],
    );
  }


  Widget _statusButton(String label, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton(
            onPressed: () => _updateStatus(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.15),
              foregroundColor: color,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _replyButton() {
    return ElevatedButton.icon(
      onPressed: () => _showQuotationDialog(context),
      icon: const Icon(Icons.reply),
      label: const Text("Reply to Enquiry"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4682B4), // Steel Azure
        foregroundColor: Colors.white, // Text and icon color white
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }



  void _showQuotationDialog(BuildContext context) {
    final TextEditingController priceCtrl = TextEditingController();
    final TextEditingController servicesCtrl = TextEditingController();
    final TextEditingController validTillCtrl = TextEditingController();
    final TextEditingController messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Centered Title
                  Center(
                    child: Column(
                      children: const [
                        Text(
                          "Quotations",
                          style: TextStyle(
                            fontSize: 22,
                            color: Color(0xFF00509D), // title color
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text("Fill up details",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Price
                  const Text("Price"),
                  const SizedBox(height: 6),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "0",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Services
                  const Text("Services"),
                  const SizedBox(height: 6),
                  TextField(
                    controller: servicesCtrl,
                    decoration: InputDecoration(
                      hintText: "e.g., Photography, Videography, Album",
                      helperText:
                      "Enter service details. This is sent as a list to the API.",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Valid Till Date
                  const Text("Valid Till Date"),
                  const SizedBox(height: 6),
                  TextField(
                    controller: validTillCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: "dd-mm-yyyy",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today_outlined),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            validTillCtrl.text =
                            "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                          }
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Message
                  const Text("Message"),
                  const SizedBox(height: 6),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 5,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      hintText: "Your Message",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Final Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final leadId = widget.lead['_id']?.toString() ??
                            widget.lead['id']?.toString();
                        if (leadId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Lead ID missing.")),
                          );
                          return;
                        }

                        if (priceCtrl.text.isEmpty ||
                            validTillCtrl.text.isEmpty ||
                            servicesCtrl.text.isEmpty ||
                            messageCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all fields.")),
                          );
                          return;
                        }

                        _sendQuotation(
                          leadId: leadId,
                          price: priceCtrl.text,
                          validTill: validTillCtrl.text,
                          services: servicesCtrl.text,
                          message: messageCtrl.text,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00509D),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:  Text(
                        "Send",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,  // <-- White text
                        ),
                      ),

                    ),
                    ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }



}
