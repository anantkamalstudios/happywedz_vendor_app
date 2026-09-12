import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shimmer/shimmer.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

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
  static const _url = '${ApiConfig.baseUrl}/events';

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
          '${ApiConfig.baseUrl}/token/vendor/$vendorId'),
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

  const UploadMediaScreen({super.key,   this.preselectedEventId,
    this.preselectedEventName,});

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


  bool get canSubmitUpload {
    return selectedEventId != null &&
        selectedToken != null &&
        collectionName.trim().isNotEmpty &&
        selectedFiles.isNotEmpty &&
        !isUploading;
  }

  late Future<List<Event>> eventsFuture;
  late Future<List<dynamic>> tokensFuture;
  /// The website's Token dropdown lists every active, non-expired token
  /// regardless of the selected Visibility — it does not cross-filter by
  /// type. Kept as a method name for minimal diff even though it no longer
  /// filters on `visibility`.
  List<dynamic> _filterTokensByVisibility(List<dynamic> tokens) {
    final now = DateTime.now();

    return tokens.where((t) {
      // 1️⃣ only ACTIVE tokens
      if (t['status']?.toString().toLowerCase() != 'active') {
        return false;
      }

      // 2️⃣ expiry check (optional but safe)
      if (t['expires_at'] != null) {
        final expiry = DateTime.tryParse(t['expires_at']);
        if (expiry != null && expiry.isBefore(now)) {
          return false;
        }
      }

      return true;
    }).toList();
  }


  List<Map<String, dynamic>> selectedFiles = [];

  @override
  void didUpdateWidget(covariant UploadMediaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.preselectedEventId != oldWidget.preselectedEventId) {
      setState(() {
        selectedEventId = widget.preselectedEventId;
      });
    }
  }

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
          '${ApiConfig.baseUrl}/vendor/dashboard/analytics'),
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
        final existingPaths =
        selectedFiles.map((f) => (f['file'] as File).path).toSet();

        final newFiles = result.files
            .where((f) => !existingPaths.contains(f.path))
            .map((f) {
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
        });

        selectedFiles = [...selectedFiles, ...newFiles];
      });
    }
  }

  /// ================= UPLOAD API =================
  Future<void> uploadMedia() async {
    if (selectedFiles.isEmpty ||
        selectedToken == null ||
        selectedEventId == null) {
      return;
    }

    setState(() => isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final vendorId = prefs.getInt('vendorId');
      final authToken =
          prefs.getString('token') ?? prefs.getString('authToken');
      debugPrint("👤 Vendor IDddddddddddddddddddddddddddddddddddddddd: $vendorId");
      debugPrint("🔑 AUTH TOKENnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn: $authToken");
      debugPrint("📦 Selected Event IDddddddddddddddddddddddddddddddddd: $selectedEventId");
      debugPrint("🎟 Selected Tokennnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn: $selectedToken");
      final uri =
      Uri.parse('${ApiConfig.baseUrl}/vendor/upload-media');

      final request = http.MultipartRequest('POST', uri);

      /// ✅ HEADERS (IMPORTANT)
      request.headers.addAll({
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      });

      /// ✅ FIELDS
      request.fields['vendorId'] = vendorId.toString();
      request.fields['event_id'] = selectedEventId!;
      request.fields['collection'] = collectionName;
      request.fields['visibility'] = visibility.toLowerCase();
      request.fields['token'] = selectedToken!;

      /// ✅ FILES
      for (var f in selectedFiles) {
        final mimeType = lookupMimeType(f['file'].path) ?? 'image/jpeg';

        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            f['file'].path,
            contentType: MediaType.parse(mimeType),
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
        // final storage = data['storageInfo'];
        //
        // setState(() {
        //   usedMB = (storage['usedMB'] as num).toDouble();
        //   incomingMB = (storage['incomingMB'] as num).toDouble();
        //   limitMB = (storage['limitMB'] as num).toDouble();
        //   freeMB = limitMB - usedMB;
        //   packageName = storage['packageName'];
        // });
        // AUDIT FIX: context used after an await — guard added.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media uploaded successfully')),
        );
        setState(() => selectedFiles.clear());
      } else {
        throw Exception(data['message'] ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint("❌ UPLOAD ERROR: $e");
      // AUDIT FIX: context used after an await — guard added.
      if (!mounted) return;
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
                    _label('Select a Token to Upload'),
                    _tokenQuickPickList(),
                    const SizedBox(height: 24),
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
                    _uploadPicker(),
                    if (selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _filesList(),
                    ],
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
            color: const Color(0xFF00509D).withValues(alpha: 0.3),
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
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
              backgroundColor: Colors.white.withValues(alpha: 0.3),
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
            initialValue: selectedEventId,
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
        initialValue: visibility,
        items: ['Public', 'Private']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          setState(() {
            visibility = v!;
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

  Widget _tokenQuickPickList() {
    return FutureBuilder<List<dynamic>>(
      future: tokensFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Text('Token load failed');
        }

        final tokens = snapshot.data ?? [];

        if (tokens.isEmpty) {
          return Text(
            'No tokens yet',
            style: TextStyle(color: Colors.grey[600]),
          );
        }

        return Container(
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: tokens.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, i) {
              final t = tokens[i];
              final isPublic =
                  t['type']?.toString().toLowerCase() == 'public';
              final isActive =
                  t['status']?.toString().toLowerCase() == 'active';

              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t['token']}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isPublic
                                      ? const Color(0xFF00509D)
                                      : Colors.orange)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  t['type']?.toString().toUpperCase() ?? '',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isPublic
                                        ? const Color(0xFF00509D)
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Event #${t['event_id']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                t['status']?.toString().toUpperCase() ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? const Color(0xFF10B981)
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => selectedToken = t['token']);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF00509D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Use for Upload',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
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

        // The quick-pick list above allows selecting any token, including
        // disabled/expired ones this dropdown normally filters out. Make
        // sure that selection still appears here so the DropdownButton's
        // value always matches one of its items.
        final dropdownTokens = tokens.any((t) => t['token'] == selectedToken)
            ? tokens
            : [
          ...tokens,
          ...allTokens.where((t) => t['token'] == selectedToken),
        ];

        return Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.white, // 🔥 dropdown bg white
          ),
          child: DropdownButtonFormField<String>(
            initialValue: selectedToken,
            hint: const Text('Select Token'),
            items: dropdownTokens.map((t) {
              return DropdownMenuItem<String>(
                value: t['token'],
                child: Text(
                  "${t['token']} (${t['type']})",
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
          label: Text(
            selectedFiles.isEmpty ? 'Select Photos/Videos' : 'Add More Files',
          ),
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
            // onPressed: isUploading ? null : uploadMedia,
            onPressed: canSubmitUpload ? uploadMedia : null,
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
        if (!canSubmitUpload && !isUploading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'All fields are required',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
