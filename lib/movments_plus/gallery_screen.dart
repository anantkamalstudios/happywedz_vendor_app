import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/movments_plus/view_photo.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

/// ================= EVENT MODEL =================
class EventModel {
  final int id;
  final String name;

  EventModel({required this.id, required this.name});

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(id: json['id'], name: json['name']);
  }
}

/// ================= MEDIA MODEL =================
class MediaItem {
  final int id;
  final String collection;
  final String visibility;
  final String s3Key;
  final String fileSizeMb;

  MediaItem({
    required this.id,
    required this.collection,
    required this.visibility,
    required this.s3Key,
    required this.fileSizeMb,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      collection: json['collection'],
      visibility: json['visibility'],
      s3Key: json['s3_key'],
      fileSizeMb: json['file_size_mb'] ?? '0',
    );
  }
}

/// ================= GALLERY SCREEN =================
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<EventModel> events = [];
  EventModel? selectedEvent;

  List<MediaItem> mediaItems = [];
  List<String> collections = [];
  String? selectedCollection;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('authToken');
  }

  /// ================= EVENTS =================
  Future<void> fetchEvents() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/events'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      events = (data['events'] as List)
          .map((e) => EventModel.fromJson(e))
          .toList();
      if (events.isNotEmpty) {
        selectedEvent = null;
      }

      setState(() {});
    }
  }

  /// ================= MEDIA =================
  Future<void> fetchMedia(int eventId) async {
    setState(() => isLoading = true);

    final token = await _getToken();

    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/media?event_id=$eventId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      mediaItems = (data['media'] as List)
          .map((e) => MediaItem.fromJson(e))
          .toList();

      collections = mediaItems.map((e) => e.collection).toSet().toList()
        ..sort();
    }

    setState(() => isLoading = false);
  }

  List<MediaItem> get filteredMedia {
    if (selectedCollection == null) return mediaItems;
    return mediaItems.where((e) => e.collection == selectedCollection).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: 'Gallery'),
      body: Column(
        children: [
          /// EVENT DROPDOWN
          if (events.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<EventModel>(
                value: selectedEvent,
                decoration: InputDecoration(
                  labelText: 'Select Event',
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF00509D),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF00509D),
                      width: 1.6,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                dropdownColor: Colors.white,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF00509D),
                ),
                items: events.map((e) {
                  return DropdownMenuItem<EventModel>(
                    value: e,
                    child: Text(
                      e.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (e) {
                  setState(() {
                    selectedEvent = e;
                    selectedCollection = null;
                  });
                  fetchMedia(e!.id);
                },
              ),
            ),
          if (selectedEvent != null && filteredMedia.isNotEmpty) ...[
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Collections',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            /// COLLECTION FILTER
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip('All', null),
                  ...collections.map((c) => _chip(c, c)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),

          /// GRID
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : selectedEvent == null
                ? _buildSelectEventEmptyState()
                : filteredMedia.isEmpty
                ? _buildNoMediaEmptyState()
                : MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredMedia.length,
                    itemBuilder: (context, index) {
                      final item = filteredMedia[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenGalleryView(
                                mediaList: filteredMedia,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl:
                                    'https://happywedz-s3-bucket.s3.ap-south-1.amazonaws.com/${item.s3Key}',
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.visibility == 'private'
                                        ? Colors.red
                                        : Colors.green,

                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      item.visibility == 'private'
                                          ? Icons.lock
                                          : Icons.public,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.visibility,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                              ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final bool selected = selectedCollection == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF00509D),
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: selected,
        onSelected: (_) {
          setState(() => selectedCollection = value);
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF00509D),
        side: const BorderSide(color: Color(0xFF00509D), width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // pill radius
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        elevation: 0,
        pressElevation: 0,
      ),
    );
  }
}

Widget _buildNoMediaEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.photo_library_outlined,
          size: 72,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        const Text(
          'No Media Found',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'This event does not have any photos yet',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    ),
  );
}

Widget _buildSelectEventEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.folder_open, size: 72, color: Color(0xFF00509D),),
        const SizedBox(height: 16),
        const Text(
          'Select an Event',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Please select an event to view its galleries',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    ),
  );
}





