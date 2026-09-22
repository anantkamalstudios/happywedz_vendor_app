import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';
import '../widgets/app_shimmer.dart';
import '../utils/subcategory_selection.dart';

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

  /// Mirrors the website's Active/Inactive switch, stored as
  /// `attributes.availability_active`. Absent means active — the public
  /// listing reads it the same way (`!== false`) and hides the calendar when
  /// it is off, so the app has to send the flag or a vendor who switched it
  /// off on the website gets switched back on here.
  bool availabilityActive = true;

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

    // _firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    // _lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final now = DateTime.now();

    _firstDay = DateTime(now.year, now.month, now.day); // today
    _lastDay  = DateTime(now.year + 20, 12, 31);        // till year 2045

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

      final attrs = data["attributes"];
      // `!= false` so a missing flag reads as active, matching the website.
      final active =
          (attrs is Map ? attrs["availability_active"] : null) != false;

      final rawSlots = data["attributes"]?["available_slots"];
      // AUDIT FIX: `data["attributes"]?["available_slots"] ?? []` was assigned
      // straight into `List<dynamic>`, which throws a raw TypeError whenever
      // the key holds anything but a list.
      final List<dynamic> apiSlots = rawSlots is List ? rawSlots : const [];

      // AUDIT FIX: `DateTime.parse(e["date"])` threw a FormatException on a
      // null or malformed date, and because this runs inside
      // `didChangeAppLifecycleState` it fired on EVERY app resume — one bad
      // slot row made the calendar unusable until reinstall. Unparseable rows
      // are skipped instead.
      final parsed = <DateTime>{};
      for (final e in apiSlots) {
        final raw = (e is Map) ? e["date"] : null;
        final d = raw == null ? null : DateTime.tryParse(raw.toString());
        if (d != null) parsed.add(_normalize(d));
      }

      if (!mounted) return;
      setState(() {
        availableDays = parsed;
        availabilityActive = active;
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
    attributes["availability_active"] = availabilityActive;

    final body = {
      "vendor_id": vendorId,
      "vendor_subcategory_id": await SubcategorySelection.payloadForPrimary(vendorSubcategoryId),
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
      // AUDIT FIX: context used after an await — guard added.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Slots saved successfully")),
      );
    } else {
      // AUDIT FIX: context used after an await — guard added.
      if (!mounted) return;
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
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }

  // ---------------- UI ----------------
  String _monthName(int month) {
    const months = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    return months[month - 1];
  }

  void _markAllAvailable() {
    final days = validDays; // only current month + future

    setState(() {
      availableDays.addAll(days);
    });
  }

  void _markAllUnavailable() {
    final days = validDays;

    setState(() {
      availableDays.removeAll(days);
    });
  }

  /// The Active/Inactive switch the website shows beside the section heading.
  Widget _activeToggle() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(
              availabilityActive ? Icons.event_available : Icons.event_busy,
              color: availabilityActive
                  ? const Color(0xFF1B5E20)
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    availabilityActive ? "Active" : "Inactive",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    availabilityActive
                        ? "Couples can see your calendar and pick a date."
                        : "Your calendar is hidden from your listing.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: availabilityActive,
              activeThumbColor: const Color(0xFF00509D),
              onChanged: (value) =>
                  setState(() => availabilityActive = value),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown in place of the calendar while the section is switched off, the
  /// same way the website swaps the calendar for a warning.
  Widget _inactiveNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD8A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFED6C02), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Availability & Slots is turned off, so couples won't see a "
              "calendar on your listing. Switch it back on to manage dates.",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Availability & Slots"),
      body: loading
          ? const ListShimmer(itemCount: 6, showAvatar: false, itemHeight: 84)
          : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                children: [
                  _activeToggle(),
                  const SizedBox(height: 16),

                  if (!availabilityActive) _inactiveNotice(),

                  if (availabilityActive) ...[
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
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Text(
                              //   "${_monthName(_focusedDay.month)} ${_focusedDay.year}",
                              //   style: const TextStyle(
                              //     fontSize: 18,
                              //     fontWeight: FontWeight.bold,
                              //   ),
                              // ),

                              PopupMenuButton<String>(
                                color: Colors.white,
                                onSelected: (value) {
                                  if (value == "all_available") {
                                    _markAllAvailable();
                                  } else if (value == "all_unavailable") {
                                    _markAllUnavailable();
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: "all_available",
                                    child: Row(
                                      children: [
                                        Icon(Icons.check, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text("Mark All Available"),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: "all_unavailable",
                                    child: Row(
                                      children: [
                                        Icon(Icons.close, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text("Mark All Unavailable"),
                                      ],
                                    ),
                                  ),
                                ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Actions",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down, // ✅ dropdown icon
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                              ),
                            ],
                          ),

                          TableCalendar(
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
                              leftChevronVisible: true,
                              rightChevronVisible: true,
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
                        ],
                      ),
                    ),
                  ),
                  ],

                  const SizedBox(height: 230),

                ],
                        ),
                      ),
              ),
              // Edge to edge (targetSdk 36): without this the button sits under
              // the 3-button navigation bar.
              SafeArea(
                top: false,
                child: Padding(
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
              ),
            ],
          ),
    );
  }
}
