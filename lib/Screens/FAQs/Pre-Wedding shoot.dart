// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'storefront_percentage_bar.dart';
//
// // ===== MODEL =====
// class FaqQuestion {
//   final int id;
//   final String text;
//   final String description;
//   final List<String> label;
//   final String type;
//   final List<String> options;
//   final int? min;
//   final int? max;
//
//   FaqQuestion({
//     required this.id,
//     required this.text,
//     required this.description,
//     required this.label,
//     required this.type,
//     required this.options,
//     this.min,
//     this.max,
//   });
//
//   factory FaqQuestion.fromJson(Map<String, dynamic> json) {
//     return FaqQuestion(
//       id: json['id'],
//       text: json['text'] ?? '',
//       description: json['description'] ?? '',
//       label: List<String>.from(json['label'] ?? []),
//       type: json['type'] ?? '',
//       options: List<String>.from(json['options'] ?? []),
//       min: json['min'],
//       max: json['max'],
//     );
//   }
// }
//
// // ===== PRE-WEDDING PHOTOGRAPHY FAQ SCREEN =====
// class PreWeddingFaqScreen extends StatefulWidget {
//   const PreWeddingFaqScreen({super.key});
//
//   @override
//   State<PreWeddingFaqScreen> createState() => _PreWeddingFaqScreenState();
// }
//
// class _PreWeddingFaqScreenState extends State<PreWeddingFaqScreen> {
//   List<FaqQuestion> faqs = [];
//
//   final Map<int, String> selectedRadio = {};
//   final Map<int, List<String>> selectedCheckbox = {};
//   final Map<int, double> selectedSlider = {};
//   final Map<int, TextEditingController> textControllers = {};
//
//   int vendorId = 0;
//   int vendorTypeId = 12;
//   String token = "";
//   bool isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initFaqScreen();
//   }
//
//   Future<void> _initFaqScreen() async {
//     // Load vendor data from SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     vendorId = prefs.getInt('vendorId') ?? 0;
//     vendorTypeId = prefs.getInt('vendorTypeId') ?? mockPreWeddingJson['vendor_type_id'] as int;
//     token = prefs.getString('authToken') ?? "";
//
//     // Initialize FAQ from static JSON
//     final data = mockPreWeddingJson['questions'] as List<dynamic>;
//     faqs = data.map((e) => FaqQuestion.fromJson(e)).toList();
//
//     // Prepare text controllers
//     for (var q in faqs) {
//       if (q.type == 'text' || q.type == 'textarea' || q.type == 'number') {
//         textControllers[q.id] = TextEditingController();
//       }
//     }
//
//     // If vendor exists and token present, fetch saved answers from backend
//     if (vendorId != 0 && token.isNotEmpty) {
//       await _fetchFaqAnswers();
//     } else {
//       setState(() {});
//     }
//   }
//
//   // ===== FETCH SAVED ANSWERS =====
//   Future<void> _fetchFaqAnswers() async {
//     setState(() => isLoading = true);
//     try {
//       final response = await http.get(
//         Uri.parse("https://happywedz.com/api/faq-answers/$vendorId"),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//       );
//
//       if (response.statusCode == 200) {
//         print("🔹 FETCH FAQ RESPONSE: ${response.body}");
//         final data = jsonDecode(response.body);
//
//         List<dynamic> answers = [];
//         if (data is Map<String, dynamic>) {
//           answers = (data['answers'] ?? []) as List<dynamic>;
//         } else if (data is List) {
//           answers = data;
//         }
//
//         for (var ans in answers) {
//           if (ans == null) continue;
//           final qid = ans['faqQuestionId'];
//           var answer = ans['answer'];
//
//           final question = faqs.firstWhere(
//                 (q) => q.id == qid,
//             orElse: () => FaqQuestion(id: 0, text: '', description: '', label: [], type: '', options: []),
//           );
//           if (question.id == 0) continue;
//
//           if (question.type == 'checkbox') {
//             try {
//               if (answer is String && answer.startsWith('{')) {
//                 answer = jsonDecode(answer.replaceAll('{', '[').replaceAll('}', ']'));
//               }
//               selectedCheckbox[qid] = List<String>.from(answer);
//             } catch (_) {
//               selectedCheckbox[qid] = [];
//             }
//           } else if (question.type == 'radio') {
//             selectedRadio[qid] = answer.toString();
//           } else if (question.type == 'range') {
//             selectedSlider[qid] = (answer is num) ? answer.toDouble() : 0.0;
//           } else {
//             textControllers[qid]?.text = answer.toString();
//           }
//         }
//       } else {
//         print("❌ Failed to fetch FAQ answers: ${response.statusCode} - ${response.body}");
//       }
//     } catch (e) {
//       print("⚠️ Error loading FAQ answers: $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   // ===== SAVE ANSWERS =====
//   Future<void> _saveFaqAnswers() async {
//     setState(() => isLoading = true);
//
//     // Only include answered questions
//     final answers = faqs.map((q) {
//       dynamic ans;
//       if (q.type == 'checkbox') {
//         ans = selectedCheckbox[q.id];
//       } else if (q.type == 'radio') {
//         ans = selectedRadio[q.id];
//       } else if (q.type == 'range') {
//         ans = selectedSlider[q.id];
//       } else {
//         ans = textControllers[q.id]?.text.trim();
//       }
//
//       // Skip unanswered questions
//       if (ans == null || (ans is String && ans.isEmpty) || (ans is List && ans.isEmpty)) {
//         return null;
//       }
//
//       return {"faqQuestionId": q.id, "answer": ans};
//     }).where((element) => element != null).toList();
//
//     if (vendorId == 0 || token.isEmpty) {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('pendingFaqAnswers', jsonEncode(answers));
//       setState(() => isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("You are not logged in yet. Answers saved locally.")),
//       );
//       return;
//     }
//
//     final body = {
//       "vendorId": vendorId,
//       "vendorTypeId": vendorTypeId,
//       "answers": answers,
//     };
//
//     try {
//       final response = await http.post(
//         Uri.parse("https://happywedz.com/api/faq-answers/save"),
//         headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
//         body: jsonEncode(body),
//       );
//
//       print("📤 Sent: ${jsonEncode(body)}");
//       print("📩 Response (${response.statusCode}): ${response.body}");
//
//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("✅ FAQ answers saved successfully")),
//         );
//         await _fetchFaqAnswers();
//       } else {
//         String msg = "Failed to save FAQ answers";
//         try {
//           final parsed = jsonDecode(response.body);
//           if (parsed['message'] != null) msg = parsed['message'].toString();
//         } catch (_) {}
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Network error while saving answers")),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   // ===== UI =====
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text("Pre Wedding Shoot FAQs", style: TextStyle(color: Colors.black)),
//         centerTitle: true,
//         backgroundColor: const Color(0xFFE0F7FA),
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         itemCount: faqs.length,
//         itemBuilder: (context, index) => _buildFaqCard(faqs[index]),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         backgroundColor: Colors.pinkAccent,
//         icon: const Icon(Icons.send),
//         label: const Text("Submit"),
//         onPressed: () async {
//           await _saveFaqAnswers();
//
//           // Mark FAQ as completed
//           await ProfileCompletionController.markDone(ProfileCompletionController.keyFaq);
//
//           if (!mounted) return;
//
//           // ✅ Go directly to Home (pop everything till the first route)
//           Navigator.popUntil(context, (route) => route.isFirst);
//         },
//       ),
//     );
//   }
//
//   Widget _buildFaqCard(FaqQuestion q) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//       elevation: 3,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(q.text,
//                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3)),
//             const SizedBox(height: 12),
//             _buildInput(q),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInput(FaqQuestion q) {
//     switch (q.type) {
//       case "number":
//         return Column(
//           children: q.label.isNotEmpty
//               ? q.label.map((lbl) {
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: TextFormField(
//                 controller: textControllers[q.id],
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: lbl,
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//               ),
//             );
//           }).toList()
//               : [
//             TextFormField(
//               controller: textControllers[q.id],
//               keyboardType: TextInputType.number,
//               decoration: InputDecoration(
//                 labelText: "Enter answer",
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//             )
//           ],
//         );
//
//       case "text":
//       case "textarea":
//         return TextFormField(
//           controller: textControllers[q.id],
//           minLines: q.type == "textarea" ? 3 : 1,
//           maxLines: q.type == "textarea" ? 5 : 1,
//           decoration: InputDecoration(
//             labelText: q.label.isNotEmpty ? q.label.first : "Enter answer",
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//         );
//
//       case "radio":
//         return Column(
//           children: q.options
//               .map((opt) => RadioListTile(
//             title: Text(opt),
//             value: opt,
//             groupValue: selectedRadio[q.id],
//             onChanged: (val) => setState(() => selectedRadio[q.id] = val.toString()),
//           ))
//               .toList(),
//         );
//
//       case "checkbox":
//         return Column(
//           children: q.options
//               .map((opt) {
//             bool isChecked = selectedCheckbox[q.id]?.contains(opt) ?? false;
//             return CheckboxListTile(
//               title: Text(opt),
//               value: isChecked,
//               onChanged: (val) {
//                 setState(() {
//                   selectedCheckbox[q.id] ??= [];
//                   if (val == true) {
//                     selectedCheckbox[q.id]!.add(opt);
//                   } else {
//                     selectedCheckbox[q.id]!.remove(opt);
//                   }
//                 });
//               },
//             );
//           })
//               .toList(),
//         );
//
//       default:
//         return const SizedBox();
//     }
//   }
// }
//
// // ===== MOCK JSON FOR PRE-WEDDING PHOTOGRAPHY =====
//
//
//
// // ===== MOCK JSON FOR PRE-WEDDING PHOTOGRAPHY =====
// const mockPreWeddingJson = {
//   "vendor_type_id": 12,
//   "vendor_type": "preweddingphotography",
//   "questions": [
//     {
//       "id": 301,
//       "text": "How many processed (edited) pictures do you usually deliver to the client?",
//       "description": "",
//       "label": [],
//       "type": "radio",
//       "options": ["<25", "25-50", "50-100", "100-200"],
//       "min": null,
//       "max": null
//     },
//     {
//       "id": 302,
//       "text": "Which services do you offer?",
//       "description": "",
//       "label": [],
//       "type": "checkbox",
//       "options": ["Still Photography", "Videography", "Albums"],
//       "min": null,
//       "max": null
//     },
//     {
//       "id": 303,
//       "text": "What are your payment terms?",
//       "description": "",
//       "label": [],
//       "type": "radio",
//       "options": ["25% Advance", "50% Advance", "100% Advance"],
//       "min": null,
//       "max": null
//     },
//     {
//       "id": 304,
//       "text": "Please mention any awards you have received?",
//       "description": "",
//       "label": [],
//       "type": "textarea",
//       "options": [],
//       "min": null,
//       "max": null
//     },
//     {
//       "id": 305,
//       "text": "Who bears the pre-wedding shoot location cost?",
//       "description": "",
//       "label": [],
//       "type": "radio",
//       "options": ["Borne by client", "Borne by photographer (Only Local)"],
//       "min": null,
//       "max": null
//     },
//     {
//       "id": 306,
//       "text": "Who bears cost of travel and lodging when travelling to a different city?",
//       "description": "",
//       "label": [],
//       "type": "radio",
//       "options": [
//         "Cost of stay and travel borne by client",
//         "Cost of stay borne by client and travel by photographer",
//         "Both borne by you"
//       ],
//       "min": null,
//       "max": null
//     },
//     {
//       "id": 307,
//       "text": "Pricing for Pre-wedding stills? (Per day)",
//       "description": "",
//       "label": ["Price per Day (Stills)"],
//       "type": "number",
//       "options": [],
//       "min": null,
//       "max": null
//     },
//     {
//       "id": 308,
//       "text": "What are the terms & conditions of your cancellation policy? (Please describe in detail - eg. No refunds within a month of the wedding day or 50% amount refundable)",
//       "description": "",
//       "label": [],
//       "type": "textarea",
//       "options": [],
//       "min": null,
//       "max": null
//     },
//     {
//       "id": 309,
//       "text": "Who bears the travel and stay cost for outstation weddings?",
//       "description": "",
//       "label": [],
//       "type": "radio",
//       "options": [
//         "Cost of stay and travel borne by client",
//         "Cost of stay borne by client and travel by you",
//         "Both borne by you"
//       ],
//       "min": null,
//       "max": null
//     },
//     {
//       "id": 310,
//       "text": "Pricing for Pre-wedding films? (Per day)",
//       "description": "",
//       "label": ["Price per Day (Films)"],
//       "type": "number",
//       "options": [],
//       "min": null,
//       "max": null
//     },
//     {
//       "id": 311,
//       "text": "How long have you been doing pre-wedding photography?",
//       "description": "",
//       "label": [],
//       "type": "number",
//       "options": [],
//       "min": null,
//       "max": null
//     }
//   ]
// };


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api_services/storefront_completion_service.dart';
import '../../utils/common_app_bar.dart';
import 'storefront_percentage_bar.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

// ===== MODEL =====
class FaqQuestion {
  final int id;
  final String text;
  final String description;
  final List<String> label;
  final String type;
  final List<String> options;
  final int? min;
  final int? max;

  FaqQuestion({
    required this.id,
    required this.text,
    required this.description,
    required this.label,
    required this.type,
    required this.options,
    this.min,
    this.max,
  });

  factory FaqQuestion.fromJson(Map<String, dynamic> json) {
    return FaqQuestion(
      id: json['id'],
      text: json['text'] ?? '',
      description: json['description'] ?? '',
      label: List<String>.from(json['label'] ?? []),
      type: json['type'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      min: json['min'],
      max: json['max'],
    );
  }
}

// ===== PRE-WEDDING FAQ SCREEN =====
class PreWeddingFaqScreen extends StatefulWidget {
  const PreWeddingFaqScreen({super.key});

  @override
  State<PreWeddingFaqScreen> createState() => _PreWeddingFaqScreenState();
}

class _PreWeddingFaqScreenState extends State<PreWeddingFaqScreen> {
  List<FaqQuestion> faqs = [];

  final Map<int, TextEditingController> textControllers = {};
  final Map<int, String> selectedRadio = {};
  final Map<int, List<String>> selectedCheckbox = {};

  int vendorId = 0;
  int vendorTypeId =0;
  String token = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ================= INIT =================
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId = prefs.getInt('vendorId') ?? 0;
    vendorTypeId =
        prefs.getInt('vendorTypeId') ?? 0;
    token = prefs.getString('authToken') ?? "";

    final data = mockPreWeddingJson['questions'] as List;
    faqs = data.map((e) => FaqQuestion.fromJson(e)).toList();

    for (var q in faqs) {
      if (q.type == 'text' || q.type == 'textarea' || q.type == 'number') {
        textControllers[q.id] = TextEditingController();
      }
    }

    if (vendorId != 0 && token.isNotEmpty) {
      await _fetchFaqAnswers();
    }

    setState(() {});
  }

  // ================= FETCH =================
  Future<void> _fetchFaqAnswers() async {
    setState(() => isLoading = true);

    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/faq-answers/$vendorId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final List answers = jsonDecode(res.body);

        for (var ans in answers) {
          final qid = ans['faq_question_id'];
          final value = ans['answer'];

          final q = faqs.firstWhere(
                (e) => e.id == qid,
            orElse: () => FaqQuestion(
              id: 0,
              text: '',
              description: '',
              label: [],
              type: '',
              options: [],
            ),
          );

          if (q.id == 0) continue;

          switch (q.type) {
            case 'radio':
              selectedRadio[qid] = value.toString();
              break;

            case 'checkbox':
              if (value is List) {
                selectedCheckbox[qid] = List<String>.from(value);
              }
              break;

            case 'number':
            case 'text':
            case 'textarea':
              textControllers[qid]?.text = value.toString();
              break;
          }
        }
      }
    } catch (e) {
      debugPrint("❌ PreWedding FAQ fetch error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ================= SAVE =================
  Future<void> _saveFaqAnswers() async {
    final List<Map<String, dynamic>> answers = [];

    for (var q in faqs) {
      dynamic ans;

      switch (q.type) {
        case 'radio':
          ans = selectedRadio[q.id];
          break;

        case 'checkbox':
          ans = selectedCheckbox[q.id];
          break;

        case 'number':
        case 'text':
        case 'textarea':
          ans = textControllers[q.id]?.text.trim();
          break;
      }

      if (ans != null &&
          !(ans is List && ans.isEmpty) &&
          ans.toString().isNotEmpty) {
        answers.add({"faqQuestionId": q.id, "answer": ans});
      }
    }

    await http.post(
      Uri.parse("${ApiConfig.baseUrl}/faq-answers/save"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "vendorId": vendorId,
        "vendorTypeId": vendorTypeId,
        "answers": answers,
      }),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("faqCompleted", true);
    final serviceId = prefs.getInt("serviceId");

    if (serviceId != null) {
      await StorefrontCompletionService.refreshCompletion(
        serviceId: serviceId,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("FAQ Saved")),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Pre Wedding Shoot FAQs"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: faqs.length,
        itemBuilder: (_, i) => _faqCard(faqs[i]),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await _saveFaqAnswers();
              // await ProfileCompletionController
              //     .markDone(ProfileCompletionController.keyFaq);

              if (!mounted) return;
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF00509D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Submit",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _faqCard(FaqQuestion q) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.text, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _input(q),
          ],
        ),
      ),
    );
  }

  Widget _input(FaqQuestion q) {
    switch (q.type) {
      case 'radio':
        return Column(
          children: q.options
              .map(
                (o) => RadioListTile(
              title: Text(o),
              value: o,
              groupValue: selectedRadio[q.id],
              onChanged: (v) =>
                  setState(() => selectedRadio[q.id] = v.toString()),
            ),
          )
              .toList(),
        );

      case 'checkbox':
        return Column(
          children: q.options.map((o) {
            final checked = selectedCheckbox[q.id]?.contains(o) ?? false;
            return CheckboxListTile(
              title: Text(o),
              value: checked,
              onChanged: (v) {
                setState(() {
                  selectedCheckbox[q.id] ??= [];
                  v == true
                      ? selectedCheckbox[q.id]!.add(o)
                      : selectedCheckbox[q.id]!.remove(o);
                });
              },
            );
          }).toList(),
        );

      case 'number':
      case 'text':
      case 'textarea':
        return TextField(
          controller: textControllers[q.id],
          keyboardType:
          q.type == 'number' ? TextInputType.number : TextInputType.text,
          minLines: q.type == 'textarea' ? 3 : 1,
          maxLines: q.type == 'textarea' ? 5 : 1,
          decoration: const InputDecoration(labelText: "Enter value"),
        );

      default:
        return const SizedBox();
    }
  }
}

