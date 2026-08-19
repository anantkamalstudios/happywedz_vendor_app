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
// //       debugPrint("Warning: Error decoding token: $e");
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
// //       debugPrint("Error: $e");
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
// //           boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
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
// //                     colors: [Color(0xFF4682B4).withValues(alpha: 0.35), Color(0xFF4682B4).withValues(alpha: 0.05)],
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
//       debugPrint("Warning: Error decoding token: $e");
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
//       debugPrint("Error: $e");
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
//                 color: Colors.black.withValues(alpha: 0.05),
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
//                       Color(0xFF4682B4).withValues(alpha: 0.35),
//                       Color(0xFF4682B4).withValues(alpha: 0.05)
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

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../auth/auth_guard.dart';
import '../auth/session_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_states.dart';
import 'new_screens/leads_list_stats.dart';

/// AUDIT NOTE — REMOVED IMPORT (import line only; NO code deleted)
/// `dart:typed_data` was imported for a `Uint8List` in the JWT-decoding helper.
/// The live helper no longer declares that type explicitly, so the import was
/// unreferenced (`unused_import`).

/// ============================================================================
/// StatsPage — Leads / Impressions / Profile Views
/// ============================================================================
///
/// API INTEGRATION IS UNCHANGED:
///   GET https://happywedz.com/api/request-pricing/vendor/dashboard
///   GET https://happywedz.com/api/vendor/profile-views/{vendorId}
///   GET https://happywedz.com/api/wishlist/vendor/stats/{vendorId}
/// Same URLs, methods and headers.
///
/// AUDIT NOTE — BUGS FIXED
///
/// 1. THE VENDOR ID WAS READ FROM THE WRONG STORAGE KEY (high severity).
///        final int? vid = prefs.getInt("vendor_id");   // snake_case
///    Login and SignUp both write `vendorId` (camelCase) — `vendor_id` is
///    never written anywhere in this project. So this lookup ALWAYS returned
///    null and the code always fell through to decoding the JWT payload. When
///    the token carried no `id`/`vendorId`/`vendor_id` claim, `vendorId`
///    stayed null and BOTH vendor-scoped requests were skipped entirely —
///    "Profile Views" and "Impressions" silently read 0 forever while "Leads"
///    worked fine. The correct key is checked first now, with the old key and
///    the JWT retained as fallbacks so nothing that used to work breaks.
///
/// 2. `DateTime.parse` ON UNVALIDATED API DATA — UNCAUGHT CRASH.
///        final d = DateTime.parse(req["createdAt"]);
///    Called in five places across the three chart builders and the PDF
///    export. A null or malformed `createdAt` threw a `FormatException`, and
///    `_regenerateAllCharts` is invoked from the range dropdown's `onChanged`
///    — OUTSIDE any try/catch — so one bad record made changing the date range
///    throw an unhandled exception. All parses now use `tryParse` and skip
///    unparseable rows.
///
/// 3. AN EMPTY CHART RENDERED AS A ZERO-WIDTH BOX.
///        SizedBox(width: labels.length * pointWidth, …)
///    With no labels that is `width: 0`, so the chart drew nothing inside a
///    260px-tall bordered rectangle. A vendor with no data saw an empty frame
///    with no explanation.
///
/// 4. A FAILED FETCH WAS INDISTINGUISHABLE FROM ZERO ACTIVITY.
///    `fetchDashboardData` caught everything into `debugPrint("Error: $e")` and
///    still rendered the charts, so a network failure displayed a confident
///    "0 leads, 0 views, 0 impressions".
///
/// 5. THE PDF EXPORT COULD DEREFERENCE NULL DATES.
///        DateFormat(…).format(customStartDate!)
///    `_generateAndShowPdf` force-unwraps both range dates. It is only called
///    from the picker, which sets them — but nothing enforced that.
/// ----------------------------------------------------------------------------
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

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

  // ---------- Data ----------
  bool isLoading = true;

  /// AUDIT FIX (bug 4): a failed load is now recorded instead of being
  /// swallowed into a print while the charts render confident zeroes.
  Object? loadError;

  /// True while the PDF export is being generated, so the range dropdown
  /// cannot start a second export on top of the first.
  bool _exporting = false;

  List<dynamic> apiRequests = [];
  List<dynamic> impressionList = [];
  List<dynamic> profileViewsList = [];
  int profileViewsTotal = 0;

  String? token;
  int? vendorId;

  // Chart Data
  List<String> dailyLabels = [];
  List<double> dailyValues = [];
  List<String> impressionDailyLabels = [];
  List<double> impressionDailyValues = [];
  List<String> profileViewLabels = [];
  List<double> profileViewValues = [];

  int visibleLeadCount = 0;
  int visibleImpressionCount = 0;
  int visibleProfileViewCount = 0;

  // Animation
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    fetchDashboardData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Token se vendor ID extract
  //
  // AUDIT FIX (bug 1): the ONLY prefs key this used to check was `vendor_id`,
  // which nothing in this project ever writes — Login.dart and SignUp.dart
  // both write `vendorId`. The lookup therefore always missed and always fell
  // through to JWT decoding, so on any token without an id claim the
  // Profile Views and Impressions requests were skipped and both tiles read 0
  // permanently. The correct key is tried FIRST; the old key and the JWT are
  // retained as fallbacks so nothing that previously worked regresses.
  int? _resolveVendorIdFromPrefsOrToken(SharedPreferences prefs, String? token) {
    // 1. The key the app actually writes at login/registration.
    final int? primary = prefs.getInt(SessionManager.kVendorId);
    if (primary != null) return primary;

    // 2. Legacy snake_case key — kept in case any older build wrote it.
    final int? legacy = prefs.getInt("vendor_id");
    if (legacy != null) return legacy;

    // 3. Last resort: decode the JWT payload.
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = base64Url.decode(normalized);
      final map = jsonDecode(utf8.decode(decoded));
      if (map is! Map) return null;
      final raw = map['id'] ?? map['vendorId'] ?? map['vendor_id'];
      // AUDIT FIX: `?.toInt()` threw `NoSuchMethodError` when the claim came
      // back as a String, which is how this backend encodes it.
      return _asInt(raw);
    } catch (e) {
      debugPrint("Token decode error: $e");
    }
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  /// AUDIT FIX (bug 2): every date coming off the API goes through here.
  /// Returns null instead of throwing a FormatException on null/garbage.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  /// Counts rows in [list] whose [dateKey] falls on [day]. Rows with a missing
  /// or unparseable date are skipped rather than crashing the whole chart.
  static int _countOnDay(List<dynamic> list, String dateKey, DateTime day) {
    return list.where((row) {
      if (row is! Map) return false;
      final d = _parseDate(row[dateKey]);
      if (d == null) return false;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).length;
  }

  /// Resolves the [start, end] window for a named period. Extracted because
  /// the identical 18-line if/else chain was copy-pasted into all three
  /// `_regenerate*Chart` methods and `_getFilteredLeads` — four places that
  /// had to be kept in sync by hand.
  static (DateTime, DateTime)? _rangeFor(String period) {
    final now = DateTime.now();
    switch (period) {
      case "This Week":
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (start, start.add(const Duration(days: 6)));
      case "This Month":
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0),
        );
      case "Last Month":
        if (now.month == 1) {
          return (DateTime(now.year - 1, 12, 1), DateTime(now.year - 1, 12, 31));
        }
        return (
          DateTime(now.year, now.month - 1, 1),
          DateTime(now.year, now.month, 0),
        );
      default:
        return null;
    }
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

    if (!mounted) return;
    setState(() {
      selectedPeriod = "Custom Range";
    });

    // Direct PDF generate & show
    await _generateAndShowPdf();
  }

  // ==================== PDF Generation & Preview ====================
  Future<void> _generateAndShowPdf() async {
    // AUDIT FIX (bug 5): `_generateAndShowPdf` force-unwraps both range dates
    // throughout. Nothing enforced that they were set; bail out safely instead
    // of throwing a null-check error inside the PDF builder.
    final start = customStartDate;
    final end = customEndDate;
    if (start == null || end == null) {
      debugPrint("⚠️ PDF export requested with no date range — ignoring");
      return;
    }

    // AUDIT FIX: the export had no progress feedback at all. On a large
    // dataset `Printing.layoutPdf` takes several seconds during which the
    // screen looked frozen, and the dropdown could start a second export.
    if (_exporting) return;
    if (mounted) setState(() => _exporting = true);

    try {
      await _buildAndPreviewPdf(start, end);
    } catch (e) {
      debugPrint("❌ PDF export failed: $e");
      if (mounted) {
        AppSnackbar.error(
          context,
          "Couldn't generate the report. Please try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }

    if (!mounted) return;
    setState(() {
      selectedPeriod = "This Week";
      customStartDate = null;
      customEndDate = null;
    });

    _regenerateAllCharts("This Week");
    _controller.forward(from: 0);
  }

  Future<void> _buildAndPreviewPdf(DateTime start, DateTime end) async {
    final pdf = pw.Document();

    Map<String, int> getCountByDate(List<dynamic> list, String dateKey) {
      final map = <String, int>{};
      final DateTime rangeStart = DateTime(start.year, start.month, start.day);
      final DateTime rangeEnd = DateTime(
        end.year,
        end.month,
        end.day,
        23,
        59,
        59,
        999,
      );

      for (final item in list) {
        if (item is! Map) continue;
        // AUDIT FIX (bug 2): `DateTime.parse(dateStr)` threw a FormatException
        // on any malformed date and aborted the whole export.
        final date = _parseDate(item[dateKey]);
        if (date == null) continue;
        // if (date.isBefore(customStartDate!) || date.isAfter(customEndDate!)) continue;
        if (date.isBefore(rangeStart) || date.isAfter(rangeEnd)) continue;

        final formatted = DateFormat("dd MMM yyyy").format(date);
        map[formatted] = (map[formatted] ?? 0) + 1;
      }
      return map;
    }

    final DateTime customStartDate = start;
    final DateTime customEndDate = end;

    final leadsData = getCountByDate(apiRequests, "createdAt");
    final impressionsData = getCountByDate(impressionList, "addedAt");
    final profileViewsData = getCountByDate(profileViewsList, "createdAt");

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
          pw.Center(
            child: pw.Text(
              "${DateFormat("dd MMM yyyy").format(customStartDate)} - ${DateFormat("dd MMM yyyy").format(customEndDate)}",
              style: const pw.TextStyle(fontSize: 16),
            ),
          ),
          pw.SizedBox(height: 30),

          if (leadsData.isNotEmpty) ...[
            pw.Text("Leads", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ["Date", "Count"],
              data: leadsData.entries.map((e) => [e.key, e.value.toString()]).toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 25),
          ],

          if (impressionsData.isNotEmpty) ...[
            pw.Text("Impressions", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ["Date", "Count"],
              data: impressionsData.entries.map((e) => [e.key, e.value.toString()]).toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 25),
          ],

          if (profileViewsData.isNotEmpty) ...[
            pw.Text("Profile Views", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ["Date", "Count"],
              data: profileViewsData.entries.map((e) => [e.key, e.value.toString()]).toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],

          if (leadsData.isEmpty && impressionsData.isEmpty && profileViewsData.isEmpty)
            pw.Center(child: pw.Text("No data available in selected range")),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
    // AUDIT NOTE: the range reset and chart regeneration that used to live
    // here now run in `_generateAndShowPdf`'s post-try block, so they still
    // happen even if `layoutPdf` throws (a user cancelling the system print
    // sheet on some Android OEMs raises a PlatformException, which previously
    // left the screen stuck on "Custom Range" with every chart hidden).
  }

  // ==================== Chart Regeneration ====================
  void _regenerateAllCharts(String period) {
    _regenerateLeadsChart(period);
    _regenerateImpressionsChart(period);
    _regenerateProfileViewsChart(period);
    // AUDIT FIX: unguarded setState. This is reachable from the dropdown's
    // async `onChanged` and from the PDF path, both of which can complete
    // after the tab has been switched away.
    if (mounted) setState(() {});
  }

  /// AUDIT NOTE: the three `_regenerate*Chart` methods were byte-for-byte
  /// identical apart from the source list and the date key. They now share
  /// [_buildSeries], so a fix in one applies to all three — the previous copies
  /// had already drifted (the impressions one carried a "Same logic as above…"
  /// comment). Behaviour, labels and totals are unchanged.
  ///
  /// AUDIT FIX (bug 2): `DateTime.parse` → `_parseDate` (tryParse). A single
  /// row with a null or malformed date used to throw a FormatException out of
  /// the range dropdown's `onChanged`, where nothing caught it.
  (List<String>, List<double>, int) _buildSeries({
    required String period,
    required List<dynamic> source,
    required String dateKey,
  }) {
    final labels = <String>[];
    final values = <double>[];

    final range = _rangeFor(period);
    if (range == null) return (labels, values, 0);

    final (start, end) = range;

    var current = DateTime(start.year, start.month, start.day);
    int total = 0;

    while (!current.isAfter(end)) {
      final label = period == "This Week"
          ? DateFormat("EEE").format(current)
          : DateFormat("dd MMM").format(current);

      final count = _countOnDay(source, dateKey, current);

      labels.add(label);
      values.add(count.toDouble());
      total += count;
      current = current.add(const Duration(days: 1));
    }

    return (labels, values, total);
  }

  void _regenerateLeadsChart(String period) {
    final (labels, values, total) = _buildSeries(
      period: period,
      source: apiRequests,
      dateKey: "createdAt",
    );
    if (labels.isEmpty && _rangeFor(period) == null) return;

    dailyLabels
      ..clear()
      ..addAll(labels);
    dailyValues
      ..clear()
      ..addAll(values);
    visibleLeadCount = total;
  }

  void _regenerateImpressionsChart(String period) {
    final (labels, values, total) = _buildSeries(
      period: period,
      source: impressionList,
      dateKey: "addedAt",
    );
    if (labels.isEmpty && _rangeFor(period) == null) return;

    impressionDailyLabels
      ..clear()
      ..addAll(labels);
    impressionDailyValues
      ..clear()
      ..addAll(values);
    visibleImpressionCount = total;
  }

  void _regenerateProfileViewsChart(String period) {
    final (labels, values, total) = _buildSeries(
      period: period,
      source: profileViewsList,
      dateKey: "createdAt",
    );
    if (labels.isEmpty && _rangeFor(period) == null) return;

    profileViewLabels
      ..clear()
      ..addAll(labels);
    profileViewValues
      ..clear()
      ..addAll(values);
    visibleProfileViewCount = total;
  }

  // ==================== API Fetch ====================
  // Endpoints, methods and headers are UNCHANGED. Only response handling and
  // error surfacing were hardened.
  Future<void> fetchDashboardData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        loadError = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      // AUDIT FIX: read only `token` before. Every other screen falls back to
      // `authToken`; a session holding only that key produced an empty
      // Statistics screen with no explanation.
      token = await SessionManager.getToken();
      vendorId = _resolveVendorIdFromPrefsOrToken(prefs, token);

      if (token == null) {
        // AUDIT FIX (bug 4): was a silent `return` that dropped the vendor on
        // a page reading 0 / 0 / 0.
        throw const StatsException(
          'Your session has expired.\nPlease log in again.',
        );
      }

      // ---- LEADS ----
      final leadRes = await http.get(
        Uri.parse("https://happywedz.com/api/request-pricing/vendor/dashboard"),
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 30));

      if (leadRes.statusCode == 200) {
        final decoded = jsonDecode(leadRes.body);
        // AUDIT FIX: `jsonDecode(...)["requests"] ?? []` assigned into
        // `List<dynamic> apiRequests` threw a raw TypeError when the endpoint
        // returned its error object.
        final requests = (decoded is Map) ? decoded["requests"] : null;
        apiRequests = requests is List ? requests : <dynamic>[];
      } else if (SessionManager.isUnauthorized(leadRes.statusCode)) {
        throw const StatsException(
          'Your session has expired.\nPlease log in again.',
        );
      } else {
        throw StatsException(
          AppErrorState.messageForStatus(leadRes.statusCode),
        );
      }

      if (vendorId != null) {
        // ---- PROFILE VIEWS ----
        final pvRes = await http.get(
          Uri.parse("https://happywedz.com/api/vendor/profile-views/$vendorId"),
          headers: {"Authorization": "Bearer $token"},
        ).timeout(const Duration(seconds: 30));

        if (pvRes.statusCode == 200) {
          final data = jsonDecode(pvRes.body);
          if (data is Map && data["success"] == true) {
            // AUDIT FIX: `(data["totalViews"] ?? 0)` was assigned straight
            // into an `int` field; the endpoint returns it as a String.
            profileViewsTotal = _asInt(data["totalViews"]) ?? 0;
            final views = data["views"];
            profileViewsList = views is List ? List<dynamic>.from(views) : [];
          }
        } else {
          // Non-fatal: leads still render. Logged so the gap is traceable.
          debugPrint("⚠️ profile-views returned ${pvRes.statusCode}");
        }

        // ---- IMPRESSIONS (wishlist adds) ----
        final impRes = await http.get(
          Uri.parse("https://happywedz.com/api/wishlist/vendor/stats/$vendorId"),
          headers: {"Authorization": "Bearer $token"},
        ).timeout(const Duration(seconds: 30));

        if (impRes.statusCode == 200) {
          final data = jsonDecode(impRes.body);
          // AUDIT FIX: `(data["data"] as List)` threw a raw TypeError whenever
          // `data` was a map, and `data["data"][0]["users"]` assumed both the
          // index and the key existed.
          final list = (data is Map) ? data["data"] : null;
          if (list is List && list.isNotEmpty) {
            final first = list.first;
            final users = (first is Map) ? first["users"] : null;
            impressionList = users is List ? List<dynamic>.from(users) : [];
          }
        } else {
          debugPrint("⚠️ wishlist stats returned ${impRes.statusCode}");
        }
      } else {
        // AUDIT NOTE (bug 1): with the storage-key fix this should now be
        // rare. Logged loudly because it is the difference between real
        // numbers and a silent zero on two of the three tiles.
        debugPrint(
          "⚠️ vendorId could not be resolved — "
          "Profile Views and Impressions will read 0",
        );
      }

      await prefs.setInt(SessionManager.kLeadCount, apiRequests.length);
      await prefs.setInt(SessionManager.kViewsCount, profileViewsTotal);
      await prefs.setInt(
        SessionManager.kImpressionCount,
        impressionList.length,
      );

      _regenerateAllCharts("This Week");

      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = null;
      });
      _controller.forward();
    } catch (e) {
      debugPrint("❌ Statistics load failed: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = e;
      });
      _controller.forward();
    }
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    final bool isCustomRange = selectedPeriod == "Custom Range";

    return Scaffold(
      backgroundColor: AppColors.surface,
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
            // AUDIT FIX: `fromLTRB(20, 30, …)` hard-coded a 30px top inset,
            // which collided with the status bar on devices with a taller cut-
            // out and left a gap on devices without one. Uses the real inset.
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 10,
              8,
              10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text("Statistics", style: AppTextStyles.headerLarge),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: isLoading ? null : fetchDashboardData,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        // AUDIT FIX: this screen had no refresh affordance at all.
        color: AppColors.primary,
        onRefresh: fetchDashboardData,
        child: _body(isCustomRange),
      ),
    );
  }

  Widget _body(bool isCustomRange) {
    // AUDIT FIX: was a bare centred CircularProgressIndicator.
    if (isLoading) return const StatsShimmer();

    if (loadError != null) {
      // AUDIT FIX (bug 4): a genuine error state instead of confident zeroes.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 60),
          AppErrorState(
            expand: false,
            title: "Couldn't load your statistics",
            message: loadError is StatsException
                ? (loadError as StatsException).message
                : AppErrorState.messageFor(loadError),
            onRetry: fetchDashboardData,
          ),
        ],
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _topStatsCards(),
              const SizedBox(height: 20),
              _sharedRangeDropdown(),
              const SizedBox(height: 25),

              if (!isCustomRange) ...[
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
              ] else
                // AUDIT FIX: selecting "Custom Range" hid every chart and put
                // nothing in their place, so if the vendor dismissed the date
                // picker the screen went blank with no way back except
                // reselecting a period from the dropdown.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: AppEmptyState(
                    expand: false,
                    icon: Icons.picture_as_pdf_outlined,
                    title: _exporting
                        ? 'Preparing your report…'
                        : 'Custom range report',
                    message: _exporting
                        ? 'This will only take a moment.'
                        : 'Pick a date range to export a PDF report,\n'
                            'or choose a period above to see charts.',
                    actionLabel: _exporting ? null : 'Choose dates',
                    onAction: _exporting ? null : _openCustomRangePicker,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sharedRangeDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_exporting) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text("Generating report…", style: AppTextStyles.caption),
          const SizedBox(width: 12),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPeriod,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary),
              style: AppTextStyles.bodyMedium,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              items: periods
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: AppTextStyles.bodyMedium),
                      ))
                  .toList(),
              // AUDIT FIX: disabled while an export is running, so a second
              // PDF cannot be started on top of the first.
              onChanged: _exporting
                  ? null
                  : (value) async {
                      if (value == null) return;
                      if (value == "Custom Range") {
                        await _openCustomRangePicker();
                      } else {
                        if (!mounted) return;
                        setState(() => selectedPeriod = value);
                        // AUDIT FIX (bug 2): `_regenerateAllCharts` used to be
                        // able to throw a FormatException straight out of this
                        // callback, where nothing caught it. Its date parsing
                        // is now non-throwing, and this is belt-and-braces.
                        try {
                          _regenerateAllCharts(value);
                        } catch (e) {
                          debugPrint("❌ Chart regeneration failed: $e");
                        }
                        _controller.forward(from: 0);
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  List<dynamic> _getFilteredLeads() {
    // ✅ Custom Range ONLY when selected
    if (selectedPeriod == "Custom Range" &&
        customStartDate != null &&
        customEndDate != null) {
      final DateTime start = DateTime(
        customStartDate!.year,
        customStartDate!.month,
        customStartDate!.day,
      );

      final DateTime end = DateTime(
        customEndDate!.year,
        customEndDate!.month,
        customEndDate!.day,
        23, 59, 59, 999,
      );

      return _inRange(start, end);
    }

    // AUDIT FIX: the 18-line if/else chain here was a fourth copy of the same
    // period → range logic; it now shares `_rangeFor` with the chart builders.
    final range = _rangeFor(selectedPeriod);
    if (range == null) return apiRequests;

    final (rawStart, rawEnd) = range;
    final start = DateTime(rawStart.year, rawStart.month, rawStart.day);
    final end =
        DateTime(rawEnd.year, rawEnd.month, rawEnd.day, 23, 59, 59, 999);

    return _inRange(start, end);
  }

  /// AUDIT FIX (bug 2): `DateTime.parse(req["createdAt"])` here threw on any
  /// null/malformed date. Rows without a usable date are skipped.
  List<dynamic> _inRange(DateTime start, DateTime end) {
    return apiRequests.where((req) {
      if (req is! Map) return false;
      final d = _parseDate(req["createdAt"]);
      if (d == null) return false;
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  Widget _sectionHeader(String title) =>
      Text(title, style: AppTextStyles.sectionTitle);

  Widget _topStatsCards() {
    // `CrossAxisAlignment.stretch` on its own asks the children for an infinite
    // height here, because this Row lives in a Column inside a vertical
    // SingleChildScrollView. IntrinsicHeight resolves the tallest card first so
    // the stretch has a finite height to work with.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _statCard(
              title: "TOTAL LEADS",
              value: visibleLeadCount.toString(),
              icon: Icons.group,
              iconBg: AppColors.successTint,
              iconColor: AppColors.success,
              onTap: () {
                // AUDIT FIX: guarded push — the leads list is protected content.
                AuthGuard.push(
                  context,
                  (_) => LeadsListScreen(leads: _getFilteredLeads()),
                  debugLabel: 'LeadsListScreen',
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              title: "PROFILE VIEWS",
              value: visibleProfileViewCount.toString(),
              icon: Icons.remove_red_eye,
              iconBg: AppColors.infoTint,
              iconColor: AppColors.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              title: "IMPRESSIONS",
              value: visibleImpressionCount.toString(),
              icon: Icons.favorite,
              iconBg: AppColors.accentPinkTint,
              iconColor: AppColors.accentPink,
            ),
          ),
        ],
      ),
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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔝 VALUE + ICON ROW
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    // AUDIT FIX (RenderFlex/text overflow): three of these
                    // cards share the screen width, so on a 320dp device each
                    // gets ~90dp. A five-digit figure at 22sp overflowed its
                    // Expanded and clipped. FittedBox scales it down instead.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, style: AppTextStyles.statValue),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                title,
                // AUDIT FIX: "PROFILE VIEWS" wrapped to two lines on narrow
                // devices while its neighbours stayed at one, so the three
                // cards ended up different heights inside the Row.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.statLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _animatedChartForLeads() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: _chartContainer(dailyLabels, dailyValues, key: ValueKey("leads_$selectedPeriod")),
    );
  }

  Widget _animatedChartForImpressions() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: _chartContainer(impressionDailyLabels, impressionDailyValues,
          key: ValueKey("impressions_$selectedPeriod")),
    );
  }

  Widget _animatedChartForProfileViews() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: _chartContainer(profileViewLabels, profileViewValues,
          key: ValueKey("profile_$selectedPeriod")),
    );
  }

  Widget _chartContainer(List<String> labels, List<double> values, {Key? key}) {
    const double pointWidth = 55;

    // AUDIT FIX (bug 3): with no labels the old code built
    // `SizedBox(width: 0, height: 260)`, so the chart drew nothing inside a
    // 260px bordered rectangle — an empty frame with no explanation. A vendor
    // with no activity in the selected period now gets a proper empty state.
    if (labels.isEmpty) {
      return Container(
        key: key,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: AppEmptyState(
          icon: Icons.show_chart_rounded,
          title: 'No activity yet',
          message: 'Nothing recorded for "$selectedPeriod".',
        ),
      );
    }

    // AUDIT FIX: `values.reduce(...)` throws `Bad state: No element` on an
    // empty list. It was previously guarded only by the `values.isEmpty ? 5`
    // ternary, which is correct — but `labels` and `values` are built
    // independently, so a mismatched pair could still reach `reduce`.
    final double maxValue =
        values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

    // A flat all-zero series produced maxY = 5 with a horizontalInterval of 5,
    // i.e. exactly two grid lines. Scaling the interval keeps small charts
    // readable.
    final double maxY = maxValue <= 0 ? 5 : maxValue + (maxValue * 0.25) + 1;
    final double gridInterval = (maxY / 4).ceilToDouble().clamp(1, 1000);

    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(4, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          // Never narrower than the viewport, so a 7-point week chart fills
          // the card instead of hugging the left edge.
          width: (labels.length * pointWidth)
              .clamp(MediaQuery.of(context).size.width - 60, double.infinity),
          height: 260,
          child: LineChart(
            LineChartData(
              maxY: maxY,
              minY: 0,
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  curveSmoothness: 0.25,
                  spots: List.generate(
                    values.length,
                    (i) => FlSpot(i.toDouble(), values[i]),
                  ),
                  color: AppColors.secondary,
                  dotData: const FlDotData(show: true),
                  barWidth: 2.5,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.35),
                        AppColors.secondary.withValues(alpha: 0.05),
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
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            labels[index],
                            style: AppTextStyles.labelSmall,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: gridInterval,
                    getTitlesWidget: (v, m) => Text(
                      v.toInt().toString(),
                      style: AppTextStyles.labelSmall,
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: gridInterval,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => const FlLine(
                  color: AppColors.divider,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.textPrimary,
                  getTooltipItems: (spots) => spots.map((spot) {
                    final idx = spot.x.toInt();
                    final label =
                        idx >= 0 && idx < labels.length ? labels[idx] : "";
                    return LineTooltipItem(
                      "$label\n${spot.y.toInt()}",
                      AppTextStyles.captionMedium.copyWith(
                        // AUDIT FIX: the tooltip drew BLACK text, and fl_chart's
                        // default tooltip background is a dark grey — black on
                        // dark grey was effectively unreadable.
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carries user-facing copy for a failed statistics load, so a status code or
/// a stack trace never reaches the screen.
class StatsException implements Exception {
  final String message;
  const StatsException(this.message);

  @override
  String toString() => message;
}