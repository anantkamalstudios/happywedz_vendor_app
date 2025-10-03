import 'package:flutter/material.dart';

class PanditFaqScreen extends StatefulWidget {
  final double profileCompletion;

  const PanditFaqScreen({super.key, required this.profileCompletion});

  @override
  State<PanditFaqScreen> createState() => _PanditFaqScreenState();
}

class _PanditFaqScreenState extends State<PanditFaqScreen> {
  final TextEditingController priceController = TextEditingController();

  final List<String> eventsCovid = [
    "Information not available",
    "Not operational",
    "Yes, with special deals",
    "Yes"
  ];

  final List<String> paymentMethod = [
    "Net banking",
    "Cash",
    "Cheque/DD",
    "Debit/Credit cards",
    "Mobile wallets",
    "UPI"
  ];

  final List<String> advicePrices = [
    "Under ₹2,000",
    "₹2,000 - ₹4,999",
    "₹5,000 - ₹7,999",
    "₹8,000 - ₹9,999",
    "₹10,000 - ₹14,999",
    "₹15,000 and more"
  ];

  final List<String> poojaServices = [
    "Wedding ceremony",
    "Kundali match-making",
    "Griha pravesh",
    "Yagya/Hawan",
    "Mangal dosh",
    "Sundarkand/ Mata ki chowki",
    "Gauri pooja",
    "Lakshmi pooja",
    "Others"
  ];

  final List<String> languages = [
    "Hindi",
    "Sanskrit",
    "Tamil",
    "Telugu",
    "Kannada",
    "Marathi",
    "English",
    "Gujarati",
    "Bangali",
    "Marwari",
    "Jain",
    "Others"
  ];

  final List<String> counsultationService = [
    "Office/ Shop",
    "Home visits",
    "Online consultation",
    "Telephone consultation",
    "Video consultation",
    "Others",
  ];

  final List<String> ritualServices = [
    "Hinduism",
    "Islam",
    "Jainism",
    "Sikhism",
    "Buddhism",
    "Christianity",
    "Parsis",
    "Judaism",
    "Others",
  ];

  // ✅ Added state for expanded checkboxes
  Map<String, bool> selectedPoojaServices = {};
  Map<String, bool> selectedLanguages = {};
  Map<String, bool> selectedConsultation = {};
  Map<String, bool> selectedritual = {};

  String? selectedAdvicePrises;
  bool expandAdvicePrises = false;

  bool expandPooja = false;
  bool expandLanguage = false;
  bool expandConsultation = false;
  bool expandritual = false;

  @override
  void initState() {
    super.initState();

    for (var m in paymentMethod) {
      selectedMethod[m] = false;
    }

    // ✅ Initialize checkbox states
    for (var s in poojaServices) {
      selectedPoojaServices[s] = false;
    }

    for (var s in languages) {
      selectedLanguages[s] = false;
    }

    for (var s in counsultationService) {
      selectedConsultation[s] = false;
    }

    for( var s in ritualServices) {
      selectedritual[s] = false;
    }

  }

  final TextEditingController additionalNoteController = TextEditingController();

  @override
  void dispose() {
    priceController.dispose();
    super.dispose();
  }

  Map<String, bool> selectedMethod = {};

  String? travelOutsideOption;
  String? radioOption;

