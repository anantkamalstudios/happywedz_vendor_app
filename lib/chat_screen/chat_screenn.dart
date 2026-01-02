import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final String receiverName;
  final String receiverId;
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.receiverName,
    required this.receiverId,
    required this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  Timer? _chatTimer;

  // ================= FETCH MESSAGES =================
  Future<void> fetchMessages() async {
    final url =
        "https://happywedz.com/api/messages/vendor/conversations/${widget.conversationId}/messages";

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('authToken');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);

        setState(() {
          messages = data.map((msg) {
            final date =
            DateTime.parse(msg["createdAt"]).toLocal();

            final time =
                "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

            return {
              "message": msg["message"],
              "isMe": msg["senderType"] == "vendor",
              "time": time,
            };
          }).toList().reversed.toList();
        });
      } else {
        debugPrint("❌ Fetch error: ${response.body}");
      }
    } catch (e) {
      debugPrint("🔥 Fetch exception: $e");
    }
  }

  // ================= SEND MESSAGE =================
  Future<void> sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    final now = DateTime.now();
    final time =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    // ✅ INSTANT UI UPDATE
    setState(() {
      messages.insert(0, {
        "message": text,
        "isMe": true,
        "time": time,
      });
    });

    _scrollToBottom();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('authToken');
    if (token == null) return;

    final url =
        "https://happywedz.com/api/messages/vendor/conversations/${widget.conversationId}/messages";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"message": text}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint("❌ Send failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("🔥 Send exception: $e");
    }
  }

  // ================= AUTO SCROLL =================
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    fetchMessages();

    // 🔁 auto refresh every 5 seconds
    _chatTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => fetchMessages());
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00509D),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Text(widget.receiverName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                return Align(
                  alignment:
                  msg["isMe"] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: msg["isMe"]
                          ? const Color(0xFF00509D)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg["message"],
                          style: TextStyle(
                            color:
                            msg["isMe"] ? Colors.white : Colors.black,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            msg["time"],
                            style: TextStyle(
                              fontSize: 11,
                              color: msg["isMe"]
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // ================= INPUT =================
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => sendMessage(),
              decoration: InputDecoration(
                hintText: "Type a message...",
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF00509D),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
