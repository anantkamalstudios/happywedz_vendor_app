import 'package:flutter/material.dart';

// class LeadsScreen extends StatefulWidget {
//   const LeadsScreen({Key? key}) : super(key: key);
//
//   @override
//   State<LeadsScreen> createState() => _LeadsScreenState();
// }
//
// class _LeadsScreenState extends State<LeadsScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: const Text("Leads", style: TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.pink[300],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(90),
//           child: Column(
//             children: [
//               // Search bar
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: TextField(
//                   decoration: InputDecoration(
//                     hintText: "Search leads",
//                     prefixIcon: const Icon(Icons.search),
//                     filled: true,
//                     fillColor: Colors.white,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                 ),
//               ),
//               // Tabs
//               TabBar(
//                 controller: _tabController,
//                 indicatorColor: Colors.white,
//                 tabs: const [
//                   Tab(text: "New Leads"),
//                   Tab(text: "Follow-ups"),
//                   Tab(text: "Archived"),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildLeadsList(),
//           _buildLeadsList(),
//           _buildLeadsList(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLeadsList() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(8),
//       itemCount: 5,
//       itemBuilder: (context, index) {
//         return Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//           elevation: 2,
//           margin: const EdgeInsets.symmetric(vertical: 6),
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Name and date
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text("Priya Sharma",
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold, fontSize: 16)),
//                     Text("12 Aug 2025",
//                         style: TextStyle(color: Colors.grey[600], fontSize: 12)),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 // Location
//                 Row(
//                   children: const [
//                     Icon(Icons.location_on, size: 16, color: Colors.grey),
//                     SizedBox(width: 4),
//                     Text("Mumbai", style: TextStyle(fontSize: 13)),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 // Action buttons
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     OutlinedButton.icon(
//                       onPressed: () {},
//                       icon: const Icon(Icons.call, size: 18),
//                       label: const Text("Call"),
//                       style: OutlinedButton.styleFrom(
//                         side: BorderSide(color: Colors.pinkAccent),
//                         foregroundColor: Colors.pinkAccent,
//                       ),
//                     ),
//                     OutlinedButton.icon(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => ChatPage(contactName: "Priya Sharma"),
//                           ),
//                         );
//                       },
//                       icon: const Icon(Icons.chat, size: 18),
//                       label: const Text("Chat"),
//                       style: OutlinedButton.styleFrom(
//                         side: BorderSide(color: Colors.pinkAccent),
//                         foregroundColor: Colors.pinkAccent,
//                       ),
//                     ),
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const LeadDetailsScreen(
//                               name: "Priya Sharma",
//                               date: "12 Aug 2025",
//                               location: "Mumbai",
//                             ),
//                           ),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.pinkAccent,
//                       ),
//                       child: const Text("View Details"),
//                     ),
//
//                   ],
//                 )
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
//
//
//
//
//
// class LeadDetailsScreen extends StatelessWidget {
//   final String name;
//   final String date;
//   final String location;
//
//   const LeadDetailsScreen({
//     Key? key,
//     required this.name,
//     required this.date,
//     required this.location,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.pink[100],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Name & Date
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   name,
//                   style: const TextStyle(
//                       fontWeight: FontWeight.bold, fontSize: 20),
//                 ),
//                 Text(
//                   date,
//                   style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//
//             // Location
//             Row(
//               children: [
//                 const Icon(Icons.location_on, color: Colors.grey, size: 18),
//                 const SizedBox(width: 4),
//                 Text(location, style: const TextStyle(fontSize: 14)),
//               ],
//             ),
//             const SizedBox(height: 20),
//
//             const Divider(),
//
//             // Example extra details
//             const Text(
//               "Lead Information",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               "• Event Type: Wedding\n"
//                   "• Budget: ₹3,00,000\n"
//                   "• Preferred Date: 25 Sep 2025\n"
//                   "• Notes: Wants a beach wedding setup",
//               style: TextStyle(fontSize: 14),
//             ),
//
//             const Spacer(),
//
//             // Action buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 OutlinedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(Icons.call, size: 18),
//                   label: const Text("Call"),
//                   style: OutlinedButton.styleFrom(
//                     side: const BorderSide(color: Colors.pinkAccent),
//                     foregroundColor: Colors.pinkAccent,
//                   ),
//                 ),
//                 OutlinedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(Icons.chat, size: 18),
//                   label: const Text("Chat"),
//                   style: OutlinedButton.styleFrom(
//                     side: const BorderSide(color: Colors.pinkAccent),
//                     foregroundColor: Colors.pinkAccent,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
// class ChatPage extends StatefulWidget {
//   final String contactName;
//
//   const ChatPage({super.key, required this.contactName});
//
//   @override
//   _ChatPageState createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final List<_Message> messages = [
//     _Message(text: "Hello! How can I help you?", isSentByMe: false, time: "10:00 AM"),
//     _Message(text: "I want to know about your services.", isSentByMe: true, time: "10:02 AM"),
//     _Message(text: "Sure! Let me share the details.", isSentByMe: false, time: "10:05 AM"),
//   ];
//
//   final TextEditingController _controller = TextEditingController();
//
//   void _sendMessage() {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;
//
//     setState(() {
//       messages.add(_Message(text: text, isSentByMe: true, time: "Now"));
//     });
//
//     _controller.clear();
//
//     // Scroll to bottom can be implemented if desired.
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(widget.contactName, style: const TextStyle(fontSize: 18)),
//             const Text("Online", style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
//           ],
//         ),
//         backgroundColor: Colors.pinkAccent,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: messages.length,
//               itemBuilder: (context, index) {
//                 final msg = messages[index];
//                 return Align(
//                   alignment: msg.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(vertical: 4),
//                     padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
//                     constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
//                     decoration: BoxDecoration(
//                       color: msg.isSentByMe ? Colors.pinkAccent : Colors.grey.shade300,
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(12),
//                         topRight: Radius.circular(12),
//                         bottomLeft: msg.isSentByMe ? Radius.circular(12) : Radius.zero,
//                         bottomRight: msg.isSentByMe ? Radius.zero : Radius.circular(12),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text(
//                           msg.text,
//                           style: TextStyle(color: msg.isSentByMe ? Colors.white : Colors.black87, fontSize: 16),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           msg.time,
//                           style: TextStyle(
//                             color: msg.isSentByMe ? Colors.white70 : Colors.black54,
//                             fontSize: 10,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           const Divider(height: 1),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       hintText: "Type your message...",
//                       border: InputBorder.none,
//                     ),
//                     minLines: 1,
//                     maxLines: 5,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send, color: Colors.pinkAccent),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
//
// class _Message {
//   final String text;
//   final bool isSentByMe;
//   final String time;
//
//   _Message({required this.text, required this.isSentByMe, required this.time});
// }
//







class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> with TickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _sort = 'Newest';
  final Set<String> _activeChips = {'All Budgets', 'All Cities', 'This Month'};

  final List<Lead> _allLeads = [
    Lead(
      name: 'Aarav Sharma',
      eventType: 'Wedding',
      eventDate: DateTime.now().add(const Duration(days: 18)),
      budget: '₹6–8L',
      city: 'Pune',
      status: LeadStatus.newLead,
      source: 'WedMeGood',
      phone: '+91 98765 43210',
      notes: 'Prefers evening ceremony; wants outdoor venue.',
      priority: 'High',
    ),
    Lead(
      name: 'Ishita & Rohan',
      eventType: 'Engagement',
      eventDate: DateTime.now().add(const Duration(days: 5)),
      budget: '₹2–3L',
      city: 'Mumbai',
      status: LeadStatus.active,
      source: 'Instagram',
      phone: '+91 90000 12345',
      notes: 'Asks for pastel theme decor.',
      priority: 'Medium',
    ),
    Lead(
      name: 'Neha Gupta',
      eventType: 'Wedding',
      eventDate: DateTime.now().add(const Duration(days: 42)),
      budget: '₹10–12L',
      city: 'Delhi',
      status: LeadStatus.followUp,
      source: 'Referral',
      phone: '+91 99876 55110',
      notes: 'Shortlist sent. Follow-up on package 2.',
      priority: 'High',
    ),
    Lead(
      name: 'Karan Mehta',
      eventType: 'Reception',
      eventDate: DateTime.now().add(const Duration(days: 60)),
      budget: '₹4–5L',
      city: 'Jaipur',
      status: LeadStatus.archived,
      source: 'Website',
      phone: '+91 91234 56780',
      notes: 'Postponed to next season.',
      priority: 'Low',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TabMeta('New', LeadStatus.newLead),
      _TabMeta('Active', LeadStatus.active),
      _TabMeta('Follow-up', LeadStatus.followUp),
      _TabMeta('Archived', LeadStatus.archived),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddLeadSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Lead'),
        ),
        body: CustomScrollView(
          slivers: [
            _GradientHeader(
              title: 'Leads',
              searchField: _buildSearch(),
              onFilterTap: () => _showFilterSheet(context),
              onSortTap: () => _showSortSheet(context),
              sortLabel: _sort,
              chipsBar: _buildChipsBar(),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: tabs.map((t) {
                  final count = _filtered(t.status).length;
                  return Tab(text: '${t.title} ($count)');
                }).toList(),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                children: tabs.map((t) {
                  final leads = _filtered(t.status);
                  if (leads.isEmpty) {
                    return _EmptyState(
                      title: 'No ${t.title.toLowerCase()} leads',
                      subtitle: 'Try adjusting filters or check other tabs.',
                      onClear: _clearFiltersIfAny,
                      showClear: _activeChips.isNotEmpty,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: leads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => LeadCard(
                      lead: leads[i],
                      onCall: () => _call(leads[i]),
                      onWhatsApp: () => _whatsapp(leads[i]),
                      onDismiss: () => _dismiss(leads[i]),
                      onTap: () => _openLead(context, leads[i]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widgets

  Widget _buildSearch() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
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

  Widget _buildChipsBar() {
    final allChips = ['All Budgets', '₹0–3L', '₹3–6L', '₹6–10L', '₹10L+',
      'All Cities', 'Delhi', 'Mumbai', 'Pune', 'Jaipur',
      'Any Time', 'This Week', 'This Month', 'Next 3 Months',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: allChips.map((label) {
          final selected = _activeChips.contains(label);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  // Make "All Budgets/All Cities/Any Time" mutually exclusive with their groups
                  if (label == 'All Budgets') {
                    _activeChips.removeWhere((c) => c.contains('₹'));
                    _activeChips.add('All Budgets');
                  } else if (label.contains('₹')) {
                    _activeChips.remove('All Budgets');
                    _toggle(label);
                  } else if (label == 'All Cities') {
                    _activeChips.removeWhere((c) => ['Delhi','Mumbai','Pune','Jaipur'].contains(c));
                    _activeChips.add('All Cities');
                  } else if (['Delhi','Mumbai','Pune','Jaipur'].contains(label)) {
                    _activeChips.remove('All Cities');
                    _toggle(label);
                  } else if (label == 'Any Time') {
                    _activeChips.removeWhere((c) => ['This Week','This Month','Next 3 Months'].contains(c));
                    _activeChips.add('Any Time');
                  } else {
                    _toggle(label);
                  }
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _toggle(String label) {
    if (_activeChips.contains(label)) {
      _activeChips.remove(label);
    } else {
      _activeChips.add(label);
    }
  }

  // Filtering

  List<Lead> _filtered(LeadStatus tab) {
    Iterable<Lead> data = _allLeads.where((l) => l.status == tab);

    // Search
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      data = data.where((l) =>
      l.name.toLowerCase().contains(q) ||
          l.city.toLowerCase().contains(q) ||
          l.eventType.toLowerCase().contains(q));
    }

    // Budget chips
    final budgetChips = _activeChips.where((c) => c.contains('₹')).toList();
    if (_activeChips.contains('All Budgets')) {
      // no-op
    } else if (budgetChips.isNotEmpty) {
      data = data.where((l) => budgetChips.any((c) => l.budget.contains(c.replaceAll(' ', '')) || l.budget.contains(c)));
    }

    // City chips
    final cityChips = _activeChips.where((c) => ['Delhi','Mumbai','Pune','Jaipur'].contains(c)).toList();
    if (_activeChips.contains('All Cities')) {
      // no-op
    } else if (cityChips.isNotEmpty) {
      data = data.where((l) => cityChips.contains(l.city));
    }

    // Time chips
    if (_activeChips.contains('Any Time')) {
      // no-op
    } else {
      final now = DateTime.now();
      if (_activeChips.contains('This Week')) {
        final end = now.add(Duration(days: 7 - now.weekday));
        data = data.where((l) => l.eventDate.isBefore(end));
      }
      if (_activeChips.contains('This Month')) {
        final end = DateTime(now.year, now.month + 1, 0);
        data = data.where((l) => l.eventDate.isBefore(end));
      }
      if (_activeChips.contains('Next 3 Months')) {
        final end = DateTime(now.year, now.month + 3, now.day);
        data = data.where((l) => l.eventDate.isBefore(end));
      }
    }

    // Sort
    final list = data.toList();
    switch (_sort) {
      case 'Newest':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Event Date':
        list.sort((a, b) => a.eventDate.compareTo(b.eventDate));
        break;
      case 'Budget (High)':
        list.sort((a, b) => _budgetValue(b.budget).compareTo(_budgetValue(a.budget)));
        break;
      case 'Budget (Low)':
        list.sort((a, b) => _budgetValue(a.budget).compareTo(_budgetValue(b.budget)));
        break;
    }
    return list;
  }

  int _budgetValue(String range) {
    // Rough extractor from strings like "₹6–8L"
    final nums = RegExp(r'(\d+)').allMatches(range).map((m) => int.tryParse(m.group(0)!) ?? 0).toList();
    if (nums.isEmpty) return 0;
    return (nums.reduce((a, b) => a + b) / nums.length * 100000).round(); // convert L to rough INR
  }

  // Actions

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, bottom: 16, top: 8 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetGrab(title: 'Filters'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activeChips.map((c) => Chip(
                label: Text(c),
                onDeleted: () => setState(() => _activeChips.remove(c)),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _activeChips.clear()),
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final options = ['Newest', 'Event Date', 'Budget (High)', 'Budget (Low)'];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetGrab(title: 'Sort by'),
          ...options.map((o) => RadioListTile<String>(
            title: Text(o),
            value: o,
            groupValue: _sort,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _sort = v);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAddLeadSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final budgetCtrl = TextEditingController(text: '₹2–3L');
    DateTime? eventDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 8,
          bottom: MediaQuery.of(c).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetGrab(title: 'Add Lead'),
            TextField(decoration: const InputDecoration(labelText: 'Name'), controller: nameCtrl),
            TextField(decoration: const InputDecoration(labelText: 'City'), controller: cityCtrl),
            TextField(decoration: const InputDecoration(labelText: 'Budget (e.g., ₹2–3L)'), controller: budgetCtrl),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event),
                    label: Text(eventDate == null ? 'Pick Event Date' : _fmtDate(eventDate!)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: c,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                      );
                      if (picked != null) {
                        setState(() {});
                        eventDate = picked;
                        // ignore: use_build_context_synchronously
                        Navigator.pop(c);
                        _showAddLeadSheet(context);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty || cityCtrl.text.trim().isEmpty || eventDate == null) {
                        Navigator.pop(c);
                        return;
                      }
                      setState(() {
                        _allLeads.add(Lead(
                          name: nameCtrl.text.trim(),
                          city: cityCtrl.text.trim(),
                          budget: budgetCtrl.text.trim().isEmpty ? '₹2–3L' : budgetCtrl.text.trim(),
                          eventDate: eventDate!,
                          eventType: 'Wedding',
                          source: 'Manual',
                          phone: '',
                          notes: '',
                          status: LeadStatus.newLead,
                          priority: 'Medium',
                        ));
                      });
                      Navigator.pop(c);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _call(Lead l) {
    // Hook your dialer intent here
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling ${l.name}…')));
  }

  void _whatsapp(Lead l) {
    // Hook your WhatsApp intent/url here
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening WhatsApp with ${l.name}…')));
  }

  void _dismiss(Lead l) {
    setState(() {
      l.status = LeadStatus.archived;
    });
  }

  void _openLead(BuildContext context, Lead l) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetGrab(title: l.name),
            const SizedBox(height: 4),
            Text('${l.eventType} • ${_fmtDate(l.eventDate)} • ${l.city}', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                LeadCard._chip('Budget: ${l.budget}', Icons.wallet),
                LeadCard._chip('Source: ${l.source}', Icons.campaign),
                LeadCard._chip('Priority: ${l.priority}', Icons.flag),
              ],
            ),
            const SizedBox(height: 12),
            Text(l.notes.isEmpty ? 'No notes yet.' : l.notes),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => _call(l), icon: const Icon(Icons.call), label: const Text('Call'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton.icon(onPressed: () => _whatsapp(l), icon:  Icon(Icons.call), label: const Text('WhatsApp'))),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _clearFiltersIfAny() {
    if (_activeChips.isNotEmpty) {
      setState(() => _activeChips.clear());
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

Widget buildChip(String text, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F4FF),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0x22000000)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

// UI pieces

class _GradientHeader extends StatelessWidget {
  final String title;
  final PreferredSizeWidget? bottom;
  final Widget searchField;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;
  final String sortLabel;
  final Widget chipsBar;

  const _GradientHeader({
    required this.title,
    required this.searchField,
    required this.onFilterTap,
    required this.onSortTap,
    required this.sortLabel,
    required this.chipsBar,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      expandedHeight: 220,
      toolbarHeight: kToolbarHeight,
      backgroundColor: Colors.deepPurple,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF4D79), Color(0xFFFF6FAF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + actions
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onFilterTap,
                    icon: const Icon(Icons.tune, color: Colors.white),
                    tooltip: 'Filters',
                  ),
                  IconButton(
                    onPressed: onSortTap,
                    icon: const Icon(Icons.sort, color: Colors.white),
                    tooltip: 'Sort',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Search
              searchField,
              const SizedBox(height: 8),
              // Quick chips
              SizedBox(height: 36, child: chipsBar),
              const SizedBox(height: 6),
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: Container(
              //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              //     decoration: BoxDecoration(
              //       color: Colors.white.withOpacity(0.18),
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     child: Text(
              //       'Sort: $sortLabel',
              //       style: const TextStyle(color: Colors.white),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
      bottom: bottom,
    );
  }
}

class _SheetGrab extends StatelessWidget {
  final String title;
  const _SheetGrab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClear;
  final bool showClear;

  const _EmptyState({super.key, required this.title, required this.subtitle, required this.onClear, required this.showClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.black26),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center),
            if (showClear) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onClear, child: const Text('Clear Filters')),
            ],
          ],
        ),
      ),
    );
  }
}

// Lead card

class LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const LeadCard({
    super.key,
    required this.lead,
    required this.onCall,
    required this.onWhatsApp,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = lead.eventDate.difference(DateTime.now()).inDays;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
          border: Border.all(color: const Color(0x11000000)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.deepPurple.shade50,
                  child: const Icon(Icons.person, color: Colors.deepPurple),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lead.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _pill(lead.priority, icon: Icons.flag, color: _priorityColor(lead.priority)),
              ],
            ),
            const SizedBox(height: 10),
            // Info row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(' ${lead.eventType} • ${_fmtDate(lead.eventDate)}', Icons.event),
                _chip(' ${lead.city}', Icons.location_on),
                _chip(' ${lead.budget}', Icons.wallet),
                _chip(' ${lead.source}', Icons.campaign),
                if (daysLeft >= 0) _chip(' ${daysLeft}d left', Icons.hourglass_bottom),
              ],
            ),
            if (lead.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(lead.notes, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: onCall, icon: const Icon(Icons.call), label: const Text('Call'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: onWhatsApp, icon:  Icon(Icons.call), label: const Text('WhatsApp'))),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDismiss,
                  tooltip: 'Archive',
                  icon: const Icon(Icons.archive_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _chip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x22000000)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  static Widget _pill(String text, {required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.36)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      default: return Colors.grey;
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// Model

enum LeadStatus { newLead, active, followUp, archived }

class Lead {
  Lead({
    required this.name,
    required this.eventType,
    required this.eventDate,
    required this.budget,
    required this.city,
    required this.status,
    required this.source,
    required this.phone,
    required this.notes,
    required this.priority,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String name;
  String eventType;
  DateTime eventDate;
  String budget;
  String city;
  LeadStatus status;
  String source;
  String phone;
  String notes;
  String priority;
  DateTime createdAt;
}

class _TabMeta {
  final String title;
  final LeadStatus status;
  _TabMeta(this.title, this.status);
}





