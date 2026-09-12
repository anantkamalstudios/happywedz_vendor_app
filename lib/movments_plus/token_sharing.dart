import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/network_service.dart';
import 'generate_tocken.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'package:happy_weds_vendors/utils/api_config.dart';

enum TokenFilterType { all, public, private, active, disabled }
class TokensService {
  static Future<List<dynamic>> fetchTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('authToken');
      final vendorId = prefs.getInt('vendorId');

      if (token == null || vendorId == null) {
        throw Exception("Auth data missing");
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/token/vendor/$vendorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['tokens'] ?? [];
      } else {
        throw Exception("Server error");
      }
    } on SocketException {
      throw Exception("NO_INTERNET");
    }
  }

  static Future<void> disableToken(int tokenId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('authToken');

      if (token == null) {
        print("❌ AUTH TOKEN NULL");
        throw Exception("Auth data missing");
      }

      final url = '${ApiConfig.baseUrl}/token/$tokenId/disable';
      print("➡️ Disable Token API HIT: $url");

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("📡 STATUS CODE: ${response.statusCode}");
      print("📦 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        if (body['success'] == true) {
          print("✅ TOKEN DISABLED SUCCESSFULLY");
          return;
        } else {
          print("❌ API SUCCESS = FALSE");
          print("❌ MESSAGE: ${body['message']}");
          throw Exception(body['message'] ?? "Disable failed");
        }
      } else {
        print("❌ INVALID STATUS CODE");
        throw Exception("Server error: ${response.statusCode}");
      }
    } on SocketException {
      print("❌ NO INTERNET");
      throw Exception("NO_INTERNET");
    } catch (e) {
      print("❌ EXCEPTION: $e");
      rethrow;
    }
  }

  static Future<void> shareTokenByEmail({
    required String tokenValue,
    required List<String> emails,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken =
          prefs.getString('token') ?? prefs.getString('authToken');

      if (authToken == null) {
        throw Exception("Auth token missing");
      }

      final url = '${ApiConfig.baseUrl}/token/share-email';
      print("➡️ SHARE API HIT: $url");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "token": tokenValue,
          "emails": emails,
        }),
      );

      print("📡 SHARE STATUS: ${response.statusCode}");
      print("📦 SHARE BODY: ${response.body}");

      final body = json.decode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        print("✅ SHARE EMAIL SUCCESS");
        return;
      } else {
        throw Exception(body['message'] ?? "Share failed");
      }
    } on SocketException {
      throw Exception("NO_INTERNET");
    } catch (e) {
      print("❌ SHARE EXCEPTION: $e");
      rethrow;
    }
  }

}

/// ======================= SCREEN =======================

class TokensSharingScreen extends StatefulWidget {
  final TokenFilterType initialFilter;

  const TokensSharingScreen({
    Key? key,
    this.initialFilter = TokenFilterType.all,
  }) : super(key: key);

  @override
  State<TokensSharingScreen> createState() => _TokensSharingScreenState();
}

