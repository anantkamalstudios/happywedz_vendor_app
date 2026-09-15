
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_services/storefront_completion_service.dart';
import '../../utils/common_app_bar.dart';
import 'storefront_percentage_bar.dart';

//===== MODEL =====
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

// ================= SCREEN =================

class VenueFaqScreen extends StatefulWidget {
  const VenueFaqScreen({super.key});

  @override
  State<VenueFaqScreen> createState() => _VenueFaqScreenState();
}

class _VenueFaqScreenState extends State<VenueFaqScreen> {
  List<FaqQuestion> faqs = [];

  int vendorId = 0;
  int vendorTypeId = 2;
  String token = "";
  bool isLoading = false;

  /// states
  final Map<int, TextEditingController> textControllers = {};
  final Map<int, String> selectedRadio = {};
  final Map<int, List<String>> selectedCheckbox = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ================= INIT =================

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    vendorId = prefs.getInt('vendorId') ?? 0;
    vendorTypeId = prefs.getInt('vendorTypeId') ?? 2;
    token = prefs.getString('authToken') ?? "";

    final data = mockVenueJson['questions'] as List;
    faqs = data.map((e) => FaqQuestion.fromJson(e)).toList();

    /// 🔥 CONTROLLER FIX HERE
    for (var q in faqs) {
      if (q.type == 'number') {
        if (q.label.isNotEmpty) {
          // multiple fields (min/max etc.)
          for (int i = 0; i < q.label.length; i++) {
            textControllers[q.id + i] = TextEditingController();
          }
        } else {
          // 🔥 single number field (rental charge case)
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("FAQ Saved")));
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Venue FAQs"),
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
        if (q.label.isNotEmpty) {
          return Column(
            children: q.label.asMap().entries.map((e) {
              return TextField(
                controller: textControllers[q.id + e.key],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: e.value),
              );
            }).toList(),
          );
        } else {
          // 🔥 rental charge input
          return TextField(
            controller: textControllers[q.id],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Enter value"),
          );
        }

      default:
        return TextField(
          controller: textControllers[q.id],
          decoration: const InputDecoration(labelText: "Answer"),
        );
    }
  }
}

const mockVenueJson = {
  "vendor_type_id": 2,
  "vendor_type": "venues",
  "questions": [
    {
      "id": 101,
      "text": "Does your venue allow outside caterers?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Yes", "No"],
      "min": null,
      "max": null,
    },
    {
      "id": 202,
      "text": "Does your venue allow outside decorators?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Yes", "No"],
      "min": null,
      "max": null,
    },
    {
      "id": 203,
      "text": "Does your venue allow outside DJ?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Yes", "No"],
      "min": null,
      "max": null,
    },
    {
      "id": 204,
      "text": "Does your venue allow alcohol from outside?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Yes", "No"],
      "min": null,
      "max": null,
    },
    {
      "id": 205,
      "text": "Does your venue allow fireworks?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Yes", "No"],
      "min": null,
      "max": null,
    },
    {
      "id": 206,
      "text": "Does your venue have rooms available?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Yes", "No"],
      "min": null,
      "max": null,
    },
    {
      "id": 207,
      "text": "What are the different spaces available at your venue?",
      "description": "",
      "label": [],
      "type": "checkbox",
      "options": [
        "Banquet Hall",
        "Lawn",
        "Resort",
        "Marriage Garden",
        "Mandapam",
        "Palace/ Fort",
        "Destination Wedding Venue",
        "Other",
      ],
      "min": null,
      "max": null,
    },
    {
      "id": 208,
      "text": "What is your USP (Unique Selling Proposition)?",
      "description": "",
      "label": [],
      "type": "text",
      "options": [],
      "min": null,
      "max": null,
    },
    {
      "id": 209,
      "text": "How many guests can you accommodate?",
      "description": "",
      "label": ["Minimum number of guests", "Maximum number of guests"],
      "type": "number",
      "options": [],
      "min": null,
      "max": null,
    },
    {
      "id": 210,
      "text": "Do you provide valet parking?",
      "description": "",
      "label": [],
      "type": "radio",
      "options": ["Yes", "No"],
      "min": null,
      "max": null,
    },
    {
      "id": 211,
      "text": "What is the starting price per plate (for veg menu)?",
      "description": "",
      "label": ["Price Per Plate (Veg)"],
      "type": "number",
      "options": [],
      "min": null,
      "max": null,
    },
    {
      "id": 212,
      "text": "What is the starting price per plate (for non-veg menu)?",
      "description": "",
      "label": ["Price Per Plate (Non-Veg)"],
      "type": "number",
      "options": [],
      "min": null,
      "max": null,
    },
    {
      "id": 213,
      "text": "What is the rental charge of your venue (if applicable)?",
      "description": "",
      "label": [],
      "type": "number",
      "options": [],
      "min": null,
      "max": null,
    },
  ],
};
