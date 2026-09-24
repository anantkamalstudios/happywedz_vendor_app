// // import 'dart:convert';
// // import 'dart:typed_data';
// // import 'package:flutter/material.dart';
// // import 'package:fl_chart/fl_chart.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:intl/intl.dart';
// // import 'new_screens/leads_list_stats.dart';
// //
// // class StatsPage extends StatefulWidget {
// //   const StatsPage({Key? key}) : super(key: key);
// //
// //   @override
// //   State<StatsPage> createState() => _StatsPageState();
// // }
// //
// // class _StatsPageState extends State<StatsPage>
// //     with SingleTickerProviderStateMixin {
// //   // ---------- Leads ----------
// //   String selectedLeadPeriod = "This Week";
// //   bool isLoading = true;
// //   List<dynamic> apiRequests = [];
// //   String? token;
// //   DateTime? customStartDate;
// //   DateTime? customEndDate;
// //   DateTime? impressionStartDate;
// //   DateTime? impressionEndDate;
// //   int? vendorId;
// //   int visibleLeadCount = 0;
// //   int visibleImpressionCount = 0;
// //
// //   final List<String> leadRanges = [
// //     "This Week",
// //     "This Month",
// //     "Last Month",
// //     "Custom Range",
// //   ];
// //
// //   List<String> dailyLabels = [];
// //   List<double> dailyValues = [];
// //
// //
// //   // ---------- Profile Views ----------
// //   String selectedProfileViewPeriod = "This Week";
// //
// //   final List<String> profileViewRanges = [
// //     "This Week",
// //     "This Month",
// //     "Last Month",
// //     "Custom Range",
// //   ];
// //
// //   DateTime? profileViewStartDate;
// //   DateTime? profileViewEndDate;
// //
// //   List<String> profileViewLabels = [];
// //   List<double> profileViewValues = [];
// //
// //   int visibleProfileViewCount = 0;
// //
// //   // ---------- Impressions ----------
// //   String selectedImpressionPeriod = "This Week";
// //   final List<String> impressionRanges = [
// //     "This Week",
// //     "This Month",
// //     "Last Month",
// //     "Custom Range",
// //   ];
// //
// //   List<String> impressionDailyLabels = [];
// //   List<double> impressionDailyValues = [];
// //
// //   // ---------- Profile Views ----------
// //   int profileViewsTotal = 0; // Lifetime total from API
// //   List<dynamic> impressionList = []; // Renamed: this is actually wishlist adds (impressions)
// //
// //   // animations
// //   late AnimationController _controller;
// //   late Animation<double> _fadeAnim;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
// //     _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
// //
// //     fetchDashboardData();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _controller.dispose();
// //     super.dispose();
// //   }
// //
// //   int? _resolveVendorIdFromPrefsOrToken(SharedPreferences prefs, String? token) {
// //     final int? vid = prefs.getInt("vendor_id");
// //     if (vid != null) return vid;
// //     if (token == null) return null;
// //     try {
// //       final parts = token.split('.');
// //       if (parts.length < 2) return null;
// //       String payload = parts[1];
// //       String normalized = base64Url.normalize(payload);
// //       final Uint8List decoded = base64Url.decode(normalized);
// //       final Map<String, dynamic> map = jsonDecode(utf8.decode(decoded));
// //       if (map.containsKey('id')) return (map['id'] as num).toInt();
// //       if (map.containsKey('vendorId')) return (map['vendorId'] as num).toInt();
// //       if (map.containsKey('vendor_id')) return (map['vendor_id'] as num).toInt();
// //     } catch (e) {
// //       print("Warning: Error decoding token: $e");
// //     }
// //     return null;
// //   }
// //
// //   // Leads Custom Range
// //   Future<void> _openCustomRangePickerForLeads() async {
// //     final DateTime now = DateTime.now();
// //     final DateTimeRange? picked = await showDateRangePicker(
// //       context: context,
// //       firstDate: DateTime(now.year - 1),
// //       lastDate: now,
// //       initialDateRange: DateTimeRange(
// //         start: customStartDate ?? now.subtract(const Duration(days: 7)),
// //         end: customEndDate ?? now,
// //       ),
// //     );
// //     if (picked == null) return;
// //     customStartDate = picked.start;
// //     customEndDate = picked.end;
// //     _generateCustomRangeLeads(picked.start, picked.end);
// //     setState(() => selectedLeadPeriod = "Custom Range");
// //     _controller.forward(from: 0);
// //   }
// //
// //   void _generateCustomRangeLeads(DateTime start, DateTime end) {
// //     dailyLabels.clear();
// //     dailyValues.clear();
// //     int total = 0;
// //     DateTime current = DateTime(start.year, start.month, start.day);
// //     while (!current.isAfter(end)) {
// //       String label = DateFormat("dd MMM").format(current);
// //       int count = apiRequests.where((req) {
// //         DateTime d = DateTime.parse(req["createdAt"]);
// //         return d.year == current.year && d.month == current.month && d.day == current.day;
// //       }).length;
// //       total += count;
// //       dailyLabels.add(label);
// //       dailyValues.add(count.toDouble());
// //       current = current.add(const Duration(days: 1));
// //     }
// //     visibleLeadCount = total;
// //   }
// //
// //   void _regenerateLeadsChart(String period) {
// //     dailyLabels.clear();
// //     dailyValues.clear();
// //     DateTime now = DateTime.now();
// //     DateTime start;
// //     DateTime end;
// //
// //     if (period == "This Week") {
// //       start = now.subtract(Duration(days: now.weekday - 1));
// //       end = start.add(const Duration(days: 6));
// //     } else if (period == "This Month") {
// //       start = DateTime(now.year, now.month, 1);
// //       end = DateTime(now.year, now.month + 1, 0);
// //     } else if (period == "Last Month") {
// //       if (now.month == 1) {
// //         start = DateTime(now.year - 1, 12, 1);
// //         end = DateTime(now.year - 1, 12, 31);
// //       } else {
// //         start = DateTime(now.year, now.month - 1, 1);
// //         end = DateTime(now.year, now.month, 0);
// //       }
// //     } else {
// //       return;
// //     }
// //
// //     DateTime current = DateTime(start.year, start.month, start.day);
// //     int total = 0;
// //     while (!current.isAfter(end)) {
// //       String label = (period == "This Week")
// //           ? DateFormat("EEE").format(current)
// //           : DateFormat("dd MMM").format(current);
// //
// //       int count = apiRequests.where((req) {
// //         DateTime d = DateTime.parse(req["createdAt"]);
// //         return d.year == current.year && d.month == current.month && d.day == current.day;
// //       }).length;
// //
// //       total += count;
// //       dailyLabels.add(label);
// //       dailyValues.add(count.toDouble());
// //       current = current.add(const Duration(days: 1));
// //     }
// //     visibleLeadCount = total;
// //   }
// //
// //   // Impressions Custom Range
// //   Future<void> _openCustomRangePickerForImpressions() async {
// //     final DateTime now = DateTime.now();
// //     final DateTimeRange? picked = await showDateRangePicker(
// //       context: context,
// //       firstDate: DateTime(now.year - 1),
// //       lastDate: now,
// //       initialDateRange: DateTimeRange(
// //         start: impressionStartDate ?? now.subtract(const Duration(days: 7)),
// //         end: impressionEndDate ?? now,
// //       ),
// //     );
// //     if (picked == null) return;
// //     impressionStartDate = picked.start;
// //     impressionEndDate = picked.end;
// //     _generateCustomRangeImpressions(picked.start, picked.end);
// //     setState(() => selectedImpressionPeriod = "Custom Range");
// //     _controller.forward(from: 0);
// //   }
// //
// //   void _generateCustomRangeImpressions(DateTime start, DateTime end) {
// //     impressionDailyLabels.clear();
// //     impressionDailyValues.clear();
// //     int total = 0;
// //     DateTime current = DateTime(start.year, start.month, start.day);
// //     while (!current.isAfter(end)) {
// //       int count = impressionList.where((v) {
// //         DateTime d = DateTime.parse(v["addedAt"]);
// //         return d.year == current.year && d.month == current.month && d.day == current.day;
// //       }).length;
// //       total += count;
// //       impressionDailyLabels.add(DateFormat("dd MMM").format(current));
// //       impressionDailyValues.add(count.toDouble());
// //       current = current.add(const Duration(days: 1));
// //     }
// //     visibleImpressionCount = total;
// //   }
// //
// //   void _regenerateImpressionsChart(String period) {
// //     impressionDailyLabels.clear();
// //     impressionDailyValues.clear();
// //     DateTime now = DateTime.now();
// //     DateTime start;
// //     DateTime end;
// //
// //     if (period == "This Week") {
// //       start = now.subtract(Duration(days: now.weekday - 1));
// //       end = start.add(const Duration(days: 6));
// //     } else if (period == "This Month") {
// //       start = DateTime(now.year, now.month, 1);
// //       end = DateTime(now.year, now.month + 1, 0);
// //     } else if (period == "Last Month") {
// //       if (now.month == 1) {
// //         start = DateTime(now.year - 1, 12, 1);
// //         end = DateTime(now.year - 1, 12, 31);
// //       } else {
// //         start = DateTime(now.year, now.month - 1, 1);
// //         end = DateTime(now.year, now.month, 0);
// //       }
// //     } else {
// //       return;
// //     }
// //
// //     DateTime current = DateTime(start.year, start.month, start.day);
// //     int total = 0;
// //     while (!current.isAfter(end)) {
// //       String label = (period == "This Week")
// //           ? DateFormat("EEE").format(current)
// //           : DateFormat("dd MMM").format(current);
// //
// //       int count = impressionList.where((v) {
// //         DateTime d = DateTime.parse(v["addedAt"]);
// //         return d.year == current.year && d.month == current.month && d.day == current.day;
// //       }).length;
// //
// //       total += count;
// //       impressionDailyLabels.add(label);
// //       impressionDailyValues.add(count.toDouble());
// //       current = current.add(const Duration(days: 1));
// //     }
// //     visibleImpressionCount = total;
// //   }
// // ///profile view
// //   void _regenerateProfileViewsChart(String period) {
// //     profileViewLabels.clear();
// //     profileViewValues.clear();
// //
// //     DateTime now = DateTime.now();
// //     DateTime start;
// //     DateTime end;
// //
// //     if (period == "This Week") {
// //       start = now.subtract(Duration(days: now.weekday - 1));
// //       end = start.add(const Duration(days: 6));
// //     } else if (period == "This Month") {
// //       start = DateTime(now.year, now.month, 1);
// //       end = DateTime(now.year, now.month + 1, 0);
// //     } else if (period == "Last Month") {
// //       start = DateTime(now.year, now.month - 1, 1);
// //       end = DateTime(now.year, now.month, 0);
// //     } else {
// //       return;
// //     }
// //
// //     int days = end.difference(start).inDays + 1;
// //     double perDay = days == 0 ? 0 : profileViewsTotal / days;
// //
// //     DateTime current = start;
// //     int total = 0;
// //
// //     while (!current.isAfter(end)) {
// //       String label =
// //       (period == "This Week")
// //           ? DateFormat("EEE").format(current)
// //           : DateFormat("dd MMM").format(current);
// //
// //       profileViewLabels.add(label);
// //       profileViewValues.add(perDay);
// //
// //       total += perDay.round();
// //       current = current.add(const Duration(days: 1));
// //     }
// //
// //     visibleProfileViewCount = total;
// //   }
// //   Future<void> _openCustomRangePickerForProfileViews() async {
// //     final DateTime now = DateTime.now();
// //
// //     final DateTimeRange? picked = await showDateRangePicker(
// //       context: context,
// //       firstDate: DateTime(now.year - 1),
// //       lastDate: now,
// //     );
// //
// //     if (picked == null) return;
// //
// //     profileViewLabels.clear();
// //     profileViewValues.clear();
// //
// //     int days = picked.end.difference(picked.start).inDays + 1;
// //     double perDay = days == 0 ? 0 : profileViewsTotal / days;
// //
// //     DateTime current = picked.start;
// //     int total = 0;
// //
// //     while (!current.isAfter(picked.end)) {
// //       profileViewLabels.add(DateFormat("dd MMM").format(current));
// //       profileViewValues.add(perDay);
// //       total += perDay.round();
// //       current = current.add(const Duration(days: 1));
// //     }
// //
// //     visibleProfileViewCount = total;
// //
// //     setState(() => selectedProfileViewPeriod = "Custom Range");
// //     _controller.forward(from: 0);
// //   }
// //   Widget _rangeDropdownForProfileViews() {
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.end,
// //       children: [
// //         Container(
// //           padding: const EdgeInsets.symmetric(horizontal: 12),
// //           decoration: BoxDecoration(
// //             border: Border.all(color: Colors.grey.shade300),
// //             borderRadius: BorderRadius.circular(6),
// //           ),
// //           child: DropdownButtonHideUnderline(
// //             child: DropdownButton<String>(
// //               value: selectedProfileViewPeriod,
// //               items: profileViewRanges
// //                   .map((e) => DropdownMenuItem(
// //                 value: e,
// //                 child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600)),
// //               ))
// //                   .toList(),
// //               onChanged: (value) async {
// //                 if (value == null) return;
// //
// //                 if (value == "Custom Range") {
// //                   await _openCustomRangePickerForProfileViews();
// //                 } else {
// //                   setState(() => selectedProfileViewPeriod = value);
// //                   _regenerateProfileViewsChart(value);
// //                 }
// //                 _controller.forward(from: 0);
// //               },
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// // ///
// //   Future<void> fetchDashboardData() async {
// //     try {
// //       SharedPreferences prefs = await SharedPreferences.getInstance();
// //       token = prefs.getString("token");
// //       vendorId = _resolveVendorIdFromPrefsOrToken(prefs, token);
// //
// //       if (token == null) {
// //         setState(() => isLoading = false);
// //         return;
// //       }
// //
// //       // Leads
// //       final leadRes = await http.get(
// //         Uri.parse("https://happywedz.com/api/request-pricing/vendor/dashboard"),
// //         headers: {"Authorization": "Bearer $token"},
// //       );
// //       if (leadRes.statusCode == 200) {
// //         apiRequests = jsonDecode(leadRes.body)["requests"] ?? [];
// //       }
// //
// //       // Profile Views Total (lifetime)
// //       if (vendorId != null) {
// //         final pvRes = await http.get(
// //           Uri.parse("https://happywedz.com/api/vendor/profile-views/$vendorId"),
// //           headers: {"Authorization": "Bearer $token"},
// //         );
// //         if (pvRes.statusCode == 200) {
// //           final data = jsonDecode(pvRes.body);
// //           if (data["success"] == true && data["vendor"] != null) {
// //             profileViewsTotal = (data["vendor"]["profileViews"] ?? 0).toInt();
// //           }
// //         }
// //       }
// //
// //       // Impressions (wishlist adds with dates)
// //       if (vendorId != null) {
// //         final impRes = await http.get(
// //           Uri.parse("https://happywedz.com/api/wishlist/vendor/stats/$vendorId"),
// //           headers: {"Authorization": "Bearer $token"},
// //         );
// //         if (impRes.statusCode == 200) {
// //           final data = jsonDecode(impRes.body);
// //           if (data["data"] != null && (data["data"] as List).isNotEmpty) {
// //             final first = data["data"][0];
// //             if (first["users"] != null) {
// //               impressionList = List<dynamic>.from(first["users"]);
// //             }
// //           }
// //         }
// //       }
// //
// //       await prefs.setInt("lead_count", apiRequests.length);
// //       await prefs.setInt("views_count", profileViewsTotal);
// //       await prefs.setInt("impression_count", impressionList.length);
// //
// //       setState(() {});
// //
// //       _regenerateLeadsChart("This Week");
// //       _regenerateImpressionsChart("This Week");
// //       _regenerateProfileViewsChart("This Week");
// //
// //     } catch (e) {
// //       print("Error: $e");
// //     }
// //
// //     setState(() => isLoading = false);
// //     _controller.forward();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: PreferredSize(
// //         preferredSize: const Size.fromHeight(70),
// //         child: AppBar(
// //           automaticallyImplyLeading: false,
// //           backgroundColor: Colors.transparent,
// //           elevation: 0,
// //           flexibleSpace: Container(
// //             decoration: const BoxDecoration(
// //               gradient: LinearGradient(colors: [Color(0xFF003F88), Color(0xFF00509D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
// //               boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
// //             ),
// //             padding: const EdgeInsets.fromLTRB(20, 30, 16, 10),
// //             alignment: Alignment.bottomLeft,
// //             child: const Text("Statistics", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
// //           ),
// //         ),
// //       ),
// //       body: isLoading
// //           ? const Center(child: CircularProgressIndicator())
// //           : FadeTransition(
// //         opacity: _fadeAnim,
// //         child: SingleChildScrollView(
// //           child: Padding(
// //             padding: const EdgeInsets.all(12),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 const SizedBox(height: 30),
// //                 _topStatsCards(),
// //                 const SizedBox(height: 30),
// //                 _sectionHeader("Leads"),
// //                 const SizedBox(height: 10),
// //                 _rangeDropdownForLeads(),
// //                 const SizedBox(height: 10),
// //                 _animatedChartForLeads(),
// //                 const SizedBox(height: 30),
// //                 _sectionHeader("Impressions"),
// //                 const SizedBox(height: 10),
// //                 _rangeDropdownForImpressions(),
// //                 const SizedBox(height: 10),
// //                 _animatedChartForImpressions(),
// //                 const SizedBox(height: 30),
// //                 _sectionHeader("Profile Views"),
// //                 const SizedBox(height: 10),
// //                _rangeDropdownForProfileViews(),
// //                 const SizedBox(height: 10),
// //                 _animatedChartForProfileViews(), // Fake even distribution
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _sectionHeader(String title) => Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
// //
// //   Widget _rangeDropdownForLeads() {
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.end,
// //       children: [
// //         Container(
// //           padding: const EdgeInsets.symmetric(horizontal: 12),
// //           decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
// //           child: DropdownButtonHideUnderline(
// //             child: DropdownButton<String>(
// //               value: selectedLeadPeriod,
// //               icon: const Icon(Icons.keyboard_arrow_down),
// //               items: leadRanges.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
// //               onChanged: (value) async {
// //                 if (value == null) return;
// //                 if (value == "Custom Range") {
// //                   await _openCustomRangePickerForLeads();
// //                 } else {
// //                   setState(() => selectedLeadPeriod = value);
// //                   _regenerateLeadsChart(value);
// //                 }
// //                 _controller.forward(from: 0);
// //               },
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _rangeDropdownForImpressions() {
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.end,
// //       children: [
// //         Container(
// //           padding: const EdgeInsets.symmetric(horizontal: 12),
// //           decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
// //           child: DropdownButtonHideUnderline(
// //             child: DropdownButton<String>(
// //               value: selectedImpressionPeriod,
// //               icon: const Icon(Icons.keyboard_arrow_down),
// //               items: impressionRanges.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
// //               onChanged: (value) async {
// //                 if (value == null) return;
// //                 if (value == "Custom Range") {
// //                   await _openCustomRangePickerForImpressions();
// //                 } else {
// //                   setState(() => selectedImpressionPeriod = value);
// //                   _regenerateImpressionsChart(value);
// //                 }
// //                 _controller.forward(from: 0);
// //               },
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _topStatsCards() {
// //     return Row(
// //       children: [
// //         Expanded(
// //           child: _statCard(
// //             title: "TOTAL LEADS",
// //             value: visibleLeadCount.toString(),
// //             icon: Icons.group,
// //             iconBg: const Color(0xFFE8F5E9),
// //             iconColor: const Color(0xFF2E7D32),
// //             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeadsListScreen(leads: apiRequests))),
// //           ),
// //         ),
// //         const SizedBox(width: 12),
// //         Expanded(
// //           child: _statCard(
// //             title: "PROFILE VIEWS",
// //             value: profileViewsTotal.toString(), // Lifetime total
// //           //  value: visibleProfileViewCount.toString(),after api update uncomment this line
// //             icon: Icons.remove_red_eye,
// //             iconBg: const Color(0xFFE3F2FD),
// //             iconColor: const Color(0xFF1565C0),
// //           ),
// //         ),
// //         const SizedBox(width: 12),
// //         Expanded(
// //           child: _statCard(
// //             title: "IMPRESSIONS",
// //             value: visibleImpressionCount.toString(),
// //             icon: Icons.favorite,
// //             iconBg: const Color(0xFFFCE4EC),
// //             iconColor: const Color(0xFFC2185B),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _statCard({required String title, required String value, required IconData icon, required Color iconBg, required Color iconColor, VoidCallback? onTap}) {
// //     return InkWell(
// //       onTap: onTap,
// //       child: Container(
// //         padding: const EdgeInsets.all(14),
// //         decoration: BoxDecoration(
// //           color: Colors.white,
// //           borderRadius: BorderRadius.circular(12),
// //           border: Border.all(color: Colors.grey.shade300),
// //           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
// //         ),
// //         child: Row(
// //           children: [
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
// //                   const SizedBox(height: 8),
// //                   Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
// //                 ],
// //               ),
// //             ),
// //             Container(height: 42, width: 42, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 22)),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _animatedChartForLeads() {
// //     return AnimatedSwitcher(
// //       duration: const Duration(milliseconds: 700),
// //       child: _chartContainer(dailyLabels, dailyValues, key: ValueKey("leads_$selectedLeadPeriod")),
// //     );
// //   }
// //
// //   Widget _animatedChartForImpressions() {
// //     return AnimatedSwitcher(
// //       duration: const Duration(milliseconds: 700),
// //       child: _chartContainer(impressionDailyLabels, impressionDailyValues, key: ValueKey("impressions_$selectedImpressionPeriod")),
// //     );
// //   }
// //
// //
// //   // Widget _animatedChartForProfileViews() {
// //   //   List<String> labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
// //   //   List<double> values =
// //   //   List.generate(7, (_) => profileViewsTotal.toDouble());
// //   //
// //   //   return AnimatedSwitcher(
// //   //     duration: const Duration(milliseconds: 700),
// //   //     child: _chartContainer(
// //   //       labels,
// //   //       values,
// //   //       key: const ValueKey("profileViews_alltime"),
// //   //       isProfileViews: true,
// //   //     ),
// //   //   );
// //   // }
// //
// //   Widget _animatedChartForProfileViews() {
// //     return AnimatedSwitcher(
// //       duration: const Duration(milliseconds: 700),
// //       child: _chartContainer(
// //         profileViewLabels,
// //         profileViewValues,
// //         key: ValueKey("profile_$selectedProfileViewPeriod"),
// //       ),
// //     );
// //   }
// //
// //
// //   Widget _chartContainer(List<String> labels, List<double> values, {Key? key,  bool isProfileViews = false, }) {
// //     return Container(
// //       key: key,
// //       padding: const EdgeInsets.symmetric(vertical: 14),
// //       decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
// //       child: SizedBox(
// //         height: 260,
// //         child: LineChart(
// //           LineChartData(
// //             maxY: (values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b)) + 5,
// //             minY: 0,
// //             lineBarsData: [
// //               LineChartBarData(
// //                 isCurved: true,
// //                 curveSmoothness: 0.25,
// //                 spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i])),
// //                 color: const Color(0xFF4682B4),
// //                 dotData: FlDotData(show: true),
// //                 barWidth: 2.5,
// //                 belowBarData: BarAreaData(
// //                   show: true,
// //                   gradient: LinearGradient(
// //                     colors: [Color(0xFF4682B4).withOpacity(0.35), Color(0xFF4682B4).withOpacity(0.05)],
// //                     begin: Alignment.topCenter,
// //                     end: Alignment.bottomCenter,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //             titlesData: FlTitlesData(
// //               bottomTitles: AxisTitles(
// //                 sideTitles: SideTitles(
// //                   showTitles: true,
// //                   interval: 1,
// //                   reservedSize: 60,
// //                   getTitlesWidget: (value, meta) {
// //                     int index = value.toInt();
// //                     if (index >= 0 && index < labels.length) {
// //                       return Padding(
// //                         padding: const EdgeInsets.only(top: 10),
// //                         child: Transform.rotate(angle: -0.7, child: Text(labels[index], style: const TextStyle(fontSize: 11))),
// //                       );
// //                     }
// //                     return const SizedBox();
// //                   },
// //                 ),
// //               ),
// //               leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
// //               topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
// //               rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
// //             ),
// //             gridData: FlGridData(show: true, horizontalInterval: 5, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.8)),
// //             borderData: FlBorderData(show: false),
// //             lineTouchData: LineTouchData(
// //               handleBuiltInTouches: true,
// //               touchTooltipData: LineTouchTooltipData(
// //                 getTooltipItems: (spots) => spots.map((spot) {
// //                   int idx = spot.x.toInt();
// //                   String label = (idx >= 0 && idx < labels.length) ? labels[idx] : "";
// //                   // return LineTooltipItem("$label\n${spot.y.toInt()}", const TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
// //                   return LineTooltipItem(
// //                     isProfileViews
// //                         ? "$label\nTotal: $profileViewsTotal"
// //                         : "$label\n${spot.y.toInt()}",
// //                     const TextStyle(
// //                       color: Colors.black,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   );
// //
// //                 }).toList(),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'new_screens/leads_list_stats.dart';
//
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
//   // ---------- Common Period ----------
//   String selectedPeriod = "This Week";
//
//   final List<String> periods = [
//     "This Week",
//     "This Month",
//     "Last Month",
//     "Custom Range",
//   ];
//
//   DateTime? customStartDate;
//   DateTime? customEndDate;
//
//   // ---------- Leads ----------
//   bool isLoading = true;
//   List<dynamic> apiRequests = [];
//   String? token;
//   int? vendorId;
//
//   List<String> dailyLabels = [];
//   List<double> dailyValues = [];
//   int visibleLeadCount = 0;
//
//   // ---------- Impressions ----------
//   List<dynamic> impressionList = [];
//   List<String> impressionDailyLabels = [];
//   List<double> impressionDailyValues = [];
//   int visibleImpressionCount = 0;
//
//   // ---------- Profile Views ----------
//   int profileViewsTotal = 0;
//   List<String> profileViewLabels = [];
//   List<double> profileViewValues = [];
//   int visibleProfileViewCount = 0;
//
//   // animations
//   late AnimationController _controller;
//   late Animation<double> _fadeAnim;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 800));
//     _fadeAnim =
//         CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
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
//   int? _resolveVendorIdFromPrefsOrToken(
//       SharedPreferences prefs, String? token) {
//     final int? vid = prefs.getInt("vendor_id");
//     if (vid != null) return vid;
//     if (token == null) return null;
//     try {
//       final parts = token.split('.');
//       if (parts.length < 2) return null;
//       String payload = parts[1];
//       String normalized = base64Url.normalize(payload);
//       final Uint8List decoded = base64Url.decode(normalized);
//       final Map<String, dynamic> map =
//       jsonDecode(utf8.decode(decoded));
//       if (map.containsKey('id')) return (map['id'] as num).toInt();
//       if (map.containsKey('vendorId')) return (map['vendorId'] as num).toInt();
//       if (map.containsKey('vendor_id')) return (map['vendor_id'] as num).toInt();
//     } catch (e) {
//       print("Warning: Error decoding token: $e");
//     }
//     return null;
//   }
//
//   // ==================== Custom Range (Common) ====================
//   Future<void> _openCustomRangePicker() async {
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
//
//     customStartDate = picked.start;
//     customEndDate = picked.end;
//
//     _generateCustomRangeLeads(picked.start, picked.end);
//     _generateCustomRangeImpressions(picked.start, picked.end);
//     _generateCustomRangeProfileViews(picked.start, picked.end);
//
//     setState(() => selectedPeriod = "Custom Range");
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
//         return d.year == current.year &&
//             d.month == current.month &&
//             d.day == current.day;
//       }).length;
//       total += count;
//       dailyLabels.add(label);
//       dailyValues.add(count.toDouble());
//       current = current.add(const Duration(days: 1));
//     }
//     visibleLeadCount = total;
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
//         return d.year == current.year &&
//             d.month == current.month &&
//             d.day == current.day;
//       }).length;
//       total += count;
//       impressionDailyLabels.add(DateFormat("dd MMM").format(current));
//       impressionDailyValues.add(count.toDouble());
//       current = current.add(const Duration(days: 1));
//     }
//     visibleImpressionCount = total;
//   }
//
//   void _generateCustomRangeProfileViews(DateTime start, DateTime end) {
//     profileViewLabels.clear();
//     profileViewValues.clear();
//     int days = end.difference(start).inDays + 1;
//     double perDay = days == 0 ? 0 : profileViewsTotal / days;
//
//     DateTime current = DateTime(start.year, start.month, start.day);
//     int total = 0;
//     while (!current.isAfter(end)) {
//       profileViewLabels.add(DateFormat("dd MMM").format(current));
//       profileViewValues.add(perDay);
//       total += perDay.round();
//       current = current.add(const Duration(days: 1));
//     }
//     visibleProfileViewCount = total;
//   }
//
//   // ==================== Regenerate Charts (Common Logic) ====================
//   void _regenerateAllCharts(String period) {
//     _regenerateLeadsChart(period);
//     _regenerateImpressionsChart(period);
//     _regenerateProfileViewsChart(period);
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
//         return d.year == current.year &&
//             d.month == current.month &&
//             d.day == current.day;
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
//         return d.year == current.year &&
//             d.month == current.month &&
//             d.day == current.day;
//       }).length;
//
//       total += count;
//       impressionDailyLabels.add(label);
//       impressionDailyValues.add(count.toDouble());
//       current = current.add(const Duration(days: 1));
//     }
//     visibleImpressionCount = total;
//   }
//
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
//     int days = end.difference(start).inDays + 1;
//     double perDay = days == 0 ? 0 : profileViewsTotal / days;
//
//     DateTime current = start;
//     int total = 0;
//
//     while (!current.isAfter(end)) {
//       String label = (period == "This Week")
//           ? DateFormat("EEE").format(current)
//           : DateFormat("dd MMM").format(current);
//
//       profileViewLabels.add(label);
//       profileViewValues.add(perDay);
//       total += perDay.round();
//       current = current.add(const Duration(days: 1));
//     }
//
//     visibleProfileViewCount = total;
//   }
//
//   // ==================== API Fetch ====================
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
//         Uri.parse(
//             "https://happywedz.com/api/request-pricing/vendor/dashboard"),
//         headers: {"Authorization": "Bearer $token"},
//       );
//       if (leadRes.statusCode == 200) {
//         apiRequests = jsonDecode(leadRes.body)["requests"] ?? [];
//       }
//
// // Profile Views Total (lifetime)
//       if (vendorId != null) {
//         final pvRes = await http.get(
//           Uri.parse(
//             "https://happywedz.com/api/vendor/profile-views/$vendorId",
//           ),
//           headers: {"Authorization": "Bearer $token"},
//         );
//
//         if (pvRes.statusCode == 200) {
//           final data = jsonDecode(pvRes.body);
//
//           if (data["success"] == true) {
//             profileViewsTotal = (data["totalViews"] ?? 0).toInt();
//           }
//         }
//       }
//
//
//       // Impressions
//       if (vendorId != null) {
//         final impRes = await http.get(
//           Uri.parse(
//               "https://happywedz.com/api/wishlist/vendor/stats/$vendorId"),
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
//       _regenerateAllCharts("This Week");
//
//     } catch (e) {
//       print("Error: $e");
//     }
//
//     setState(() => isLoading = false);
//     _controller.forward();
//   }
//
//   // ==================== UI ====================
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
//               gradient: LinearGradient(
//                   colors: [Color(0xFF003F88), Color(0xFF00509D)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight),
//               boxShadow: [
//                 BoxShadow(
//                     color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
//               ],
//             ),
//             padding: const EdgeInsets.fromLTRB(20, 30, 16, 10),
//             alignment: Alignment.bottomLeft,
//             child: const Text("Statistics",
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.w700)),
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
//                 const SizedBox(height: 20),
//                 _sharedRangeDropdown(), // dropdown
//                 const SizedBox(height: 25),
//                 _sectionHeader("Leads"),
//                 const SizedBox(height: 10),
//                 _animatedChartForLeads(),
//                 const SizedBox(height: 30),
//                 _sectionHeader("Impressions"),
//                 const SizedBox(height: 10),
//                 _animatedChartForImpressions(),
//                 const SizedBox(height: 30),
//                 _sectionHeader("Profile Views"),
//                 const SizedBox(height: 10),
//                 _animatedChartForProfileViews(),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _sharedRangeDropdown() {
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
//               value: selectedPeriod,
//               icon: const Icon(Icons.keyboard_arrow_down),
//               items: periods
//                   .map((e) => DropdownMenuItem(
//                 value: e,
//                 child: Text(e,
//                     style: const TextStyle(fontWeight: FontWeight.w600)),
//               ))
//                   .toList(),
//               onChanged: (value) async {
//                 if (value == null) return;
//
//                 if (value == "Custom Range") {
//                   await _openCustomRangePicker();
//                 } else {
//                   setState(() => selectedPeriod = value);
//                   _regenerateAllCharts(value);
//                 }
//                 _controller.forward(from: 0);
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//   List<dynamic> _getFilteredLeads() {
//     if (selectedPeriod == "Custom Range" && customStartDate != null && customEndDate != null) {
//       return apiRequests.where((req) {
//         DateTime d = DateTime.parse(req["createdAt"]);
//         return !d.isBefore(customStartDate!) && !d.isAfter(customEndDate!);
//       }).toList();
//     }
//
//     DateTime now = DateTime.now();
//     DateTime start;
//     DateTime end;
//
//     if (selectedPeriod == "This Week") {
//       start = now.subtract(Duration(days: now.weekday - 1));
//       end = start.add(const Duration(days: 6));
//     } else if (selectedPeriod == "This Month") {
//       start = DateTime(now.year, now.month, 1);
//       end = DateTime(now.year, now.month + 1, 0);
//     } else if (selectedPeriod == "Last Month") {
//       if (now.month == 1) {
//         start = DateTime(now.year - 1, 12, 1);
//         end = DateTime(now.year - 1, 12, 31);
//       } else {
//         start = DateTime(now.year, now.month - 1, 1);
//         end = DateTime(now.year, now.month, 0);
//       }
//     } else {
//       return apiRequests; // fallback
//     }
//
//     start = DateTime(start.year, start.month, start.day);
//     end = DateTime(end.year, end.month, end.day);
//
//     return apiRequests.where((req) {
//       DateTime d = DateTime.parse(req["createdAt"]);
//       return !d.isBefore(start) && !d.isAfter(end);
//     }).toList();
//   }
//
//   Widget _sectionHeader(String title) =>
//       Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
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
//
//             onTap: () {
//               // Current selected period के अनुसार filtered leads निकालो
//               List<dynamic> filteredLeads = _getFilteredLeads();
//
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => LeadsListScreen(leads: filteredLeads),
//                 ),
//               );
//             },
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _statCard(
//             title: "PROFILE VIEWS",
//             value: profileViewsTotal.toString(), // Lifetime total
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
//   Widget _statCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color iconBg,
//     required Color iconColor,
//     VoidCallback? onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade300),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4))
//           ],
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(value,
//                       style: const TextStyle(
//                           fontSize: 22, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   Text(title,
//                       style: const TextStyle(
//                           fontSize: 12,
//                           color: Colors.black54,
//                           fontWeight: FontWeight.w600)),
//                 ],
//               ),
//             ),
//             Container(
//                 height: 42,
//                 width: 42,
//                 decoration:
//                 BoxDecoration(color: iconBg, shape: BoxShape.circle),
//                 child: Icon(icon, color: iconColor, size: 22)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _animatedChartForLeads() {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 700),
//       child: _chartContainer(
//         dailyLabels,
//         dailyValues,
//         key: ValueKey("leads_$selectedPeriod"),
//       ),
//     );
//   }
//
//   Widget _animatedChartForImpressions() {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 700),
//       child: _chartContainer(
//         impressionDailyLabels,
//         impressionDailyValues,
//         key: ValueKey("impressions_$selectedPeriod"),
//       ),
//     );
//   }
//
//   Widget _animatedChartForProfileViews() {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 700),
//       child: _chartContainer(
//         profileViewLabels,
//         profileViewValues,
//         key: ValueKey("profile_$selectedPeriod"),
//       ),
//     );
//   }
//
//   Widget _chartContainer(
//       List<String> labels,
//       List<double> values, {
//         Key? key,
//       }) {
//     return Container(
//       key: key,
//       padding: const EdgeInsets.symmetric(vertical: 14),
//       decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.shade300),
//           borderRadius: BorderRadius.circular(6)),
//       child: SizedBox(
//         height: 260,
//         child: LineChart(
//           LineChartData(
//             maxY: (values.isEmpty
//                 ? 0
//                 : values.reduce((a, b) => a > b ? a : b)) +
//                 5,
//             minY: 0,
//             lineBarsData: [
//               LineChartBarData(
//                 isCurved: true,
//                 curveSmoothness: 0.25,
//                 spots: List.generate(
//                     values.length, (i) => FlSpot(i.toDouble(), values[i])),
//                 color: const Color(0xFF4682B4),
//                 dotData: FlDotData(show: true),
//                 barWidth: 2.5,
//                 belowBarData: BarAreaData(
//                   show: true,
//                   gradient: LinearGradient(
//                     colors: [
//                       Color(0xFF4682B4).withOpacity(0.35),
//                       Color(0xFF4682B4).withOpacity(0.05)
//                     ],
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
//                         child: Transform.rotate(
//                             angle: -0.7,
//                             child: Text(labels[index],
//                                 style: const TextStyle(fontSize: 11))),
//                       );
//                     }
//                     return const SizedBox();
//                   },
//                 ),
//               ),
//               leftTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 30,
//                       getTitlesWidget: (v, m) =>
//                           Text(v.toInt().toString(),
//                               style: const TextStyle(fontSize: 10)))),
//               topTitles:
//               const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//               rightTitles:
//               const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             ),
//             gridData: FlGridData(
//                 show: true,
//                 horizontalInterval: 5,
//                 drawVerticalLine: false,
//                 getDrawingHorizontalLine: (v) =>
//                     FlLine(color: Colors.grey.shade300, strokeWidth: 0.8)),
//             borderData: FlBorderData(show: false),
//             lineTouchData: LineTouchData(
//               handleBuiltInTouches: true,
//               touchTooltipData: LineTouchTooltipData(
//                 getTooltipItems: (spots) => spots.map((spot) {
//                   int idx = spot.x.toInt();
//                   String label =
//                   (idx >= 0 && idx < labels.length) ? labels[idx] : "";
//                   return LineTooltipItem(
//                     "$label\n${spot.y.toInt()}",
//                     const TextStyle(
//                         color: Colors.black, fontWeight: FontWeight.bold),
//                   );
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
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'new_screens/leads_list_stats.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';
import '../theme/app_colors.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/app_states.dart';
import '../auth/session_manager.dart';
import 'Login.dart';

/// Statistics — mirrors the web vendor dashboard (HomeAdmin.jsx):
/// three stat cards (Leads / Profile Views / Impressions), a shared date
/// filter (All Time, This Week, This Month, Last Month, Custom Range) that is
/// remembered between visits, and one combined "Performance Statistic" chart.
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

enum _CrmFilter { allTime, thisWeek, thisMonth, lastMonth, custom }

extension on _CrmFilter {
  String get key => const {
        _CrmFilter.allTime: 'all_time',
        _CrmFilter.thisWeek: 'this_week',
        _CrmFilter.thisMonth: 'this_month',
        _CrmFilter.lastMonth: 'last_month',
        _CrmFilter.custom: 'custom',
      }[this]!;

  String get label => const {
        _CrmFilter.allTime: 'All Time',
        _CrmFilter.thisWeek: 'This Week',
        _CrmFilter.thisMonth: 'This Month',
        _CrmFilter.lastMonth: 'Last Month',
        _CrmFilter.custom: 'Custom Range',
      }[this]!;
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin {
  // Same persistence idea as the web dashboard ("homeAdmin_filters_v1").
  static const String _filterPrefsKey = 'crm_dashboard_filters_v1';

  static const Color _leadsColor = AppColors.primary;
  static const Color _viewsColor = AppColors.secondary;
  static const Color _impressionsColor = AppColors.accentPink;

  // ---------- Filter ----------
  _CrmFilter _filter = _CrmFilter.allTime;
  DateTime? customStartDate;
  DateTime? customEndDate;

  // ---------- Data ----------
  bool isLoading = true;
  String? _error;
  /// The server rejected the token (401/403): retrying cannot help, the
  /// vendor has to sign in again.
  bool _sessionExpired = false;
  List<dynamic> apiRequests = [];
  List<dynamic> impressionList = [];
  List<dynamic> profileViewsList = [];
  int profileViewsTotal = 0;

  String? token;
  int? vendorId;

  // ---------- Derived (for the selected range) ----------
  List<dynamic> _leadsInRange = [];
  int _viewsInRange = 0;
  int _impressionsInRange = 0;
  List<String> _chartLabels = [];
  List<double> _leadSeries = [];
  List<double> _viewSeries = [];
  List<double> _impressionSeries = [];

  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _restoreFilter();
    await fetchDashboardData();
  }

  // ==================== Filter persistence ====================
  Future<void> _restoreFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_filterPrefsKey);
      if (raw == null) return;
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final saved = _CrmFilter.values.firstWhere(
        (f) => f.key == obj['dateFilter'],
        orElse: () => _CrmFilter.allTime,
      );
      final start = DateTime.tryParse(obj['customStart'] ?? '');
      final end = DateTime.tryParse(obj['customEnd'] ?? '');
      if (saved == _CrmFilter.custom && (start == null || end == null)) return;
      _filter = saved;
      customStartDate = start;
      customEndDate = end;
    } catch (e) {
      debugPrint('Failed to load saved dashboard filters: $e');
    }
  }

  Future<void> _saveFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _filterPrefsKey,
        jsonEncode({
          'dateFilter': _filter.key,
          'customStart': customStartDate?.toIso8601String(),
          'customEnd': customEndDate?.toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Failed to save dashboard filters: $e');
    }
  }

  // Token se vendor ID extract
  int? _resolveVendorIdFromPrefsOrToken(SharedPreferences prefs, String? token) {
    final int? vid = prefs.getInt("vendor_id");
    if (vid != null) return vid;
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = base64Url.decode(normalized);
      final map = jsonDecode(utf8.decode(decoded));
      return (map['id'] ?? map['vendorId'] ?? map['vendor_id'])?.toInt();
    } catch (e) {
      debugPrint("Token decode error: $e");
    }
    return null;
  }

  // ==================== Date helpers ====================
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  /// Same ranges as the web CRM's computeRange(). Returns null for "All Time"
  /// (no bounds) and for a custom range that has not been picked yet.
  DateTimeRange? _currentRange() {
    final now = DateTime.now();
    switch (_filter) {
      case _CrmFilter.thisWeek:
        return DateTimeRange(
          start: _startOfDay(now.subtract(Duration(days: now.weekday - 1))),
          end: _endOfDay(now),
        );
      case _CrmFilter.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: _endOfDay(now),
        );
      case _CrmFilter.lastMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: _endOfDay(DateTime(now.year, now.month, 0)),
        );
      case _CrmFilter.custom:
        if (customStartDate == null || customEndDate == null) return null;
        return DateTimeRange(
          start: _startOfDay(customStartDate!),
          end: _endOfDay(customEndDate!),
        );
      case _CrmFilter.allTime:
        return null;
    }
  }

  List<DateTime> _datesOf(List<dynamic> items, List<String> keys) {
    final dates = <DateTime>[];
    for (final item in items) {
      if (item is! Map) continue;
      for (final k in keys) {
        final d = _parseDate(item[k]);
        if (d != null) {
          dates.add(d);
          break;
        }
      }
    }
    return dates;
  }

  bool _inRange(DateTime d, DateTimeRange? range) =>
      range == null || (!d.isBefore(range.start) && !d.isAfter(range.end));

  // ==================== Recompute for selected filter ====================
  void _recompute() {
    final range = _currentRange();

    _leadsInRange = apiRequests.where((req) {
      final d = req is Map ? _parseDate(req['createdAt']) : null;
      return d != null && _inRange(d, range);
    }).toList();

    final leadDates = _leadsInRange
        .map((r) => _parseDate((r as Map)['createdAt'])!)
        .toList();
    final viewDates = _datesOf(profileViewsList, ['createdAt', 'view_date', 'date'])
        .where((d) => _inRange(d, range))
        .toList();
    final impressionDates = _datesOf(impressionList, ['addedAt', 'createdAt', 'date'])
        .where((d) => _inRange(d, range))
        .toList();

    _viewsInRange = viewDates.length;
    _impressionsInRange = impressionDates.length;

    // Chart window: the selected range, or for All Time the span of the data.
    DateTime start, end;
    if (range != null) {
      start = range.start;
      end = range.end;
    } else {
      final all = [...leadDates, ...viewDates, ...impressionDates];
      end = _endOfDay(DateTime.now());
      start = all.isEmpty
          ? _startOfDay(end.subtract(const Duration(days: 29)))
          : _startOfDay(all.reduce((a, b) => a.isBefore(b) ? a : b));
    }

    // Daily buckets for up to ~2 months, monthly buckets beyond that so the
    // chart stays readable on a phone.
    final spanDays = end.difference(start).inDays + 1;
    final monthly = spanDays > 62;

    final bucketStarts = <DateTime>[];
    if (monthly) {
      var cur = DateTime(start.year, start.month, 1);
      while (!cur.isAfter(end)) {
        bucketStarts.add(cur);
        cur = DateTime(cur.year, cur.month + 1, 1);
      }
    } else {
      var cur = _startOfDay(start);
      while (!cur.isAfter(end)) {
        bucketStarts.add(cur);
        cur = DateTime(cur.year, cur.month, cur.day + 1);
      }
    }

    String keyOf(DateTime d) => monthly
        ? DateFormat('yyyy-MM').format(d)
        : DateFormat('yyyy-MM-dd').format(d);

    List<double> seriesOf(List<DateTime> dates) {
      final counts = <String, int>{};
      for (final d in dates) {
        counts[keyOf(d)] = (counts[keyOf(d)] ?? 0) + 1;
      }
      return bucketStarts.map((b) => (counts[keyOf(b)] ?? 0).toDouble()).toList();
    }

    final labelFormat = monthly
        ? DateFormat('MMM yy')
        : (_filter == _CrmFilter.thisWeek ? DateFormat('EEE') : DateFormat('dd MMM'));
    _chartLabels = bucketStarts.map(labelFormat.format).toList();
    _leadSeries = seriesOf(leadDates);
    _viewSeries = seriesOf(viewDates);
    _impressionSeries = seriesOf(impressionDates);
  }

  void _applyFilter(_CrmFilter filter) {
    setState(() {
      _filter = filter;
      if (filter != _CrmFilter.custom) {
        customStartDate = null;
        customEndDate = null;
      }
      _recompute();
    });
    _saveFilter();
    _controller.forward(from: 0);
  }

  // ==================== Custom Range Picker ====================
  Future<void> _openCustomRangePicker() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: customStartDate != null && customEndDate != null
          ? DateTimeRange(start: customStartDate!, end: customEndDate!)
          : null,
    );
    if (picked == null) return;

    customStartDate = picked.start;
    customEndDate = picked.end;
    _applyFilter(_CrmFilter.custom);
  }

  String get _filterDisplayLabel {
    if (_filter == _CrmFilter.custom &&
        customStartDate != null &&
        customEndDate != null) {
      final f = DateFormat('dd MMM yy');
      return '${f.format(customStartDate!)} – ${f.format(customEndDate!)}';
    }
    return _filter.label;
  }

  // ==================== PDF Report (selected range) ====================
  Future<void> _generateAndShowPdf() async {
    final range = _currentRange();
    final pdf = pw.Document();

    Map<String, int> countByDate(List<DateTime> dates) {
      final sorted = [...dates]..sort();
      final map = <String, int>{};
      for (final d in sorted) {
        final formatted = DateFormat("dd MMM yyyy").format(d);
        map[formatted] = (map[formatted] ?? 0) + 1;
      }
      return map;
    }

    final leadsData = countByDate(_datesOf(_leadsInRange, ['createdAt']));
    final impressionsData = countByDate(
        _datesOf(impressionList, ['addedAt', 'createdAt', 'date'])
            .where((d) => _inRange(d, range))
            .toList());
    final profileViewsData = countByDate(
        _datesOf(profileViewsList, ['createdAt', 'view_date', 'date'])
            .where((d) => _inRange(d, range))
            .toList());

    final rangeText = range == null
        ? "All Time"
        : "${DateFormat("dd MMM yyyy").format(range.start)} - ${DateFormat("dd MMM yyyy").format(range.end)}";

    pw.Widget section(String title, Map<String, int> data) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ["Date", "Count"],
              data: data.entries.map((e) => [e.key, e.value.toString()]).toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 25),
          ],
        );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Center(
            child: pw.Text("Statistics Report",
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 12),
          pw.Center(child: pw.Text(rangeText, style: const pw.TextStyle(fontSize: 16))),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              "Leads: ${_leadsInRange.length}   ·   Profile Views: $_viewsInRange   ·   Impressions: $_impressionsInRange",
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          pw.SizedBox(height: 30),
          if (leadsData.isNotEmpty) section("Leads", leadsData),
          if (impressionsData.isNotEmpty) section("Impressions", impressionsData),
          if (profileViewsData.isNotEmpty) section("Profile Views", profileViewsData),
          if (leadsData.isEmpty && impressionsData.isEmpty && profileViewsData.isEmpty)
            pw.Center(child: pw.Text("No data available in selected range")),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ==================== API Fetch ====================
  Future<void> fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // `token` first, then `authToken`; an empty string counts as missing.
      token = await SessionManager.getToken();
      vendorId = _resolveVendorIdFromPrefsOrToken(prefs, token);

      if (token == null) {
        _sessionExpired = true;
        _error = AppErrorState.messageForStatus(401);
        return;
      }

      final headers = {"Authorization": "Bearer $token"};
      final leadRes = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/request-pricing/vendor/dashboard"),
        headers: headers,
      );
      if (leadRes.statusCode == 200) {
        apiRequests = jsonDecode(leadRes.body)["requests"] ?? [];
      } else {
        debugPrint("Dashboard request failed (${leadRes.statusCode})");
        _sessionExpired = SessionManager.isUnauthorized(leadRes.statusCode);
        _error = AppErrorState.messageForStatus(leadRes.statusCode);
        return;
      }

      if (vendorId != null) {
        try {
          final pvRes = await http.get(
            Uri.parse("${ApiConfig.baseUrl}/vendor/profile-views/$vendorId"),
            headers: headers,
          );
          if (pvRes.statusCode == 200) {
            final data = jsonDecode(pvRes.body);
            if (data["success"] == true) {
              profileViewsTotal = (data["totalViews"] ?? 0);
              profileViewsList = List<dynamic>.from(data["views"] ?? []);
            }
          }
        } catch (e) {
          debugPrint("Failed to fetch profile views: $e");
        }

        try {
          final impRes = await http.get(
            Uri.parse("${ApiConfig.baseUrl}/wishlist/vendor/stats/$vendorId"),
            headers: headers,
          );
          if (impRes.statusCode == 200) {
            final data = jsonDecode(impRes.body);
            if (data["data"] != null && (data["data"] as List).isNotEmpty) {
              impressionList = List<dynamic>.from(data["data"][0]["users"] ?? []);
            }
          }
        } catch (e) {
          debugPrint("Failed to fetch wishlist stats: $e");
        }
      }

      await prefs.setInt("lead_count", apiRequests.length);
      await prefs.setInt("views_count", profileViewsTotal);
      await prefs.setInt("impression_count", impressionList.length);

      _error = null;
      _sessionExpired = false;
      _recompute();
    } catch (e) {
      debugPrint("Error fetching dashboard: $e");
      _error = "Couldn't load your dashboard. Pull down to try again.";
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        _controller.forward(from: 0);
      }
    }
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 30, 8, 10),
            alignment: Alignment.bottomLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Text("Statistics",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700)),
                ),
                if (!isLoading && _error == null)
                  IconButton(
                    tooltip: "Download report",
                    icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
                    onPressed: _generateAndShowPdf,
                  ),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          // A skeleton shaped like the real page instead of a spinner.
          ? const StatsShimmer()
          : RefreshIndicator(
              onRefresh: fetchDashboardData,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Edge to edge (targetSdk 36): the extra bottom keeps the
                  // last item clear of the 3-button navigation bar.
                  padding: EdgeInsets.fromLTRB(
                      14, 16, 14, 16 + MediaQuery.of(context).padding.bottom),
                  children: _error != null
                      ? [_errorView()]
                      : [
                          _statCard(
                            title: "New Users / Leads",
                            value: _leadsInRange.length,
                            subtitle: "Total registered leads",
                            icon: Icons.people_alt_outlined,
                            color: _leadsColor,
                            series: _leadSeries,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LeadsListScreen(
                                  leads: _leadsInRange,
                                  periodLabel: _filterDisplayLabel,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _statCard(
                            title: "Profile Views",
                            value: _viewsInRange,
                            subtitle: "Total storefront views",
                            icon: Icons.storefront_outlined,
                            color: _viewsColor,
                            series: _viewSeries,
                          ),
                          const SizedBox(height: 12),
                          _statCard(
                            title: "Impressions",
                            value: _impressionsInRange,
                            subtitle: "Wishlist saves & discovery reach",
                            icon: Icons.favorite_border,
                            color: _impressionsColor,
                            series: _impressionSeries,
                          ),
                          const SizedBox(height: 20),
                          _performanceCard(),
                        ],
                ),
              ),
            ),
    );
  }

  Widget _errorView() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          if (_sessionExpired)
            ElevatedButton(
              onPressed: () => SessionManager.logout(
                context,
                loginPageBuilder: (_) => const Login(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Log in again"),
            )
          else
            OutlinedButton(
              onPressed: () {
                setState(() => isLoading = true);
                fetchDashboardData();
              },
              child: const Text("Retry"),
            ),
        ],
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _statCard({
    required String title,
    required int value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<double> series,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(NumberFormat.decimalPattern().format(value),
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  SizedBox(width: 110, height: 46, child: _sparkline(series, color)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                  ),
                  if (onTap != null)
                    Row(
                      children: [
                        Text("View all",
                            style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.w600)),
                        Icon(Icons.arrow_forward, size: 14, color: color),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Small trend line built from the real series for the selected range.
  Widget _sparkline(List<double> series, Color color) {
    final data = series.length >= 2 ? series : [0.0, ...series, 0.0];
    final maxY = data.fold<double>(0, math.max);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY * 1.15,
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
            isCurved: true,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _performanceCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Performance Statistic",
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          const Text("Engagement and inquiries overview",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          _filterBar(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _pill("Leads", _leadsInRange.length, Icons.people_alt_outlined, _leadsColor)),
              const SizedBox(width: 8),
              Expanded(child: _pill("Views", _viewsInRange, Icons.storefront_outlined, _viewsColor)),
              const SizedBox(width: 8),
              Expanded(child: _pill("Impressions", _impressionsInRange, Icons.favorite_border, _impressionsColor)),
            ],
          ),
          const SizedBox(height: 20),
          _combinedChart(),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<_CrmFilter>(
            tooltip: "Select frequency",
            onSelected: (f) {
              if (f == _CrmFilter.custom) {
                _openCustomRangePicker();
              } else {
                _applyFilter(f);
              }
            },
            itemBuilder: (_) => _CrmFilter.values
                .map((f) => CheckedPopupMenuItem<_CrmFilter>(
                      value: f,
                      checked: f == _filter,
                      child: Text(f == _CrmFilter.allTime ? "All Data" : f.label),
                    ))
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderStrong),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_filterDisplayLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
          ),
        ),
        if (_filter != _CrmFilter.allTime) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _applyFilter(_CrmFilter.allTime),
            icon: const Icon(Icons.restart_alt, size: 16),
            label: const Text("Reset"),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _pill(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(NumberFormat.compact().format(value),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _combinedChart() {
    final labels = _chartLabels;
    if (labels.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text("No data for this period",
              style: TextStyle(color: AppColors.textTertiary)),
        ),
      );
    }

    final series = [
      (_leadSeries, _leadsColor, "Leads"),
      (_viewSeries, _viewsColor, "Profile Views"),
      (_impressionSeries, _impressionsColor, "Impressions"),
    ];
    final maxVal = series
        .expand((s) => s.$1)
        .fold<double>(0, math.max);
    final maxY = maxVal == 0 ? 5.0 : (maxVal * 1.2).ceilToDouble();
    final yInterval = math.max(1.0, (maxY / 4).ceilToDouble());

    const double pointWidth = 48;
    final chartWidth = math.max(
        MediaQuery.of(context).size.width - 76, labels.length * pointWidth);
    final labelStep = labels.length > 14 ? 2 : 1;

    return Column(
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: series
              .map((s) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: s.$2, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(s.$3,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            key: ValueKey("crm_chart_${_filter.key}_${labels.length}"),
            width: chartWidth,
            height: 260,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                lineBarsData: series
                    .map((s) => LineChartBarData(
                          isCurved: true,
                          curveSmoothness: 0.3,
                          preventCurveOverShooting: true,
                          spots: List.generate(
                              s.$1.length, (i) => FlSpot(i.toDouble(), s.$1[i])),
                          color: s.$2,
                          barWidth: 2.5,
                          dotData: FlDotData(show: labels.length <= 31),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                s.$2.withValues(alpha: 0.18),
                                s.$2.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ))
                    .toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length || index % labelStep != 0) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(labels[index],
                              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: yInterval,
                      getTitlesWidget: (v, m) => Text(v.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: yInterval,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      const FlLine(color: AppColors.divider, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xEB0F172A),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final idx = spot.x.toInt();
                      final s = series[spot.barIndex];
                      final header = spot == spots.first && idx >= 0 && idx < labels.length
                          ? "${labels[idx]}\n"
                          : "";
                      return LineTooltipItem(
                        "$header${s.$3}: ${spot.y.toInt()}",
                        const TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
