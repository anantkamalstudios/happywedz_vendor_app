import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api_services/storefront_completion_service.dart';
import '../../utils/common_app_bar.dart';
import 'storefront_percentage_bar.dart';

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

// ===== GIFTS SCREEN =====
// class GiftsScreen extends StatefulWidget {
//   const GiftsScreen({super.key});
//
//   @override
//   State<GiftsScreen> createState() => _GiftsScreenState();
// }
//
// class _GiftsScreenState extends State<GiftsScreen> {
//   late List<VendorQuestion> questions;
//
//   final Map<int, String> selectedRadio = {};
//   final Map<int, List<String>> selectedCheckbox = {};
//   final Map<int, double> selectedSlider = {};
//   final Map<int, TextEditingController> textControllers = {};
//   final Map<int, bool> expandCheckbox = {};
//
//   int vendorId = 0;
//   int vendorTypeId = 9; // Gifts
//   String token = "";
//   bool isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initGiftsScreen();
//
//   }
//
//   Future<void> _initGiftsScreen() async {
//     final prefs = await SharedPreferences.getInstance();
//     vendorId = prefs.getInt('vendorId') ?? 0;
//     vendorTypeId = prefs.getInt('vendorTypeId') ?? (giftsJson['vendor_type_id'] ?? 9) as int;
//     token = prefs.getString('authToken') ?? "";
//
//     final data = giftsJson['questions'] as List<dynamic>;
//     questions = data.map((e) => VendorQuestion.fromJson(e)).toList();
//
//     // Initialize text controllers
//     for (var q in questions) {
//       if (q.type == 'text' || q.type == 'textarea' || q.type == 'number') {
//         textControllers[q.id] = TextEditingController();
//       }
//     }
//
//     if (vendorId != 0 && token.isNotEmpty) {
//       await _fetchSavedAnswers();
//     } else {
//       setState(() {});
//     }
//   }
//
//   // ===== FETCH SAVED ANSWERS =====
//   Future<void> _fetchSavedAnswers() async {
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
//           final answer = ans['answer'];
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
//               selectedCheckbox[qid] = List<String>.from(answer);
//             } catch (_) {
//               selectedCheckbox[qid] = [];
//             }
//           } else if (question.type == 'radio') {
//             selectedRadio[qid] = answer.toString();
//           } else if (question.type == 'range') {
//             selectedSlider[qid] =
//             (answer is num) ? answer.toDouble() : (question.min?.toDouble() ?? 0);
//           } else {
//             textControllers[qid]?.text = answer.toString();
//           }
//         }
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
//     // Only include answered questions
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
//         headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
//         body: jsonEncode(body),
//       );
//
//
//       print("📤 Sent: ${jsonEncode(body)}");
//       print("📩 Response (${response.statusCode}): ${response.body}");
//       print("🪪 vendorId: $vendorId");
//       print("🔐 token: $token");
//       print("🎨 vendorTypeId: $vendorTypeId");
//       print("➡️ Sending: ${jsonEncode(body)}");
//
//
//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("✅ FAQ answers saved successfully")),
//         );
//         await _fetchSavedAnswers();
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
//           "Wedding Gift FAQs",
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
//         backgroundColor: const Color(0xFF00BCD4),
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
//                 style: const TextStyle(
//                     fontSize: 16, fontWeight: FontWeight.w600, height: 1.3)),
//             if (q.description.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 4, bottom: 8),
//                 child: Text(q.description,
//                     style: TextStyle(color: Colors.grey[700])),
//               ),
//             const SizedBox(height: 8),
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
//           minLines: q.type == "textarea" ? 3 : 1,
//           maxLines: q.type == "textarea" ? 5 : 1,
//           keyboardType: q.type == "number" ? TextInputType.number : TextInputType.text,
//           decoration: InputDecoration(
//             labelText: q.label.isNotEmpty ? q.label.first : "Enter answer",
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           ),
//         );
//
//       case "radio":
//         return Column(
//           children: q.options.map((opt) {
//             return RadioListTile(
//               title: Text(opt),
//               value: opt,
//               groupValue: selectedRadio[q.id],
//               onChanged: (val) => setState(() => selectedRadio[q.id] = val.toString()),
//             );
//           }).toList(),
//         );
//
//       case "checkbox":
//         bool isExpanded = expandCheckbox[q.id] ?? false;
//         List<String> optionsToShow = isExpanded || q.options.length <= 2
//             ? q.options
//             : q.options.sublist(0, 2);
//
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ...optionsToShow.map((opt) {
//               bool checked = selectedCheckbox[q.id]?.contains(opt) ?? false;
//               return CheckboxListTile(
//                 title: Text(opt),
//                 value: checked,
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
//             }).toList(),
//             if (!isExpanded && q.options.length > 2)
//               TextButton(
//                   onPressed: () {
//                     setState(() => expandCheckbox[q.id] = true);
//                   },
//                   child: const Text("View More"))
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
//               max: q.max?.toDouble() ?? 100,
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
class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  List<VendorQuestion> questions = [];

  final Map<int, TextEditingController> textControllers = {};
  final Map<int, String> selectedRadio = {};
  final Map<int, List<String>> selectedCheckbox = {};
  final Map<int, double> selectedSlider = {};
  final Map<int, bool> expandCheckbox = {};

  int vendorId = 0;
  int vendorTypeId = 9;
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
    vendorTypeId = prefs.getInt('vendorTypeId') ?? 9;
    token = prefs.getString('authToken') ?? "";

    final data = giftsJson['questions'] as List;
    questions = data.map((e) => VendorQuestion.fromJson(e)).toList();

    /// 🔥 Controller init (Venue jaisa)
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
      await _fetchSavedAnswers();
    }

    setState(() {});
  }

  // ================= FETCH =================
  Future<void> _fetchSavedAnswers() async {
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
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("FAQ Saved")));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Wedding Gift FAQs",),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: questions.length,
        itemBuilder: (_, i) => _card(questions[i]),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   backgroundColor: const Color(0xFF00BCD4),
      //   icon: const Icon(Icons.send),
      //   label: const Text("Submit"),
      //   onPressed: () async {
      //     await _saveFaqAnswers();
      //     await ProfileCompletionController.markDone(ProfileCompletionController.keyFaq);
      //     if (!mounted) return;
      //     Navigator.popUntil(context, (r) => r.isFirst);
      //   },
      // ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
              onPressed: () async {
                await _saveFaqAnswers();
                // await ProfileCompletionController.markDone(ProfileCompletionController.keyFaq);
                if (!mounted) return;
                Navigator.popUntil(context, (r) => r.isFirst);
              }, // 🔥 same save method
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
          max: q.max?.toDouble() ?? 5000,
          onChanged: (v) => setState(() => selectedSlider[q.id] = v),
        );

      case 'number':
      case 'text':
      case 'textarea':
        return TextField(
          controller: textControllers[q.id],
          keyboardType:
          q.type == 'number' ? TextInputType.number : TextInputType.text,
          maxLines: q.type == 'textarea' ? 4 : 1,
          decoration: const InputDecoration(labelText: "Enter value"),
        );

      default:
        return const SizedBox();
    }
  }
}


