import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';
import 'package:shimmer/shimmer.dart';

// ======================= SERVICE =======================
class AnalyticsService {
  static const String _url =
      "https://happywedz.com/api/vendor/dashboard/analytics";

  static Future<Map<String, dynamic>> fetchAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      throw Exception("Auth token not found");
    }

    final response = await http.get(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Analytics API failed");
    }
  }
}

// ======================= COLORS (WEB MATCH) =======================
String normalizeCollection(String name) {
  return name.trim().toLowerCase();
}
final List<Color> fallbackPalette = [
  Color(0xFF845EC2),
  Color(0xFF4D96FF),
  Color(0xFFFF6F91),
  Color(0xFF2C73D2),
  Color(0xFF008F7A),
  Color(0xFFFF9671),
  Color(0xFF00C9A7),
];

// Media by Collection
const Map<String, Color> baseCollectionColors  = {
  'Haldi': Color(0xFF36A2EB),
  'Engagement': Color(0xFFFF6384),
  'test': Color(0xFFFFCE56),
  'wedding': Color(0xFF4BC0C0),
};

Color getCollectionColor(String rawLabel) {
  final key = normalizeCollection(rawLabel);

  // 1️⃣ predefined color
  if (baseCollectionColors.containsKey(key)) {
    return baseCollectionColors[key]!;
  }

  // 2️⃣ auto color (same name = same color)
  return fallbackPalette[key.hashCode % fallbackPalette.length];
}
// Media Visibility
const Map<String, Color> visibilityColors = {
  'private': Color(0xFF4BC0C0),
  'public': Color(0xFFFF6384),
};

// Tokens by Type
const Map<String, Color> tokenColors = {
  'private': Color(0xFF36A2EB),
  'public': Color(0xFFFFCE56)
};

