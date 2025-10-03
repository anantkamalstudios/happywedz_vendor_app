import 'package:flutter/material.dart';

class VenuefaqScreen extends StatefulWidget {
  final double profileCompletion;

  const VenuefaqScreen({super.key, required this.profileCompletion});

  @override
  State<VenuefaqScreen> createState() => _VenuefaqScreenState();
}

class _VenuefaqScreenState extends State<VenuefaqScreen> {
  bool isYesSelected = false;
  bool isNoSelected = false;

  final List<String> venueOptions = [
    'Farmhouse with Indoor Banquet capability',
    'Farmhouse with only outdoor area',
    'Hotel with indoor banquets & lawn',
    'Hotel with indoor banquets',
    'Standalone Banquet hall',
    'Standalone Banquet hall with outdoor area',
    'Restaurant / Lounge for Pre wedding events',
    'Fort / Palace venue',
    'Cultural Center / Club with Banquet capability',
    '5 Star Hotel with indoor banquets & lawn',
    '5 Star Hotel with indoor banquets',
  ];

  final List<String> cancellationOptions = [
    'Partial Refund Offered',
    'No Refund Offered',
    'No Refund Offered However Date Adjustment Can Be Done',
    'Full Refund Offered',
  ];

  final List<String> cateringPolicy = [
    'Inhouse catering, Outside vendors not permitted',
    'Inhouse catering, Outside vendors alloed',
    'No Inhouse service, Outside vendors allowed from panel',
    'No inhouse services, outside vendors allowed',
  ];

  final List<String> decorPolicy = [
    'Decorators should be chosen only from enlisted Panel',
    'Outside decorators permitted',
    'In-house decor',
  ];

  final List<String> parkingAvailable = [
    'There is sufficient parking available',
    'Parking is available near the venue',
    'No parking available',
  ];

  final List<String> alcoholPolicy = [
    'In house alcohol available, Outside alcohol permitted',
    'In house alcohol available, Outside alcohol not permitted',
    'In house alcohol not available, Outside alcohol permitted',
    'In house alcohol not available, Outside alcohol not permitted',
  ];

  final List<String> DjPolicy = [
    'In house DJ available, Outside DJ permitted',
    'In house DJ available, Outside DJ not permitted',
    'In house DJ not available, Outside DJ permitted',
    'In house DJ not available, Outside DJ not permitted',
  ];

  String? selectedVenue;
  String? selectedCancellation;
  String? selectedCatering;
  String? seletcedDecor;
  String? selectedParking;
  String? selectedAlcohol;
  String? selectedDj;

  bool isOption1Selected = false;
  bool isOption2Selected = false;
  bool isOption3Selected = false;

  bool isIndoorSelected = false;
  bool isOutdoorSelected = false;
  bool isPoolsideSelected = false;
  bool isTerraceSelected = false;


  final TextEditingController bookingController = TextEditingController();
  final TextEditingController uspController = TextEditingController();
  final TextEditingController advanceBookingController = TextEditingController();

