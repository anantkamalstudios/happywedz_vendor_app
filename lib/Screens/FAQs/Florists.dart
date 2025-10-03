import 'package:flutter/material.dart';

class FloristsFaqScreen extends StatefulWidget {
  final double profileCompletion;

  const FloristsFaqScreen({super.key, required this.profileCompletion});

  @override
  State<FloristsFaqScreen> createState() => _FloristsFaqScreenState();
}

class _FloristsFaqScreenState extends State<FloristsFaqScreen> {
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

  final List<String> preWeddingAmount = [
    "Under ₹5,000",
    "₹5,000 - ₹9,999",
    "₹10,000 - ₹14,999",
    "₹15,000 - ₹19,999",
    "₹20,000 - ₹24,999",
    "₹25,000 - ₹29,999",
    "₹30,000 - ₹39,999",
    "₹40,000 - ₹49,999",
    "₹50,000 and more"
  ];

  final List<String> day1Amount = [
    "Under ₹25,000",
    "₹25,000 - ₹49,999",
    "₹50,000- ₹74,999",
    "₹75,000 - ₹99,999",
    "₹1,00,,000 - ₹1,24,999",
    "₹1,25,,000 - ₹1,49,999",
    "₹1,50,000 - ₹1,74,999",
    "₹1,75,,000 - ₹1,99,999",
    "₹2,00,000 and more"
  ];

  final List<String> day2Amount = [
    "Under ₹50,000",
    "50,000 - 74,999",
    "75,000 - 99,999",
    "1,00,000 - 1,24,999",
    "1,25,000 - 1,49,999",
    "1,50,000 - 1,74,999",
    "1,75,000 - 1,99,999",
    "2,00,000 - 2,99,999",
    "3,00,000 and more"
  ];


  final List<String> floralDecor = [
    "Jasmine",
    "Sunflower",
    "Lotus",
    "Rose",
    "Orchid",
    "Lillies",
    "Periwinkle",
    "Bougainvillaea",
    "Marigold",
    "Hibiscus",
    "Carnations",
    "Gerbera",
  ];

  String? selectedPreWedAmount;
  String? selectedDay1Amount;
  String? selectedDay2Amount;

  String? selectedFloralDecor;

  bool expandPreWeddingAmount = false;
  bool expandDay1Amount = false;
  bool expandDay2Amount = false;

  bool expandFloralDecor = false;


  double outdoorBudget = 0;
  String? radioOption;


  bool expandIdeas = false;

  Map<String, bool> selectedConcept = {};
  Map<String, bool> selectedPaper = {};
  Map<String, bool> selectedIdea = {};
  Map<String, bool> selectedMethod = {};

  String? travelOutsideOption;

  final TextEditingController additionalNoteController = TextEditingController();


  @override
  void initState() {
    super.initState();
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
                      const Text("PROFILE COMPLETION", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("${(widget.profileCompletion * 100).toInt()}%",
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                      "What is the price for flower based traditional decoration for an indoor venue setup for 100 PAX for pre-wedding/ reception events?"
                          "(Typically inlcudes decoration of: entrance-8*8 ft, passage, guest area, satge area-16*12 ft)?",
                      priceController,
                    ),


                    _buildQuestionWithSlider(
                        "What is the starting price for indoor floral decor services?"),
                    _buildQuestionWithSlider(
                        "What is the starting price for flower based traditional decoration for an indoor venue setup for 100 PAX for pre-wedding/ reception events?"
                            "(Typically includes decoration of: entrance- 8*8 ft, passage, guest area, stage area-16*12 ft?"),
                    _buildQuestionWithRadio("Are you ready to host/provide service to events during COVID19, following the government guidelines?", eventsCovid),

                    _buildQuestionWithSlider(
                        "What is the starting price for outdoor floral decor services?"),
                    _buildQuestionWithSlider(
                        "What is the starting price for flower based traditional decoration for an outdoor setup for 300 PAX for wedding events?"
                            "(Typically includes decoration of: entrance, passage, guest area, stage area, mandapa)"),

                    _buildRadioWithExpand(
                      "Which flowers do you provide for floral decorations?",
                      floralDecor,
                      selectedFloralDecor,
                          (value) => setState(() => selectedFloralDecor = value),
                      expandFloralDecor,
                          () => setState(() => expandFloralDecor = !expandFloralDecor),
                    ),


                    _buildCheckboxAll(
                      "Which forms of payment do you accept?",
                      paymentMethod,
                      selectedMethod,
                    ),


                    _buildAdditionalQuestion("What is the % advance amount to confirm the booking?"),
                    _buildAdditionalQuestion("What is your cancellation policy?"),


                    _buildAdditionalQuestion("which year did you/your company professionally start services in?"),
                    _buildAdditionalQuestion("Awards, recognitions and publications"),

                    _buildRadioWithExpand(
                      "What is the price for flower based home decoration for sangeet related events?"
                          "(Typically includes decoration of: balcony, entrance & common area)?",
                      preWeddingAmount,
                      selectedPreWedAmount,
                          (value) => setState(() => selectedPreWedAmount = value),
                      expandPreWeddingAmount,
                          () => setState(() => expandPreWeddingAmount = !expandPreWeddingAmount),
                    ),
                    _buildRadioWithExpand(
                      "What is the price range for flower based traditional decoration for an inoor venue setup for 100 PAX for pre-wedding/ reception events?"
                          "(Typically includes decoration of: entrance- 8*8 ft, passage, guest area, stage area-16*12 ft)?",
                      day1Amount,
                      selectedDay1Amount,
                          (value) => setState(() => selectedDay1Amount = value),
                      expandDay1Amount,
                          () => setState(() => expandDay1Amount = !expandDay1Amount),
                    ),
                    _buildRadioWithExpand(
                      "What is the price range for flower based traditional decoration for an outdoor setup for 300 PAX for wedding events?"
                          "(Typically includes decoration of: entrance, passage, guest area, stage area, mandapa)",
                      day2Amount,
                      selectedDay2Amount,
                          (value) => setState(() => selectedDay2Amount = value),
                      expandDay2Amount,
                          () => setState(() => expandDay2Amount = !expandDay2Amount),
                    ),

                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
