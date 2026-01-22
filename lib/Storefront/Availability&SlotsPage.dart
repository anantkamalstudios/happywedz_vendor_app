import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';

class SlotsPage extends StatefulWidget {
  const SlotsPage({super.key});

  @override
  State<SlotsPage> createState() => _SlotsPageState();
}

class _SlotsPageState extends State<SlotsPage>
    with WidgetsBindingObserver {
  DateTime _focusedDay = DateTime.now();
  late DateTime _firstDay;
  late DateTime _lastDay;

  Set<DateTime> availableDays = {};

  bool loading = true;
  bool saving = false;

  int? vendorId;
  int? serviceId;
  int? vendorSubcategoryId;
  String? token;

  final VendorServiceApi _vendorApi = VendorServiceApi();

  // ---------------- DATE HELPERS ----------------

  DateTime get todayDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isPastDay(DateTime day) => day.isBefore(todayDate);

  bool _isAvailable(DateTime day) =>
      availableDays.contains(_normalize(day));

  // ---------------- MONTH DAYS ----------------

  // Set<DateTime> _generateTotalMonthDays() => {
  //   for (int i = 1; i <= _lastDay.day; i++)
  //     DateTime(_focusedDay.year, _focusedDay.month, i)
  // };
  Set<DateTime> _generateMonthDays() {
    final first = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final last = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    return {
      for (int i = 0; i < last.day; i++)
        _normalize(DateTime(first.year, first.month, first.day + i))
    };
  }

  // 🔥 ONLY TODAY + FUTURE DAYS
  Set<DateTime> get validDays =>
      _generateMonthDays().where((d) => !d.isBefore(todayDate)).toSet();


  // ---------------- COUNTS ----------------

  int get availableCount =>
      availableDays.where((d) => validDays.contains(d)).length;

  int get unavailableCount =>
      validDays.length - availableCount;

  int get totalValidDays => validDays.length;

  // ---------------- LIFECYCLE ----------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    _lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    _loadCredentialsAndFetch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchVendorSlots();
    }
  }

  // ---------------- API / STORAGE ----------------

  Future<void> _loadCredentialsAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId = prefs.getInt('vendorId');
    token = prefs.getString('token');

    if (vendorId == null || token == null) {
      setState(() => loading = false);
      return;
    }

    await fetchVendorSlots();
    setState(() => loading = false);
  }

  Future<void> fetchVendorSlots() async {
    if (vendorId == null || token == null) return;

    try {
      final data = await _vendorApi.getByVendorId(
        vendorId: vendorId!,
        token: token!,
      );

      if (data == null) return;

      serviceId = data["id"];
      vendorSubcategoryId = data["vendor_subcategory_id"];

      final List<dynamic> apiSlots =
          data["attributes"]?["available_slots"] ?? [];

      setState(() {
        availableDays = apiSlots
            .map<DateTime>(
                (e) => _normalize(DateTime.parse(e["date"])))
            .toSet();
      });

      await _saveLocally();
    } catch (e) {
      debugPrint("❌ Fetch slots error: $e");
    }
  }

  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "slotsData",
      jsonEncode(
        availableDays.map((e) => e.toIso8601String()).toList(),
      ),
    );
  }

  Future<void> _saveToServer() async {
    if (serviceId == null || vendorId == null || token == null) return;

    setState(() => saving = true);

    final latest = await _vendorApi.getByServiceId(
      serviceId: serviceId!,
      token: token!,
    );

    Map<String, dynamic> attributes =
    Map<String, dynamic>.from(latest?["attributes"] ?? {});

    attributes["available_slots"] = availableDays
        .map((d) => {
      "date": d.toIso8601String().split("T")[0],
    })
        .toList();

    final body = {
      "vendor_id": vendorId,
      "vendor_subcategory_id": vendorSubcategoryId,
      "attributes": attributes,
    };

    final success = await _vendorApi.updateService(
      serviceId: serviceId!,
      token: token!,
      body: body,
    );

    if (success) {
      await StorefrontCompletionService.refreshCompletion(
        serviceId: serviceId!,
      );
      await fetchVendorSlots();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Slots saved successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save slots")),
      );
    }

    setState(() => saving = false);
  }

  // ---------------- UI HELPERS ----------------

  Widget _dayBox(int day, Color bg, Color textColor) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        "$day",
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _summaryChip(IconData icon, int count, Color color) {
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(
        "$count",
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Availability & Slots"),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryChip(
                          Icons.check, availableCount, Colors.green),
                      _summaryChip(
                          Icons.close, unavailableCount, Colors.red),
                      _summaryChip(Icons.calendar_today,
                          totalValidDays, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Card(
                    elevation: 4,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(36),
                      child: TableCalendar(
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },

                        firstDay: _firstDay,
                        lastDay: _lastDay,
                        focusedDay: _focusedDay,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronVisible: false,
                          rightChevronVisible: false,
                          headerPadding: EdgeInsets.only(bottom: 4),
                          headerMargin: EdgeInsets.only(bottom: 8),
                        ),
                        enabledDayPredicate: (day) =>
                        !_isPastDay(_normalize(day)),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, _) {
                            final d = _normalize(day);

                            if (_isPastDay(d)) {
                              return _dayBox(
                                d.day,
                                const Color(0xFF424242),
                                const Color(0xFF424242),
                              );
                            }

                            if (_isAvailable(d)) {
                              return _dayBox(
                                d.day,
                                const Color(0xFF1B5E20),
                                Colors.white,
                              );
                            }

                            return _dayBox(
                              d.day,
                              const Color(0xFFB11226),
                              Colors.white,
                            );
                          },
                          todayBuilder: (context, day, _) {
                            final d = _normalize(day);
                            return _dayBox(
                              d.day,
                              const Color(0xFF0D47A1),
                              Colors.white,
                            );
                          },
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          final d = _normalize(selectedDay);
                          if (_isPastDay(d)) return;

                          setState(() {
                            _focusedDay = focusedDay;
                            availableDays.contains(d)
                                ? availableDays.remove(d)
                                : availableDays.add(d);
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 230),

                ],
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : _saveToServer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00509D),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: saving
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text(
                      "Save Availability Details",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
