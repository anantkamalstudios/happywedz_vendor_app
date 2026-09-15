import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/movments_plus/token_sharing.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/network_service.dart';
import 'bottom_bar.dart';
import 'gallery_screen.dart';
import 'package_page.dart';
import 'analytics_screen.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

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
  String getCurrentDateTime() {
    final now = DateTime.now();
    return DateFormat('hh:mm:ss a  EEEE, MMMM dd, yyyy').format(now);
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
        Uri.parse('${ApiConfig.baseUrl}/vendor/dashboard/analytics'),
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

  int getMediaCountByVisibility(Map<String, dynamic> media, String visibility) {
    final list = (media['visibility'] ?? []) as List;

    final item = list.firstWhere(
          (e) => e['visibility'] == visibility,
      orElse: () => {'count': 0},
    );

    return toInt(item['count']);
  }
  // ======================= UI =======================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const DashboardShimmer();
    }

    if (hasInternetError) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CommonAppBar(title: "Movments Plus", showBack: false),
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
    final usage = data!['usage'] ?? {};
    final publicTokens = getTokenCountByType(tokens, 'public');
    final privateTokens = getTokenCountByType(tokens, 'private');
    final publicMedia = getMediaCountByVisibility(media, 'public');
    final activeTokens = toInt(tokens['active']);
    final totalTokens = toInt(tokens['total']);
    final canUpload = usage['canUpload'] ?? true;
    final storageWarning = usage['storageWarning'] ?? false;


    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CommonAppBar(title: "Movments Plus", showBack: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= STATUS + REFRESH =================
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
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    getCurrentDateTime(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _fetchDashboard,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Refresh"),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF00509D),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),

            if (storageWarning) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Storage is running low! Consider upgrading your package.",
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ================= PRIMARY STATS (4 cards) =================
            Row(
              children: [
                Expanded(
                  child: _buildPrimaryStatCard(
                    icon: Icons.inventory_2_outlined,
                    value:
                    "${package['usedMB']} MB",
                    label: "Storage Used",
                    trend: "${package['usagePercent']}%",
                    caption:
                    "${package['remainingMB']} MB of ${package['limitMB']} MB remaining",
                    progress: (toInt(package['usagePercent'])) / 100,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPrimaryStatCard(
                    icon: Icons.photo_library_outlined,
                    value: media['total'].toString(),
                    label: "Total Media Files",
                    caption:
                    "${media['byCollection'].length} Collections • $publicMedia Public",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPrimaryStatCard(
                    icon: Icons.remove_red_eye_outlined,
                    value: reach['totalViews'].toString(),
                    label: "Total Gallery Views",
                    caption: "${reach['uniqueViews']} Unique Visitors",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPrimaryStatCard(
                    icon: Icons.vpn_key_outlined,
                    value: totalTokens.toString(),
                    label: "Access Tokens",
                    trend: activeTokens.toString(),
                    caption:
                    "$activeTokens Active • ${totalTokens - activeTokens} Inactive",
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
                  onPressed: () {
                    MainHomeScreen.of(context)?.openUpload();
                  },
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
                        MainHomeScreen.of(context)?.openUpload();
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
                    GestureDetector(
                      onTap: () {
                        MainHomeScreen.of(context)
                            ?.openTokensWithFilter(TokenFilterType.public);
                      },
                      child: _buildDistributionRow(
                        "Public Tokens",
                        publicTokens,
                        tokens['total'],
                        const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        MainHomeScreen.of(context)
                            ?.openTokensWithFilter(TokenFilterType.private);
                      },
                      child: _buildDistributionRow(
                        "Private Tokens",
                        privateTokens,
                        tokens['total'],
                        const Color(0xFF00509D),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // ================= CURRENT PACKAGE =================
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
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium_outlined,
                          color: Color(0xFF00509D), size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Current Package",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00509D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${package['name']} Plan",
                      style: const TextStyle(
                        color: Color(0xFF00509D),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPackageStatItem(
                          "Storage Limit",
                          "${package['limitMB']} MB",
                        ),
                      ),
                      Expanded(
                        child: _buildPackageStatItem(
                          "Used Space",
                          "${package['usedMB']} MB",
                        ),
                      ),
                      Expanded(
                        child: _buildPackageStatItem(
                          "Available",
                          "${package['remainingMB']} MB",
                          valueColor: const Color(0xFF00509D),
                        ),
                      ),
                    ],
                  ),
                  if (package['name'] == 'Basic' ||
                      package['name'] == 'Standard') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PackageStoragePage()),
                          );
                        },
                        icon: const Icon(Icons.trending_up, size: 18),
                        label: const Text("Upgrade Package"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00509D),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ================= QUICK ACTIONS =================
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _buildQuickAction(
                  icon: Icons.cloud_upload_outlined,
                  label: "Upload Media",
                  enabled: canUpload,
                  onTap: () => MainHomeScreen.of(context)?.openUpload(),
                ),
                _buildQuickAction(
                  icon: Icons.create_new_folder_outlined,
                  label: "New Collection",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GalleryScreen()),
                    );
                  },
                ),
                _buildQuickAction(
                  icon: Icons.vpn_key_outlined,
                  label: "Generate Token",
                  onTap: () => MainHomeScreen.of(context)
                      ?.openTokensWithFilter(TokenFilterType.all),
                ),
                _buildQuickAction(
                  icon: Icons.bar_chart_outlined,
                  label: "View Analytics",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AnalyticsScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageStatItem(String label, String value,
      {Color valueColor = const Color(0xFF1A1A1A)}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: enabled ? const Color(0xFF00509D) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled ? const Color(0xFF1A1A1A) : Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
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

  Widget _buildPrimaryStatCard({
    required IconData icon,
    required String value,
    required String label,
    String? trend,
    String? caption,
    double? progress,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00509D).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF00509D), size: 20),
              ),
              if (trend != null)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00509D)),
                minHeight: 6,
              ),
            ),
          ],
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(
              caption,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollectionCard(String name, int fileCount, int colorValue) {
    final color = Color(colorValue);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GalleryScreen()),
        );
      },
      child: Container(
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
