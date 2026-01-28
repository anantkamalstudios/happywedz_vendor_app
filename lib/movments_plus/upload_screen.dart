// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// class UploadMediaScreen extends StatefulWidget {
//   const UploadMediaScreen({Key? key}) : super(key: key);
//
//   @override
//   State<UploadMediaScreen> createState() => _UploadMediaScreenState();
// }
//
// class _UploadMediaScreenState extends State<UploadMediaScreen> {
//   String? selectedToken;
//   String? selectedEvent;
//   String eventId = '';
//   String collectionName = '';
//   String visibility = 'Public';
//   List<Map<String, dynamic>> selectedFiles = [];
//
//   final tokens = [
//     {
//       'code': '2e93e27ca649',
//       'type': 'Public',
//       'event': 'Event #2',
//       'status': 'Active',
//       'views': 0,
//       'emails': 1,
//       'created': 'Jan 19, 2026, 01:27 PM',
//       'expires': 'No expiry',
//     },
//     {
//       'code': '576a9fb8233c',
//       'type': 'Private',
//       'event': 'Event #2',
//       'status': 'Active',
//       'views': 0,
//       'emails': 1,
//       'created': 'Jan 16, 2026, 11:23 AM',
//       'expires': 'No expiry',
//     },
//     {
//       'code': '8b376088b7a6',
//       'type': 'Private',
//       'event': 'Event #2',
//       'status': 'Active',
//       'views': 0,
//       'emails': 2,
//       'created': 'Dec 27, 2025, 06:32 PM',
//       'expires': 'No expiry',
//     },
//     {
//       'code': '99d86cc73f68',
//       'type': 'Public',
//       'event': 'Event #2',
//       'status': 'Active',
//       'views': 0,
//       'emails': 0,
//       'created': 'Dec 27, 2025, 06:32 PM',
//       'expires': 'No expiry',
//     },
//     {
//       'code': 'f70f9fa21591',
//       'type': 'Private',
//       'event': 'Event #2',
//       'status': 'Active',
//       'views': 0,
//       'emails': 0,
//       'created': 'Dec 26, 2025, 10:52 AM',
//       'expires': 'Jan 1, 2026, 05:29 AM',
//     },
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildHeader(),
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildInputField(
//                       label: 'Event ID*',
//                       hint: 'Enter event ID',
//                       icon: Icons.calendar_today,
//                       onChanged: (value) => setState(() => eventId = value),
//                     ),
//                     const SizedBox(height: 20),
//                     _buildInputField(
//                       label: 'Collection*',
//                       hint: 'Enter collection name',
//                       icon: Icons.folder_outlined,
//                       onChanged: (value) => setState(() => collectionName = value),
//                     ),
//                     const SizedBox(height: 20),
//                     _buildDropdownField(
//                       label: 'Visibility*',
//                       hint: 'Select visibility',
//                       value: visibility,
//                       items: ['Public', 'Private'],
//                       onChanged: (value) => setState(() => visibility = value ?? 'Public'),
//                     ),
//                     const SizedBox(height: 20),
//                     _buildTokenDropdownField(),
//                     const SizedBox(height: 12),
//                     Padding(
//                       padding: const EdgeInsets.only(left: 4),
//                       child: Text(
//                         'You can also select a token from the table above.',
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey[600],
//                           fontStyle: FontStyle.italic,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 30),
//                     _buildFileUploadArea(),
//                     const SizedBox(height: 24),
//                     if (selectedFiles.isNotEmpty) _buildSelectedFilesList(),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF00509D), Color(0xFF0066CC)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF00509D).withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               IconButton(
//                 onPressed: () => Navigator.pop(context),
//                 icon: const Icon(Icons.arrow_back, color: Colors.white),
//                 padding: EdgeInsets.zero,
//                 constraints: const BoxConstraints(),
//               ),
//               const SizedBox(width: 16),
//               const Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Upload Media',
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       'Select token & upload your files',
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.white70,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           _buildStorageInfo(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStorageInfo() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white.withOpacity(0.3)),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _buildStorageStat('Used', '32.49 MB', Icons.storage),
//               Container(width: 1, height: 30, color: Colors.white30),
//               _buildStorageStat('Free', '10207 MB', Icons.cloud_done),
//             ],
//           ),
//           const SizedBox(height: 12),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(6),
//             child: LinearProgressIndicator(
//               value: 0.003,
//               backgroundColor: Colors.white.withOpacity(0.3),
//               valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
//               minHeight: 6,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStorageStat(String label, String value, IconData icon) {
//     return Expanded(
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: Colors.white, size: 18),
//           const SizedBox(width: 8),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: const TextStyle(
//                   color: Colors.white70,
//                   fontSize: 11,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInputField({
//     required String label,
//     required String hint,
//     required IconData icon,
//     required ValueChanged<String> onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.w600,
//             color: Color(0xFF1A1A1A),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: TextField(
//             onChanged: onChanged,
//             style: const TextStyle(
//               fontSize: 15,
//               color: Color(0xFF1A1A1A),
//             ),
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: TextStyle(
//                 fontSize: 15,
//                 color: Colors.grey[400],
//               ),
//               prefixIcon: Icon(icon, color: const Color(0xFF00509D), size: 22),
//               filled: true,
//               fillColor: Colors.white,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide.none,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: const BorderSide(color: Color(0xFF00509D), width: 2),
//               ),
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDropdownField({
//     required String label,
//     required String hint,
//     required String value,
//     required List<String> items,
//     required ValueChanged<String?> onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.w600,
//             color: Color(0xFF1A1A1A),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey[200]!, width: 1),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: DropdownButtonFormField<String>(
//             value: value,
//             decoration: InputDecoration(
//               border: InputBorder.none,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//               hintStyle: TextStyle(
//                 fontSize: 15,
//                 color: Colors.grey[400],
//               ),
//             ),
//             style: const TextStyle(
//               fontSize: 15,
//               color: Color(0xFF1A1A1A),
//             ),
//             icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 24),
//             items: items.map((String item) {
//               return DropdownMenuItem<String>(
//                 value: item,
//                 child: Text(item),
//               );
//             }).toList(),
//             onChanged: onChanged,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTokenDropdownField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Token*',
//           style: TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.w600,
//             color: Color(0xFF1A1A1A),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey[200]!, width: 1),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: DropdownButtonFormField<String>(
//             value: selectedToken,
//             decoration: InputDecoration(
//               prefixIcon: Icon(Icons.vpn_key, color: const Color(0xFF00509D), size: 22),
//               border: InputBorder.none,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//               hintText: 'Select token',
//               hintStyle: TextStyle(
//                 fontSize: 15,
//                 color: Colors.grey[400],
//               ),
//             ),
//             style: const TextStyle(
//               fontSize: 14,
//               color: Color(0xFF1A1A1A),
//               fontFamily: 'monospace',
//             ),
//             icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 24),
//             items: tokens.map((token) {
//               return DropdownMenuItem<String>(
//                 value: token['code'].toString(),
//                 child: Text(
//                   token['code'].toString(),
//                   style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
//                 ),
//               );
//             }).toList(),
//             onChanged: (value) {
//               setState(() {
//                 selectedToken = value;
//                 selectedEvent = tokens.firstWhere((t) => t['code'] == value)['event'].toString();
//               });
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildFileUploadArea() {
//     return Center(
//       child: SizedBox(
//         width: double.infinity,
//         child: OutlinedButton.icon(
//           onPressed: () {},
//           icon: const Icon(Icons.upload, size: 18),
//           label: const Text('Upload Media'),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: const Color(0xFF00509D),
//             side: const BorderSide(color: Color(0xFF00509D)),
//             padding: const EdgeInsets.symmetric(vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//
//   Widget _buildSelectedFilesList() {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 12,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF10B981).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Icon(Icons.attachment, color: Color(0xFF10B981), size: 20),
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     '${selectedFiles.length} Files Selected',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1A1A1A),
//                     ),
//                   ),
//                 ],
//               ),
//               TextButton(
//                 onPressed: () => setState(() => selectedFiles.clear()),
//                 style: TextButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   minimumSize: Size.zero,
//                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 ),
//                 child: const Text(
//                   'Clear',
//                   style: TextStyle(
//                     color: Colors.red,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           ...selectedFiles.map((file) => _buildFileListItem(file)),
//           const SizedBox(height: 18),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: (){},
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF00509D),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 elevation: 3,
//                 shadowColor: const Color(0xFF00509D).withOpacity(0.4),
//               ),
//               child: const Text(
//                 'Upload Files',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 17,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFileListItem(Map<String, dynamic> file) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF8F9FA),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[200]!, width: 1),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: const Color(0xFF00509D).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(
//               file['type'] == 'image' ? Icons.image_outlined : Icons.videocam_outlined,
//               color: const Color(0xFF00509D),
//               size: 24,
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   file['name'],
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1A1A1A),
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   file['size'],
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             onPressed: () => setState(() => selectedFiles.remove(file)),
//             icon: const Icon(Icons.close, color: Colors.red, size: 22),
//             padding: EdgeInsets.zero,
//             constraints: const BoxConstraints(),
//           ),
//         ],
//       ),
//     );
//   }
//
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';


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
  const UploadMediaScreen({Key? key}) : super(key: key);

  @override
  State<UploadMediaScreen> createState() =>
      _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  String? selectedEventId;
  String? selectedToken;
  String collectionName = '';
  String visibility = 'Public';

  bool isUploading = false;

  late Future<List<Event>> eventsFuture;
  late Future<List<dynamic>> tokensFuture;

  List<Map<String, dynamic>> selectedFiles = [];

  @override
  void initState() {
    super.initState();
    eventsFuture = EventsService.fetchEvents();
    tokensFuture = TokensService.fetchTokens();
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
            'files', // ✅ EXACT same as Postman
            f['file'].path,
            contentType: MediaType.parse(mimeType!),
          ),
        );
      }

      // for (var f in selectedFiles) {
      //   final mimeType = lookupMimeType(f['file'].path);
      //
      //   print("📸 File: ${f['file'].path}");
      //   print("🧪 MIME: $mimeType");
      //
      //   if (mimeType == null ||
      //       (!mimeType.startsWith('image/') &&
      //           !mimeType.startsWith('video/'))) {
      //     throw Exception("Only image/video allowed");
      //   }
      //
      //   request.files.add(
      //     await http.MultipartFile.fromPath(
      //       'files[]',
      //       f['file'].path,
      //       contentType: MediaType.parse(mimeType),
      //     ),
      //   );
      // }

      final streamedResponse = await request.send();
      final responseBody =
      await streamedResponse.stream.bytesToString();

      print("📥 STATUS: ${streamedResponse.statusCode}");
      print("📥 BODY: $responseBody");

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Media uploaded successfully')),
        );
        setState(() => selectedFiles.clear());
      } else {
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
      body: SafeArea(
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
                    _eventDropdown(),
                    const SizedBox(height: 20),
                    _input(
                        'Collection*',
                        Icons.folder_outlined,
                            (v) => collectionName = v),
                    const SizedBox(height: 20),
                    _visibilityDropdown(),
                    const SizedBox(height: 20),
                    _tokenDropdown(),
                    const SizedBox(height: 30),
                    _uploadPicker(),
                    const SizedBox(height: 24),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF00509D), Color(0xFF0066CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Media',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Select token & upload your files',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStorageStat('Used', '32.49 MB', Icons.storage),
              Container(width: 1, height: 30, color: Colors.white30),
              _buildStorageStat('Free', '10207 MB', Icons.cloud_done),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.003,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
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
            prefixIcon: Icon(icon),
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
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }

  Widget _visibilityDropdown() {
    return DropdownButtonFormField<String>(
      value: visibility,
      items: ['Public', 'Private']
          .map((e) =>
          DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => setState(() => visibility = v!),
      decoration:
      const InputDecoration(border: OutlineInputBorder()),
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

        final tokens = snapshot.data ?? [];

        return DropdownButtonFormField<String>(
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
          decoration:
          const InputDecoration(border: OutlineInputBorder()),
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
        ElevatedButton(
          onPressed: isUploading ? null : uploadMedia,
          child: isUploading
              ? const CircularProgressIndicator(
              color: Colors.white)
              : const Text('Upload Files'),
        ),
      ],
    );
  }
}

