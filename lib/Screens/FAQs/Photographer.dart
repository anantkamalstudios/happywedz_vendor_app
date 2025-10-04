import 'package:flutter/material.dart';

class PhotographerFaqScreen extends StatefulWidget {


  const PhotographerFaqScreen({super.key});

  @override
  State<PhotographerFaqScreen> createState() => _PhotographerFaqScreenState();
}


class _PhotographerFaqScreenState extends State<PhotographerFaqScreen> {
  final TextEditingController priceController = TextEditingController();

  double completionPercentage = 0.0;


  final List<String> eventsCovid = [
    "Information not available",
    "Not operational",
    "Yes, with special deals",
    "Yes"
  ];

  final List<String> occasionsList = [
    "Wedding & engagement",
    "Engagement photography",
    "Mehndi & sangeet",
    "Couple pre-wedding",
    "Parties",
    "Corporate events",
    "Maternity shoot",
    "Baby Shoot"
  ];

  final List<String> shootingIdeas = [
    "Traditioanl",
    "Candid",
    "cinematographic",
    "Drone Shoots",
    "Photobooth",
    "Live Screening",
  ];

  final List<String> paymentMethod = [
    "Net banking",
    "Cash",
    "Cheque/DD",
    "Debit/Credit cards",
    "Mobile wallets",
    "UPI"
  ];

  final List<String> preWeddingAmount = [
    "Under ₹25,000 ",
    "₹25,000 - ₹49,999",
    "₹50,000 - ₹74,999",
    "₹75,000 - ₹99,999",
    "₹1,00,000 - ₹1,24,999",
    "₹1,25,000 - ₹1,49,999",
    "₹1,50,000 - ₹1,99,999",
    "₹2,00,000 and more"
  ];

  final List<String> day1Amount = [
    "Under ₹25,000",
    "₹25,000 - ₹49,999",
    "₹50,000 - ₹74,999",
    "₹75,000 - ₹99,999",
    "₹1,00,000 - ₹1,24,999",
    "₹1,25,000 - ₹1,49,999",
    "₹1,50,000 - ₹1,99,999",
    "₹2,00,000 and more",
  ];

  final List<String> day2Amount = [
    "Under ₹50,000",
    "50,000 - ₹74,999",
    "75,000 - ₹99,999",
    "₹1,00,000 - ₹1,49,999",
    "₹1,50,000 - ₹1,99,999",
    "₹2,00,000 - ₹2,49,999",
    "₹2,50,000 - ₹2,99,999",
    "₹3,00,000 and more"
  ];

  final List<String> day3Amount = [
    "Under ₹75,000",
    "₹75,000 - ₹99,999",
    "₹1,00,000 - 1,49,999",
    "₹1,50,000 - 1,99,999",
    "₹2,00,000 - ₹2,49,999",
    "₹2,50,000 - ₹2,99,999",
    "₹3,00,000 - ₹3,99,999",
    "₹4,00,000 and more"
  ];

  String? selectedPreWedAmount;
  String? selectedDay1Amount;
  String? selectedDay2Amount;
  String? selectedDay3Amount;

  bool expandPreWeddingAmount = false;
  bool expandDay1Amount = false;
  bool expandDay2Amount = false;
  bool expandDay3Amount = false;


  double outdoorBudget = 0;
  String? radioOption;

  bool expandedOcassions = false;
  bool expandIdeas = false;

  Map<String, bool> selectedOcassion = {};
  Map<String, bool> selectedIdea = {};
  Map<String, bool> selectedMethod = {};

  String? travelOutsideOption;

  final TextEditingController additionalNoteController = TextEditingController();


  @override
  void initState() {
    super.initState();
    for (var occasionsList in occasionsList) {
      selectedOcassion[occasionsList] = false;
    }
    for( var shootingIdeas in shootingIdeas){
      selectedIdea[shootingIdeas] = false;
    }
    for( var paymentMethod in paymentMethod) {
      selectedMethod[paymentMethod] = false;
    }
  }

  @override
  void dispose() {
    priceController.dispose();
    super.dispose();
  }

