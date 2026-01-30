import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shimmer/shimmer.dart';

/// ======================= EVENT MODEL =======================
class Event {
  final int id;
  final String name;

  Event({required this.id, required this.name});

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
    );
  }
}
/// ======================= EVENTS SERVICE =======================
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
}
/// ======================= TOKENS SERVICE =======================
class TokensService {
  static Future<List<dynamic>> fetchTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('token') ?? prefs.getString('authToken');
    final vendorId = prefs.getInt('vendorId');

    if (token == null || vendorId == null) {
      throw Exception("Auth data missing");
    }

    final res = await http.get(
      Uri.parse(
          'https://happywedz.com/api/token/vendor/$vendorId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final body = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return body['tokens'] ?? [];
    } else {
      throw Exception("Failed to load tokens");
    }
  }
}
/// ======================= SCREEN =======================
class UploadMediaScreen extends StatefulWidget {
  final String? preselectedEventId;
  final String? preselectedEventName;

  const UploadMediaScreen({Key? key,   this.preselectedEventId,
    this.preselectedEventName,}) : super(key: key);

  @override
  State<UploadMediaScreen> createState() =>
      _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  String? selectedEventId;
  String? selectedToken;
  String collectionName = '';
  String visibility = 'Public';
  double usedMB = 0;
  double limitMB = 0;
  double freeMB = 0;
  double incomingMB = 0;
  String packageName = '';
  double remainingMB = 0;
  int usagePercent = 0;
  bool canUpload = true;
  bool storageWarning = false;
  bool isAnalyticsLoading = false;
  bool isUploading = false;

