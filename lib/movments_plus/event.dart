import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/movments_plus/upload_screen.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'bottom_bar.dart';








/// ======================= MODEL =======================
class Event {
  final int id;
  final String name;
  final DateTime date;
  final String venue;
  bool hasMedia;

  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.venue,
    this.hasMedia = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['event_date']),
      venue: json['venue'],
    );
  }
}

/// ======================= SERVICE =======================

class EventsService {
  static const _url = 'https://happywedz.com/api/events';

  static Future<List<Event>> fetchEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('authToken');

    final res = await http.get(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final body = jsonDecode(res.body);

    if (res.statusCode == 200 && body['success'] == true) {
      return (body['events'] as List)
          .map((e) => Event.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load events");
    }
  }

  static Future<void> createEvent({
    required String name,
    required DateTime date,
    required String venue,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('authToken');
    debugPrint("📤 CREATE EVENT API CALLED");
    debugPrint("🔑 Token: $token");

    final res = await http.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "name": name,
        "event_date": date.toIso8601String().split('T').first,
        "venue": venue,
      }),
    );

    debugPrint("📥 Status Code: ${res.statusCode}");
    debugPrint("📥 Raw Response: ${res.body}");
    final body = jsonDecode(res.body);
    debugPrint("📥 Parsed Response: $body");

    if ((res.statusCode != 200 && res.statusCode != 201) || body['success'] != true) {
      throw Exception(body['message'] ?? "Create failed");
    }
  }
}

/// ======================= PAGE =======================

class EventsManagementPage extends StatefulWidget {
  const EventsManagementPage({super.key});

  @override
  State<EventsManagementPage> createState() => _EventsManagementPageState();
}