  Widget _buildQuestionWithCurrency(String question, TextEditingController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
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
        ]),
      ),
    );
  }




  Widget _buildCheckboxWithExpand(
      String question, List<String> items, Map<String, bool> selectedMap, bool expand, VoidCallback toggleExpand) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          ...items.take(2).map((item) {
            return CheckboxListTile(
              title: Text(item),
              value: selectedMap[item],
              onChanged: (val) {
                setState(() {
                  selectedMap[item] = val!;
                });
              },
            );
          }).toList(),
          if (items.length > 2)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: toggleExpand,
                child: Text(expand ? "Show Less" : "Show More"),
              ),
            ),
          if (expand)
            ...items.skip(2).map((item) {
              return CheckboxListTile(
                title: Text(item),
                value: selectedMap[item],
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

  Widget _buildQuestionWithSlider(String question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          Slider(
            value: outdoorBudget,
            min: 0,
            max: 1000000,
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
              Text("₹0", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("₹ 1,000,000+", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ]),
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

  Widget _buildTravelOutsideQuestion() {
    final options = ["Yes", "No"];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            "Do you travel outside?",
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
  Widget _buildCheckboxAll(String question, List<String> items, Map<String, bool> selectedMap) {
    // For payment methods: show all at once
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
              value: selectedMap[item],
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
                print("Price Question: ${priceController.text}");
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
                      "What is the price for 1 day Marriage offering that inclides Photography and Vediography "
                          "(Candid/ Cinematographic & Traditional) for an audinece size of 300?",
                      priceController,
                    ),
                    _buildQuestionWithSlider(
                        "What is the price for 1 day pre-wedding photoshoot? (Typically inlcudes: Teaser & a highlight video with photographs shot candidly and traditionally)"),
                    _buildQuestionWithRadio("Are you ready to host/provide service to events during COVID19, following the government guidelines?", eventsCovid),
                    _buildQuestionWithSlider(
                        "What is the price for 2 day wedding package that covers engagement/reception & wedding for an audience size of 300? "
                            "(Typically includes: Photography & Videography, both shot candidly and traditionally"),
                    _buildQuestionWithSlider(
                        "What is the price for 3 day wedding package that covers pre-Wedding, engagement/reception & wedding for an audience size of 300?"
                            "(Typically includes: Photography & Videography, both shot candidly and traditionally"),

                    _buildCheckboxWithExpand(
                      "What are the occasions that you cover?",
                      occasionsList,
                      selectedOcassion,
                      expandedOcassions,
                          () => setState(() => expandedOcassions = !expandedOcassions),
                    ),
                    _buildCheckboxWithExpand(
                      "What shooting capabilities do you provide?",
                      shootingIdeas,
                      selectedIdea,
                      expandIdeas,
                          () => setState(() => expandIdeas = !expandIdeas),
                    ),
                    _buildTravelOutsideQuestion(),
                    _buildCheckboxAll(
                      "Which forms of payment do you accept?",
                      paymentMethod,
                      selectedMethod,
                    ),
                    _buildAdditionalQuestion("What is the % advance amount to confirm the booking?"),
                    _buildAdditionalQuestion("What is your cancellation policy?"),
                    _buildAdditionalQuestion("which year did you/your company professionally start services in?"),

                    _buildRadioWithExpand(
                      "What is the price range for 1 day pre-wedding photoshoot? (Typically includes: Teaser & a highlight vedio with photographs shot candidly and traditionally)",
                      preWeddingAmount,
                      selectedPreWedAmount,
                          (value) => setState(() => selectedPreWedAmount = value),
                      expandPreWeddingAmount,
                          () => setState(() => expandPreWeddingAmount = !expandPreWeddingAmount),
                    ),
                    _buildRadioWithExpand(
                      "What is the price range for 1 day wedding package for an audience size of 300?"
                          "(Typically includes: Photography & Videography, both shot candidly and traditioanlly)",
                      day1Amount,
                      selectedDay1Amount,
                          (value) => setState(() => selectedDay1Amount = value),
                      expandDay1Amount,
                          () => setState(() => expandDay1Amount = !expandDay1Amount),
                    ),
                    _buildRadioWithExpand(
                      "What is the price range for 2 day wedding package that covers engagement/reception & wedding for an audience size of 300?"
                          "(Typically includes: Photography & Videography, both shot candidly and traditionally)",
                      day2Amount,
                      selectedDay2Amount,
                          (value) => setState(() => selectedDay2Amount = value),
                      expandDay2Amount,
                          () => setState(() => expandDay2Amount = !expandDay2Amount),
                    ),
                    _buildRadioWithExpand(
                      "What is the price range fir 3 day wedding packgae that covers pre-Wedding, enagagement/reception & wedding for an audience size of 300?"
                          "(Typically includes: Photography & Videography, both shot candidly and traditioanlly)",
                      day3Amount,
                      selectedDay3Amount,
                          (value) => setState(() => selectedDay3Amount = value),
                      expandDay3Amount,
                          () => setState(() => expandDay3Amount = !expandDay3Amount),
                    ),
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
