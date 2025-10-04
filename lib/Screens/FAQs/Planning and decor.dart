import 'package:flutter/material.dart';

class DecorationAndPlanningfaq extends StatefulWidget {


  const DecorationAndPlanningfaq({super.key});

  @override
  State<DecorationAndPlanningfaq> createState() => _DecorationAndPlanningfaqState();
}

class _DecorationAndPlanningfaqState extends State<DecorationAndPlanningfaq> {
  final TextEditingController decorationBudgetController = TextEditingController();
  final TextEditingController additionalNoteController = TextEditingController();
  double outdoorBudget = 0;
  String covidOption = '';
  double completionPercentage = 0.0;

  Map<String, bool> selectedThemes = {};
  Map<String, bool> selectedModernThemes = {};
  Map<String, bool> selectedPayment = {};

  // For last two expandable radio questions
  String? selectedIndoorPrice;
  String? selectedOutdoorPrice;
  bool expandIndoorOptions = false;
  bool expandOutdoorOptions = false;

  final List<String> covidOptions = [
    "Information not available",
    "Not operational",
    "Yes, with special deals",
    "Yes",
  ];

  final List<String> flowerDecoration1 = [
    "Under ₹25,000",
    "₹25,000 - ₹49,999",
    "₹50,000 - ₹74,999",
    "₹75,000 - ₹99,999",
    "₹1,00,000 - ₹1,24,999",
    "₹1,25,000 - ₹1,49,999",
    "₹1,50,000 - ₹1,74,999",
    "₹1,75,000 - ₹1,99,999",
    "₹2,00,000 and more"
  ];

  final List<String> flowerDecoration2 = [
    "Under ₹50,000",
    "₹50,000 - ₹74,999",
    "₹75,000 - ₹99,999",
    "₹1,00,000 - ₹1,24,999",
    "₹1,25,000 - ₹1,49,999",
    "₹1,50,000 - ₹1,74,999",
    "₹1,75,000 - ₹1,99,999",
    "₹2,00,000 - ₹2,99,999",
    "₹3,00,000 and more",
  ];

  final List<String> traditionalThemes = [
    "Floral",
    "Rajasthani",
    "Punjabi",
    "South Indian",
    "Royal",
    "Bollywood",
  ];

  final List<String> decorationThemes = [
    "Art deco/ Gatsby",
    "Vintage",
    "Bohemian",
    "Greenhouse",
    "Metallic",
    "Moroccan",
    "Rustic",
    "Sun Downer",
    "Theatrical",
  ];

  final List<String> paymentType = [
    "Cash",
    "Cheque/DD",
    "Credit/Debit Card",
    "UPI",
    "Net banking",
    "Mobile wallets",
  ];

  @override
  void initState() {
    super.initState();
    for (var theme in traditionalThemes) {
      selectedThemes[theme] = false;
    }
    for (var theme in decorationThemes) {
      selectedModernThemes[theme] = false;
    }
    for (var pay in paymentType) {
      selectedPayment[pay] = false;
    }
  }

  @override
  void dispose() {
    decorationBudgetController.dispose();
    additionalNoteController.dispose();
    super.dispose();
  }

  Widget _buildQuestionWithCurrency(String question, TextEditingController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text(
              "Enter your average pricing for your storefront to appear in search results.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: "Enter amount",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWithSlider(String question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            Slider(
              value: outdoorBudget,
              min: 0,
              max: 300000,
              divisions: 300,
              label: "₹ ${outdoorBudget.toInt()}",
              onChanged: (value) {
                setState(() {
                  outdoorBudget = value;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("0", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("₹ 3,00,000+", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWithRadio(String question, List<String> options, String? groupValue, Function(String) onChanged,
      {bool expandable = false, bool expanded = false, VoidCallback? onToggle}) {
    final visibleOptions = expandable && !expanded ? options.take(2).toList() : options;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          ...visibleOptions.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: groupValue,
              onChanged: (value) => setState(() => onChanged(value!)),
            );
          }),
          if (expandable && options.length > 2)
            TextButton.icon(
              onPressed: onToggle,
              icon: Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              label: Text(expanded ? "View less" : "View more"),
            ),
        ]),
      ),
    );
  }

  Widget _buildQuestionWithCheckboxMap(String question, List<String> options, Map<String, bool> selectedMap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            ...options.map((option) {
              return CheckboxListTile(
                title: Text(option),
                value: selectedMap[option],
                onChanged: (value) {
                  setState(() {
                    selectedMap[option] = value!;
                  });
                },
              );
            }),
          ],
        ),
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
                print("Indoor Range: $selectedIndoorPrice");
                print("Outdoor Range: $selectedOutdoorPrice");
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
                      value: completionPercentage.clamp(0.0, 1.0),
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
                        "${(completionPercentage * 100).toInt()}%",
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
                    "What is the price for flower-based traditional decoration for an indoor venue setup for 100 PAX?",
                    decorationBudgetController,
                  ),
                  _buildQuestionWithSlider(
                    "What is the price for flower-based traditional decoration for an outdoor setup for 300 PAX?",
                  ),
                  _buildQuestionWithRadio(
                    "Are you ready to host/provide service to events during COVID19?",
                    covidOptions,
                    covidOption,
                        (v) => covidOption = v,
                  ),
                  _buildQuestionWithCheckboxMap(
                    "What all traditional themes of decoration can you fulfill?",
                    traditionalThemes,
                    selectedThemes,
                  ),
                  _buildQuestionWithCheckboxMap(
                    "What all modern themes of decoration can you fulfill?",
                    decorationThemes,
                    selectedModernThemes,
                  ),
                  _buildQuestionWithCheckboxMap(
                    "Which form of payment do you accept?",
                    paymentType,
                    selectedPayment,
                  ),
                  _buildAdditionalQuestion("What is the % payment/ amount to confirm the booking?"),
                  _buildAdditionalQuestion("What is the cancellation policy?"),
                  _buildAdditionalQuestion("Which year did you/ your company professionally start your services?"),
                  _buildAdditionalQuestion("Awards, recognitions and publications"),
                  _buildQuestionWithRadio(
                    "Indoor flower-based decoration price range",
                    flowerDecoration1,
                    selectedIndoorPrice,
                        (v) => selectedIndoorPrice = v,
                    expandable: true,
                    expanded: expandIndoorOptions,
                    onToggle: () => setState(() => expandIndoorOptions = !expandIndoorOptions),
                  ),
                  _buildQuestionWithRadio(
                    "Outdoor flower-based decoration price range",
                    flowerDecoration2,
                    selectedOutdoorPrice,
                        (v) => selectedOutdoorPrice = v,
                    expandable: true,
                    expanded: expandOutdoorOptions,
                    onToggle: () => setState(() => expandOutdoorOptions = !expandOutdoorOptions),
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
