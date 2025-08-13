import 'package:flutter/material.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({Key? key}) : super(key: key);

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Leads", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink[300],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search leads",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: "New Leads"),
                  Tab(text: "Follow-ups"),
                  Tab(text: "Archived"),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeadsList(),
          _buildLeadsList(),
          _buildLeadsList(),
        ],
      ),
    );
  }

  Widget _buildLeadsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Priya Sharma",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("12 Aug 2025",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                // Location
                Row(
                  children: const [
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text("Mumbai", style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text("Call"),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.pinkAccent),
                        foregroundColor: Colors.pinkAccent,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(contactName: "Priya Sharma"),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text("Chat"),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.pinkAccent),
                        foregroundColor: Colors.pinkAccent,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LeadDetailsScreen(
                              name: "Priya Sharma",
                              date: "12 Aug 2025",
                              location: "Mumbai",
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                      ),
                      child: const Text("View Details"),
                    ),

                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}






class LeadDetailsScreen extends StatelessWidget {
  final String name;
  final String date;
  final String location;

  const LeadDetailsScreen({
    Key? key,
    required this.name,
    required this.date,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 18),
                const SizedBox(width: 4),
                Text(location, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 20),

            const Divider(),

            // Example extra details
            const Text(
              "Lead Information",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              "• Event Type: Wedding\n"
                  "• Budget: ₹3,00,000\n"
                  "• Preferred Date: 25 Sep 2025\n"
                  "• Notes: Wants a beach wedding setup",
              style: TextStyle(fontSize: 14),
            ),

            const Spacer(),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text("Call"),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.pinkAccent),
                    foregroundColor: Colors.pinkAccent,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text("Chat"),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.pinkAccent),
                    foregroundColor: Colors.pinkAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}







class ChatPage extends StatefulWidget {
  final String contactName;

  const ChatPage({super.key, required this.contactName});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<_Message> messages = [
    _Message(text: "Hello! How can I help you?", isSentByMe: false, time: "10:00 AM"),
    _Message(text: "I want to know about your services.", isSentByMe: true, time: "10:02 AM"),
    _Message(text: "Sure! Let me share the details.", isSentByMe: false, time: "10:05 AM"),
  ];

  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add(_Message(text: text, isSentByMe: true, time: "Now"));
    });

    _controller.clear();

    // Scroll to bottom can be implemented if desired.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contactName, style: const TextStyle(fontSize: 18)),
            const Text("Online", style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
          ],
        ),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment: msg.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: msg.isSentByMe ? Colors.pinkAccent : Colors.grey.shade300,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                        bottomLeft: msg.isSentByMe ? Radius.circular(12) : Radius.zero,
                        bottomRight: msg.isSentByMe ? Radius.zero : Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(color: msg.isSentByMe ? Colors.white : Colors.black87, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.time,
                          style: TextStyle(
                            color: msg.isSentByMe ? Colors.white70 : Colors.black54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                      border: InputBorder.none,
                    ),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.pinkAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isSentByMe;
  final String time;

  _Message({required this.text, required this.isSentByMe, required this.time});
}












