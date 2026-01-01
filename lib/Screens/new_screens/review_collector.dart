// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../utils/common_app_bar.dart';
// import 'package:flutter/services.dart';
//
//
// class ReviewCollectorScreen extends StatefulWidget {
//   const ReviewCollectorScreen({Key? key}) : super(key: key);
//
//   @override
//   State<ReviewCollectorScreen> createState() => _ReviewCollectorScreenState();
// }
//
// class _ReviewCollectorScreenState extends State<ReviewCollectorScreen> {
//   static const Color primaryBlue = Color(0xFF00509D);
//   static const Color lightBlue = Color(0xFF4682B4);
//
//   bool isLoading = true;
//   bool sending = false;
//
//   List<dynamic> bookedInbox = [];
//   dynamic selectedCustomer;
//
//   final TextEditingController messageCtrl = TextEditingController();
//   final TextEditingController nameCtrl = TextEditingController();
//   final TextEditingController emailCtrl = TextEditingController();
//
//   String reviewLink = "";
//
//   // ================= INIT =================
//   @override
//   void initState() {
//     super.initState();
//     _fetchBookedInbox();
//   }
//
//   // ================= GET BOOKED INBOX =================
//   Future<void> _fetchBookedInbox() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');
//
//     if (token == null) return;
//
//     try {
//       final res = await http.get(
//         Uri.parse("https://happywedz.com/api/inbox?filter=booked"),
//         headers: {"Authorization": "Bearer $token"},
//       );
//
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//         setState(() {
//           bookedInbox = data['inbox'] ?? [];
//           isLoading = false;
//         });
//       } else {
//         isLoading = false;
//       }
//     } catch (e) {
//       isLoading = false;
//     }
//   }
//
//   // ================= SEND REVIEW REQUEST =================
//   Future<void> _sendReviewRequest() async {
//     if (selectedCustomer == null || messageCtrl.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Select customer & write message")),
//       );
//       return;
//     }
//
//     setState(() => sending = true);
//
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');
//
//     final request = selectedCustomer['request'];
//     final int requestId = request['id'];
//     final int vendorId = request['vendorId'];
//
//     final res = await http.post(
//       Uri.parse(
//           "https://happywedz.com/api/reviews/send-review-request/$requestId"),
//       headers: {
//         "Authorization": "Bearer $token",
//         "Content-Type": "application/json",
//       },
//       body: jsonEncode({
//         "message": messageCtrl.text.trim(),
//         "reviewLink": "https://happywedz.com/write-review/$vendorId",
//       }),
//     );
//
//     setState(() => sending = false);
//
//     if (res.statusCode == 200) {
//       final data = json.decode(res.body);
//       if (data['success'] == true) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Review request sent successfully")),
//         );
//         messageCtrl.clear();
//         nameCtrl.clear();
//         emailCtrl.clear();
//         setState(() {
//           selectedCustomer = null;
//           reviewLink = "";
//         });
//       }
//     }
//   }
//
//   // ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: CommonAppBar(title: "Review Collector"),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             const Text(
//               "Send review requests to your happy clients and grow your reputation",
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.black54),
//             ),
//             const SizedBox(height: 20),
//             _sendReviewCard(),
//             const SizedBox(height: 20),
//             _shareLinkCard(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ================= SEND REVIEW CARD =================
//   Widget _sendReviewCard() {
//     return Container(
//       decoration: _cardDecoration(),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: const BoxDecoration(
//               color: primaryBlue,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
//             ),
//             child: const Row(
//               children: [
//                 Icon(Icons.send, color: Colors.white),
//                 SizedBox(width: 8),
//                 Text("Send Review Request",
//                     style: TextStyle(color: Colors.white)),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(14),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text("Select Customer"),
//                 const SizedBox(height: 6),
//                 _customerDropdown(),
//                 const SizedBox(height: 14),
//                 _customerInfoBox(),
//                 const SizedBox(height: 14),
//                 const Text("Personalized Message"),
//                 const SizedBox(height: 6),
//                 _messageField(),
//                 const SizedBox(height: 16),
//                 _sendButton(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================= CUSTOMER DROPDOWN =================
//   Widget _customerDropdown() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<dynamic>(
//           dropdownColor: Colors.white,
//           isExpanded: true,
//           hint: const Text("Choose booked customer"),
//           value: selectedCustomer,
//           items: bookedInbox.map((item) {
//             final request = item['request'];
//             final String fullName =
//                 "${request['firstName']} ${request['lastName']}";
//             final String phone = request['eventDate'] ?? "";
//             return DropdownMenuItem(
//               value: item,
//               child: Text("$fullName • $phone"),
//             );
//           }).toList(),
//           onChanged: (val) {
//             final request = val['request'];
//
//             final String fullName =
//                 "${request['firstName']} ${request['lastName']}";
//             final String eventDate = request['eventDate'];
//             final String email = request['email'] ?? "";
//
//             setState(() {
//               selectedCustomer = val;
//               nameCtrl.text = fullName;
//               emailCtrl.text = email;
//
//               reviewLink =
//               "https://happywedz.com/write-review/${request['vendorId']}";
//
//               messageCtrl.text =
//               "Hi $fullName,\n\n"
//                   "Thank you for choosing our services for your event on $eventDate.\n"
//                   "We would love to hear your feedback!\n\n"
//                   "Thanks & Regards";
//             });
//           },
//         ),
//       ),
//     );
//   }
//
//   // ================= CUSTOMER INFO BOX =================
//   Widget _customerInfoBox() {
//     if (selectedCustomer == null) return const SizedBox();
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Customer Details"),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 controller: nameCtrl,
//                 readOnly: true,
//                 decoration: InputDecoration(
//                   labelText: "Customer Name",
//                   prefixIcon: const Icon(Icons.person),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: const BorderSide(
//                       color: Colors.grey, // lightBlue
//                       width: 1.2,
//                     ),
//                   ),
//
//                   // 🔹 When focused (purple ko override karega)
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: const BorderSide(
//                       color: Color(0xFF4682B4), // lightBlue
//                       width: 1.5,
//                     ),
//                   ),
//                 ),
//
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: TextField(
//                 controller: emailCtrl,
//                 readOnly: true,
//                 decoration: InputDecoration(
//                   labelText: "Email Address",
//                   prefixIcon: const Icon(Icons.email),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//
//                   // 🔹 Normal border
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: const BorderSide(
//                       color: Colors.grey, // lightBlue
//                       width: 1.2,
//                     ),
//                   ),
//
//                   // 🔹 When focused (purple ko override karega)
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: const BorderSide(
//                       color: Color(0xFF4682B4), // lightBlue
//                       width: 1.5,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//
//           ],
//         ),
//       ],
//     );
//   }
//
//   // ================= MESSAGE FIELD =================
//   Widget _messageField() {
//     return TextField(
//       controller: messageCtrl,
//       maxLines: 5,
//       decoration: InputDecoration(
//         hintText: "Write message...",
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: const BorderSide(color: primaryBlue),
//         ),
//       ),
//     );
//   }
//
//   // ================= SEND BUTTON =================
//   Widget _sendButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: primaryBlue,
//           padding: const EdgeInsets.symmetric(vertical: 14),
//         ),
//         onPressed: sending ? null : _sendReviewRequest,
//         child: sending
//             ? const SizedBox(
//           height: 18,
//           width: 18,
//           child: CircularProgressIndicator(
//             strokeWidth: 2,
//             color: Colors.white,
//           ),
//         )
//             : const Text(
//           "Send Review Request",
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//     );
//   }
//
//   // ================= SHARE LINK CARD =================
//   Widget _shareLinkCard() {
//     return Container(
//       decoration: _cardDecoration(),
//       padding: const EdgeInsets.all(14),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               reviewLink.isEmpty ? "Select customer to get link" : reviewLink,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.copy, color: primaryBlue),
//             onPressed: reviewLink.isEmpty
//                 ? null
//                 : () async {
//               await Clipboard.setData(
//                 ClipboardData(text: reviewLink),
//               );
//
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Link copied")),
//               );
//             },
//
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================= CARD DECORATION =================
//   BoxDecoration _cardDecoration() {
//     return BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.05),
//           blurRadius: 12,
//         ),
//       ],
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/common_app_bar.dart';
import 'package:flutter/services.dart';

class ReviewCollectorScreen extends StatefulWidget {
  const ReviewCollectorScreen({Key? key}) : super(key: key);

  @override
  State<ReviewCollectorScreen> createState() => _ReviewCollectorScreenState();
}

class _ReviewCollectorScreenState extends State<ReviewCollectorScreen> {
  static const Color primaryBlue = Color(0xFF00509D);
  static const Color lightBlue = Color(0xFF4682B4);

  bool isLoading = true;
  bool sending = false;
  bool loadingLink = false;

  List<dynamic> bookedInbox = [];
  dynamic selectedCustomer;

  final TextEditingController messageCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  String reviewLink = "";

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _fetchBookedInbox();
    _generateReviewLinkOnce(); // 🔥 LINK LOAD ONCE
  }

  // ================= GET BOOKED INBOX =================
  Future<void> _fetchBookedInbox() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse("https://happywedz.com/api/inbox?filter=booked"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          bookedInbox = data['inbox'] ?? [];
          isLoading = false;
        });
      } else {
        isLoading = false;
      }
    } catch (e) {
      isLoading = false;
    }
  }

  // ================= GET VENDOR SERVICE ID =================
  Future<int?> _getVendorServiceId(int vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final res = await http.get(
      Uri.parse(
          "https://happywedz.com/api/vendor-services/vendor/$vendorId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      if (data.isNotEmpty) {
        return data[0]['id'];
      }
    }
    return null;
  }

  // ================= GENERATE REVIEW LINK ONCE =================
  Future<void> _generateReviewLinkOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final vendorId = prefs.getInt("vendorId"); // must be saved earlier
    if (vendorId == null) return;

    setState(() => loadingLink = true);

    final serviceId = await _getVendorServiceId(vendorId);

    setState(() {
      loadingLink = false;
      reviewLink = serviceId != null
          ? "https://happywedz.com/write-review/$serviceId"
          : "";
    });
  }

  // ================= SEND REVIEW REQUEST =================
  Future<void> _sendReviewRequest() async {
    if (selectedCustomer == null || messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select customer & write message")),
      );
      return;
    }

    setState(() => sending = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = selectedCustomer['request'];
    final int requestId = request['id'];

    final res = await http.post(
      Uri.parse(
          "https://happywedz.com/api/reviews/send-review-request/$requestId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "message": messageCtrl.text.trim(),
        "reviewLink": reviewLink, // 🔥 SAME LINK ALWAYS
      }),
    );

    setState(() => sending = false);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review request sent successfully")),
        );
        messageCtrl.clear();
        nameCtrl.clear();
        emailCtrl.clear();
        setState(() {
          selectedCustomer = null;
        });
      }
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Review Collector"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Send review requests to your happy clients and grow your reputation",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _sendReviewCard(),
            const SizedBox(height: 20),
            _shareLinkCard(),
          ],
        ),
      ),
    );
  }

  // ================= SEND REVIEW CARD =================
  Widget _sendReviewCard() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Icon(Icons.send, color: Colors.white),
                SizedBox(width: 8),
                Text("Send Review Request",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select Customer"),
                const SizedBox(height: 6),
                _customerDropdown(),
                const SizedBox(height: 14),
                _customerInfoBox(),
                const SizedBox(height: 14),
                const Text("Personalized Message"),
                const SizedBox(height: 6),
                _messageField(),
                const SizedBox(height: 16),
                _sendButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= CUSTOMER DROPDOWN =================
  Widget _customerDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          isExpanded: true,
          hint: const Text("Choose booked customer"),
          value: selectedCustomer,
          items: bookedInbox.map((item) {
            final request = item['request'];
            final String fullName =
                "${request['firstName']} ${request['lastName']}";
            final String eventDate = request['eventDate'] ?? "";
            return DropdownMenuItem(
              value: item,
              child: Text("$fullName • $eventDate"),
            );
          }).toList(),
          onChanged: (val) {
            final request = val['request'];

            setState(() {
              selectedCustomer = val;
              nameCtrl.text =
              "${request['firstName']} ${request['lastName']}";
              emailCtrl.text = request['email'] ?? "";
              messageCtrl.text =
              "Hi ${nameCtrl.text},\n\n"
                  "Thank you for choosing our services for your event on ${request['eventDate']}.\n"
                  "We would love to hear your feedback!\n\n"
                  "Thanks & Regards";
            });
          },
        ),
      ),
    );
  }

  // ================= CUSTOMER INFO =================
  Widget _customerInfoBox() {
    if (selectedCustomer == null) return const SizedBox();

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: nameCtrl,
            readOnly: true,
            decoration: _inputDecoration("Customer Name", Icons.person),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: emailCtrl,
            readOnly: true,
            decoration: _inputDecoration("Email Address", Icons.email),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightBlue, width: 1.5),
      ),
    );
  }

  // ================= MESSAGE =================
  Widget _messageField() {
    return TextField(
      controller: messageCtrl,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: "Write message...",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ================= SEND BUTTON =================
  Widget _sendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: sending ? null : _sendReviewRequest,
        child: sending
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Send Review Request",
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ================= SHARE LINK =================
  Widget _shareLinkCard() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: loadingLink
                ? const Text("Generating review link...")
                : Text(
              reviewLink.isEmpty
                  ? "Review link not available"
                  : reviewLink,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: primaryBlue),
            onPressed: reviewLink.isEmpty
                ? null
                : () async {
              await Clipboard.setData(
                  ClipboardData(text: reviewLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Link copied")),
              );
            },
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12),
      ],
    );
  }
}