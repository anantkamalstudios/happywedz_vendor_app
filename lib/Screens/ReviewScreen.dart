import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';
import '../theme/app_colors.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/app_states.dart';
import 'new_screens/review_collector.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  bool _isLoading = true;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  // ✅ FETCH REVIEWS
  Future<void> fetchReviews() async {
    print('📡 Fetching reviews from: ${ApiConfig.baseUrl}/reviews/my-reviews');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('🔑 Token found: $token');

    if (token == null) {
      print('❌ No token found in SharedPreferences');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reviews/my-reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🟡 FETCH Status Code: ${response.statusCode}');
      print('📦 FETCH Response Body:\n${response.body}\n');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🧩 Parsed Data: $data');

        if (data['success'] == true && data['reviews'] != null) {
          setState(() {
            _reviews = data['reviews'];
            _isLoading = false;
          });
          print('✅ Reviews fetched successfully! Count: ${_reviews.length}');
        } else {
          print('⚠️ No reviews found or invalid response structure');
          setState(() {
            _isLoading = false;
            _reviews = [];
          });
        }
      } else {
        print('❌ Failed to load reviews, status: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('🔥 Error fetching reviews: $e');
      setState(() => _isLoading = false);
    }
  }

  // ✅ SEND REPLY
  Future<void> _sendReply(int reviewId, String message) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/reviews/reply/$reviewId');
    print('✉️ Sending reply for review ID $reviewId...');
    print('🌍 PUT URL: $url');
    print('📝 Message to send: "$message"');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('🔑 Token found for reply: $token');

    if (token == null) {
      print('❌ No token found in SharedPreferences for reply');
      return;
    }

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"vendor_reply": message}),
      );

      print('🟢 REPLY Status Code: ${response.statusCode}');
      print('📦 REPLY Response Body:\n${response.body}\n');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('🧩 Parsed REPLY Data: $data');

        setState(() {
          final idx = _reviews.indexWhere((r) => r['id'] == reviewId);
          if (idx != -1) {
            _reviews[idx]['vendor_reply'] = message;
            print('✅ Updated local review list with new reply');
          }
        });

        print('✅ Reply successfully sent and UI updated!');
      } else {
        print('❌ Failed to send reply. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Error sending reply: $e');
    }
  }

  // ✅ DIALOG FOR REPLY INPUT
  void _showReplyDialog(int reviewId, String? existingReply) {
    final TextEditingController ctrl = TextEditingController(text: existingReply ?? '');
    print('💬 Opening reply dialog for review ID: $reviewId');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Text(
          'Reply to Review',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00509D),),
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Type your reply...',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ Reply dialog cancelled');
              Navigator.pop(ctx);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00509D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final msg = ctrl.text.trim();
              if (msg.isEmpty) {
                print('⚠️ Reply message is empty');
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              print('📤 Sending reply: $msg');
              await _sendReply(reviewId, msg);
            },
            child: const Text(
              'Send',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),

          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: fetchReviews,
        child: CustomScrollView(
          // Always scrollable so the pull gesture works even on the empty
          // and loading states.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildHeader(),

            // 🔹 LOADER BELOW APP BAR
            // A skeleton the shape of the cards, rather than a spinner pushed
            // down by 350px of hard-coded padding that guessed at the middle
            // of one particular screen size.
            if (_isLoading)
              const SliverToBoxAdapter(
                child: ListShimmer(itemCount: 4, itemHeight: 150),
              )

            // 🔹 EMPTY STATE
            else if (_reviews.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: Icons.reviews_outlined,
                  title: 'No reviews yet',
                  message:
                      'Ask the couples you have worked with to leave a review. '
                      'Reviews are the first thing people read on your listing.',
                  actionLabel: 'Collect reviews',
                  onAction: _openCollector,
                ),
              )

            // 🔹 REVIEWS LIST
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    final r = _reviews[i];
                    return _buildReviewCard(r);
                  },
                  childCount: _reviews.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  void _openCollector() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReviewCollectorScreen()),
    );
  }

  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.white,
  //     body: _isLoading
  //         ? const Center(child: CircularProgressIndicator(color: Colors.pink))
  //         : _reviews.isEmpty
  //         ? const Center(
  //       child: Text(
  //         'No reviews available',
  //         style: TextStyle(fontSize: 16, color: Colors.grey),
  //       ),
  //     )
  //         : CustomScrollView(
  //       slivers: [
  //         _buildHeader(),
  //         SliverList(
  //           delegate: SliverChildBuilderDelegate(
  //                 (context, i) {
  //               final r = _reviews[i];
  //               print('🧾 Building Review Card for ID: ${r['id']}');
  //               return _buildReviewCard(r);
  //             },
  //             childCount: _reviews.length,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
// ✅ MODERN HEADER
  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 70,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          tooltip: 'Collect reviews',
          icon: const Icon(Icons.person_add_alt_outlined, color: Colors.white),
          onPressed: _openCollector,
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF003F88), // French Blue
              Color(0xFF00509D), // Steel Azure
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(20, topPad + 10, 16, 10),
        alignment: Alignment.bottomLeft,
        // One line with an ellipsis: the bar has a fixed height, so at a large
        // accessibility text size the title has to shrink into it rather than
        // run off the edge.
        child: const Text(
          'My Reviews',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }


// ✅ MODERN REVIEW CARD
  Widget _buildReviewCard(dynamic r) {
    final user = r['user']?['name'] ?? 'Anonymous';
    final title = r['title'] ?? '';
    final comment = r['comment'] ?? '';
    final vendorReply = r['vendor_reply'] ?? '';
    final date = r['createdAt'] ?? '';
    final rating = r['rating_quality'] ?? 0;

    print('🧱 Review Data -> ID: ${r['id']}, User: $user, Reply: $vendorReply');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 USER HEADER
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _initialOf(user),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _stars(rating),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            // 🔹 TITLE & COMMENT
            if (title.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
            if (comment.isNotEmpty) ...[
              SizedBox(height: title.isNotEmpty ? 5 : 14),
              Text(
                comment,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ],

            // 🔹 VENDOR REPLY
            // This block used to paint white text on a pale blue fill, which
            // left every reply effectively unreadable.
            if (vendorReply.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply,
                            size: 14, color: AppColors.primaryDark),
                        const SizedBox(width: 6),
                        Text(
                          'Your reply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vendorReply,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 6),

            // 🔹 ACTION BUTTON
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    _showReplyDialog(r['id'], r['vendor_reply']?.toString()),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: Icon(
                  vendorReply.isEmpty ? Icons.reply : Icons.edit_outlined,
                  size: 17,
                ),
                label: Text(
                  vendorReply.isEmpty ? 'Reply' : 'Edit reply',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stars plus the number, so the score reads at a glance.
  Widget _stars(dynamic rating) {
    final value = (rating is num) ? rating.toDouble() : 0.0;

    return Row(
      children: [
        for (int i = 0; i < 5; i++)
          Icon(
            i < value ? Icons.star_rounded : Icons.star_border_rounded,
            color: AppColors.rating,
            size: 17,
          ),
        const SizedBox(width: 6),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// "5 Jan 2026" instead of the raw "2026-01-05T…".
  /// Falls back to whatever was there if it will not parse.
  String _formatDate(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.isEmpty) return '';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.split('T').first;

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  /// The avatar letter. A review whose name is an empty string used to throw
  /// a RangeError out of build on `user[0]`.
  String _initialOf(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }
}
