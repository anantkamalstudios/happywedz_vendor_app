import 'package:flutter/material.dart';

class CaterarFaqScreen extends StatefulWidget {


  const CaterarFaqScreen({super.key});

  @override
  State<CaterarFaqScreen> createState() => _CaterarFaqScreenState();
}


final TextEditingController minGuestController = TextEditingController();
final TextEditingController maxGuestController = TextEditingController();


class _CaterarFaqScreenState extends State<CaterarFaqScreen> {
  final TextEditingController priceController = TextEditingController();
  double completionPercentage = 0.0;

  final List<String> eventsCovid = [
    "Information not available",
    "Not operational",
    "Yes, with special deals",
    "Yes"
  ];

  final List<String> menuOptions =[
    "North indian/ mughlai",
    "Italian/ european/ continental",
    "Chinese/ thai/ oriental",
    "South indian",
    "Garlic Free/ Onion Free",
    "Live food counters",
    "Chaat & indian street food",
    "Seafood",
    "Drinks(non-alcoholic)"
  ];



  final List<String> paymentMethod = [
    "Net banking",
    "Cash",
    "Cheque/DD",
    "Debit/Credit cards",
    "Mobile wallets",
    "UPI"
  ];

  final List<String> vegMenu = [
    "Under ₹500",
    "₹500 - ₹799",
    "₹800 - ₹1199",
    "₹1200 - ₹1499",
    "₹1500 - ₹1799",
    "₹1800 - ₹1999",
    "₹2000 - ₹2499",
    "₹2500 - ₹2999",
    "₹3000 and more",
  ];

  final List<String> nonVegMenu = [
    "Under ₹500",
    "v500 - ₹799",
    "₹800 - ₹1199",
    "₹1200 - ₹1499",
    "₹1500 - ₹1799",
    "₹1800 - ₹1999",
    "₹2000 - ₹2499",
    "₹2500 - ₹2999",
    "₹3000 and more",
  ];

  Map<String, bool> selectedMenuoption = {};
  String? selectedVegMenu;
  String? selectedNonVegMenu;


  bool expandMenuOption = false;
  bool expandVegMenu = false;
  bool expandNonVegMenu = false;



  double outdoorBudget = 0;
  String? radioOption;




  Map<String, bool> selectedMethod = {};


  final TextEditingController additionalNoteController = TextEditingController();


  @override
  void initState() {
    super.initState();
    for( var paymentMethod in paymentMethod) {
      selectedMethod[paymentMethod] = false;
    }
    for (var menu in menuOptions) {
      selectedMenuoption[menu] = false;
    }
  }

  @override
  void dispose() {
    priceController.dispose();
    super.dispose();
  }

  Widget _buildMinMaxGuestQuestion(String question) {
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Minimum number of guests",
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: minGuestController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Maximum number of guests",
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: maxGuestController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                      "What is the starting price for 1 event of your DJ only services?",
                      priceController,
                    ),

                    _buildMinMaxGuestQuestion(
                      "How many guests can you accommodate in your event space?",
                    ),

                    _buildQuestionWithSlider(
                        "What is the starting price for 1 event of your DJ services with setup? (Typically includes: sound, light & dance floor set up"),
                    _buildQuestionWithRadio("Are you ready to host/provide service to events during COVID19, following the government guidelines?", eventsCovid),
                    _buildCheckboxWithExpand(
                      "Which musical genres do you specialise in?",
                      menuOptions,
                      selectedMenuoption,
                      expandMenuOption,
                          () => setState(() => expandMenuOption = !expandMenuOption),
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
                      "What is the starting price range of your photobooth installation for one event?",
                      vegMenu,
                      selectedVegMenu,
                          (value) => setState(() => selectedVegMenu = value),
                      expandVegMenu,
                          () => setState(() => expandVegMenu = !expandVegMenu),
                    ),
                    _buildRadioWithExpand(
                      "What is the starting price range of your photobooth installation for one event?",
                      nonVegMenu,
                      selectedNonVegMenu,
                          (value) => setState(() => selectedNonVegMenu = value),
                      expandNonVegMenu,
                          () => setState(() => expandNonVegMenu = !expandNonVegMenu),
                    ),
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