  Widget _buildQuestionWithCurrency(String question, TextEditingController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter your average pricing in order for your Storefront to appear in results when couples search by price.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxAll(String question, List<String> items, Map<String, bool> selectedMap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          ...items.map((item) {
            return CheckboxListTile(
              title: Text(item),
              value: selectedMap[item] ?? false,
              onChanged: (val) {
                setState(() {
                  selectedMap[item] = val!;
                });
              },
            );
          }).toList(),
        ]),
      ),
    );
  }

  // ✅ Reusable expanded checkbox widget
  Widget _buildCheckboxWithExpand(
      String question,
      List<String> items,
      Map<String, bool> selectedMap,
      bool expand,
      VoidCallback toggleExpand,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            ...items.take(2).map((item) {
              return CheckboxListTile(
                title: Text(item),
                value: selectedMap[item] ?? false,
                onChanged: (val) {
                  setState(() {
                    selectedMap[item] = val!;
                  });
                },
              );
            }).toList(),

            if (items.length > 2 && !expand)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: toggleExpand,
                  child: const Text("Show More"),
                ),
              ),

            if (expand)
              ...items.skip(2).map((item) {
                return CheckboxListTile(
                  title: Text(item),
                  value: selectedMap[item] ?? false,
                  onChanged: (val) {
                    setState(() {
                      selectedMap[item] = val!;
                    });
                  },
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWithRadio(String question, List<String> options) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          ...options.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: radioOption,
              onChanged: (value) => setState(() => radioOption = value),
            );
          }).toList(),
        ]),
      ),
    );
  }

  Widget _buildTravelOutsideQuestion() {
    final options = ["Yes", "No"];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            "Do you provide multi-tier cakes?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: options.map((option) {
              return Expanded(
                child: RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: travelOutsideOption,
                  onChanged: (val) {
                    setState(() {
                      travelOutsideOption = val;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  Widget _buildAdditionalQuestion(String question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          TextField(
            controller: additionalNoteController,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildRadioWithExpand(
      String question,
      List<String> options,
      String? groupValue,
      ValueChanged<String?> onChanged,
      bool expand,
      VoidCallback toggleExpand,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),

            // Always show first 2 options
            ...options.take(2).map((option) => RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: groupValue,
              onChanged: onChanged,
            )),

            // Show "Show More" button only when collapsed
            if (options.length > 2 && !expand)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: toggleExpand,
                  child: const Text("Show More"),
                ),
              ),

            // Show remaining options only when expanded
            if (expand)
              ...options.skip(2).map((option) => RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: groupValue,
                onChanged: onChanged,
              )),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Row(
          children: [
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                print("Entertainment price: ${priceController.text}");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.grey[300],
            pinned: true,
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: widget.profileCompletion,
                      minHeight: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "PROFILE COMPLETION",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        "${(widget.profileCompletion * 100).toInt()}%",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [

                  _buildQuestionWithCurrency(
                    "What is the starting price for wedding ceremony services (pooja/ feras)?",
                    priceController,
                  ),

                  // ✅ Astrology Services
                  _buildCheckboxWithExpand(
                    "What type of pooja/ceremony services do you provide?",
                    poojaServices,
                    selectedPoojaServices,
                    expandPooja,
                        () => setState(() => expandPooja = true),
                  ),

                  // ✅ Language Services
                  _buildCheckboxWithExpand(
                    "What are the language in which you can perform rituals/ceremonies",
                    languages,
                    selectedLanguages,
                    expandLanguage,
                        () => setState(() => expandLanguage = true),
                  ),

                  // ✅ Consultation Services
                  _buildCheckboxWithExpand(
                    "How do you provide consultation services?",
                    counsultationService,
                    selectedConsultation,
                    expandConsultation,
                        () => setState(() => expandConsultation = true),
                  ),
                  _buildCheckboxWithExpand(
                    "What religious/ faiths can you serve with ceremony or ritual services?",
                    ritualServices,
                    selectedritual,
                    expandritual,
                        () => setState(() => expandritual = true),
                  ),

                  _buildTravelOutsideQuestion(),

                  _buildCheckboxAll("Which forms of paymnet do you accept?", paymentMethod, selectedMethod),
                  _buildAdditionalQuestion("what is the % payment/ amount to confirm the booking?"),
                  _buildAdditionalQuestion("What is your cancellation policy?"),
                  _buildAdditionalQuestion("Which year did you/ your company professionally start your services?"),
                  _buildAdditionalQuestion("Awrds, recognitions and publications"),
                  _buildRadioWithExpand(
                    "What is the start price range for wedding ceremony services (pooja/ feras)?",
                    advicePrices,
                    selectedAdvicePrises,
                        (value) => setState(() => selectedAdvicePrises = value),
                    expandAdvicePrises,
                        () => setState(() => expandAdvicePrises = !expandAdvicePrises),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
