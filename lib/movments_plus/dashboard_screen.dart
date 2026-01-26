import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/network_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  bool hasInternetError = false;



  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  // ======================= API =======================
  Future<void> _fetchDashboard() async {
    try {
      setState(() {
        isLoading = true;
        hasInternetError = false;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('authToken');

      if (token == null) throw Exception("Auth token missing");

      final response = await http.get(
        Uri.parse('https://happywedz.com/api/vendor/dashboard/analytics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final res = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          res['success'] == true) {
        setState(() {
          data = res;
          isLoading = false;
        });
      } else {
        throw Exception("Server error");
      }
    } on SocketException {
      setState(() {
        isLoading = false;
        hasInternetError = true;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong")),
      );
    }
  }

  // Future<void> _fetchDashboard() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('token') ?? prefs.getString('authToken');
  //
  //     if (token == null) throw Exception("Auth token missing");
  //
  //     final response = await http.get(
  //       Uri.parse('https://happywedz.com/api/vendor/dashboard/analytics'),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Accept': 'application/json',
  //       },
  //     );
  //
  //     final res = jsonDecode(response.body);
  //
  //     if ((response.statusCode == 200 || response.statusCode == 201) &&
  //         res['success'] == true) {
  //       setState(() {
  //         data = res;
  //         isLoading = false;
  //       });
  //     } else {
  //       throw Exception("Failed to load dashboard");
  //     }
  //   } catch (e) {
  //     isLoading = false;
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text(e.toString())));
  //   }
  // }

  // ======================= HELPERS =======================

  int toInt(dynamic v) => int.tryParse(v.toString()) ?? 0;

  String timeAgo(String isoDate) {
    final date = DateTime.parse(isoDate);
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  int getTokenCountByType(Map<String, dynamic> tokens, String type) {
    final list = (tokens['byType'] ?? []) as List;

    final item = list.firstWhere(
          (e) => e['type'] == type,
      orElse: () => {'count': 0},
    );

    return toInt(item['count']);
  }
  // ======================= UI =======================

  @override
  Widget build(BuildContext context) {
    // if (isLoading) {
    //   return const Scaffold(body: Center(child: CircularProgressIndicator()));
    // }
    if (isLoading) {
      return const DashboardShimmer();
    }

    if (hasInternetError) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CommonAppBar(title: "Movments Plus"),
        body: NoInternetView(
          onRetry: _fetchDashboard,
        ),
      );
    }

    final package = data!['package'];
    final media = data!['media'];
    final tokens = data!['tokens'];
    final reach = data!['reach'];
    final activity = data!['activity'];

    // final publicTokens = toInt(
    //   tokens['byType'].firstWhere((e) => e['type'] == 'public')['count'],
    // );
    // final privateTokens = toInt(
    //   tokens['byType'].firstWhere((e) => e['type'] == 'private')['count'],
    // );
    final publicTokens = getTokenCountByType(tokens, 'public');
    final privateTokens = getTokenCountByType(tokens, 'private');


    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CommonAppBar(title: "Movments Plus"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= STATUS =================
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                      SizedBox(width: 6),
                      Text(
                        "Online",
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Last updated: Just now",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ================= PACKAGE =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00509D), Color(0xFF0066CC)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00509D).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${package['name']} Plan",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${(package['limitMB'] / 1024).toStringAsFixed(1)} GB Storage Available",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              "${package['usedMB']} MB",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "used",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= STATS =================
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.photo_library,
                    value: media['total'].toString(),
                    label: "Media Files",
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.visibility,
                    value: reach['totalViews'].toString(),
                    label: "Views",
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.key,
                    value: tokens['total'].toString(),
                    label: "Tokens",
                    color: const Color(0xFF00509D),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),


            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Collections",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("New"),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF00509D),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // SizedBox(
            //   height: 140,
            //   child: ListView.builder(
            //     scrollDirection: Axis.horizontal,
            //     itemCount: media['byCollection'].length,
            //     itemBuilder: (_, i) {
            //       final c = media['byCollection'][i];
            //       return _buildCollectionCard(
            //         c['collection'],
            //         toInt(c['count']),
            //         0xFF00509D,
            //       );
            //     },
            //   ),
            // ),
            if (media['byCollection'].isEmpty)
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      "No collections created yet",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 12,),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to Create Collection Screen
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => CreateCollectionScreen()));
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Create Collection"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00509D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: media['byCollection'].length,
                  itemBuilder: (_, i) {
                    final c = media['byCollection'][i];
                    return _buildCollectionCard(
                      c['collection'],
                      toInt(c['count']),
                      0xFF00509D,
                    );
                  },
                ),
              ),


            const SizedBox(height: 28),

            // ================= RECENT ACTIVITY =================
            // const Text(
            //   "Recent Activity",
            //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 12),
            //
            // if (activity['lastUploadAt'] != null)
            //   _buildActivityTile(
            //     icon: Icons.cloud_upload,
            //     title: "Media Upload",
            //     subtitle: "Media uploaded successfully",
            //     time: timeAgo(activity['lastUploadAt']),
            //     iconBg: const Color(0xFF10B981),
            //   ),
            //
            // if (activity['lastTokenCreatedAt'] != null)
            //   _buildActivityTile(
            //     icon: Icons.vpn_key,
            //     title: "Token Generated",
            //     subtitle: "New access token created",
            //     time: timeAgo(activity['lastTokenCreatedAt']),
            //     iconBg: const Color(0xFF00509D),
            //   ),
