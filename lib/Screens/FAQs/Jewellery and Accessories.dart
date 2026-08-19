// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'storefront_percentage_bar.dart';
//
// // ===== MODEL =====
// class VendorQuestion {
//   final int id;
//   final String text;
//   final String description;
//   final List<String> label;
//   final String type;
//   final List<String> options;
//   final int? min;
//   final int? max;
//
//   VendorQuestion({
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
//   factory VendorQuestion.fromJson(Map<String, dynamic> json) {
//     return VendorQuestion(
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
// // ===== JEWELLERY FAQ SCREEN =====
// class JewelleryFaqScreen extends StatefulWidget {
//   const JewelleryFaqScreen({super.key});
//
//   @override
//   State<JewelleryFaqScreen> createState() => _JewelleryFaqScreenState();
// }
//
// class _JewelleryFaqScreenState extends State<JewelleryFaqScreen> {
//   late List<VendorQuestion> questions = [];
//   final Map<int, String> selectedRadio = {};
//   final Map<int, List<String>> selectedCheckbox = {};
//   final Map<int, double> selectedSlider = {};
//   final Map<int, TextEditingController> textControllers = {};
//   final Map<int, bool> expandCheckbox = {};
//
//   int vendorId = 0;
//   int vendorTypeId = 6;
//   String token = "";
//
//   bool isLoading = false;
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
//     vendorTypeId =
//         prefs.getInt('vendorTypeId') ?? (jewelleryJson['vendor_type_id'] ?? 6) as int;
//     token = prefs.getString('authToken') ?? "";
//
//     // Load static questions
//     final data = jewelleryJson['questions'] as List<dynamic>;
//     var faqs = data.map((e) => VendorQuestion.fromJson(e)).toList();
//     questions = faqs;
//
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
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
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
//             selectedSlider[qid] = (answer is num) ? answer.toDouble() : (question.min?.toDouble() ?? 0);
//           } else {
//             textControllers[qid]?.text = answer.toString();
//           }
//         }
//       } else {
//         debugPrint("❌ Failed to fetch FAQ answers: ${response.statusCode}");
//       }
//     } catch (e) {
//       debugPrint("⚠️ Error fetching FAQ answers: $e");
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
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//         body: jsonEncode(body),
//       );
//
//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("✅ FAQ answers saved successfully")),
//         );
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
//           "Jewellery FAQs",
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
//
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
//             Text(q.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//             if (q.description.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 4),
//                 child: Text(q.description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
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
//         return TextFormField(
//           controller: textControllers[q.id],
//           keyboardType: TextInputType.number,
//           decoration: InputDecoration(
//             labelText: q.label.isNotEmpty ? q.label.first : "Enter answer",
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//         );
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
//       case "radio":
//         return Column(
//           children: q.options.map((opt) => RadioListTile(
//             title: Text(opt),
//             value: opt,
//             groupValue: selectedRadio[q.id],
//             onChanged: (val) => setState(() => selectedRadio[q.id] = val.toString()),
//           )).toList(),
//         );
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
//                     if (val == true) selectedCheckbox[q.id]!.add(opt);
//                     else selectedCheckbox[q.id]!.remove(opt);
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
//       case "range":
//         double value = selectedSlider[q.id] ?? (q.min?.toDouble() ?? 0.0);
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Slider(
//               value: value,
//               min: q.min?.toDouble() ?? 0,
//               max: q.max?.toDouble() ?? 1000000,
//               divisions: 10,
//               label: value.toStringAsFixed(0),
//               onChanged: (val) => setState(() => selectedSlider[q.id] = val),
//             ),
//             Text("Selected: ${value.toStringAsFixed(0)}"),
//           ],
//         );
//       default:
//         return const SizedBox();
//     }
//   }
// }
//
//
//
//
// const jewelleryJson = {
//   "vendor_type_id": 6,
//   "vendor_type": "jewellery",
//   "questions": [
//     {"id":501,"text":"Which types of jewellery do you offer?","description":"","label":[],"type":"checkbox","options":["Gold Jewellery","Diamond Jewellery","Polki Jewellery","Kundan Jewellery","Platinum Jewellery","Silver Jewellery","Gemstone Jewellery","Temple Jewellery","Antique Jewellery","Artificial/Imitation Jewellery"],"min":null,"max":null},
//     {"id":502,"text":"Do you provide customised jewellery?","description":"","label":[],"type":"radio","options":["Yes","No"],"min":null,"max":null},
//     {"id":503,"text":"Do you provide rental jewellery?","description":"","label":[],"type":"radio","options":["Yes","No"],"min":null,"max":null},
//     {"id":504,"text":"What is the starting price range of your jewellery?","description":"","label":[],"type":"radio","options":["Under ₹10,000","₹10,000 - ₹49,999","₹50,000 - ₹99,999","₹1,00,000 - ₹2,49,999","₹2,50,000 - ₹4,99,999","₹5,00,000 and above"],"min":null,"max":null},
//     {"id":505,"text":"Do you provide Hallmarked Jewellery?","description":"","label":[],"type":"radio","options":["Yes","No"],"min":null,"max":null},
//     {"id":506,"text":"Do you provide certification for your jewellery?","description":"","label":[],"type":"radio","options":["Yes","No"],"min":null,"max":null},
//     {"id":507,"text":"Which forms of payment do you accept?","description":"","label":[],"type":"checkbox","options":["Cash","Cheque/ DD","Credit/ Debit card","UPI","Net Banking","Mobile wallets"],"min":null,"max":null},
//     {"id":508,"text":"What is your cancellation/return policy?","description":"","label":[],"type":"textarea","options":[],"min":null,"max":null},
//     {"id":509,"text":"Which year did you/your store professionally start providing jewellery?","description":"","label":[],"type":"number","options":[],"min":null,"max":null}
//   ]
// };


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api_services/storefront_completion_service.dart';
import '../../utils/common_app_bar.dart';
import '../../widgets/app_shimmer.dart';

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

// ===== JEWELLERY FAQ SCREEN =====
class JewelleryFaqScreen extends StatefulWidget {
  const JewelleryFaqScreen({super.key});

  @override
  State<JewelleryFaqScreen> createState() => _JewelleryFaqScreenState();
}

class _JewelleryFaqScreenState extends State<JewelleryFaqScreen> {
  List<VendorQuestion> questions = [];

  final Map<int, TextEditingController> textControllers = {};
  final Map<int, String> selectedRadio = {};
  final Map<int, List<String>> selectedCheckbox = {};

  int vendorId = 0;
  int vendorTypeId = 0;
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
    vendorTypeId = prefs.getInt('vendorTypeId') ?? 0;
    token = prefs.getString('authToken') ?? "";

    final data = jewelleryJson['questions'] as List;
    questions = data.map((e) => VendorQuestion.fromJson(e)).toList();

    for (var q in questions) {
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
        Uri.parse("https://happywedz.com/api/faq-answers/$vendorId"),
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

            case 'number':
            case 'text':
            case 'textarea':
              textControllers[qid]?.text = value.toString();
              break;
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Jewellery FAQ fetch error: $e");
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

        case 'number':
        case 'text':
        case 'textarea':
          ans = textControllers[q.id]?.text.trim();
          break;
      }

      if (ans != null && !(ans is List && ans.isEmpty) && ans.toString().isNotEmpty) {
        answers.add({"faqQuestionId": q.id, "answer": ans});
      }
    }

    await http.post(
      Uri.parse("https://happywedz.com/api/faq-answers/save"),
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

    // AUDIT FIX: context used after an await — guard added.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("FAQ Saved")),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Jewellery FAQs"),
      body: isLoading
          ? const ListShimmer(itemCount: 5, showAvatar: false, itemHeight: 120)
          : ListView.builder(
        itemCount: questions.length,
        itemBuilder: (_, i) => _faqCard(questions[i]),
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

              if (!context.mounted) return;
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

  Widget _faqCard(VendorQuestion q) {
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
        // AUDIT FIX — DEPRECATED RADIO API.
        // `RadioListTile.groupValue` and `.onChanged` were deprecated after
        // Flutter 3.32 in favour of a `RadioGroup` ancestor. The previous code
        // also did `selectedRadio[q.id] = v.toString()`, which stored the string
        // "null" if the tile ever reported a null value. Behaviour is otherwise
        // unchanged: the choice is still held in `selectedRadio[q.id]`.
        return RadioGroup<String>(
          groupValue: selectedRadio[q.id],
          onChanged: (v) => setState(() {
            if (v == null) {
              selectedRadio.remove(q.id);
            } else {
              selectedRadio[q.id] = v;
            }
          }),
          child: Column(
            children: q.options
                .map((o) => RadioListTile<String>(
                      title: Text(o),
                      value: o,
                    ))
                .toList(),
          ),
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
const jewelleryJson = {
  "vendor_type_id": 6,
  "vendor_type": "jewellery",
  "questions": [
    {
      "id": 501,
      "text": "Which types of jewellery do you offer?",
      "description": "",
      "label": [],
      "type": "checkbox",
      "options": [
        "Gold Jewellery",
        "Diamond Jewellery",
        "Polki Jewellery",
        "Kundan Jewellery",
        "Platinum Jewellery",
        "Silver Jewellery",
        "Gemstone Jewellery",
        "Temple Jewellery",
        "Antique Jewellery",
        "Artificial/Imitation Jewellery"
      ],
      "min": null,
      "max": null
    },
    {
      "id": 502,
      "text": "Do you provide customised jewellery?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Yes", "No"],
      "min": null,
      "max": null
    },
    {
      "id": 503,
      "text": "Do you provide rental jewellery?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Yes", "No"],
      "min": null,
      "max": null
    },
    {
      "id": 504,
      "text": "What is the starting price range of your jewellery?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": [
        "Under ₹10,000",
        "₹10,000 - ₹49,999",
        "₹50,000 - ₹99,999",
        "₹1,00,000 - ₹2,49,999",
        "₹2,50,000 - ₹4,99,999",
        "₹5,00,000 and above"
      ],
      "min": null,
      "max": null
    },
    {
      "id": 505,
      "text": "Do you provide Hallmarked Jewellery?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Yes", "No"],
      "min": null,
      "max": null
    },
    {
      "id": 506,
      "text": "Do you provide certification for your jewellery?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Yes", "No"],
      "min": null,
      "max": null
    },
    {
      "id": 507,
      "text": "Which forms of payment do you accept?",
      "description": "",
      "label": [],
      "type": "checkbox",
      "options": [
        "Cash",
        "Cheque/ DD",
        "Credit/ Debit card",
        "UPI",
        "Net Banking",
        "Mobile wallets"
      ],
      "min": null,
      "max": null
    },
    {
      "id": 508,
      "text": "What is your cancellation/return policy?",
      "description": "",
      "label": [],
      "type": "textarea",
      "options": [],
      "min": null,
      "max": null
    },
    {
      "id": 509,
      "text":
      "Which year did you/your store professionally start providing jewellery?",
      "description": "",
      "label": [],
      "type": "number",
      "options": [],
      "min": null,
      "max": null
    }
  ]
};
