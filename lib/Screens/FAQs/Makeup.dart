import 'package:flutter/material.dart';

class MakeupFaqScreen extends StatefulWidget {


  const MakeupFaqScreen({super.key});

  @override
  State<MakeupFaqScreen> createState() => _MakeupFaqScreenState();
}

class _MakeupFaqScreenState extends State<MakeupFaqScreen> {
  final TextEditingController priceController = TextEditingController();

  double completionPercentage = 0.0;


  final List<String> makeupOffer = [
    "Bridal Makeup",
    "Airbrush Makeup",
    "Party Makeup(for Family)",
    "Engagement makeup",
    "Extensions"
  ];

  final List<String>  styles = [
    "Hair Styling",
    "Draping",
    "Nail Polish Change",
    "Makeup",
    "Extensions",
    "False Lashes"
  ];

  double outdoorBudget = 0;
  String? radioOption;

  Map<String, bool> selectedMethod = {};
  Map<String, bool> selectedStyle = {};

  String? travelOutsideOption;
  String? selectedTrainer;


  final TextEditingController additionalNoteController = TextEditingController();


  @override
  void initState() {
    super.initState();
    for( var makeupOffer in makeupOffer) {
      selectedMethod[makeupOffer] = false;
    }
    for( var styles in styles) {
      selectedStyle[styles] = false;
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

  // state variable for dropdown

  Widget _buildQuestionWithDropdown(String question, List<String> options) {
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
            DropdownButtonFormField<String>(
              value: selectedTrainer,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              hint: const Text("Please select"),
              items: options.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(opt),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedTrainer = val;
                });
              },
            ),
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

  Widget _buildTravelOutsideQuestion() {
    final options = ["Yes", "No"];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            "Do you travel to the venue",
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
            expandedHeight: 80,flexibleSpace: FlexibleSpaceBar(
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
                    _buildCheckboxAll(
                      "Which of the following do you offer",
                      makeupOffer,
                      selectedMethod,
                    ),
                    _buildAdditionalQuestion("If you travel outside of your hometown for bridal makeup, how much do you charge for one event?"),
                    _buildAdditionalQuestion("Which products do you see for bridal makeup?"),
                    _buildAdditionalQuestion("Have you recieved any awards you would like to mention?"),
                    _buildAdditionalQuestion("What year did you work on your first client professionally? (please mention the year you got your first paid client and not since you have been pracising on yourself"),
                    _buildQuestionWithDropdown(
                      "Describe your Business",
                      [ "Freelance Artist", "Bridal Makeup Studio", "Salon Chain"],
                    ),
                    _buildAdditionalQuestion("What are the terms & conditions of your cancellation policy? (please describe in detail- "
                        "No refunds within a month of the wedding day or 50% amount refundable"),

                    _buildAdditionalQuestion("What Percentage of Booking Advance should be paid"),
                    _buildAdditionalQuestion("Have you been trained under someone \n Please name them"),
                    _buildAdditionalQuestion("Describe your signature makeup look in 3 words (example: Glamorous, Minimal, Smokey eyes, natural, fresh, dewy, elegant, minimal,"
                        "classy, versatile,Ethnic, smkey eyes etc etc. Please DONT write Natural Bridal look or Bridal Loor or classy"),
                    _buildAdditionalQuestion("I choose to be a MUA because"),
                    _buildAdditionalQuestion("How many weeks in advanc should a booking be made?"),
                    _buildAdditionalQuestion("What is the price of bridal makeup from a senior artist your team(Pls ignore if you dont have  a team"),
                    _buildAdditionalQuestion("What is the price of bridal makeup from the junior artist in your team(Pls ignore if you dont have a team"),

                    _buildTravelOutsideQuestion(),

                    _buildCheckboxAll(
                      "Which forms of payment do you accept?",
                      styles,
                      selectedStyle,
                    ),
                    _buildQuestionWithDropdown(
                      "What is your policy on trails?",
                      [ "Offer free trail","Offer paid trial","Offer paid triaal - Money adjusted if booked", "Trial not Available"],
                    ),


                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
