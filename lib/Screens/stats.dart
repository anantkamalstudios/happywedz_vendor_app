import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String selectedRange = "Weekly";

  final List<String> ranges = ["Daily", "Weekly", "Monthly"];

  final List<int> sampleData = [5, 8, 6, 10, 7, 12, 9];
  final List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stats"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("Leads"),
            const SizedBox(height: 12),
            _rangeChips(),
            const SizedBox(height: 12),
            _buildBarChart(),
            const SizedBox(height: 16),
            _monthStats(highest: "15", avg: "8", your: "12"),

            const SizedBox(height: 24),
            _sectionHeader("Profile Views"),
            const SizedBox(height: 12),
            _rangeChips(),
            const SizedBox(height: 12),
            _buildBarChart(),
            const SizedBox(height: 16),
            _monthStats(highest: "30", avg: "18", your: "20"),

            const SizedBox(height: 24),
            _sectionHeader("Collection Clicks"),
            const SizedBox(height: 12),
            _rangeChips(),
            const SizedBox(height: 12),
            _buildBarChart(),
            const SizedBox(height: 16),
            _monthStats(highest: "25", avg: "10", your: "18"),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _rangeChips() {
    return Row(
      children: ranges.map((range) {
        bool isSelected = selectedRange == range;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(range),
            selected: isSelected,
            selectedColor: Colors.pinkAccent,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
            onSelected: (_) {
              setState(() {
                selectedRange = range;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChart() {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 15,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < days.length) {
                    return Text(days[index],
                        style: const TextStyle(fontSize: 10));
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28),
            ),
            rightTitles:
            AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(sampleData.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: sampleData[i].toDouble(),
                  color: Colors.pinkAccent,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _monthStats({required String highest, required String avg, required String your}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statBox("Highest Leads", highest),
        _statBox("Avg Leads", avg),
        _statBox("Your Leads", your),
      ],
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.pinkAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
