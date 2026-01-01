import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../api_services/storefront_completion_service.dart';
import 'storefront_percentage_bar.dart';

// // ===== MODEL =====
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

// ===== FLORIST FAQ SCREEN =====
class FloristFaqScreen extends StatefulWidget {
  const FloristFaqScreen({super.key});

  @override
  State<FloristFaqScreen> createState() => _FloristFaqScreenState();
}

class _FloristFaqScreenState extends State<FloristFaqScreen> {
  List<FaqQuestion> faqs = [];

  final Map<int, String> selectedRadio = {};
  final Map<int, List<String>> selectedCheckbox = {};
  final Map<int, double> selectedSlider = {};
  final Map<int, TextEditingController> textControllers = {};
  final Map<int, bool> expandCheckbox = {};

  int vendorId = 0;
  int vendorTypeId = 0; // ✅ SAME FOR ALL SCREENS
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
    vendorTypeId = prefs.getInt('vendorTypeId') ?? 0; // ✅ FIXED
    token = prefs.getString('authToken') ?? "";

    final data = floristJson['questions'] as List;
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
      final response = await http.get(
        Uri.parse("https://happywedz.com/api/faq-answers/$vendorId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answers = (data is Map && data['answers'] != null)
            ? data['answers']
            : data;

        for (var ans in answers) {
          final qid = ans['faqQuestionId'] ?? ans['faq_question_id'];
          var value = ans['answer'];

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
              try {
                if (value is String && value.startsWith('{')) {
                  value = jsonDecode(
                      value.replaceAll('{', '[').replaceAll('}', ']'));
                }
                selectedCheckbox[qid] = List<String>.from(value);
              } catch (_) {
                selectedCheckbox[qid] = [];
              }
              break;

            case 'range':
              selectedSlider[qid] =
              (value is num) ? value.toDouble() : (q.min?.toDouble() ?? 0);
              break;

            default:
              textControllers[qid]?.text = value.toString();
          }
        }
      }
    } catch (e) {
      debugPrint("Florist FAQ fetch error: $e");
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
        case 'range':
          ans = selectedSlider[q.id];
          break;
        default:
          ans = textControllers[q.id]?.text.trim();
      }

      if (ans != null &&
          !(ans is String && ans.isEmpty) &&
          !(ans is List && ans.isEmpty)) {
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
        "vendorTypeId": vendorTypeId, // ✅ SAME
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
      appBar: AppBar(
        title: const Text("Florist FAQs", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F7FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
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
            onPressed: _saveFaqAnswers,
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
                  fontWeight: FontWeight.bold),
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
            if (q.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(q.description,
                    style: const TextStyle(color: Colors.grey)),
              ),
            const SizedBox(height: 10),
            _buildInput(q),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(FaqQuestion q) {
    switch (q.type) {
      case 'radio':
        return Column(
          children: q.options
              .map((o) => RadioListTile(
            title: Text(o),
            value: o,
            groupValue: selectedRadio[q.id],
            onChanged: (v) =>
                setState(() => selectedRadio[q.id] = v.toString()),
          ))
              .toList(),
        );

      case 'checkbox':
        return Column(
          children: q.options.map((o) {
            final checked =
                selectedCheckbox[q.id]?.contains(o) ?? false;
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
        final value =
            selectedSlider[q.id] ?? (q.min?.toDouble() ?? 0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Slider(
              value: value,
              min: q.min?.toDouble() ?? 0,
              max: q.max?.toDouble() ?? 1000000,
              divisions: 10,
              label: value.toStringAsFixed(0),
              onChanged: (v) =>
                  setState(() => selectedSlider[q.id] = v),
            ),
            Text("Selected: ${value.toStringAsFixed(0)}"),
          ],
        );

      default:
        return TextField(
          controller: textControllers[q.id],
          decoration: const InputDecoration(labelText: "Answer"),
        );
    }
  }
}
const floristJson = {
  "vendor_type_id": 13,
  "vendor_type": "Florist",
  "questions": [
    {
      "id": 801,
      "text":
      "What is the price for flower based traditional decoration for an indoor venue setup for 100 PAX for pre-wedding/ reception events? (Typically includes decoration of: entrance-8x8 ft, passage, guest area, stage area-16x12 ft)?",
      "description":
      "Enter your average pricing in order for your Storefront to appear in results when couples search by price.",
      "label": ["Venue decor"],
      "type": "number",
      "options": [],
      "min": null,
      "max": null
    },
    {
      "id": 802,
      "text":
      "What is the starting price for indoor floral decor services?",
      "description": "",
      "label": [],
      "type": "range",
      "options": [],
      "min": 0,
      "max": 1000000
    },
    {
      "id": 803,
      "text":
      "What is the starting price for flower based traditional decoration for an indoor venue setup for 100 PAX for pre-wedding/ reception events? (Typically includes decoration of: entrance-8x8 ft, passage, guest area, stage area-16x12 ft)?  ",
      "description":"",
      "label": [],
      "type": "range",
      "options": [],
      "min": 0,
      "max": 1000000
    },
    {
      "id": 804,
      "text":
      "Are you ready to host/provide service to events during COVID19, following the government guidelines?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": [
        "Information not available",
        "Not operational",
        "Yes, with special deals",
        "Yes"
      ],
      "min": null,
      "max": null
    },
    {
      "id": 805,
      "text":
      "What is the starting price for outdoor floral decor services?",
      "description":"",
      "label": [],
      "type": "range",
      "options": [],
      "min": 0,
      "max": 2000000
    },
    {
      "id": 806,
      "text":
      "What is the starting price for flower based traditional decoration for an outdoor setup for 300 PAX for wedding events? (Typically includes decoration of: entrance, passage, guest area, stage area, mandapa)",
      "description":"",
      "label": [],
      "type": "range",
      "options": [],
      "min": 0,
      "max": 2000000
    },
    {
      "id": 807,
      "text": "Which flowers do you provide for floral decorations?",
      "description": "",
      "label": [],
      "type": "checkbox",
      "options": [
        "Jasmine",
        "Sunflower",
        "Lotus",
        "Rose",
        "Orchid",
        "Lillies",
        "Perwinkle",
        "Bougainvillaea",
        "Marigold",
        "Hibiscus",
        "Carnations",
        "Gerbera"
      ],
      "min": null,
      "max": null
    },

    {
      "id": 808,
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
      "id": 809,
      "text": "What is the % payment/ amount to confirm the booking?",
      "description": "",
      "label": [],
      "type": "text",
      "options": [],
      "min": null,
      "max": null
    },
    {
      "id": 810,
      "text": "What is the cancellation policy?",
      "description": "",
      "label": [],
      "type": "text",
      "options": [],
      "min": null,
      "max": null
    },

    {
      "id": 811,
      "text": "Which year did you/your company professionally start services in?",
      "description": "",
      "label": [],
      "type": "number",
      "options": [],
      "min": null,
      "max": null,
    },
    {
      "id": 812,
      "text": "Awards, recognitions and publications",
      "description": "",
      "label": [],
      "type": "number",
      "options": [],
      "min": null,
      "max": null
    },
    {
      "id": 813,
      "text":
      "What is the price range for flower based home decoration for sangeet related events? (Typically includes decoration of balcony, entrance, & common area)?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": [
        "Under ₹5,000",
        "₹5,000 - ₹9,999",
        "₹10,000 - ₹14,999",
        "₹15,000 - ₹19,999",
        "₹20,000 - ₹24,999",
        "₹25,000 - ₹29,999",
        "₹30,000 - ₹39,999",
        "₹40,000 - ₹49,999",
        "₹50,000 and more",
      ],
      "min": null,
      "max": null
    },
    {
      "id": 814,
      "text":
      "What is the price range for flower based traditional decoration for an indoor venue setup for 100 PAX for pre-wedding/ reception events? (Typically includes decoration of entrance-8x8 ft, passage, guest area, stage area-16x12 ft)?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": [
        "Under ₹25,000",
        "₹25,000 - ₹49,999",
        "₹50,000 - ₹74,999",
        "₹75,000 - ₹99,999",
        "₹1,00,000 - ₹1,24,999",
        "₹1,25,000 - ₹1,49,999",
        "₹1,50,000 - ₹1,74,999",
        "₹1,75,000 - ₹1,99,999",
        "₹2,00,000 and more",
      ],
      "min": null,
      "max": null
    },
    {
      "id": 815,
      "text":
      "What is the price range for flower based traditional decoration for an outdoor setup for 300 PAX for wedding events?(Typically includes decoration of: entrance, passage, guest area, stage area, mandapa)",
      "description": "",
      "label": [],
      "type": "radio",
      "options": [
        "Under ₹50,000",
        "₹50,000 - ₹74,999",
        "₹75,000 - ₹99,999",
        "₹1,00,000 - ₹1,24,999",
        "₹1,25,000 - ₹1,49,999",
        "₹1,50,000 - ₹1,74,999",
        "₹1,75,000 - ₹1,99,999",
        "₹2,00,000 - ₹2,99,999",
        "₹3,00,000 and more",
      ],
      "min": null,
      "max": null
    },

    // Add remaining questions as needed
  ]
};