class _EventsManagementPageState extends State<EventsManagementPage> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All Events', 'Upcoming', 'Past', 'This Month'];

  List<Event> events = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final data = await EventsService.fetchEvents();
      setState(() {
        events = data;
        loading = false;
      });
    } catch (e) {
      loading = false;
    }
  }

  List<Event> get filteredEvents {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 1:
        return events.where((e) => e.date.isAfter(now)).toList();
      case 2:
        return events.where((e) => e.date.isBefore(now)).toList();
      case 3:
        return events
            .where((e) => e.date.year == now.year && e.date.month == now.month)
            .toList();
      default:
        return events;
    }
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return CreateEventDialog(
          onEventCreated: _loadEvents,
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CommonAppBar(title: 'Events Management'),
      body: loading
          ?  EventsShimmer()
          : Column(
        children: [
          _buildStatsSection(),
          _buildFilterChips(),
          Expanded(
            child: filteredEvents.isEmpty
                ? _buildNoEvents()
                : (isMobile
                ? _buildMobileLayout(filteredEvents)
                : _buildDesktopLayout(filteredEvents)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEventDialog,
        backgroundColor: const Color(0xFF00509D),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text(
          'Create Event',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// ======================= UI (UNCHANGED) =======================

  Widget _buildStatsSection() {
    final now = DateTime.now();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _stat('Total Events', events.length, Icons.event, const Color(0xFF00509D)),
              const SizedBox(width: 12),
              _stat(
                'Upcoming',
                events.where((e) => e.date.isAfter(now)).length,
                Icons.calendar_today,
                const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(
                'With Media',
                events.where((e) => e.hasMedia).length,
                Icons.photo_library,
                const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 12),
              _stat(
                'This Month',
                events.where((e) => e.date.month == now.month).length,
                Icons.date_range,
                const Color(0xFF00509D),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(_filters[i]),
            selected: _selectedFilter == i,
            onSelected: (_) => setState(() => _selectedFilter = i),
            labelStyle: TextStyle(
              color: _selectedFilter == i ? Colors.white : const Color(0xFF00509D),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            selectedColor: const Color(0xFF00509D),
            backgroundColor: Colors.white,
            side: BorderSide(color: const Color(0xFF00509D).withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildNoEvents() {
    return const Center(child: Text("No events found"));
  }

  Widget _buildMobileLayout(List<Event> list) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _eventCard(list[i]),
    );
  }

  Widget _buildDesktopLayout(List<Event> list) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        children: list.map(_eventCard).toList(),
      ),
    );
  }

  Widget _eventCard(Event e) {
    return SizedBox(
      width: 350,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= HEADER =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      e.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00509D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Text(
                      '#${e.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF00509D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// ================= DATE =================
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMMM dd, yyyy').format(e.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// ================= VENUE =================
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    e.venue,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// ================= BUTTON =================
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  // onPressed: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (_) => UploadMediaScreen(
                  //         preselectedEventId: e.id.toString(),
                  //         preselectedEventName: e.name,
                  //       ),
                  //     ),
                  //   );
                  // },
                  // onPressed: () {
                  //   MainHomeScreen.of(context)?.openUploadFromEvent(
                  //     eventId: e.id.toString(),
                  //     eventName: e.name,
                  //   );
                  // },
                  onPressed: () {
                    MainHomeScreen.of(context)?.openUpload(
                      eventId: e.id.toString(),
                      eventName: e.name,
                    );
                  },



                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Upload Media'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00509D),
                    side: const BorderSide(color: Color(0xFF00509D)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/// ======================= CREATE DIALOG (DICTO UI) =======================
class CreateEventDialog extends StatefulWidget {
  final VoidCallback onEventCreated;

  const CreateEventDialog({
    super.key,
    required this.onEventCreated,
  });

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  DateTime? _selectedDate;
  bool _submitting = false; // ✅ NEW


  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  // ======================= DATE PICKER =======================

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00509D),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

 // ======================= SUBMIT =======================
   Future<void> _submit() async {
    if (_submitting) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select event date")),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await EventsService.createEvent(
        name: _nameController.text.trim(),
        date: _selectedDate!,
        venue: _venueController.text.trim(),
      );

      if (!mounted) return;
      widget.onEventCreated();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Event created successfully"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.antiAlias, // 🔥 IMPORTANT
        backgroundColor: Colors.white,
        elevation: 20, // 🔥 IMPORTANT
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material( // 🔥 WRAP WITH MATERIAL
          color: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 24),

                  _label("Event Name *"),
                  _textField(
                    controller: _nameController,
                    hint: "e.g. pratham weds Diksha",
                  ),

                  const SizedBox(height: 20),

                  _label("Event Date *"),
                  _dateField(),

                  const SizedBox(height: 20),

                  _label("Venue *"),
                  _textField(
                    controller: _venueController,
                    hint: "e.g. Taj Palace",
                  ),

                  const SizedBox(height: 32),

                  _actions(),
                ],
              ),
            ),
          ),
        ),
      ),
        )
    );
  }

  // ======================= COMPONENTS =======================

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Create New Event",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      validator: (value) =>
      value == null || value.trim().isEmpty ? "This field is required" : null,
      decoration: _inputDecoration(hint),
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedDate == null
                ? Colors.grey.shade300
                : const Color(0xFF00509D),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null
                  ? "MM/DD/YYYY"
                  : DateFormat('MM/dd/yyyy').format(_selectedDate!),
              style: TextStyle(
                color: _selectedDate == null
                    ? Colors.grey[400]
                    : Colors.grey[900],
                fontSize: 16,
              ),
            ),
            Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00509D),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _submitting
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text(
            "Create Event",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00509D)),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}


/// ======================= SHIMMER PLACEHOLDER =======================

class EventsShimmer extends StatelessWidget {
  const EventsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 🔹 STATS SHIMMER
          Row(
            children: [
              Expanded(child: _statCard()),
              const SizedBox(width: 12),
              Expanded(child: _statCard()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard()),
              const SizedBox(width: 12),
              Expanded(child: _statCard()),
            ],
          ),

          const SizedBox(height: 20),

          // 🔹 FILTER CHIPS
          _chipRow(),

          const SizedBox(height: 20),

          // 🔹 EVENT CARDS
          if (isMobile) ...List.generate(4, (_) => _eventCard())
          else
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: List.generate(6, (_) => _eventCard()),
            ),
        ],
      ),
    );
  }

  // ======================= SHIMMER PARTS =======================

  Widget _statCard() {
    return _shimmer(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _chipRow() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => _shimmer(
          child: Container(
            width: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _eventCard() {
    return _shimmer(
      child: Container(
        width: 350,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(width: 180, height: 16),
            const SizedBox(height: 12),
            _line(width: 140),
            const SizedBox(height: 8),
            _line(width: 200),
            const SizedBox(height: 20),
            _line(width: double.infinity, height: 36),
          ],
        ),
      ),
    );
  }

  Widget _line({double width = 120, double height = 12}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _shimmer({required Widget child}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: child,
    );
  }
}
