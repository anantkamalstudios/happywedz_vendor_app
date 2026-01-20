import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CommonAppBar(title: 'Analytics'),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _storageCard(),
            const SizedBox(height: 16),
            _statsRow(),
            const SizedBox(height: 20),
            _chartCard(
              title: "Media by Collection",
              chart: _donutChart([
                PieChartSectionData(
                    value: 40, color: Colors.blue),
                PieChartSectionData(
                    value: 30, color: Colors.pink),
                PieChartSectionData(
                    value: 20, color: Colors.teal),
                PieChartSectionData(
                    value: 10, color: Colors.amber),
              ]),
            ),
            _chartCard(
              title: "Media Visibility",
              chart: _donutChart([
                PieChartSectionData(
                    value: 65, color: Colors.pink),
                PieChartSectionData(
                    value: 35, color: Colors.teal),
              ]),
            ),
            _chartCard(
              title: "Tokens by Type",
              chart: _donutChart([
                PieChartSectionData(
                    value: 70, color: Colors.amber),
                PieChartSectionData(
                    value: 30, color: Colors.blue),
              ]),
            ),
            const SizedBox(height: 20),
            _recentActivity(),
          ],
        ),
      ),
    );
  }

  // 🔹 STORAGE CARD
  Widget _storageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Storage Usage (Premium)",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: 0.03,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor:
            const AlwaysStoppedAnimation(Color(0xFF00509D)),
          ),
          const SizedBox(height: 8),
          const Text(
            "32.49 MB of 10 GB used",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 🔹 STATS ROW
  Widget _statsRow() {
    return Row(
      children: [
        _statCard("Media", "22", Icons.photo_library),
        const SizedBox(width: 12),
        _statCard("Tokens", "6 / 7", Icons.vpn_key),
        const SizedBox(width: 12),
        _statCard("Views", "0", Icons.remove_red_eye),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00509D)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 CHART CARD
  Widget _chartCard({required String title, required Widget chart}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
            const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 180, child: chart),
        ],
      ),
    );
  }

  // 🔹 DONUT CHART
  Widget _donutChart(List<PieChartSectionData> sections) {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 45,
        sections: sections.map((e) {
          return e.copyWith(
            radius: 40,
            title: '',
          );
        }).toList(),
      ),
    );
  }

  // 🔹 RECENT ACTIVITY
  Widget _recentActivity() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Recent Activity",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.cloud_upload),
            title: Text("Last Upload"),
            subtitle: Text("19/01/2026 • 11:49 AM"),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.vpn_key),
            title: Text("Token Created"),
            subtitle: Text("19/01/2026 • 01:27 PM"),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