// ================= RECENT ACTIVITY =================
            const Text(
              "Recent Activity",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (activity['lastUploadAt'] == null &&
                activity['lastTokenCreatedAt'] == null)
              _buildNoRecentActivity()
            else ...[
              if (activity['lastUploadAt'] != null)
                _buildActivityTile(
                  icon: Icons.cloud_upload,
                  title: "Media Upload",
                  subtitle: "Media uploaded successfully",
                  time: timeAgo(activity['lastUploadAt']),
                  iconBg: const Color(0xFF10B981),
                ),

              if (activity['lastTokenCreatedAt'] != null)
                _buildActivityTile(
                  icon: Icons.vpn_key,
                  title: "Token Generated",
                  subtitle: "New access token created",
                  time: timeAgo(activity['lastTokenCreatedAt']),
                  iconBg: const Color(0xFF00509D),
                ),
            ],

            const SizedBox(height: 28),

            // ================= TOKEN DISTRIBUTION =================
            Container(
              padding: const EdgeInsets.all(20),
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
                  Row(
                    children: [
                      const Icon(
                        Icons.pie_chart,
                        color: Color(0xFF00509D),
                        size: 20,
                      ),
                      SizedBox(width: 8,),
                      const Text(
                        "Token Distribution",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDistributionRow(
                    "Public Tokens",
                    publicTokens,
                    tokens['total'],
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  _buildDistributionRow(
                    "Private Tokens",
                    privateTokens,
                    tokens['total'],
                    const Color(0xFF00509D),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildNoRecentActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 42,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 10),
          Text(
            "No recent activity",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Your recent uploads and actions will appear here",
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

  // ======================= UI HELPERS =======================

  Widget _buildMiniStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(String name, int fileCount, int colorValue) {
    final color = Color(colorValue);
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.folder, color: Colors.white, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$fileCount files",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color iconBg,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconBg, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  // Widget _buildDistributionRow(
  //   String label,
  //   int count,
  //   int total,
  //   Color color,
  // ) {
  //   final percentage = count / total;
  Widget _buildDistributionRow(
      String label,
      int count,
      int total,
      Color color,
      ) {
    final percentage = total == 0 ? 0.0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              "$count / $total",
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}


class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _shimmerBox(height: 20, width: 120),
            const SizedBox(height: 24),

            // Premium Banner
            _shimmerBox(height: 140, radius: 20),
            const SizedBox(height: 24),

            // Stats
            Row(
              children: [
                Expanded(child: _shimmerBox(height: 110, radius: 16)),
                const SizedBox(width: 12),
                Expanded(child: _shimmerBox(height: 110, radius: 16)),
                const SizedBox(width: 12),
                Expanded(child: _shimmerBox(height: 110, radius: 16)),
              ],
            ),

            const SizedBox(height: 28),

            // Collections
            Align(
              alignment: Alignment.centerLeft,
              child: _shimmerBox(height: 20, width: 120),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, __) =>
                    _shimmerBox(width: 120, height: 140, radius: 16),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: 4,
              ),
            ),

            const SizedBox(height: 28),

            // Activity
            Align(
              alignment: Alignment.centerLeft,
              child: _shimmerBox(height: 20, width: 150),
            ),
            const SizedBox(height: 12),
            _activityShimmer(),
            _activityShimmer(),

            const SizedBox(height: 28),

            // Token Distribution
            _shimmerBox(height: 160, radius: 16),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({
    double height = 20,
    double width = double.infinity,
    double radius = 12,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _activityShimmer() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 120, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 180, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