  @override
  void dispose() {
    bookingController.dispose();
    uspController.dispose();
    advanceBookingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            // Remove or set to true to show the back button
            automaticallyImplyLeading: true,
            backgroundColor: Colors.grey[200],
            pinned: true,
            expandedHeight: 60,
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "${(widget.profileCompletion * 100).toInt()}%",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Yes/No rental cost
                    const SizedBox(height: 20),
                    const Text(
                      "Does your venue have rental cost along with per plate cost?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isYesSelected = true;
                              isNoSelected = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isYesSelected ? Colors.green : Colors.white,
                            foregroundColor: isYesSelected ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                              side: const BorderSide(color: Colors.grey),
                            ),
                            fixedSize: const Size(100, 45),
                            elevation: isYesSelected ? 2 : 0,
                          ),
                          child: const Text("Yes"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isYesSelected = false;
                              isNoSelected = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isNoSelected ? Colors.green : Colors.white,
                            foregroundColor: isNoSelected ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                              side: const BorderSide(color: Colors.grey),
                            ),
                            fixedSize: const Size(100, 45),
                            elevation: isNoSelected ? 2 : 0,
                          ),
                          child: const Text("No"),
                        ),
                      ],
                    ),

                    // Primary venue dropdown
                    const SizedBox(height: 20),
                    const Text(
                      "Primary Venue Type",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedVenue,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: const Text(
                        "Please Select",
                        style: TextStyle(color: Colors.grey),
                      ),
                      items: venueOptions.map((venue) {
                        return DropdownMenuItem<String>(
                          value: venue,
                          child: Text(venue),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedVenue = value;
                        });
                      },
                      isExpanded: true,
                    ),

                    // Booking amount
                    const SizedBox(height: 14),
                    const Text(
                      "What is the booking amount (in percentage terms you take) to block a date?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bookingController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),

                    // USP
                    const SizedBox(height: 20),
                    const Text(
                      "What is your USP? (Max 230 characters)",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: uspController,
                        maxLines: 5,
                        maxLength: 230,
                        decoration: const InputDecoration(
                          hintText: "Enter your USP here",
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),

                    // Advance booking weeks
                    const SizedBox(height: 20),
                    const Text(
                      "How many weeks in advance should a booking be made?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    Container(
                      height: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: uspController,
                        maxLines: 5,
                        maxLength: 230,
                        decoration: const InputDecoration(
                          hintText: "Enter your USP here",
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),

                    // Cancellation policy dropdown
                    const SizedBox(height: 20),
                    const Text(
                      "Please describe your cancellation policy (if a user initiates a cancellation including whether you provide refunds of booking amounts and terms for doing so.)",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCancellation,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: const Text(
                        "Please Select",
                        style: TextStyle(color: Colors.grey),
                      ),
                      items: cancellationOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCancellation = value;
                        });
                      },
                      isExpanded: true,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Please describe your cancellation policy (if a user initiates a cancellation including whether you provide refunds of booking amounts and terms for doing so.)",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCancellation,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: const Text(
                        "Please Select",
                        style: TextStyle(color: Colors.grey),
                      ),
                      items: cancellationOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCancellation = value;
                        });
                      },
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      "What are the terms & conditions of your cancellation policy? (please describe in detail -eg No refunds within a month of the wedding day or 50% amount refundable)",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    Container(
                      height: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: uspController,
                        maxLines: 5,
                        maxLength: 230,
                        decoration: const InputDecoration(
                          hintText: "",
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      "How many rooms are included in your destination Price(per Night)/ (default is 100)",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: uspController,
                        maxLines: 3,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          hintText: "",
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "What would be the one line bio for your venue",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    Container(
                      height: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: uspController,
                        maxLines: 5,
                        maxLength: 230,
                        decoration: const InputDecoration(
                          hintText: "",
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      "Do you need a minimum guarantee of Room booking for hosting a wedding?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),

                    Column(
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Checkbox(
                                  value: isOption1Selected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      isOption1Selected = value ?? false;
                                    });
                                  },
                                ),
                                title: const Text(
                                  "Yes, set a number of rooms should be booked to host a wedding",
                                ),
                              ),

                              // Conditional green box inside the same card
                              if (isOption1Selected)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green, // Green background
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "What is the minimum number of Room bookings required to host weddings?",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black, // White text
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 80,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white, // White input area
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: TextField(
                                          maxLines: 4,
                                          decoration: const InputDecoration(
                                            hintText: "Enter number of rooms...",
                                            border: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: isOption2Selected,
                              onChanged: (bool? value) {
                                setState(() {
                                  isOption2Selected = value ?? false;
                                });
                              },
                            ),
                            title: const Text("No, can host a wedding without room booking"),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: isOption3Selected,
                              onChanged: (bool? value) {
                                setState(() {
                                  isOption3Selected = value ?? false;
                                });
                              },
                            ),
                            title: const Text("Complete buyout of the room is mandatory"),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "What is the strating price for vegetarian menu? (assume 250 pax and standard menu)",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: uspController,
                        maxLines: 3,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          hintText: "",
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "How many rooms are available in your accomodation?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: uspController,
                        maxLines: 3,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          hintText: "",
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "What is your policy on catering?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCatering,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: const Text(
                        "Please Select",
                        style: TextStyle(color: Colors.grey),
                      ),
                      items: cateringPolicy.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCatering = value;
                        });
                      },
                      isExpanded: true,
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "What is the starting price for a non-veg menu? (assume 250 pax and standard menu)",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: uspController,
                        maxLines: 3,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          hintText: "",
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      "What is your policy on decor?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: seletcedDecor,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: const Text(
                        "Please Select",
                        style: TextStyle(color: Colors.grey),
                      ),
                      items: decorPolicy.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          seletcedDecor = value;
                        });
                      },
                      isExpanded: true,
                    ),

                    const SizedBox(height: 20),


                    const Text(
                      "What Spaces are available to host wedding events?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    Column(
                      children: [
                        // Indoor
                        Card(
                          color: isIndoorSelected ? Colors.green : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: isIndoorSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  isIndoorSelected = value ?? false;
                                });
                              },
                              activeColor: Colors.white,
                              checkColor: Colors.green,
                            ),
                            title: Text(
                              "Indoor",
                              style: TextStyle(
                                color: isIndoorSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),

                        // Outdoor
                        Card(
                          color: isOutdoorSelected ? Colors.green : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: isOutdoorSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  isOutdoorSelected = value ?? false;
                                });
                              },
                              activeColor: Colors.white,
                              checkColor: Colors.green,
                            ),
                            title: Text(
                              "Outdoor",
                              style: TextStyle(
                                color: isOutdoorSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),

                        // Poolside
                        Card(
                          color: isPoolsideSelected ? Colors.green : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: isPoolsideSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  isPoolsideSelected = value ?? false;
                                });
                              },
                              activeColor: Colors.white,
                              checkColor: Colors.green,
                            ),
                            title: Text(
                              "Poolside",
                              style: TextStyle(
                                color: isPoolsideSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),

                        // Terrace
                        Card(
                          color: isTerraceSelected ? Colors.green : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: isTerraceSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  isTerraceSelected = value ?? false;
                                });
                              },
                              activeColor: Colors.white,
                              checkColor: Colors.green,
                            ),
                            title: Text(
                              "Terrace/ Rooftop",
                              style: TextStyle(
                                color: isTerraceSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),

                        const Text(
                          "What is the starting price for a basic room at your hotel?",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 80,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: TextField(
                            controller: uspController,
                            maxLines: 3,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              hintText: "",
                              border: InputBorder.none,
                              counterText: "",
                            ),
                          ),


                        ),

                        const SizedBox(height: 16),
                        const Text(
                          "Do you also allow small size gatherings (>50)?",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isYesSelected = true;
                                    isNoSelected = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isYesSelected ? Colors.green : Colors.white,
                                  foregroundColor: isYesSelected ? Colors.white : Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(color: Colors.grey),
                                  ),
                                ),
                                child: const Text(
                                  "Yes",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isYesSelected = false;
                                    isNoSelected = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isNoSelected ? Colors.green : Colors.white,
                                  foregroundColor: isNoSelected ? Colors.white : Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(color: Colors.grey),
                                  ),
                                ),
                                child: const Text(
                                  "No",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                    ),
                    const Text(
                      "Please select whatever is applicable for your venue",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: uspController,
                        maxLines: 3,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          hintText: "",
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),
                    const Text(
                      "What year did your venuw start operations?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: uspController,
                        maxLines: 3,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          hintText: "",
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),

                    const Text(
                      "Is parking available at the venue?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedParking,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: const Text(
                        "Please Select",
                        style: TextStyle(color: Colors.grey),
                      ),
                      items: parkingAvailable.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedParking = value;
                        });
                      },
                      isExpanded: true,
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "What is your policy on alcohol?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedAlcohol,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: const Text(
                        "Please Select",
                        style: TextStyle(color: Colors.grey),
                      ),
                      items: alcoholPolicy.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),

                      onChanged: (value) {
                        setState(() {
                          selectedAlcohol = value;
                        });
                      },
                      isExpanded: true,
                    ),

                    const Text(
                      "What is the minimum starting price to decorate your venue?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bookingController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "What is your policy on DJ's?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDj,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: const Text(
                        "Please Select",
                        style: TextStyle(color: Colors.grey),
                      ),
                      items: DjPolicy.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),

                      onChanged: (value) {
                        setState(() {
                          selectedDj = value;
                        });
                      },
                      isExpanded: true,
                    ),

                    const SizedBox(height: 24), // spacing from previous content
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: handle save action
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[100], // faint green
                          foregroundColor: Colors.green[800], // text color
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0, // flat appearance
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), // optional spacing at bottom
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
