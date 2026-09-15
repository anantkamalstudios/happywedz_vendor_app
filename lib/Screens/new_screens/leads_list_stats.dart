import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'leaddetails_screen.dart';

class LeadsListScreen extends StatelessWidget {
  final List<dynamic> leads;

  const LeadsListScreen({super.key, required this.leads});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Leads"),
        backgroundColor: const Color(0xFF00509D),
        foregroundColor: Colors.white,
      ),
      body: leads.isEmpty
          ? const Center(
        child: Text(
          "No leads found",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final lead = leads[index];

          final name =
          "${lead["firstName"] ?? ""} ${lead["lastName"] ?? ""}".trim();
          final email = lead["email"] ?? "-";
          final phone = lead["phone"] ?? "-";
          final message = lead["message"] ?? "-";

          final eventDateStr = lead["eventDate"];
          final eventDate = eventDateStr != null
              ? DateFormat("dd MMM yyyy")
              .format(DateTime.parse(eventDateStr))
              : "-";

          final createdAtStr = lead["createdAt"];
          final createdDate = createdAtStr != null
              ? DateFormat("dd MMM yyyy")
              .format(DateTime.parse(createdAtStr))
              : "-";

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// NAME
                Text(
                  name.isEmpty ? "Unknown User" : name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                _infoRow(Icons.email, email),
                _infoRow(Icons.phone, phone),
                _infoRow(Icons.event, "Event: $eventDate"),
                _infoRow(Icons.calendar_today, "Created: $createdDate"),

                const SizedBox(height: 10),

                /// MESSAGE
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 14),

                /// 🔥 SEND QUOTATION BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LeadDetailScreen(
                            lead: lead, // 👈 SAME USER DATA
                            conversationId:
                            lead['conversationId']?.toString(),
                            openQuotation: true, // 👈 MAGIC FLAG
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00509D),
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
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
        },
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
