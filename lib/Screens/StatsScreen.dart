// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';
// import 'new_screens/leads_list_stats.dart';
//
// class StatsPage extends StatefulWidget {
//   const StatsPage({Key? key}) : super(key: key);
//
//   @override
//   State<StatsPage> createState() => _StatsPageState();
// }
//
// class _StatsPageState extends State<StatsPage>
//     with SingleTickerProviderStateMixin {
//   // ---------- Leads ----------
//   String selectedLeadPeriod = "This Week";
//   bool isLoading = true;
//   List<dynamic> apiRequests = [];
//   String? token;
//   DateTime? customStartDate;
//   DateTime? customEndDate;
//   DateTime? impressionStartDate;
//   DateTime? impressionEndDate;
//   int? vendorId;
//   int visibleLeadCount = 0;
//   int visibleImpressionCount = 0;
//
//   final List<String> leadRanges = [
//     "This Week",
//     "This Month",
//     "Last Month",
//     "Custom Range",
//   ];
//
//   List<String> dailyLabels = [];
//   List<double> dailyValues = [];
//
//
//   // ---------- Profile Views ----------
//   String selectedProfileViewPeriod = "This Week";
//
//   final List<String> profileViewRanges = [
//     "This Week",
//     "This Month",
//     "Last Month",
//     "Custom Range",
//   ];
//
//   DateTime? profileViewStartDate;
//   DateTime? profileViewEndDate;
//
//   List<String> profileViewLabels = [];
//   List<double> profileViewValues = [];
//
//   int visibleProfileViewCount = 0;
//
//   // ---------- Impressions ----------
//   String selectedImpressionPeriod = "This Week";
//   final List<String> impressionRanges = [
//     "This Week",
//     "This Month",
//     "Last Month",
//     "Custom Range",
//   ];
//
//   List<String> impressionDailyLabels = [];
//   List<double> impressionDailyValues = [];
//
//   // ---------- Profile Views ----------
//   int profileViewsTotal = 0; // Lifetime total from API
//   List<dynamic> impressionList = []; // Renamed: this is actually wishlist adds (impressions)
//
//   // animations
//   late AnimationController _controller;
//   late Animation<double> _fadeAnim;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
//     _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
//
//     fetchDashboardData();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   int? _resolveVendorIdFromPrefsOrToken(SharedPreferences prefs, String? token) {
//     final int? vid = prefs.getInt("vendor_id");
//     if (vid != null) return vid;
//     if (token == null) return null;
//     try {
//       final parts = token.split('.');
//       if (parts.length < 2) return null;
//       String payload = parts[1];
//       String normalized = base64Url.normalize(payload);
//       final Uint8List decoded = base64Url.decode(normalized);
//       final Map<String, dynamic> map = jsonDecode(utf8.decode(decoded));
//       if (map.containsKey('id')) return (map['id'] as num).toInt();
//       if (map.containsKey('vendorId')) return (map['vendorId'] as num).toInt();
//       if (map.containsKey('vendor_id')) return (map['vendor_id'] as num).toInt();
//     } catch (e) {
//       print("Warning: Error decoding token: $e");
//     }
//     return null;
//   }
//
//   // Leads Custom Range
//   Future<void> _openCustomRangePickerForLeads() async {
//     final DateTime now = DateTime.now();
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(now.year - 1),
//       lastDate: now,
//       initialDateRange: DateTimeRange(
//         start: customStartDate ?? now.subtract(const Duration(days: 7)),
//         end: customEndDate ?? now,
//       ),
//     );
//     if (picked == null) return;
//     customStartDate = picked.start;
//     customEndDate = picked.end;
//     _generateCustomRangeLeads(picked.start, picked.end);
//     setState(() => selectedLeadPeriod = "Custom Range");
//     _controller.forward(from: 0);
//   }
//
//   void _generateCustomRangeLeads(DateTime start, DateTime end) {
//     dailyLabels.clear();
//     dailyValues.clear();
//     int total = 0;
//     DateTime current = DateTime(start.year, start.month, start.day);
//     while (!current.isAfter(end)) {
//       String label = DateFormat("dd MMM").format(current);
//       int count = apiRequests.where((req) {
//         DateTime d = DateTime.parse(req["createdAt"]);
//         return d.year == current.year && d.month == current.month && d.day == current.day;
//       }).length;
//       total += count;
//       dailyLabels.add(label);
//       dailyValues.add(count.toDouble());
//       current = current.add(const Duration(days: 1));
//     }
//     visibleLeadCount = total;
//   }
//
//   void _regenerateLeadsChart(String period) {
//     dailyLabels.clear();
//     dailyValues.clear();
//     DateTime now = DateTime.now();
//     DateTime start;
//     DateTime end;
//
//     if (period == "This Week") {
//       start = now.subtract(Duration(days: now.weekday - 1));
//       end = start.add(const Duration(days: 6));
//     } else if (period == "This Month") {
//       start = DateTime(now.year, now.month, 1);
//       end = DateTime(now.year, now.month + 1, 0);
//     } else if (period == "Last Month") {
//       if (now.month == 1) {
//         start = DateTime(now.year - 1, 12, 1);
//         end = DateTime(now.year - 1, 12, 31);
//       } else {
//         start = DateTime(now.year, now.month - 1, 1);
//         end = DateTime(now.year, now.month, 0);
//       }
//     } else {
//       return;
//     }
//
//     DateTime current = DateTime(start.year, start.month, start.day);
//     int total = 0;
//     while (!current.isAfter(end)) {
//       String label = (period == "This Week")
//           ? DateFormat("EEE").format(current)
//           : DateFormat("dd MMM").format(current);
//
//       int count = apiRequests.where((req) {
//         DateTime d = DateTime.parse(req["createdAt"]);
//         return d.year == current.year && d.month == current.month && d.day == current.day;
//       }).length;
//
//       total += count;
//       dailyLabels.add(label);
//       dailyValues.add(count.toDouble());
//       current = current.add(const Duration(days: 1));
//     }
//     visibleLeadCount = total;
//   }
//
//   // Impressions Custom Range
//   Future<void> _openCustomRangePickerForImpressions() async {
//     final DateTime now = DateTime.now();
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(now.year - 1),
//       lastDate: now,
//       initialDateRange: DateTimeRange(
//         start: impressionStartDate ?? now.subtract(const Duration(days: 7)),
//         end: impressionEndDate ?? now,
//       ),
//     );
//     if (picked == null) return;
//     impressionStartDate = picked.start;
//     impressionEndDate = picked.end;
//     _generateCustomRangeImpressions(picked.start, picked.end);
//     setState(() => selectedImpressionPeriod = "Custom Range");
//     _controller.forward(from: 0);
//   }
//
//   void _generateCustomRangeImpressions(DateTime start, DateTime end) {
//     impressionDailyLabels.clear();
//     impressionDailyValues.clear();
//     int total = 0;
//     DateTime current = DateTime(start.year, start.month, start.day);
//     while (!current.isAfter(end)) {
//       int count = impressionList.where((v) {
//         DateTime d = DateTime.parse(v["addedAt"]);
//         return d.year == current.year && d.month == current.month && d.day == current.day;
//       }).length;
//       total += count;
//       impressionDailyLabels.add(DateFormat("dd MMM").format(current));
//       impressionDailyValues.add(count.toDouble());
//       current = current.add(const Duration(days: 1));
//     }
//     visibleImpressionCount = total;
//   }
//
//   void _regenerateImpressionsChart(String period) {
//     impressionDailyLabels.clear();
//     impressionDailyValues.clear();
//     DateTime now = DateTime.now();
//     DateTime start;
//     DateTime end;
//
//     if (period == "This Week") {
//       start = now.subtract(Duration(days: now.weekday - 1));
//       end = start.add(const Duration(days: 6));
//     } else if (period == "This Month") {
//       start = DateTime(now.year, now.month, 1);
//       end = DateTime(now.year, now.month + 1, 0);
//     } else if (period == "Last Month") {
//       if (now.month == 1) {
//         start = DateTime(now.year - 1, 12, 1);
//         end = DateTime(now.year - 1, 12, 31);
//       } else {
//         start = DateTime(now.year, now.month - 1, 1);
//         end = DateTime(now.year, now.month, 0);
//       }
//     } else {
//       return;
//     }
//
//     DateTime current = DateTime(start.year, start.month, start.day);
//     int total = 0;
//     while (!current.isAfter(end)) {
//       String label = (period == "This Week")
//           ? DateFormat("EEE").format(current)
//           : DateFormat("dd MMM").format(current);
//
//       int count = impressionList.where((v) {
//         DateTime d = DateTime.parse(v["addedAt"]);
//         return d.year == current.year && d.month == current.month && d.day == current.day;
//       }).length;
//
//       total += count;
//       impressionDailyLabels.add(label);
//       impressionDailyValues.add(count.toDouble());
//       current = current.add(const Duration(days: 1));
//     }
//     visibleImpressionCount = total;
//   }
// ///profile view
//   void _regenerateProfileViewsChart(String period) {
//     profileViewLabels.clear();
//     profileViewValues.clear();
//
//     DateTime now = DateTime.now();
//     DateTime start;
//     DateTime end;
//
//     if (period == "This Week") {
//       start = now.subtract(Duration(days: now.weekday - 1));
//       end = start.add(const Duration(days: 6));
//     } else if (period == "This Month") {
//       start = DateTime(now.year, now.month, 1);
//       end = DateTime(now.year, now.month + 1, 0);
//     } else if (period == "Last Month") {
//       start = DateTime(now.year, now.month - 1, 1);
//       end = DateTime(now.year, now.month, 0);
//     } else {
//       return;
//     }
//
//     int days = end.difference(start).inDays + 1;
//     double perDay = days == 0 ? 0 : profileViewsTotal / days;
//
//     DateTime current = start;
//     int total = 0;
//
//     while (!current.isAfter(end)) {
//       String label =
//       (period == "This Week")
//           ? DateFormat("EEE").format(current)
//           : DateFormat("dd MMM").format(current);
//
//       profileViewLabels.add(label);
//       profileViewValues.add(perDay);
//
//       total += perDay.round();
//       current = current.add(const Duration(days: 1));
//     }
//
//     visibleProfileViewCount = total;
//   }
//   Future<void> _openCustomRangePickerForProfileViews() async {
//     final DateTime now = DateTime.now();
//
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(now.year - 1),
//       lastDate: now,
//     );
//
//     if (picked == null) return;
//
//     profileViewLabels.clear();
//     profileViewValues.clear();
//
//     int days = picked.end.difference(picked.start).inDays + 1;
//     double perDay = days == 0 ? 0 : profileViewsTotal / days;
//
//     DateTime current = picked.start;
//     int total = 0;
//
//     while (!current.isAfter(picked.end)) {
//       profileViewLabels.add(DateFormat("dd MMM").format(current));
//       profileViewValues.add(perDay);
//       total += perDay.round();
//       current = current.add(const Duration(days: 1));
//     }
//
//     visibleProfileViewCount = total;
//
//     setState(() => selectedProfileViewPeriod = "Custom Range");
//     _controller.forward(from: 0);
//   }
//   Widget _rangeDropdownForProfileViews() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade300),
//             borderRadius: BorderRadius.circular(6),
//           ),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<String>(
//               value: selectedProfileViewPeriod,
//               items: profileViewRanges
//                   .map((e) => DropdownMenuItem(
//                 value: e,
//                 child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600)),
//               ))
//                   .toList(),
//               onChanged: (value) async {
//                 if (value == null) return;
//
//                 if (value == "Custom Range") {
//                   await _openCustomRangePickerForProfileViews();
//                 } else {
//                   setState(() => selectedProfileViewPeriod = value);
//                   _regenerateProfileViewsChart(value);
//                 }
//                 _controller.forward(from: 0);
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
// ///
//   Future<void> fetchDashboardData() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       token = prefs.getString("token");
//       vendorId = _resolveVendorIdFromPrefsOrToken(prefs, token);
//
//       if (token == null) {
//         setState(() => isLoading = false);
//         return;
//       }
//
//       // Leads
//       final leadRes = await http.get(
//         Uri.parse("https://happywedz.com/api/request-pricing/vendor/dashboard"),
//         headers: {"Authorization": "Bearer $token"},
//       );
//       if (leadRes.statusCode == 200) {
//         apiRequests = jsonDecode(leadRes.body)["requests"] ?? [];
//       }
//
//       // Profile Views Total (lifetime)
//       if (vendorId != null) {
//         final pvRes = await http.get(
//           Uri.parse("https://happywedz.com/api/vendor/profile-views/$vendorId"),
//           headers: {"Authorization": "Bearer $token"},
//         );
//         if (pvRes.statusCode == 200) {
//           final data = jsonDecode(pvRes.body);
//           if (data["success"] == true && data["vendor"] != null) {
//             profileViewsTotal = (data["vendor"]["profileViews"] ?? 0).toInt();
//           }
//         }
//       }
//
//       // Impressions (wishlist adds with dates)
//       if (vendorId != null) {
//         final impRes = await http.get(
//           Uri.parse("https://happywedz.com/api/wishlist/vendor/stats/$vendorId"),
//           headers: {"Authorization": "Bearer $token"},
//         );
//         if (impRes.statusCode == 200) {
//           final data = jsonDecode(impRes.body);
//           if (data["data"] != null && (data["data"] as List).isNotEmpty) {
//             final first = data["data"][0];
//             if (first["users"] != null) {
//               impressionList = List<dynamic>.from(first["users"]);
//             }
//           }
//         }
//       }
//
//       await prefs.setInt("lead_count", apiRequests.length);
//       await prefs.setInt("views_count", profileViewsTotal);
//       await prefs.setInt("impression_count", impressionList.length);
//
//       setState(() {});
//
//       _regenerateLeadsChart("This Week");
//       _regenerateImpressionsChart("This Week");
//       _regenerateProfileViewsChart("This Week");
//
//     } catch (e) {
//       print("Error: $e");
//     }
//
//     setState(() => isLoading = false);
//     _controller.forward();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(70),
//         child: AppBar(
//           automaticallyImplyLeading: false,
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           flexibleSpace: Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(colors: [Color(0xFF003F88), Color(0xFF00509D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
//               boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
//             ),
//             padding: const EdgeInsets.fromLTRB(20, 30, 16, 10),
//             alignment: Alignment.bottomLeft,
//             child: const Text("Statistics", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
//           ),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : FadeTransition(
//         opacity: _fadeAnim,
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 30),
//                 _topStatsCards(),
//                 const SizedBox(height: 30),
//                 _sectionHeader("Leads"),
//                 const SizedBox(height: 10),
//                 _rangeDropdownForLeads(),
//                 const SizedBox(height: 10),
//                 _animatedChartForLeads(),
//                 const SizedBox(height: 30),
//                 _sectionHeader("Impressions"),
//                 const SizedBox(height: 10),
//                 _rangeDropdownForImpressions(),
//                 const SizedBox(height: 10),
//                 _animatedChartForImpressions(),
//                 const SizedBox(height: 30),
//                 _sectionHeader("Profile Views"),
//                 const SizedBox(height: 10),
//                _rangeDropdownForProfileViews(),
//                 const SizedBox(height: 10),
//                 _animatedChartForProfileViews(), // Fake even distribution
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _sectionHeader(String title) => Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
//
//   Widget _rangeDropdownForLeads() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<String>(
//               value: selectedLeadPeriod,
//               icon: const Icon(Icons.keyboard_arrow_down),
//               items: leadRanges.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
//               onChanged: (value) async {
//                 if (value == null) return;
//                 if (value == "Custom Range") {
//                   await _openCustomRangePickerForLeads();
//                 } else {
//                   setState(() => selectedLeadPeriod = value);
//                   _regenerateLeadsChart(value);
//                 }
//                 _controller.forward(from: 0);
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _rangeDropdownForImpressions() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<String>(
//               value: selectedImpressionPeriod,
//               icon: const Icon(Icons.keyboard_arrow_down),
//               items: impressionRanges.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
//               onChanged: (value) async {
//                 if (value == null) return;
//                 if (value == "Custom Range") {
//                   await _openCustomRangePickerForImpressions();
//                 } else {
//                   setState(() => selectedImpressionPeriod = value);
//                   _regenerateImpressionsChart(value);
//                 }
//                 _controller.forward(from: 0);
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _topStatsCards() {
//     return Row(
//       children: [
//         Expanded(
//           child: _statCard(
//             title: "TOTAL LEADS",
//             value: visibleLeadCount.toString(),
//             icon: Icons.group,
//             iconBg: const Color(0xFFE8F5E9),
//             iconColor: const Color(0xFF2E7D32),
//             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeadsListScreen(leads: apiRequests))),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _statCard(
//             title: "PROFILE VIEWS",
//             value: profileViewsTotal.toString(), // Lifetime total
//           //  value: visibleProfileViewCount.toString(),after api update uncomment this line
//             icon: Icons.remove_red_eye,
//             iconBg: const Color(0xFFE3F2FD),
//             iconColor: const Color(0xFF1565C0),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _statCard(
//             title: "IMPRESSIONS",
//             value: visibleImpressionCount.toString(),
//             icon: Icons.favorite,
//             iconBg: const Color(0xFFFCE4EC),
//             iconColor: const Color(0xFFC2185B),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _statCard({required String title, required String value, required IconData icon, required Color iconBg, required Color iconColor, VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade300),
//           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
//                 ],
//               ),
//             ),
//             Container(height: 42, width: 42, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 22)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _animatedChartForLeads() {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 700),
//       child: _chartContainer(dailyLabels, dailyValues, key: ValueKey("leads_$selectedLeadPeriod")),
//     );
//   }
//
//   Widget _animatedChartForImpressions() {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 700),
//       child: _chartContainer(impressionDailyLabels, impressionDailyValues, key: ValueKey("impressions_$selectedImpressionPeriod")),
//     );
//   }
//
//
//   // Widget _animatedChartForProfileViews() {
//   //   List<String> labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
//   //   List<double> values =
//   //   List.generate(7, (_) => profileViewsTotal.toDouble());
//   //
//   //   return AnimatedSwitcher(
//   //     duration: const Duration(milliseconds: 700),
//   //     child: _chartContainer(
//   //       labels,
//   //       values,
//   //       key: const ValueKey("profileViews_alltime"),
//   //       isProfileViews: true,
//   //     ),
//   //   );
//   // }
//
//   Widget _animatedChartForProfileViews() {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 700),
//       child: _chartContainer(
//         profileViewLabels,
//         profileViewValues,
//         key: ValueKey("profile_$selectedProfileViewPeriod"),
//       ),
//     );
//   }
//
//
//   Widget _chartContainer(List<String> labels, List<double> values, {Key? key,  bool isProfileViews = false, }) {
//     return Container(
//       key: key,
//       padding: const EdgeInsets.symmetric(vertical: 14),
//       decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
//       child: SizedBox(
//         height: 260,
//         child: LineChart(
//           LineChartData(
//             maxY: (values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b)) + 5,
//             minY: 0,
//             lineBarsData: [
//               LineChartBarData(
//                 isCurved: true,
//                 curveSmoothness: 0.25,
//                 spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i])),
//                 color: const Color(0xFF4682B4),
//                 dotData: FlDotData(show: true),
//                 barWidth: 2.5,
//                 belowBarData: BarAreaData(
//                   show: true,
//                   gradient: LinearGradient(
//                     colors: [Color(0xFF4682B4).withOpacity(0.35), Color(0xFF4682B4).withOpacity(0.05)],
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                   ),
//                 ),
//               ),
//             ],
//             titlesData: FlTitlesData(
//               bottomTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: true,
//                   interval: 1,
//                   reservedSize: 60,
//                   getTitlesWidget: (value, meta) {
//                     int index = value.toInt();
//                     if (index >= 0 && index < labels.length) {
//                       return Padding(
//                         padding: const EdgeInsets.only(top: 10),
//                         child: Transform.rotate(angle: -0.7, child: Text(labels[index], style: const TextStyle(fontSize: 11))),
//                       );
//                     }
//                     return const SizedBox();
//                   },
//                 ),
//               ),
//               leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
//               topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//               rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             ),
//             gridData: FlGridData(show: true, horizontalInterval: 5, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.8)),
//             borderData: FlBorderData(show: false),
//             lineTouchData: LineTouchData(
//               handleBuiltInTouches: true,
//               touchTooltipData: LineTouchTooltipData(
//                 getTooltipItems: (spots) => spots.map((spot) {
//                   int idx = spot.x.toInt();
//                   String label = (idx >= 0 && idx < labels.length) ? labels[idx] : "";
//                   // return LineTooltipItem("$label\n${spot.y.toInt()}", const TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
//                   return LineTooltipItem(
//                     isProfileViews
//                         ? "$label\nTotal: $profileViewsTotal"
//                         : "$label\n${spot.y.toInt()}",
//                     const TextStyle(
//                       color: Colors.black,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   );
//
//                 }).toList(),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'new_screens/leads_list_stats.dart';


class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin {
  // ---------- Common Period ----------
  String selectedPeriod = "This Week";

  final List<String> periods = [
    "This Week",
    "This Month",
    "Last Month",
    "Custom Range",
  ];

  DateTime? customStartDate;
  DateTime? customEndDate;

  // ---------- Leads ----------
  bool isLoading = true;
  List<dynamic> apiRequests = [];
  String? token;
  int? vendorId;

  List<String> dailyLabels = [];
  List<double> dailyValues = [];
  int visibleLeadCount = 0;

  // ---------- Impressions ----------
  List<dynamic> impressionList = [];
  List<String> impressionDailyLabels = [];
  List<double> impressionDailyValues = [];
  int visibleImpressionCount = 0;

  // ---------- Profile Views ----------
  int profileViewsTotal = 0;
  List<String> profileViewLabels = [];
  List<double> profileViewValues = [];
  int visibleProfileViewCount = 0;

  // animations
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    fetchDashboardData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _resolveVendorIdFromPrefsOrToken(
      SharedPreferences prefs, String? token) {
    final int? vid = prefs.getInt("vendor_id");
    if (vid != null) return vid;
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      String payload = parts[1];
      String normalized = base64Url.normalize(payload);
      final Uint8List decoded = base64Url.decode(normalized);
      final Map<String, dynamic> map =
      jsonDecode(utf8.decode(decoded));
      if (map.containsKey('id')) return (map['id'] as num).toInt();
      if (map.containsKey('vendorId')) return (map['vendorId'] as num).toInt();
      if (map.containsKey('vendor_id')) return (map['vendor_id'] as num).toInt();
    } catch (e) {
      print("Warning: Error decoding token: $e");
    }
    return null;
  }

  // ==================== Custom Range (Common) ====================
  Future<void> _openCustomRangePicker() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: customStartDate ?? now.subtract(const Duration(days: 7)),
        end: customEndDate ?? now,
      ),
    );
    if (picked == null) return;

    customStartDate = picked.start;
    customEndDate = picked.end;

    _generateCustomRangeLeads(picked.start, picked.end);
    _generateCustomRangeImpressions(picked.start, picked.end);
    _generateCustomRangeProfileViews(picked.start, picked.end);

    setState(() => selectedPeriod = "Custom Range");
    _controller.forward(from: 0);
  }

  void _generateCustomRangeLeads(DateTime start, DateTime end) {
    dailyLabels.clear();
    dailyValues.clear();
    int total = 0;
    DateTime current = DateTime(start.year, start.month, start.day);
    while (!current.isAfter(end)) {
      String label = DateFormat("dd MMM").format(current);
      int count = apiRequests.where((req) {
        DateTime d = DateTime.parse(req["createdAt"]);
        return d.year == current.year &&
            d.month == current.month &&
            d.day == current.day;
      }).length;
      total += count;
      dailyLabels.add(label);
      dailyValues.add(count.toDouble());
      current = current.add(const Duration(days: 1));
    }
    visibleLeadCount = total;
  }

  void _generateCustomRangeImpressions(DateTime start, DateTime end) {
    impressionDailyLabels.clear();
    impressionDailyValues.clear();
    int total = 0;
    DateTime current = DateTime(start.year, start.month, start.day);
    while (!current.isAfter(end)) {
      int count = impressionList.where((v) {
        DateTime d = DateTime.parse(v["addedAt"]);
        return d.year == current.year &&
            d.month == current.month &&
            d.day == current.day;
      }).length;
      total += count;
      impressionDailyLabels.add(DateFormat("dd MMM").format(current));
      impressionDailyValues.add(count.toDouble());
      current = current.add(const Duration(days: 1));
    }
    visibleImpressionCount = total;
  }

  void _generateCustomRangeProfileViews(DateTime start, DateTime end) {
    profileViewLabels.clear();
    profileViewValues.clear();
    int days = end.difference(start).inDays + 1;
    double perDay = days == 0 ? 0 : profileViewsTotal / days;

    DateTime current = DateTime(start.year, start.month, start.day);
    int total = 0;
    while (!current.isAfter(end)) {
      profileViewLabels.add(DateFormat("dd MMM").format(current));
      profileViewValues.add(perDay);
      total += perDay.round();
      current = current.add(const Duration(days: 1));
    }
    visibleProfileViewCount = total;
  }

  // ==================== Regenerate Charts (Common Logic) ====================
  void _regenerateAllCharts(String period) {
    _regenerateLeadsChart(period);
    _regenerateImpressionsChart(period);
    _regenerateProfileViewsChart(period);
  }

  void _regenerateLeadsChart(String period) {
    dailyLabels.clear();
    dailyValues.clear();
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end;

    if (period == "This Week") {
      start = now.subtract(Duration(days: now.weekday - 1));
      end = start.add(const Duration(days: 6));
    } else if (period == "This Month") {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    } else if (period == "Last Month") {
      if (now.month == 1) {
        start = DateTime(now.year - 1, 12, 1);
        end = DateTime(now.year - 1, 12, 31);
      } else {
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
      }
    } else {
      return;
    }

    DateTime current = DateTime(start.year, start.month, start.day);
    int total = 0;
    while (!current.isAfter(end)) {
      String label = (period == "This Week")
          ? DateFormat("EEE").format(current)
          : DateFormat("dd MMM").format(current);

      int count = apiRequests.where((req) {
        DateTime d = DateTime.parse(req["createdAt"]);
        return d.year == current.year &&
            d.month == current.month &&
            d.day == current.day;
      }).length;

      total += count;
      dailyLabels.add(label);
      dailyValues.add(count.toDouble());
      current = current.add(const Duration(days: 1));
    }
    visibleLeadCount = total;
  }

  void _regenerateImpressionsChart(String period) {
    impressionDailyLabels.clear();
    impressionDailyValues.clear();
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end;

    if (period == "This Week") {
      start = now.subtract(Duration(days: now.weekday - 1));
      end = start.add(const Duration(days: 6));
    } else if (period == "This Month") {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    } else if (period == "Last Month") {
      if (now.month == 1) {
        start = DateTime(now.year - 1, 12, 1);
        end = DateTime(now.year - 1, 12, 31);
      } else {
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
      }
    } else {
      return;
    }

    DateTime current = DateTime(start.year, start.month, start.day);
    int total = 0;
    while (!current.isAfter(end)) {
      String label = (period == "This Week")
          ? DateFormat("EEE").format(current)
          : DateFormat("dd MMM").format(current);

      int count = impressionList.where((v) {
        DateTime d = DateTime.parse(v["addedAt"]);
        return d.year == current.year &&
            d.month == current.month &&
            d.day == current.day;
      }).length;

      total += count;
      impressionDailyLabels.add(label);
      impressionDailyValues.add(count.toDouble());
      current = current.add(const Duration(days: 1));
    }
    visibleImpressionCount = total;
  }

  void _regenerateProfileViewsChart(String period) {
    profileViewLabels.clear();
    profileViewValues.clear();

    DateTime now = DateTime.now();
    DateTime start;
    DateTime end;

    if (period == "This Week") {
      start = now.subtract(Duration(days: now.weekday - 1));
      end = start.add(const Duration(days: 6));
    } else if (period == "This Month") {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    } else if (period == "Last Month") {
      if (now.month == 1) {
        start = DateTime(now.year - 1, 12, 1);
        end = DateTime(now.year - 1, 12, 31);
      } else {
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
      }
    } else {
      return;
    }

    int days = end.difference(start).inDays + 1;
    double perDay = days == 0 ? 0 : profileViewsTotal / days;

    DateTime current = start;
    int total = 0;

    while (!current.isAfter(end)) {
      String label = (period == "This Week")
          ? DateFormat("EEE").format(current)
          : DateFormat("dd MMM").format(current);

      profileViewLabels.add(label);
      profileViewValues.add(perDay);
      total += perDay.round();
      current = current.add(const Duration(days: 1));
    }

    visibleProfileViewCount = total;
  }

  // ==================== API Fetch ====================
  Future<void> fetchDashboardData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      token = prefs.getString("token");
      vendorId = _resolveVendorIdFromPrefsOrToken(prefs, token);

      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      // Leads
      final leadRes = await http.get(
        Uri.parse(
            "https://happywedz.com/api/request-pricing/vendor/dashboard"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (leadRes.statusCode == 200) {
        apiRequests = jsonDecode(leadRes.body)["requests"] ?? [];
      }

// Profile Views Total (lifetime)
      if (vendorId != null) {
        final pvRes = await http.get(
          Uri.parse(
            "https://happywedz.com/api/vendor/profile-views/$vendorId",
          ),
          headers: {"Authorization": "Bearer $token"},
        );

        if (pvRes.statusCode == 200) {
          final data = jsonDecode(pvRes.body);

          if (data["success"] == true) {
            profileViewsTotal = (data["totalViews"] ?? 0).toInt();
          }
        }
      }


      // Impressions
      if (vendorId != null) {
        final impRes = await http.get(
          Uri.parse(
              "https://happywedz.com/api/wishlist/vendor/stats/$vendorId"),
          headers: {"Authorization": "Bearer $token"},
        );
        if (impRes.statusCode == 200) {
          final data = jsonDecode(impRes.body);
          if (data["data"] != null && (data["data"] as List).isNotEmpty) {
            final first = data["data"][0];
            if (first["users"] != null) {
              impressionList = List<dynamic>.from(first["users"]);
            }
          }
        }
      }

      await prefs.setInt("lead_count", apiRequests.length);
      await prefs.setInt("views_count", profileViewsTotal);
      await prefs.setInt("impression_count", impressionList.length);

      setState(() {});

      _regenerateAllCharts("This Week");

    } catch (e) {
      print("Error: $e");
    }

    setState(() => isLoading = false);
    _controller.forward();
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF003F88), Color(0xFF00509D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 30, 16, 10),
            alignment: Alignment.bottomLeft,
            child: const Text("Statistics",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                _topStatsCards(),
                const SizedBox(height: 20),
                _sharedRangeDropdown(), // dropdown
                const SizedBox(height: 25),
                _sectionHeader("Leads"),
                const SizedBox(height: 10),
                _animatedChartForLeads(),
                const SizedBox(height: 30),
                _sectionHeader("Impressions"),
                const SizedBox(height: 10),
                _animatedChartForImpressions(),
                const SizedBox(height: 30),
                _sectionHeader("Profile Views"),
                const SizedBox(height: 10),
                _animatedChartForProfileViews(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sharedRangeDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPeriod,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: periods
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ))
                  .toList(),
              onChanged: (value) async {
                if (value == null) return;

                if (value == "Custom Range") {
                  await _openCustomRangePicker();
                } else {
                  setState(() => selectedPeriod = value);
                  _regenerateAllCharts(value);
                }
                _controller.forward(from: 0);
              },
            ),
          ),
        ),
      ],
    );
  }
  List<dynamic> _getFilteredLeads() {
    if (selectedPeriod == "Custom Range" && customStartDate != null && customEndDate != null) {
      return apiRequests.where((req) {
        DateTime d = DateTime.parse(req["createdAt"]);
        return !d.isBefore(customStartDate!) && !d.isAfter(customEndDate!);
      }).toList();
    }

    DateTime now = DateTime.now();
    DateTime start;
    DateTime end;

    if (selectedPeriod == "This Week") {
      start = now.subtract(Duration(days: now.weekday - 1));
      end = start.add(const Duration(days: 6));
    } else if (selectedPeriod == "This Month") {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    } else if (selectedPeriod == "Last Month") {
      if (now.month == 1) {
        start = DateTime(now.year - 1, 12, 1);
        end = DateTime(now.year - 1, 12, 31);
      } else {
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
      }
    } else {
      return apiRequests; // fallback
    }

    start = DateTime(start.year, start.month, start.day);
    end = DateTime(end.year, end.month, end.day);

    return apiRequests.where((req) {
      DateTime d = DateTime.parse(req["createdAt"]);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  Widget _sectionHeader(String title) =>
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));

  Widget _topStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: "TOTAL LEADS",
            value: visibleLeadCount.toString(),
            icon: Icons.group,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF2E7D32),

            onTap: () {
              // Current selected period के अनुसार filtered leads निकालो
              List<dynamic> filteredLeads = _getFilteredLeads();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeadsListScreen(leads: filteredLeads),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: "PROFILE VIEWS",
            value: profileViewsTotal.toString(), // Lifetime total
            icon: Icons.remove_red_eye,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: "IMPRESSIONS",
            value: visibleImpressionCount.toString(),
            icon: Icons.favorite,
            iconBg: const Color(0xFFFCE4EC),
            iconColor: const Color(0xFFC2185B),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Container(
                height: 42,
                width: 42,
                decoration:
                BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 22)),
          ],
        ),
      ),
    );
  }

  Widget _animatedChartForLeads() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: _chartContainer(
        dailyLabels,
        dailyValues,
        key: ValueKey("leads_$selectedPeriod"),
      ),
    );
  }

  Widget _animatedChartForImpressions() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: _chartContainer(
        impressionDailyLabels,
        impressionDailyValues,
        key: ValueKey("impressions_$selectedPeriod"),
      ),
    );
  }

  Widget _animatedChartForProfileViews() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: _chartContainer(
        profileViewLabels,
        profileViewValues,
        key: ValueKey("profile_$selectedPeriod"),
      ),
    );
  }

  Widget _chartContainer(
      List<String> labels,
      List<double> values, {
        Key? key,
      }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6)),
      child: SizedBox(
        height: 260,
        child: LineChart(
          LineChartData(
            maxY: (values.isEmpty
                ? 0
                : values.reduce((a, b) => a > b ? a : b)) +
                5,
            minY: 0,
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                curveSmoothness: 0.25,
                spots: List.generate(
                    values.length, (i) => FlSpot(i.toDouble(), values[i])),
                color: const Color(0xFF4682B4),
                dotData: FlDotData(show: true),
                barWidth: 2.5,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4682B4).withOpacity(0.35),
                      Color(0xFF4682B4).withOpacity(0.05)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < labels.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Transform.rotate(
                            angle: -0.7,
                            child: Text(labels[index],
                                style: const TextStyle(fontSize: 11))),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, m) =>
                          Text(v.toInt().toString(),
                              style: const TextStyle(fontSize: 10)))),
              topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
                show: true,
                horizontalInterval: 5,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.grey.shade300, strokeWidth: 0.8)),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((spot) {
                  int idx = spot.x.toInt();
                  String label =
                  (idx >= 0 && idx < labels.length) ? labels[idx] : "";
                  return LineTooltipItem(
                    "$label\n${spot.y.toInt()}",
                    const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}