class _TokensSharingScreenState extends State<TokensSharingScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All Tokens', 'Public', 'Private', 'Active' , 'Disabled'];

  late Future<List<dynamic>> tokensFuture;
  void _retryFetch() {
    setState(() {
      tokensFuture = TokensService.fetchTokens();
    });
  }

  // @override
  // void initState() {
  //   super.initState();
  //   tokensFuture = TokensService.fetchTokens();
  // }

  @override
  void initState() {
    super.initState();
    _selectedFilter = _mapFilterToIndex(widget.initialFilter);
    tokensFuture = TokensService.fetchTokens();
  }

  @override
  void didUpdateWidget(covariant TokensSharingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        _selectedFilter = _mapFilterToIndex(widget.initialFilter);
      });
    }
  }

  int _mapFilterToIndex(TokenFilterType filter) {
    switch (filter) {
      case TokenFilterType.public:
        return 1;
      case TokenFilterType.private:
        return 2;
      case TokenFilterType.active:
        return 3;
      case TokenFilterType.disabled:
        return 4;
      case TokenFilterType.all:
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false, // 🔥 THIS IS THE KEY
        backgroundColor: const Color(0xFF00509D),
        title: const Text(
          "Tokens & Sharing",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        elevation: 1,
      ),

      //appBar: CommonAppBar(title: "Tokens & Sharing"),
      body: FutureBuilder<List<dynamic>>(
        future: tokensFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const TokensShimmer();
          }

          if (snapshot.hasError) {
            final error = snapshot.error.toString();

            // ✅ Internet OFF case
            if (error.contains("NO_INTERNET")) {
              return NoInternetView(onRetry: _retryFetch);
            }

            // ❌ Other errors
            return Center(
              child: Text(
                "Something went wrong",
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          final tokens = snapshot.data!;
          final filteredTokens = _applyFilter(tokens);

          return Column(
            children: [
              _buildStatsSection(tokens),
              _buildFilterChips(),
              Expanded(
                child: filteredTokens.isEmpty
                    ? _buildNoTokens()
                    : _buildTokensList(filteredTokens),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tokens_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TokenGeneratorPage()),
          );

          if (result == true) {
            setState(() {
              tokensFuture = TokensService.fetchTokens();
            });
          }
        },
        backgroundColor: const Color(0xFF00509D),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text(
          'Generate Token',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

    );
  }

  /// ======================= FILTER =======================

  List<dynamic> _applyFilter(List<dynamic> tokens) {
    switch (_selectedFilter) {
      case 1:
        return tokens.where((t) => t['type'] == 'public').toList();
      case 2:
        return tokens.where((t) => t['type'] == 'private').toList();
      case 3:
        return tokens.where((t) => t['status'] == 'active').toList();
      case 4:
        return tokens.where((t) => t['status'] == 'disabled').toList();
      default:
        return tokens;
    }
  }

  /// ======================= STATS =======================
  Widget _buildNoTokens() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.vpn_key_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            "No tokens available",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Generate a token to start sharing access",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(List<dynamic> tokens) {
    final totalTokens = tokens.length;
    final activeTokens =
        tokens.where((t) => t['status'] == 'active').length;

    final totalViews = tokens.fold<int>(
      0,
          (sum, t) => sum + ((t['view_count'] ?? 0) as num).toInt(),
    );

    final totalEmails = tokens.fold<int>(
      0,
          (sum, t) => sum + ((t['email_sent_count'] ?? 0) as num).toInt(),
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Tokens',
                  totalTokens.toString(),
                  Icons.key,
                  const Color(0xFF00509D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  activeTokens.toString(),
                  Icons.check_circle,
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
                  'Total Views',
                  totalViews.toString(),
                  Icons.visibility,
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Emails Sent',
                  totalEmails.toString(),
                  Icons.email,
                  const Color(0xFF00509D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ======================= FILTER CHIPS =======================

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

  /// ======================= TOKENS LIST =======================

  Widget _buildTokensList(List<dynamic> tokens) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tokens.length,
      itemBuilder: (context, index) {
        return _buildTokenCard(tokens[index]);
      },
    );
  }

  /// ======================= TOKEN CARD =======================
  Widget _buildTokenCard(dynamic token) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ================= TOP ROW =================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// LEFT ICON
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.key,
                  color: Color(0xFF00509D),
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              /// TOKEN + BADGES
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      token['token'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTypeBadge(token['type']),
                        const SizedBox(width: 8),
                        _buildStatusBadge(token['status']),
                      ],
                    ),
                  ],
                ),
              ),

              /// MENU
              _buildTokenMenu(token),
            ],
          ),

          const SizedBox(height: 16),

          /// ================= EVENT ROW =================
          Row(
            children: [
              const Icon(Icons.event, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Event #${token['event_id']}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.visibility, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${token['view_count']}'),
                  const SizedBox(width: 14),
                  const Icon(Icons.email, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${token['email_sent_count']}'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// ================= DATE BOX =================
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                /// CREATED DATE
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatCreatedDate(token['created_at']),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                /// EXPIRE DATE
                if (token['expires_at'] != null)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.event_available,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatExpireDate(token['expires_at']),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          )

        ],
      ),
    );
  }
  String _formatCreatedDate(dynamic date) {
    if (date == null || date.toString().isEmpty) return "-";

    final dt = DateTime.parse(date.toString()).toLocal();
    return "${dt.day} ${_month(dt.month)}, ${dt.year}, "
        "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String _formatExpireDate(dynamic date) {
    if (date == null || date.toString().isEmpty) return "-";

    final dt = DateTime.parse(date.toString()).toLocal();
    return "${dt.day} ${_month(dt.month)}, ${dt.year}";
  }



  String _month(int m) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[m - 1];
  }

  /// ======================= HELPERS =======================

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final isPublic = type == 'public';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isPublic
            ? const Color(0xFF00509D).withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Icon(isPublic ? Icons.public : Icons.lock,
              size: 12,
              color: isPublic
                  ? const Color(0xFF00509D)
                  : Colors.orange),
          const SizedBox(width: 6),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color:
              isPublic ? const Color(0xFF00509D) : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenMenu(dynamic token) {
    return PopupMenuButton<String>(
      color: Colors.white,
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (value) async {
        if (value == 'copy') {
          Clipboard.setData(ClipboardData(text: token['token']));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Token copied")),
          );
        }

        if (value == 'share') {
          openShareDialog(context, token);
        }

        if (value == 'disable') {
          _confirmDisableToken(token);
        }
      },
      itemBuilder: (context) => [
        if (token['status'] == 'active')
          const PopupMenuItem(
            value: 'disable',
            child: Row(
              children: [
                Icon(Icons.block, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text("Disable Token"),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 16),
              SizedBox(width: 8),
              Text("Copy Token"),
            ],
          ),
        ),
        if (token['status'] == 'active')
          const PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share, size: 16),
                SizedBox(width: 8),
                Text("Share"),
              ],
            ),
          ),
      ],
    );
  }
  void _confirmDisableToken(dynamic token) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Disable Token"),
        content: const Text("Are you sure you want to disable this token?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              try {
                await TokensService.disableToken(token['id']);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Token disabled successfully"),
                  ),
                );

                // 🔄 Refresh list
                setState(() {
                  tokensFuture = TokensService.fetchTokens();
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to disable token")),
                );
              }
            },
            child: const Text("Disable", style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }
  Widget _buildStatusBadge(String status) {
    final isDisabled = status == 'disabled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDisabled
            ? Colors.red.withOpacity(0.1)
            : const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: isDisabled ? Colors.red : const Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isDisabled ? Colors.red : const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}
