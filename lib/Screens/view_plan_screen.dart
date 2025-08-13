import 'package:flutter/material.dart';

class ViewPlansScreen extends StatelessWidget {
  const ViewPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[300],
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text("Membership Plans"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPlanCard(
              planName: "Basic Plan",
              price: "₹1,999 / 3 months",
              features: [
                "Appear in vendor search results",
                "Access to 50 monthly leads",
                "Basic analytics dashboard",
              ],
              buttonColor: Colors.pinkAccent,
            ),
            _buildPlanCard(
              planName: "Standard Plan",
              price: "₹4,999 / 6 months",
              features: [
                "Higher search ranking",
                "Access to 150 monthly leads",
                "Full analytics dashboard",
                "Priority customer support",
              ],
              buttonColor: Colors.pinkAccent,
            ),
            _buildPlanCard(
              planName: "Premium Plan",
              price: "₹8,999 / 12 months",
              features: [
                "Top search listing",
                "Unlimited leads",
                "Advanced analytics",
                "Dedicated account manager",
                "Featured vendor badge",
              ],
              highlight: true,
              buttonColor: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              "All prices are inclusive of taxes. Terms & conditions apply.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String planName,
    required String price,
    required List<String> features,
    bool highlight = false,
    required Color buttonColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? Colors.yellow[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: highlight ? Border.all(color: Colors.orange, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlight)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Most Popular",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          Text(planName,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(price,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.pinkAccent)),
          const Divider(height: 20),
          ...features.map((f) => Row(
            children: [
              const Icon(Icons.check_circle,
                  color: Colors.green, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(f)),
            ],
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: () {},
              child: const Text("Subscribe Now"),
            ),
          ),
        ],
      ),
    );
  }
}
