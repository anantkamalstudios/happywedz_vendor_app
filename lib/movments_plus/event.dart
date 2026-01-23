import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';
import 'package:intl/intl.dart';


class Event {
  final String id;
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
}

class EventsManagementPage extends StatefulWidget {
  const EventsManagementPage({Key? key}) : super(key: key);

  @override
  State<EventsManagementPage> createState() => _EventsManagementPageState();
}

class _EventsManagementPageState extends State<EventsManagementPage> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All Events', 'Upcoming', 'Past', 'This Month'];

  List<Event> events = [
    Event(
      id: '#3',
      name: 'sample',
      date: DateTime(2026, 1, 28),
      venue: 'Express NN',
    ),
    Event(
      id: '#2',
      name: 'rimesh wedz disha',
      date: DateTime(2026, 1, 19),
      venue: 'Taj Palace',
    ),
    Event(
      id: '#1',
      name: 'prathames wedz disha patani',
      date: DateTime(2026, 1, 19),
      venue: 'Taj Palace',
    ),
  ];

  List<Event> get filteredEvents {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 1: // Upcoming
        return events.where((e) => e.date.isAfter(now)).toList();
      case 2: // Past
        return events.where((e) => e.date.isBefore(now)).toList();
      case 3: // This Month
        return events.where((e) =>
        e.date.year == now.year && e.date.month == now.month
        ).toList();
      default:
        return events;
    }
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateEventDialog(
        onEventCreated: (event) {
          setState(() {
            events.insert(0, event);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final displayEvents = filteredEvents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CommonAppBar(title: 'Events Management'),
      body: Column(
        children: [
          _buildStatsSection(isMobile),
          _buildFilterChips(),
          Expanded(
            child: displayEvents.isEmpty
                ? _buildNoEvents()
                : (isMobile
                ? _buildMobileLayout(displayEvents)
                : _buildDesktopLayout(displayEvents)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEventDialog,
        backgroundColor: const Color(0xFF00509D),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: Text(
          isMobile ? 'Create' : 'Create Event',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isMobile) {
    final totalEvents = events.length;
    final upcomingEvents = events.where((e) => e.date.isAfter(DateTime.now())).length;
    final withMedia = events.where((e) => e.hasMedia).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Events',
                  totalEvents.toString(),
                  Icons.event,
                  const Color(0xFF00509D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Upcoming',
                  upcomingEvents.toString(),
                  Icons.calendar_today,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'With Media',
                  withMedia.toString(),
                  Icons.photo_library,
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'This Month',
                  events.where((e) {
                    final now = DateTime.now();
                    return e.date.year == now.year && e.date.month == now.month;
                  }).length.toString(),
                  Icons.date_range,
                  const Color(0xFF00509D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
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
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_filters[index]),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = index),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF00509D),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF00509D),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF00509D)
                    : const Color(0xFF00509D).withOpacity(0.3),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoEvents() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            "No events found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Create an event to get started",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(List<Event> displayEvents) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayEvents.length,
      itemBuilder: (context, index) {
        return _buildMobileEventCard(displayEvents[index]);
      },
    );
  }

  Widget _buildDesktopLayout(List<Event> displayEvents) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          children: displayEvents.map((event) => _buildDesktopEventCard(event)).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00509D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Text(
                    event.id,
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
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMMM dd, yyyy').format(event.date),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  event.venue,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
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
    );
  }

  Widget _buildDesktopEventCard(Event event) {
    return SizedBox(
      width: 350,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00509D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Text(
                      event.id,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF00509D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMMM dd, yyyy').format(event.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    event.venue,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Upload Media'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00509D),
                    side: const BorderSide(color: Color(0xFF00509D)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

class CreateEventDialog extends StatefulWidget {
  final void Function(Event event) onEventCreated;

  const CreateEventDialog({
    super.key,
    required this.onEventCreated,
  });

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();

  final _eventNameController = TextEditingController();
  final _venueController = TextEditingController();

  DateTime? _selectedDate;

  // ======================= LIFECYCLE =======================

  @override
  void dispose() {
    _eventNameController.dispose();
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

  // ======================= CREATE EVENT =======================

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select event date")),
      );
      return;
    }

    final event = Event(
      id: '#${DateTime.now().millisecondsSinceEpoch % 10000}',
      name: _eventNameController.text.trim(),
      date: _selectedDate!,
      venue: _venueController.text.trim(),
    );

    widget.onEventCreated(event);
    Navigator.pop(context);
  }

  // ======================= UI =======================

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                    controller: _eventNameController,
                    hint: "e.g. Rimesh weds Disha",
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
          onPressed: () => Navigator.pop(context),
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
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00509D),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
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

  // ======================= STYLES =======================

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