void openShareDialog(BuildContext context, dynamic token) {
  final scaffoldContext = context;
  final TextEditingController emailController = TextEditingController();
  final List<String> emails = [];

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogInnerContext, setModalState) {
          void addEmail(String value) {
            final email = value.trim();
            if (email.isNotEmpty && !emails.contains(email)) {
              setModalState(() => emails.add(email));
            }
            emailController.clear();
          }

          return Center(
              child: Material(
                  color: Colors.white,
                  elevation: 24,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 320,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// ================= HEADER =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Share this project",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    const Text(
                      "Invite people to view this gallery",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                    const SizedBox(height: 14),

                    /// ================= EMAIL INPUT =================
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF00509D).withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...emails.map(
                                (e) => Chip(
                              label: Text(
                                e,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor:
                              const Color(0xFFEFF6FF),
                              deleteIcon:
                              const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setModalState(() => emails.remove(e));
                              },
                            ),
                          ),

                          Container(
                            width: 160,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TextField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                hintText: "Enter email",
                                isDense: true,
                                border: InputBorder.none,
                              ),
                              onSubmitted: addEmail,
                              onChanged: (value) {
                                if (value.endsWith(',')) {
                                  addEmail(value.replaceAll(',', ''));
                                }
                              },
                            ),
                          ),

                        ],
                      ),
                    ),

                    const SizedBox(height: 6),
                    const Text(
                      "Press Enter or comma to add multiple emails",
                      style:
                      TextStyle(fontSize: 11, color: Colors.grey),
                    ),

                    const SizedBox(height: 14),

                    /// ================= SEND BUTTON =================
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00509D),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        onPressed: emails.isEmpty
                            ? null
                            : () async {
                          Navigator.pop(dialogContext);

                          try {
                            await TokensService.shareTokenByEmail(
                              tokenValue: token['token'],
                              emails: emails,
                            );

                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              const SnackBar(
                                content: Text("Gallery invitation sent successfully"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: Text(
                          "Send invitations (${emails.length})",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// ================= GENERAL ACCESS =================
                    const Text(
                      "General access",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    /// Anyone with link
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.link,
                              size: 18, color: Color(0xFF00509D)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Anyone with the link",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Anyone on the Internet with the link can view",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    _roundedWhatsAppButton(
                      label: "Share via WhatsApp",
                      onTap: () {
                        shareOnWhatsApp(
                          "${ApiConfig.websiteUrl}/gallery/${token['token']}",
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    /// ================= COPY LINK BOX =================
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border:
                        Border.all(color: Colors.grey.shade300),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${ApiConfig.websiteUrl}/gallery/${token['token']}",
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text:
                                  "${ApiConfig.websiteUrl}/gallery/${token['token']}",
                                ),
                              );
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                    content: Text("Link copied")),
                              );
                            },
                            icon:
                            const Icon(Icons.copy, size: 16),
                            label: const Text("Copy link"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),          )
          );
        },
      );
    },
  );
}
Future<void> shareOnWhatsApp(String link) async {
  final encodedText = Uri.encodeComponent(
    "Check out this gallery:\n$link",
  );

  final uri = Uri.parse("https://wa.me/?text=$encodedText");

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not open WhatsApp';
  }
}