// ======================= SCREEN =======================

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<Map<String, dynamic>> analyticsFuture;

  // 🔥 Separate selection state per chart
  final Map<String, int?> touchedIndexMap = {
    'collection': null,
    'visibility': null,
    'token': null,
  };

  @override
  void initState() {
    super.initState();
    analyticsFuture = AnalyticsService.fetchAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CommonAppBar(title: 'Analytics'),
      body: FutureBuilder<Map<String, dynamic>>(
        future: analyticsFuture,
        builder: (context, snapshot) {
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return const Center(child: CircularProgressIndicator());
          // }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AnalyticsShimmer();
          }


          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data!;
          final package = data['package'];
          final media = data['media'];
          final tokens = data['tokens'];
          final activity = data['activity'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _storageCard(package),
                const SizedBox(height: 16),
                _statsRow(media, tokens),
                const SizedBox(height: 20),

                _chartCard(
                  title: "Media by Collection",
                  chart: media['byCollection'].isEmpty
                      ? _emptyChart("No media uploaded")
                      : _donutChartWithLegend(
                    list: media['byCollection'],
                    labelKey: 'collection',
                    chartKey: 'collection',
                      useDynamicCollectionColors: true,
                      //  colorMap: collectionColors,
                    colorMap: baseCollectionColors
                  ),
                ),

                _chartCard(
                  title: "Media Visibility",
                  chart: (media['visibility'] == null || media['visibility'].isEmpty)
                      ? _emptyChart("No visibility data available")
                      : _donutChartWithLegend(
                    list: media['visibility'],
                    labelKey: 'visibility',
                    chartKey: 'visibility',
                    useDynamicCollectionColors: false,
                    colorMap: visibilityColors,
                  ),
                ),

                _chartCard(
                  title: "Tokens by Type",
                  chart: (tokens['byType'] == null || tokens['byType'].isEmpty)
                      ? _emptyChart("No tokens created yet")
                      : _donutChartWithLegend(
                    list: tokens['byType'],
                    labelKey: 'type',
                    chartKey: 'token',
                    useDynamicCollectionColors: false,
                    colorMap: tokenColors,
                  ),
                ),


                const SizedBox(height: 20),
                _recentActivity(activity),
              ],
            ),
          );
        },
      ),
    );
  }

  // ======================= STORAGE =======================

  Widget _storageCard(dynamic package) {
    final double used = package['usedMB'].toDouble();
    final double limit = package['limitMB'].toDouble();
    final double progress = limit == 0 ? 0 : used / limit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Storage Usage (${package['name']})",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          LinearProgressIndicator(
            // value: used / limit,
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor:
            const AlwaysStoppedAnimation(Color(0xFF00509D)),
          ),
          const SizedBox(height: 8),
          Text(
            "${used.toStringAsFixed(2)} MB of ${(limit / 1024).toStringAsFixed(0)} GB used",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ======================= STATS =======================

  Widget _statsRow(dynamic media, dynamic tokens) {
    return Row(
      children: [
        _statCard("Media", media['total'].toString(), Icons.photo_library),
        const SizedBox(width: 12),
        _statCard(
          "Tokens",
          "${tokens['active']} / ${tokens['total']}",
          Icons.vpn_key,
        ),
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
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ======================= CHART CARD =======================
  Widget _emptyChart(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 42, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _chartCard({required String title, required Widget chart}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          chart,
          //SizedBox(height: 240, child: chart),
        ],
      ),
    );
  }

  // ======================= DONUT + CENTER TEXT + LEGEND =======================

  Widget _donutChartWithLegend({
    required List list,
    required String labelKey,
    required String chartKey,
    required bool useDynamicCollectionColors,
    required Map<String, Color> colorMap,
  }) {
    final int? rawIndex = touchedIndexMap[chartKey];
    final int? selectedIndex =
    (rawIndex != null && rawIndex >= 0 && rawIndex < list.length)
        ? rawIndex
        : null;

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 60,
                  sectionsSpace: 3,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (response == null ||
                            response.touchedSection == null) {
                          touchedIndexMap[chartKey] = null;
                        } else {
                          touchedIndexMap[chartKey] =
                              response.touchedSection!.touchedSectionIndex;
                        }
                      });
                    },
                  ),
                  sections: List.generate(list.length, (i) {
                    final value =
                    double.parse(list[i]['count'].toString());
                    final label = list[i][labelKey];
                    final isSelected = i == selectedIndex;

                    return PieChartSectionData(
                      value: value,
                      radius: isSelected ? 48 : 40,
                      // color: colorMap[label] ?? Colors.grey,
                      //color: getCollectionColor(label),
                      color: useDynamicCollectionColors
                          ? getCollectionColor(label)
                          : (colorMap[label] ?? Colors.grey),

                      title: '',
                    );
                  }),
                ),
              ),

              // 🔥 CENTER TEXT (Professional & Safe)
              if (selectedIndex != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      list[selectedIndex][labelKey],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      list[selectedIndex]['count'].toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Wrap(
          spacing: 14,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(list.length, (i) {
            final label = list[i][labelKey];
            final isSelected = i == selectedIndex;

            return GestureDetector(
              onTap: () {
                setState(() {
                  touchedIndexMap[chartKey] = i;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      // color: colorMap[label],
                      //color: getCollectionColor(label),
                      color: useDynamicCollectionColors
                          ? getCollectionColor(label)
                          : colorMap[label],


                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ======================= ACTIVITY =======================
  Widget _recentActivity(dynamic activity) {
    final lastUpload = activity['lastUploadAt'];
    final lastToken = activity['lastTokenCreatedAt'];

    // 🔥 EMPTY STATE
    if (lastUpload == null && lastToken == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Icon(Icons.history, size: 42, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              "No recent activity",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Uploads and token activity will appear here",
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // ✅ NORMAL STATE
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Activity",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          if (lastUpload != null)
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text("Last Upload"),
              subtitle: Text(lastUpload.toString()),
            ),

          if (lastToken != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text("Token Created"),
              subtitle: Text(lastToken.toString()),
            ),
          ],
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


class AnalyticsShimmer extends StatelessWidget {
  const AnalyticsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(height: 90), // Storage
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _card(height: 90)),
                const SizedBox(width: 12),
                Expanded(child: _card(height: 90)),
                const SizedBox(width: 12),
                Expanded(child: _card(height: 90)),
              ],
            ),

            const SizedBox(height: 20),

            _card(height: 260), // Collection chart
            _card(height: 260), // Visibility chart
            _card(height: 260), // Token chart

            const SizedBox(height: 20),

            _activityShimmer(),
            _activityShimmer(),
          ],
        ),
      ),
    );
  }

  Widget _card({double height = 120}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _activityShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 120, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 180, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