  late Future<List<Event>> eventsFuture;
  late Future<List<dynamic>> tokensFuture;
  List<dynamic> _filterTokensByVisibility(List<dynamic> tokens) {
    final selectedVisibility = visibility.toLowerCase();
    final now = DateTime.now();

    return tokens.where((t) {
      // 1️⃣ only ACTIVE tokens
      if (t['status']?.toString().toLowerCase() != 'active') {
        return false;
      }

      // 2️⃣ visibility/type match
      if (t['type']?.toString().toLowerCase() != selectedVisibility) {
        return false;
      }

      // 3️⃣ expiry check (optional but safe)
      if (t['expires_at'] != null) {
        final expiry = DateTime.tryParse(t['expires_at']);
        if (expiry != null && expiry.isBefore(now)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // List<dynamic> _filterTokensByVisibility(List<dynamic> tokens) {
  //   final selected = visibility.toLowerCase();
  //
  //   return tokens.where((t) {
  //     final v1 = t['visibility']?.toString().toLowerCase();
  //     final v2 = t['type']?.toString().toLowerCase();
  //
  //     return v1 == selected || v2 == selected;
  //   }).toList();
  // }


  List<Map<String, dynamic>> selectedFiles = [];

  @override
  void initState() {
    super.initState();
    selectedEventId = widget.preselectedEventId;
    eventsFuture = EventsService.fetchEvents();
    tokensFuture = TokensService.fetchTokens();
    fetchDashboardAnalytics();
  }

  Future<void> fetchDashboardAnalytics() async {
    setState(() => isAnalyticsLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('authToken');

    final res = await http.get(
      Uri.parse(
          'https://happywedz.com/api/vendor/dashboard/analytics'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      final pkg = body['package'];
      final usage = body['usage'];

      setState(() {
        packageName = pkg['name'];
        limitMB = (pkg['limitMB'] as num).toDouble();
        usedMB = (pkg['usedMB'] as num).toDouble();
        remainingMB = (pkg['remainingMB'] as num).toDouble();
        usagePercent = pkg['usagePercent'];
        canUpload = usage['canUpload'];
        storageWarning = usage['storageWarning'];
      });
    }

    setState(() => isAnalyticsLoading = false);
  }

  /// ================= FILE PICKER =================
  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media,
    );

    if (result != null) {
      setState(() {
        selectedFiles = result.files.map((f) {
          final mime = lookupMimeType(f.path!);
          return {
            'file': File(f.path!),
            'name': f.name,
            'size':
            "${(f.size / 1024 / 1024).toStringAsFixed(2)} MB",
            'type': mime != null && mime.startsWith('video')
                ? 'video'
                : 'image',
          };
        }).toList();
      });
    }
  }

  /// ================= UPLOAD API =================
  Future<void> uploadMedia() async {
    if (selectedFiles.isEmpty ||
        selectedToken == null ||
        selectedEventId == null) return;

    setState(() => isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final vendorId = prefs.getInt('vendorId');

      final uri = Uri.parse(
          'https://happywedz.com/api/vendor/upload-media');

      final request = http.MultipartRequest('POST', uri);

      request.fields['vendorId'] = vendorId.toString();
      request.fields['event_id'] = selectedEventId!;
      request.fields['collection'] = collectionName;
      request.fields['visibility'] = visibility.toLowerCase();
      request.fields['token'] = selectedToken!;
      for (var f in selectedFiles) {
        final mimeType = lookupMimeType(f['file'].path);

        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            f['file'].path,
            contentType: MediaType.parse(mimeType!),
          ),
        );
      }

      final streamedResponse = await request.send();
      final responseBody =
      await streamedResponse.stream.bytesToString();

      final data = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        await fetchDashboardAnalytics();
        final storage = data['storageInfo'];

        setState(() {
          usedMB = (storage['usedMB'] as num).toDouble();
          incomingMB = (storage['incomingMB'] as num).toDouble();
          limitMB = (storage['limitMB'] as num).toDouble();
          freeMB = limitMB - usedMB;
          packageName = storage['packageName'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media uploaded successfully')),
        );

        setState(() => selectedFiles.clear());
      }

      else {
        throw Exception(responseBody);
      }
    } catch (e) {
      print("❌ UPLOAD ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }


  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: isAnalyticsLoading
          ? const UploadMediaShimmer()
      : SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Event*'),
                        _eventDropdown(),
                      ],
                    ),
                    // _eventDropdown(),
                    const SizedBox(height: 20),
                    _input(
                        'Collection*',
                        Icons.folder_outlined,
                            (v) => collectionName = v),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Visibility*'),
                        _visibilityDropdown(),
                      ],
                    ),

                    // _visibilityDropdown(),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Token*'),
                        _tokenDropdown(),
                      ],
                    ),

                    // _tokenDropdown(),
                    const SizedBox(height: 30),
                    // _uploadPicker(),
                    // const SizedBox(height: 24),
                    if (selectedFiles.isEmpty) ...[
                      _uploadPicker(),
                      const SizedBox(height: 24),
                    ],
                    if (selectedFiles.isNotEmpty)
                      _filesList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= UI PARTS =================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // gradient: const LinearGradient(
        //   colors: [Color(0xFF00509D), Color(0xFF0066CC)],
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // ),
        color: Color(0xFF00509D),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00509D).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // IconButton(
              //   onPressed: () => Navigator.pop(context),
              //   /icon: const Icon(Icons.arrow_back, color: Colors.white),
              //   padding: EdgeInsets.zero,
              //   constraints: const BoxConstraints(),
              // ),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Upload Media',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Select token & upload your files',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStorageInfo(),
        ],
      ),
    );
  }

  Widget _buildStorageStat(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildStorageInfo() {
    if (isAnalyticsLoading) {
      return const LinearProgressIndicator(color: Colors.white);
    }

    final double progress =
    limitMB == 0 ? 0.0 : usedMB / limitMB;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStorageStat(
                'Used',
                '${usedMB.toStringAsFixed(2)} MB',
                Icons.storage,
              ),
              Container(width: 1, height: 30, color: Colors.white30),
              _buildStorageStat(
                'Ramaining',
                '${remainingMB.toStringAsFixed(2)} MB',
                Icons.cloud_done,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor:
              const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Package: $packageName',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
              Text(
                '$usagePercent%',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          if (!canUpload || storageWarning)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Storage almost full',
                style: TextStyle(
                    color: Colors.orangeAccent, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _input(
      String label, IconData icon, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF00509D),),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF00509D), // 🔵 blue border
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF00509D), // 🔵 blue border on focus
                width: 1.6,
              ),
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _eventDropdown() {
    return FutureBuilder<List<Event>>(
      future: eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        if (snapshot.hasError) {
          return const Text('Event load failed');
        }

        final events = snapshot.data ?? [];

        return DropdownButtonFormField<String>(
          // value: selectedEventId,
            value: selectedEventId,
          hint: const Text('Select Event'),
          items: events.map((e) {
            return DropdownMenuItem<String>(
              value: e.id.toString(),
              child: Text(e.name),
            );
          }).toList(),
          onChanged: (v) =>
              setState(() => selectedEventId = v),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF00509D),),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF00509D), // 🔵 blue border
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF00509D), // 🔵 blue border on focus
                width: 1.6,
              ),
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }
  Widget _visibilityDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
      ),
      child: DropdownButtonFormField<String>(
        value: visibility,
        items: ['Public', 'Private']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          setState(() {
            visibility = v!;
            selectedToken = null; // 🔥 reset token
          });
        },
        decoration: InputDecoration(
          // prefixIcon: Icon(Icons.calendar_today),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF00509D), // 🔵 blue border
              width: 1.4,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF00509D), // 🔵 blue border on focus
              width: 1.6,
            ),
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }


  Widget _tokenDropdown() {
    return FutureBuilder<List<dynamic>>(
      future: tokensFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        if (snapshot.hasError) {
          return const Text('Token load failed');
        }

        // final tokens = snapshot.data ?? [];
        final allTokens = snapshot.data ?? [];
        final tokens = _filterTokensByVisibility(allTokens);


        return Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.white, // 🔥 dropdown bg white
          ),
          child: DropdownButtonFormField<String>(
            value: selectedToken,
            hint: const Text('Select Token'),
            items: tokens.map((t) {
              return DropdownMenuItem<String>(
          
                value: t['token'],
                child: Text(
                  t['token'],
                  style: const TextStyle(
                      fontFamily: 'monospace'),
                ),
              );
            }).toList(),
            onChanged: (v) =>
                setState(() => selectedToken = v),

            decoration: InputDecoration(
              prefixIcon: Icon(Icons.vpn_key, color: const Color(0xFF00509D), size: 22),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF00509D), // 🔵 blue border
                  width: 1.4,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF00509D), // 🔵 blue border on focus
                  width: 1.6,
                ),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      },
    );
  }

  Widget _uploadPicker() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: pickFiles,
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
    );
  }


  Widget _filesList() {
    return Column(
      children: [
        ...selectedFiles.map(
              (f) => ListTile(
            leading: Icon(f['type'] == 'image'
                ? Icons.image
                : Icons.videocam),
            title: Text(f['name']),
            subtitle: Text(f['size']),
            trailing: IconButton(
              icon:
              const Icon(Icons.close, color: Colors.red),
              onPressed: () =>
                  setState(() => selectedFiles.remove(f)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isUploading ? null : uploadMedia,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00509D),
              side: const BorderSide(color: Color(0xFF00509D)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isUploading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF00509D),
              ),
            )
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload, size: 18),
                SizedBox(width: 8),
                Text(
                  'Upload File',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

      ],
    );
  }
}

class UploadMediaShimmer extends StatelessWidget {
  const UploadMediaShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerShimmer(),
          const SizedBox(height: 30),

          _labelShimmer(),
          _fieldShimmer(),

          const SizedBox(height: 20),
          _labelShimmer(),
          _fieldShimmer(),

          const SizedBox(height: 20),
          _labelShimmer(),
          _fieldShimmer(),

          const SizedBox(height: 20),
          _labelShimmer(),
          _fieldShimmer(),

          const SizedBox(height: 30),
          _buttonShimmer(),
        ],
      ),
    );
  }

  // ===================== PARTS =====================

  Widget _headerShimmer() {
    return _shimmer(
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _labelShimmer() {
    return _shimmer(
      child: Container(
        height: 14,
        width: 120,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _fieldShimmer() {
    return _shimmer(
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buttonShimmer() {
    return _shimmer(
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
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
