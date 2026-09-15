import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api_services/storefront_completion_service.dart';
import '../../utils/common_app_bar.dart';
import 'storefront_percentage_bar.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

// ===== MODEL =====
class VendorQuestion {
  final int id;
  final String text;
  final String description;
  final List<String> label;
  final String type;
  final List<String> options;
  final int? min;
  final int? max;

  VendorQuestion({
    required this.id,
    required this.text,
    required this.description,
    required this.label,
    required this.type,
    required this.options,
    this.min,
    this.max,
  });

  factory VendorQuestion.fromJson(Map<String, dynamic> json) {
    return VendorQuestion(
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
//
// // ===== WEDDING DJ SCREEN =====
// class WeddingDjScreen extends StatefulWidget {
//   const WeddingDjScreen({super.key});
//
//   @override
//   State<WeddingDjScreen> createState() => _WeddingDjScreenState();
// }
//
// class _WeddingDjScreenState extends State<WeddingDjScreen> {
//   late List<VendorQuestion> questions = [];
//   final Map<int, String> selectedRadio = {};
//   final Map<int, List<String>> selectedCheckbox = {};
//   final Map<int, double> selectedSlider = {};
//   final Map<int, TextEditingController> textControllers = {};
//   final Map<int, bool> expandCheckbox = {};
//
//   int vendorId = 0;
//   int vendorTypeId = 8;
//   String token = "";
//   bool isLoading = false;
//
//   late List<VendorQuestion> faqs = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _initFaqScreen();
//   }
//
//   Future<void> _initFaqScreen() async {
//     final prefs = await SharedPreferences.getInstance();
//     vendorId = prefs.getInt('vendorId') ?? 0;
//     vendorTypeId = prefs.getInt('vendorTypeId') ?? (weddingDjJson['vendor_type_id'] ?? 8) as int;
//     token = prefs.getString('authToken') ?? "";
//
//     // Load static questions
//     final data = weddingDjJson['questions'] as List<dynamic>;
//     faqs = data.map((e) => VendorQuestion.fromJson(e)).toList();
//     questions = faqs;
//
//     // Prepare text controllers
//     for (var q in questions) {
//       if (q.type == 'text' || q.type == 'textarea' || q.type == 'number') {
//         textControllers[q.id] = TextEditingController();
//       }
//     }
//
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
//
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         List<dynamic> answers = [];
//         if (data is Map<String, dynamic>) {
//           answers = (data['answers'] ?? []) as List<dynamic>;
//         } else if (data is List) {
//           answers = data;
//         }
//
//
//
//         for (var ans in answers) {
//           if (ans == null) continue;
//           final qid = ans['faqQuestionId'];
//           var answer = ans['answer'];
//
//
//
//           final question = questions.firstWhere(
//                 (q) => q.id == qid,
//             orElse: () => VendorQuestion(
//               id: 0,
//               text: '',
//               description: '',
//               label: [],
//               type: '',
//               options: [],
//             ),
//           );
//
//
//           if (question.id == 0) continue;
//
//
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
//             selectedSlider[qid] = (answer is num) ? answer.toDouble() : (question.min?.toDouble() ?? 0);
//           } else {
//             textControllers[qid]?.text = answer.toString();
//           }
//         }
//       } else {
//         print("❌ Failed to fetch FAQ answers: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("⚠️ Error fetching FAQ answers: $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   // ===== SAVE ANSWERS =====
//   Future<void> _saveFaqAnswers() async {
//     setState(() => isLoading = true);
//
//     final answers = questions.map((q) {
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
//
//
//       print("📤 Sent: ${jsonEncode(body)}");
//       print("📩 Response (${response.statusCode}): ${response.body}");
//       print("🪪 vendorId: $vendorId");
//       print("🔐 token: $token");
//       print("🎨 vendorTypeId: $vendorTypeId");
//       print("➡️ Sending: ${jsonEncode(body)}");
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
//         title: const Text(
//           "Wedding DJ FAQs",
//           style: TextStyle(color: Colors.black), // optional for better contrast
//         ),
//         centerTitle: true,
//         backgroundColor: const Color(0xFFE0F7FA), // 🌸 light WedMeGood blue
//         elevation: 0, // optional: gives a clean flat look
//         iconTheme: const IconThemeData(color: Colors.black), // optional for visibility
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         itemCount: questions.length,
//         itemBuilder: (context, index) => _buildQuestionCard(questions[index]),
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
//   Widget _buildQuestionCard(VendorQuestion q) {
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
//                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//             if (q.description.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 4),
//                 child: Text(q.description,
//                     style: const TextStyle(fontSize: 13, color: Colors.grey)),
//               ),
//             const SizedBox(height: 12),
//             _buildInput(q),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInput(VendorQuestion q) {
//     switch (q.type) {
//       case "number":
//       case "text":
//       case "textarea":
//         return TextFormField(
//           controller: textControllers[q.id],
//           keyboardType: q.type == "number" ? TextInputType.number : TextInputType.text,
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
//             onChanged: (val) =>
//                 setState(() => selectedRadio[q.id] = val.toString()),
//           ))
//               .toList(),
//         );
//
//       case "checkbox":
//         int visibleCount = expandCheckbox[q.id] == true ? q.options.length : 2;
//         List<String> visibleOptions = q.options.take(visibleCount).toList();
//         return Column(
//           children: [
//             ...visibleOptions.map((opt) {
//               bool isChecked = selectedCheckbox[q.id]?.contains(opt) ?? false;
//               return CheckboxListTile(
//                 title: Text(opt),
//                 value: isChecked,
//                 onChanged: (val) {
//                   setState(() {
//                     selectedCheckbox[q.id] ??= [];
//                     if (val == true) {
//                       selectedCheckbox[q.id]!.add(opt);
//                     } else {
//                       selectedCheckbox[q.id]!.remove(opt);
//                     }
//                   });
//                 },
//               );
//             }),
//             if (q.options.length > 2 && expandCheckbox[q.id] != true)
//               TextButton(
//                 onPressed: () => setState(() => expandCheckbox[q.id] = true),
//                 child: const Text("View more"),
//               ),
//           ],
//         );
//
//       case "range":
//         double value = selectedSlider[q.id] ?? (q.min?.toDouble() ?? 0.0);
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Slider(
//               value: value,
//               min: q.min?.toDouble() ?? 0,
//               max: q.max?.toDouble() ?? 100000,
//               divisions: 10,
//               label: value.toStringAsFixed(0),
//               onChanged: (val) => setState(() => selectedSlider[q.id] = val),
//             ),
//             Text("Selected: ${value.toStringAsFixed(0)}"),
//           ],
//         );
//
//       default:
//         return const SizedBox();
//     }
//   }
// }


// ================= SCREEN =================
class WeddingDjScreen extends StatefulWidget {
  const WeddingDjScreen({super.key});

  @override
  State<WeddingDjScreen> createState() => _WeddingDjScreenState();
}

class _WeddingDjScreenState extends State<WeddingDjScreen> {
  List<VendorQuestion> questions = [];

  final Map<int, TextEditingController> textControllers = {};
  final Map<int, String> selectedRadio = {};
  final Map<int, List<String>> selectedCheckbox = {};
  final Map<int, double> selectedSlider = {};
  final Map<int, bool> expandCheckbox = {};

  int vendorId = 0;
  int vendorTypeId = 8;
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
    vendorTypeId = prefs.getInt('vendorTypeId') ?? 8;
    token = prefs.getString('authToken') ?? "";

    final data = weddingDjJson['questions'] as List;
    questions = data.map((e) => VendorQuestion.fromJson(e)).toList();

    /// 🔥 controller creation (Venue jaisa)
    for (var q in questions) {
      if (q.type == 'number') {
        if (q.label.isNotEmpty) {
          for (int i = 0; i < q.label.length; i++) {
            textControllers[q.id + i] = TextEditingController();
          }
        } else {
          textControllers[q.id] = TextEditingController();
        }
      } else if (q.type == 'text' || q.type == 'textarea') {
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
          final qid = ans['faq_question_id'] ?? ans['faqQuestionId'];
          final value = ans['answer'];

          final q = questions.firstWhere(
                (e) => e.id == qid,
            orElse: () => VendorQuestion(
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

            case 'range':
              if (value is num) {
                selectedSlider[qid] = value.toDouble();
              }
              break;

            case 'number':
              if (value is Map) {
                value.forEach((k, v) {
                  textControllers[qid + int.parse(k)]?.text = v.toString();
                });
              } else {
                textControllers[qid]?.text = value.toString();
              }
              break;

            case 'text':
            case 'textarea':
              textControllers[qid]?.text = value.toString();
              break;
          }
        }
      }
    } catch (e) {
      debugPrint("FAQ fetch error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ================= SAVE =================
  Future<void> _saveFaqAnswers() async {
    final List<Map<String, dynamic>> answers = [];

    for (var q in questions) {
      dynamic ans;

      switch (q.type) {
        case 'radio':
          ans = selectedRadio[q.id];
          break;

        case 'checkbox':
          ans = selectedCheckbox[q.id];
          break;

        case 'range':
          ans = selectedSlider[q.id];
          break;

        case 'number':
          if (q.label.isNotEmpty) {
            final map = <String, String>{};
            for (int i = 0; i < q.label.length; i++) {
              final txt = textControllers[q.id + i]?.text.trim();
              if (txt != null && txt.isNotEmpty) {
                map[i.toString()] = txt;
              }
            }
            ans = map.isNotEmpty ? map : null;
          } else {
            ans = textControllers[q.id]?.text.trim();
          }
          break;

        case 'text':
        case 'textarea':
          ans = textControllers[q.id]?.text.trim();
          break;
      }

      if (ans != null && !(ans is List && ans.isEmpty)) {
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
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("FAQ Saved")));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Wedding DJ FAQs"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: questions.length,
        itemBuilder: (_, i) => _card(questions[i]),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveFaqAnswers, // 🔥 same save method
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

  Widget _card(VendorQuestion q) {
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

  Widget _input(VendorQuestion q) {
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

      case 'range':
        final value = selectedSlider[q.id] ?? q.min?.toDouble() ?? 0;
        return Slider(
          value: value,
          min: q.min?.toDouble() ?? 0,
          max: q.max?.toDouble() ?? 100000,
          onChanged: (v) => setState(() => selectedSlider[q.id] = v),
        );

      case 'number':
        return TextField(
          controller: textControllers[q.id],
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Enter value"),
        );

      default:
        return TextField(
          controller: textControllers[q.id],
          decoration: const InputDecoration(labelText: "Answer"),
        );
    }
  }
}


// ===== WEDDING DJ JSON =====
const weddingDjJson = {
  "vendor_type_id": 8,
  "vendor_type": "Wedding DJ",
  "questions": [
    {
      "id": 1501,
      "text": "What is the starting price for 1 event of your DJ only services?",
      "description": "Enter your average pricing in order for your Storefront to appear in results when couples search by price.",
      "label": [],
      "type": "number",
      "options": [],
      "min": null,
      "max": null
    },
    {
      "id": 1502,
      "text": "What is the starting price for 1 event of your DJ services with setup? (Typically includes: sound, light & dance floor set up)",
      "description": "",
      "label": [],
      "type": "range",
      "options": [],
      "min": 0,
      "max": 50000
    },
    {
      "id": 1503,
      "text": "Are you ready to host/provide service to events during COVID19, following the government guidelines?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Information not available", "Not operational", "Yes, with special deals", "Yes"],
      "min": null,
      "max": null
    },
    {
      "id": 1504,
      "text": "Which musical genres do you specialise in?",
      "description": "",
      "label": [],
      "type": "checkbox",
      "options": ["Bollywood","EDM","Punjabi","Rock","Hollywood","Hip-hop"],
      "min": null,
      "max": null
    },
    {
      "id": 1505,
      "text": "What additional setups do you offer?",
      "description": "",
      "label": [],
      "type": "checkbox",
      "options": ["Sound system","Dance floor","Lighting","LED screens","Projector","Karaoke"],
      "min": null,
      "max": null
    },
    {
      "id": 1506,
      "text": "Which forms of payment do you accept",
      "description": "",
      "label": [],
      "type": "checkbox",
      "options": ["Cash","Cheque/ DD","Credit/ Debit card","UPI","Net Banking","Mobile wallets"],
      "min": null,
      "max": null
    },
    {
      "id": 1507,
      "text": "What is the % payment/ amount to confirm the booking?",
      "description": "",
      "label": [],
      "type": "number",
      "options": [],
      "min": null,
      "max": null
    },
    {
      "id": 1508,
      "text": "What is the cancellation policy?",
      "description": "",
      "label": [],
      "type": "text",
      "options": [],
      "min": null,
      "max": null
    },
    {
      "id": 1509,
      "text": "Which year did you/your company professionally start your services?",
      "description": "",
      "label": [],
      "type": "number",
      "options": [],
      "min": null,
      "max": null
    },
    {
      "id": 1510,
      "text": "Awards, recognitions and publications",
      "description": "",
      "label": [],
      "type": "textarea",
      "options": [],
      "min": null,
      "max": null
    },
    {
      "id": 1511,
      "text": "What is the starting price range for 1 event of your DJ only services?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Under 5,000","5,000 - 9,999","10,000 - 14,999","15,000 - 19,999","20,000 - 24,999","25,000 - 29,999","30,000 - 39,999","40,000 - 49,999","50,000 and more"],
      "min": null,
      "max": null
    },
    {
      "id": 1512,
      "text": "What is the starting price range for 1 event of your DJ services with setup? (Typically includes: sound, light & dance floor set up)",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Under 10,000","10,000 - 14,999","15,000 - 19,999","20,000 - 24,999","25,000 - 29,999","30,000 - 49,999","50,000 - 74,999","75,000 - 99,999","1,00,000 and more"],
      "min": null,
      "max": null
    }
  ]
};
