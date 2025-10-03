import 'package:flutter/material.dart';

class InviteAndGiftFaqScreen extends StatefulWidget {
  final double profileCompletion;

  const InviteAndGiftFaqScreen({super.key, required this.profileCompletion});

  @override
  State<InviteAndGiftFaqScreen> createState() => _InviteAndGiftFaqScreenState();
}

class _InviteAndGiftFaqScreenState extends State<InviteAndGiftFaqScreen> {
  final TextEditingController priceController = TextEditingController();

  final List<String> eventsCovid = [
    "Information not available",
    "Not operational",
    "Yes, with special deals",
    "Yes"
  ];

  final List<String> invitationConcepts = [
    "Cards",
    "Boxed gifting",
    "Novel concepts",
  ];

  final List<String> invitePapers = [
    "Matte",
    "Glossy",
    "Handmade",
    "Mylar",
    "Recycled",
    "Parchment"
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
    " ₹0-₹49",
    "₹50 - ₹74",
    "₹75 - ₹99",
    "₹100 - ₹149",
    "₹150 - ₹199",
    "₹200 and more",
  ];

  final List<String> day1Amount = [
    "₹0- ₹99",
    "₹100 - ₹199",
    "₹200 - ₹299",
    "₹300 - ₹499",
    "₹500 - ₹799",
    "₹800 and more"
  ];

  final List<String> day2Amount = [
    "0 - 24"
        "25 - 49",
    "50 - 74",
    "75 - 99",
    "100 - 124",
    "125 and more"
  ];

  final List<String> day3Amount = [
    "0 - 24",
    "25 - 49",
    "50 - 74",
    "75 - 99",
    "100 - 124",
    "125 and more"
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
    for (var invitationConcepts in invitationConcepts) {
      selectedConcept[invitationConcepts] = false;
    }
    for( var invitePapers in invitePapers){
      selectedPaper[invitePapers] = false;
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
                      "What is the starting price per invite for wedding cards?",
                      priceController,
                    ),

                    _buildQuestionWithRadio("Are you ready to host/provide service to events during COVID19, following the government guidelines?", eventsCovid),
                    _buildQuestionWithSlider(
                        "What is the starting price per box packaged (boxed) invitations?"),
                    _buildQuestionWithSlider(
                        "What is the minimum order quantity for printed cards?"),
                    _buildQuestionWithSlider(
                        "What is the minimum order quantity for boxed invites?"),

                    _buildCheckboxAll(
                      "What kind of invitation concepts do you provide",
                      invitationConcepts,
                      selectedConcept,

                    ),
                    _buildCheckboxAll(
                      "What types of papers do you use for print invites?",
                      invitePapers,
                      selectedPaper,

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
                      "What is the starting price range per invite for wedding cards?",
                      preWeddingAmount,
                      selectedPreWedAmount,
                          (value) => setState(() => selectedPreWedAmount = value),
                      expandPreWeddingAmount,
                          () => setState(() => expandPreWeddingAmount = !expandPreWeddingAmount),
                    ),
                    _buildRadioWithExpand(
                      "What is the starting price range per invite for packaged (boxed) invitation only?",
                      day1Amount,
                      selectedDay1Amount,
                          (value) => setState(() => selectedDay1Amount = value),
                      expandDay1Amount,
                          () => setState(() => expandDay1Amount = !expandDay1Amount),
                    ),
                    _buildRadioWithExpand(
                      "What is the minimum order quantity range for printed cards?",
                      day2Amount,
                      selectedDay2Amount,
                          (value) => setState(() => selectedDay2Amount = value),
                      expandDay2Amount,
                          () => setState(() => expandDay2Amount = !expandDay2Amount),
                    ),
                    _buildRadioWithExpand(
                      "What is the minimum order quantity range for packaged (boxed) invitations?",
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