// ===== GIFTS JSON =====
const giftsJson = {
  "vendor_type_id": 9,
  "vendor_type": "Gifts",
  "questions": [
    {"id":2101,"text":"What is the starting price per kg for edible gifting or favors? (Typically includes: Sweets or chocolates)","description":"Enter your average pricing in order for your Storefront to appear in results when couples search by price.","label":["Price per gift"],"type":"number","options":[],"min":null,"max":null},
    {"id":2102,"text":"Are you ready to host/provide service to events during COVID19, following the government guidelines?","description":"","label":[],"type":"radio","options":["Information not available","Not operational","Yes, with special deals","Yes"],"min":null,"max":null},
    {"id":2103,"text":"What is the starting price per gift/ pack for non-edible gifting or favors?","description":"","label":[],"type":"range","options":[],"min":0,"max":5000},
    {"id":2104,"text":"What is the minimum order quantity for edible gifting or favors?","description":"","label":[],"type":"textarea","options":[],"min":null,"max":null},
    {"id":2105,"text":"What is the minimum order quantity for non-edible gifting or favors?","description":"","label":[],"type":"textarea","options":[],"min":null,"max":null},
    {"id":2106,"text":"What types of gifting options do you provide?","description":"","label":[],"type":"checkbox","options":["Edible","Non-edible"],"min":null,"max":null},
    {"id":2107,"text":"Which forms of payment do you accept?","description":"","label":[],"type":"checkbox","options":["Cash","Cheque/ DD","Credit/ Debit card","UPI","Net Banking","Mobile wallets"],"min":null,"max":null},
    {"id":2108,"text":"What is the % payment/ amount to confirm the booking?","description":"","label":[],"type":"number","options":[],"min":null,"max":null},
    {"id":2109,"text":"What is the cancellation policy?","description":"","label":[],"type":"text","options":[],"min":null,"max":null},
    {"id":2110,"text":"Which year did you/your company professionally start your services?","description":"","label":[],"type":"number","options":[],"min":null,"max":null},
    {"id":2111,"text":"Awards, recognitions and publications","description":"","label":[],"type":"textarea","options":[],"min":null,"max":null},
    {"id":2112,"text":"What is the starting price range per kg for edible gifting or favors? (Typically includes: Sweets or chocolates)","description":"","label":[],"type":"radio","options":["Under ₹100","₹100 - ₹199","₹200 - ₹499","₹500 - ₹999","₹1000 - ₹1999","₹2000 and more"],"min":null,"max":null},
    {"id":2113,"text":"What is the starting price range per gift/ pack for non-edible gifting or favors?","description":"","label":[],"type":"radio","options":["Under ₹100","₹100 - ₹199","₹200 - ₹499","₹500 - ₹999","₹1000 - ₹1999","₹2000 and more"],"min":null,"max":null},
    {"id":2114,"text":"What is the minimum order quantity range for edible gifting or favors?","description":"","label":[],"type":"radio","options":["0-19","20-49","50-99","100-199","200-299","300 and more"],"min":null,"max":null},
    {"id":2115,"text":"What is the minimum order quantity range for non-edible gifting or favors?","description":"","label":[],"type":"radio","options":["0-19","20-49","50-99","100-199","200-299","300 and more"],"min":null,"max":null}
  ]
};
