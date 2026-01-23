import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';
import '../utils/network_service.dart';
import 'generate_tocken.dart';
import 'package:shimmer/shimmer.dart';

/// ======================= SERVICE =======================
import 'dart:io';

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
        Uri.parse('https://happywedz.com/api/token/vendor/$vendorId'),
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
}

// class TokensService {
//   static Future<List<dynamic>> fetchTokens() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token') ?? prefs.getString('authToken');
//     final vendorId = prefs.getInt('vendorId');
//
//     if (token == null || vendorId == null) {
//       throw Exception("Auth data missing");
//     }
//
//     final response = await http.get(
//       Uri.parse('https://happywedz.com/api/token/vendor/$vendorId'),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Accept': 'application/json',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       return data['tokens'] ?? [];
//     } else {
//       throw Exception("Failed to load tokens");
//     }
//   }
// }

/// ======================= SCREEN =======================

class TokensSharingScreen extends StatefulWidget {
  const TokensSharingScreen({Key? key}) : super(key: key);

  @override
  State<TokensSharingScreen> createState() => _TokensSharingScreenState();
}

class _TokensSharingScreenState extends State<TokensSharingScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All Tokens', 'Public', 'Private', 'Active'];

  late Future<List<dynamic>> tokensFuture;
  void _retryFetch() {
    setState(() {
      tokensFuture = TokensService.fetchTokens();
    });
  }

  @override
  void initState() {
    super.initState();
    tokensFuture = TokensService.fetchTokens();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CommonAppBar(title: "Tokens & Sharing"),
      // body: FutureBuilder<List<dynamic>>(
      //   future: tokensFuture,
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const TokensShimmer();
      //     }
      //
      //     if (snapshot.hasError) {
      //       return Center(child: Text(snapshot.error.toString()));
      //     }
      //
      //     final tokens = snapshot.data!;
      //     final filteredTokens = _applyFilter(tokens);
      //
      //     return Column(
      //       children: [
      //         _buildStatsSection(tokens),
      //         _buildFilterChips(),
      //
      //         Expanded(
      //           child: filteredTokens.isEmpty
      //               ? _buildNoTokens()
      //               : _buildTokensList(filteredTokens),
      //         ),
      //       ],
      //     );
      //
      //   },
      // ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.vpn_key,
                        size: 16, color: Color(0xFF00509D)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        token['token'],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 16,),
                    _buildTypeBadge(token['type']),
                    const SizedBox(width: 8),
                    _buildStatusBadge(token['status']),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        Icons.event,
                        'Event',
                        'Event #${token['event_id']}',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        Icons.calendar_today,
                        'Created',
                        token['created_at'].toString().substring(0, 10),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          Icons.visibility,
                          '${token['view_count']}',
                          'Views',
                          const Color(0xFF8B5CF6),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: _buildMetricItem(
                          Icons.email,
                          '${token['email_sent_count']}',
                          'Emails',
                          const Color(0xFF00509D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPublic
            ? const Color(0xFF00509D).withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(60),
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
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color:
              isPublic ? const Color(0xFF00509D) : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(60),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(
      IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
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