// ===== JSON =====
const mockPreWeddingJson = {
  "vendor_type_id": 12,
  "vendor_type": "preweddingphotography",
  "questions": [
    {
      "id": 301,
      "text":
      "How many processed (edited) pictures do you usually deliver to the client?",
      "type": "radio",
      "options": ["<25", "25-50", "50-100", "100-200"]
    },
    {
      "id": 302,
      "text": "Which services do you offer?",
      "type": "checkbox",
      "options": ["Still Photography", "Videography", "Albums"]
    },
    {
      "id": 303,
      "text": "What are your payment terms?",
      "type": "radio",
      "options": ["25% Advance", "50% Advance", "100% Advance"]
    },
    {
      "id": 304,
      "text": "Please mention any awards you have received?",
      "type": "textarea",
      "options": []
    },
    {
      "id": 305,
      "text": "Who bears the pre-wedding shoot location cost?",
      "type": "radio",
      "options": ["Borne by client", "Borne by photographer (Only Local)"]
    },
    {
      "id": 306,
      "text":
      "Who bears cost of travel and lodging when travelling to a different city?",
      "type": "radio",
      "options": [
        "Cost of stay and travel borne by client",
        "Cost of stay borne by client and travel by photographer",
        "Both borne by you"
      ]
    },
    {
      "id": 307,
      "text": "Pricing for Pre-wedding stills? (Per day)",
      "type": "number",
      "options": []
    },
    {
      "id": 308,
      "text": "What are the terms & conditions of your cancellation policy?",
      "type": "textarea",
      "options": []
    },
    {
      "id": 309,
      "text":
      "Who bears the travel and stay cost for outstation weddings?",
      "type": "radio",
      "options": [
        "Cost of stay and travel borne by client",
        "Cost of stay borne by client and travel by you",
        "Both borne by you"
      ]
    },
    {
      "id": 310,
      "text": "Pricing for Pre-wedding films? (Per day)",
      "type": "number",
      "options": []
    },
    {
      "id": 311,
      "text":
      "How long have you been doing pre-wedding photography?",
      "type": "number",
      "options": []
    }
  ]
};