Widget _roundedWhatsAppButton({
  required String label,
  required VoidCallback onTap,
}) {
  return OutlinedButton.icon(
    onPressed: onTap,
    icon: const Icon(
      Icons.maps_ugc_sharp,
      color: Color(0xFF25D366),
      size: 20,
    ),
    label: Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF25D366),
      ),
    ),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Color(0xFF25D366)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 20,
      ),
    ),
  );
}


class TokensShimmer extends StatelessWidget {
  const TokensShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ===== STATS =====
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _statBox()),
                  const SizedBox(width: 12),
                  Expanded(child: _statBox()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _statBox()),
                  const SizedBox(width: 12),
                  Expanded(child: _statBox()),
                ],
              ),
            ],
          ),
        ),

        // ===== FILTERS =====
        Container(
          height: 60,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _chip(),
            ),
          ),
        ),

        // ===== LIST =====
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 4,
            itemBuilder: (_, __) => _tokenCard(),
          ),
        ),
      ],
    );
  }

  // ================= WIDGETS =================

  Widget _statBox() {
    return _shimmer(
      Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _chip() {
    return _shimmer(
      Container(
        width: 90,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _tokenCard() {
    return _shimmer(
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _line(width: 150),
                const Spacer(),
                _badge(),
                const SizedBox(width: 8),
                _badge(),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _line()),
                const SizedBox(width: 16),
                Expanded(child: _line()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _metric()),
                const SizedBox(width: 12),
                Expanded(child: _metric()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric() {
    return Column(
      children: [
        _line(width: 40),
        const SizedBox(height: 8),
        _line(width: 60),
      ],
    );
  }

  Widget _badge() {
    return Container(
      width: 60,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _line({double width = double.infinity}) {
    return Container(
      height: 14,
      width: width,
      color: Colors.white,
    );
  }

  Widget _shimmer(Widget child) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: child,
    );
  }
}



