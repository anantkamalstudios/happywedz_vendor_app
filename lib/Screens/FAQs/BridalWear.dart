
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

// ===== BRIDALWEAR FAQ SCREEN =====
class BridalwearFaqScreen extends StatefulWidget {
  const BridalwearFaqScreen({super.key});

  @override
  State<BridalwearFaqScreen> createState() => _BridalwearFaqScreenState();
}

class _BridalwearFaqScreenState extends State<BridalwearFaqScreen> {
  List<VendorQuestion> faqs = [];

  final Map<int, String> selectedRadio = {};
  final Map<int, List<String>> selectedCheckbox = {};
  final Map<int, TextEditingController> textControllers = {};
  final Map<int, bool> expandCheckbox = {};

  int vendorId = 0;
  int vendorTypeId = bridalwearJson["vendor_type_id"] as int;
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

    final data = bridalwearJson['questions'] as List;
    faqs = data.map((e) => VendorQuestion.fromJson(e)).toList();

    for (var q in faqs) {
      if (q.type == 'text' ||
          q.type == 'textarea' ||
          q.type == 'number') {
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
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List answers = [];
        if (data is List) {
          answers = data;
        } else if (data is Map && data['answers'] != null) {
          answers = data['answers'];
        }

        for (var ans in answers) {
          final qid =
              ans['faq_question_id'] ?? ans['faqQuestionId'];
          final value = ans['answer'];

          if (qid == null || value == null) continue;

          final q = faqs.firstWhere(
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
                selectedCheckbox[qid] =
                List<String>.from(value);
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
      debugPrint("Bridal FAQ fetch error: $e");
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
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("FAQ Saved")));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Bridal Wear FAQs"),
      body: isLoading
          ? const ListShimmer(itemCount: 5, showAvatar: false, itemHeight: 120)
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
            Text(q.text,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (q.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(q.description,
                    style: const TextStyle(color: Colors.grey)),
              ),
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
        bool expanded = expandCheckbox[q.id] ?? false;
        List<String> visible =
        expanded || q.options.length <= 2
            ? q.options
            : q.options.take(2).toList();

        return Column(
          children: [
            ...visible.map((o) {
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
            }),
            if (q.options.length > 2 && !expanded)
              TextButton(
                onPressed: () =>
                    setState(() => expandCheckbox[q.id] = true),
                child: const Text("View more"),
              ),
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

// ===== STATIC JSON =====
const bridalwearJson = {
  "vendor_type_id": 10,
  "vendor_type": "bridalwear",
  "questions": [
    {
      "id": 601,
      "text": "Which of the following outfit types do you offer?",
      "type": "checkbox",
      "options": [
        "Bridal Lehengas",
        "Light Lehengas",
        "Sarees",
        "Shararas",
        "Gowns",
        "Anarkalis",
        "Custom made outfits"
      ]
    },
    {
      "id": 602,
      "text": "Do you provide customization services?",
      "type": "radio",
      "options": ["Yes", "No"]
    },
    {
      "id": 603,
      "text": "Do you provide rental outfits?",
      "type": "radio",
      "options": ["Yes", "No"]
    },
    {
      "id": 604,
      "text": "What is the price range of your outfits?",
      "type": "radio",
      "options": [
        "Under ₹10,000",
        "₹10,000 - ₹24,999",
        "₹25,000 - ₹49,999",
        "₹50,000 - ₹74,999",
        "₹75,000 - ₹99,999",
        "₹1,00,000 and above"
      ]
    },
    {
      "id": 605,
      "text": "What is the starting price of bridal lehengas?",
      "label": ["Price(Bridal Lehengas)"],
      "type": "number",
      "options": []
    },
    {
      "id": 606,
      "text": "What is the starting price of light lehengas?",
      "label": ["Price(Light Lehengas)"],
      "type": "number",
      "options": []
    },
    {
      "id": 607,
      "text": "What is the starting price of sarees?",
      "label": ["Price (Sarees)"],
      "type": "number",
      "options": []
    },
    {
      "id": 608,
      "text": "What is the starting price of gowns?",
      "label": ["Price(Gowns)"],
      "type": "number",
      "options": []
    },
    {
      "id": 609,
      "text": "Which forms of payment do you accept?",
      "type": "checkbox",
      "options": [
        "Cash",
        "Cheque/ DD",
        "Credit/ Debit card",
        "UPI",
        "Net Banking",
        "Mobile wallets"
      ]
    },
    {
      "id": 610,
      "text": "What is your cancellation policy?",
      "type": "textarea",
      "options": []
    },
    {
      "id": 611,
      "text":
      "Which year did you/your company professionally start services in?",
      "type": "number",
      "options": []
    }
  ]
};
