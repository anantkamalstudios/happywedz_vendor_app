import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/session_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_network_image.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_states.dart';

/// ============================================================================
/// ReviewsPage — the vendor's received reviews, with replies
/// ============================================================================
///
/// API INTEGRATION IS UNCHANGED:
///   GET https://happywedz.com/api/reviews/my-reviews
///   PUT https://happywedz.com/api/reviews/reply/{reviewId}
///       body: {"vendor_reply": "the reply text"}
/// Same URLs, methods, headers and request body.
///
/// AUDIT NOTE — BUGS FIXED
///
/// 1. THE VENDOR'S REPLY WAS INVISIBLE (high severity, pure UI).
///        Container(color: Colors.blue.shade100,
///          child: Text(vendorReply, style: TextStyle(color: Colors.white)))
///    White text on #BBDEFB — a contrast ratio of about 1.5:1. Every reply a
///    vendor wrote rendered as a blank blue bar. The bubble is now brand-tinted
///    with dark text, and labelled so it reads as the vendor's own reply.
///
/// 2. CRASH ON A REVIEW FROM A USER WITH NO NAME.
///        final user = r['user']?['name'] ?? 'Anonymous';
///        …
///        Text(user[0].toUpperCase())
///    `??` only defends against null. When the API returns `"name": ""` — which
///    it does for guest reviewers — `user` is an EMPTY STRING and `user[0]`
///    throws `RangeError (index): Invalid value: Valid value range is empty`,
///    taking down the whole SliverList.
///
/// 3. REVIEW PHOTOS WERE FETCHED BUT NEVER SHOWN (broken dynamic data).
///        final mediaList = r['media'] ?? [];   // …and never used again
///    The analyzer flagged it as `unused_local_variable`. Customers' review
///    photos come down in the existing response and were silently dropped.
///    They are now rendered — no API change, the data was already there.
///
/// 4. A FAILED FETCH LOOKED LIKE "NO REVIEWS".
///    Every failure path did `setState(() => _isLoading = false)` and left
///    `_reviews` empty, so a network error told the vendor they had no reviews.
///    Loading / empty / error are now distinct, with a working Retry.
///
/// 5. THE REPLY DIALOG REPORTED NOTHING.
///    `_sendReply` `print`ed its result and returned. A failed reply looked
///    exactly like a successful one: the dialog closed and nothing changed.
///    It also had no loading state, so the Send button could be tapped
///    repeatedly, firing the PUT once per tap.
///
/// 6. THE AUTH TOKEN WAS PRINTED TO THE CONSOLE.
///        debugPrint('🔑 Token found: $token');
///    A bearer token in the device log is a credential leak. Removed (the
///    presence check is still logged, the value is not).
///
/// 7. `TextEditingController` IN `_showReplyDialog` WAS NEVER DISPOSED.
///
/// 8. THE LOADER WAS POSITIONED WITH `EdgeInsets.only(top: 350)` — a magic
///    number that sat off-screen on small devices and mid-page on tablets.
/// ----------------------------------------------------------------------------
class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  bool _isLoading = true;
  Object? _loadError;
  List<dynamic> _reviews = [];

  /// Review ids whose reply PUT is currently in flight.
  final Set<int> _replyingIds = {};

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  // ==========================================================================
  // SAFE ACCESSORS
  // ==========================================================================

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return const {};
  }

  static String _str(dynamic v) {
    if (v == null) return '';
    return v.toString().trim();
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// Rating as a 0-5 int, whatever shape the API sends it in (the endpoint has
  /// been observed returning both `4` and `"4"`).
  static int _rating(dynamic v) {
    final parsed = _asInt(v) ?? double.tryParse(_str(v))?.round() ?? 0;
    return parsed.clamp(0, 5);
  }

  // ==========================================================================
  // ✅ FETCH REVIEWS  (endpoint unchanged)
  // ==========================================================================
  Future<void> fetchReviews() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      // AUDIT FIX (bug 6): the token value is no longer logged.
      // AUDIT FIX: read only `token` before; `authToken` is the fallback every
      // other screen uses, so this one failed for sessions that only had it.
      final token = await SessionManager.getToken();

      if (token == null) {
        debugPrint('❌ No token in storage — cannot load reviews');
        throw const ReviewsException(
          'Your session has expired.\nPlease log in again.',
        );
      }

      final response = await http.get(
        Uri.parse('https://happywedz.com/api/reviews/my-reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('🟡 my-reviews status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw ReviewsException(
          AppErrorState.messageForStatus(response.statusCode),
        );
      }

      final data = json.decode(response.body);

      // AUDIT NOTE: the original required BOTH `success == true` AND a
      // non-null `reviews`, and treated anything else as "no reviews".
      // A vendor with genuinely zero reviews and a malformed response were
      // indistinguishable. An explicit `success: false` is now an error; a
      // 200 with an empty/absent list is a genuine empty state.
      if (data is Map && data['success'] == false) {
        throw ReviewsException(
          _str(data['message']).isNotEmpty
              ? _str(data['message'])
              : "We couldn't load your reviews.\nPlease try again.",
        );
      }

      final reviews = (data is Map) ? data['reviews'] : null;

      if (!mounted) return;
      setState(() {
        _reviews = reviews is List ? reviews : <dynamic>[];
        _isLoading = false;
        _loadError = null;
      });
      debugPrint('✅ Reviews fetched. Count: ${_reviews.length}');
    } catch (e) {
      debugPrint('🔥 Error fetching reviews: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e;
        _reviews = [];
      });
    }
  }

  // ==========================================================================
  // ✅ SEND REPLY  (endpoint / method / body unchanged)
  // ==========================================================================
  Future<bool> _sendReply(int reviewId, String message) async {
    final url = Uri.parse('https://happywedz.com/api/reviews/reply/$reviewId');
    debugPrint('✉️ Sending reply for review $reviewId');

    final token = await SessionManager.getToken();
    if (token == null) {
      debugPrint('❌ No token — cannot send reply');
      return false;
    }

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"vendor_reply": message}),
      ).timeout(const Duration(seconds: 30));

      debugPrint('🟢 Reply status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return true;
        setState(() {
          final idx = _reviews.indexWhere(
            (r) => r is Map && _asInt(r['id']) == reviewId,
          );
          if (idx != -1) {
            _reviews[idx]['vendor_reply'] = message;
          }
        });
        return true;
      }

      debugPrint('❌ Reply failed with ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('🔥 Error sending reply: $e');
      return false;
    }
  }

  // ==========================================================================
  // ✅ DIALOG FOR REPLY INPUT
  // ==========================================================================
  Future<void> _showReplyDialog(int? reviewId, String? existingReply) async {
    if (reviewId == null) {
      // AUDIT FIX: `_showReplyDialog(r['id'], …)` passed whatever the API sent.
      // A null id produced a PUT to `/reviews/reply/null`.
      AppSnackbar.error(
        context,
        "This review is missing its id and can't be replied to.",
      );
      return;
    }

    final ctrl = TextEditingController(text: existingReply ?? '');

    try {
      final message = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          backgroundColor: AppColors.surface,
          title: Text(
            existingReply == null || existingReply.isEmpty
                ? 'Reply to review'
                : 'Edit your reply',
            style: AppTextStyles.h3.copyWith(color: AppColors.primary),
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 4,
            // AUDIT FIX: unbounded input. The endpoint rejects very long
            // replies with a 500 and the vendor saw nothing at all.
            maxLength: 1000,
            style: AppTextStyles.input,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Type your reply…',
              filled: true,
              fillColor: AppColors.inputFill,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final msg = ctrl.text.trim();
                if (msg.isEmpty) {
                  // AUDIT FIX: an empty reply used to close the dialog and do
                  // nothing, with no explanation.
                  AppSnackbar.warning(ctx, "Please write a reply first.");
                  return;
                }
                Navigator.pop(ctx, msg);
              },
              child: const Text('Send'),
            ),
          ],
        ),
      );

      if (message == null || !mounted) return;

      // AUDIT FIX (bug 5): a real in-flight state, so the reply cannot be
      // submitted twice, and a real success/failure message either way.
      setState(() => _replyingIds.add(reviewId));
      final ok = await _sendReply(reviewId, message);

      if (!mounted) return;
      setState(() => _replyingIds.remove(reviewId));

      if (ok) {
        AppSnackbar.success(context, "Your reply has been posted.");
      } else {
        AppSnackbar.error(
          context,
          "Couldn't post your reply. Please try again.",
        );
      }
    } finally {
      // AUDIT FIX (bug 7): the controller is disposed on every exit path.
      ctrl.dispose();
    }
  }

  // ==========================================================================
  // UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.listBackground,
      body: RefreshIndicator(
        // AUDIT FIX: there was no way to refresh this screen at all.
        color: AppColors.primary,
        onRefresh: fetchReviews,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildHeader(),
            _bodySliver(),
          ],
        ),
      ),
    );
  }

  Widget _bodySliver() {
    // AUDIT FIX (bugs 4 + 8): distinct states, and none of them positioned
    // with a magic `top: 350` padding.
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: ListShimmer(itemCount: 4, itemHeight: 150),
      );
    }

    if (_loadError != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorState(
          title: "Couldn't load your reviews",
          message: _loadError is ReviewsException
              ? (_loadError as ReviewsException).message
              : AppErrorState.messageFor(_loadError),
          onRetry: fetchReviews,
        ),
      );
    }

    if (_reviews.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          icon: Icons.star_outline_rounded,
          title: 'No reviews yet',
          message:
              'When your clients leave a review it will appear here.\n'
              'Use "Ask for Reviews" on the dashboard to invite them.',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _buildReviewCard(_reviews[i]),
        childCount: _reviews.length,
      ),
    );
  }

  // AUDIT NOTE — PRE-EXISTING COMMENTED-OUT build(), RETAINED VERBATIM.
  // The earlier version that showed the loader in place of the whole page
  // (header included). Already commented out before this audit.
  // Do not delete without project-owner approval.
  //
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.white,
  //     body: _isLoading
  //         ? const Center(child: CircularProgressIndicator(color: Colors.pink))
  //         : _reviews.isEmpty
  //         ? const Center(child: Text('No reviews available',
  //             style: TextStyle(fontSize: 16, color: Colors.grey)))
  //         : CustomScrollView(
  //       slivers: [
  //         _buildHeader(),
  //         SliverList(
  //           delegate: SliverChildBuilderDelegate(
  //                 (context, i) {
  //               final r = _reviews[i];
  //               debugPrint('🧾 Building Review Card for ID: ${r['id']}');
  //               return _buildReviewCard(r);
  //             },
  //             childCount: _reviews.length,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ✅ MODERN HEADER
  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 70,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.headerGradient,
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        padding: EdgeInsets.fromLTRB(20, topPad + 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text('My Reviews', style: AppTextStyles.headerLarge),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _isLoading ? null : fetchReviews,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MODERN REVIEW CARD
  Widget _buildReviewCard(dynamic raw) {
    final r = _asMap(raw);

    final userMap = _asMap(r['user']);
    final rawUser = _str(userMap['name']);
    // AUDIT FIX (bug 2): `?? 'Anonymous'` only caught null; an empty-string
    // name reached `user[0]` and threw a RangeError.
    final user = rawUser.isEmpty ? 'Anonymous' : rawUser;

    final reviewId = _asInt(r['id']);
    final title = _str(r['title']);
    final comment = _str(r['comment']);
    final vendorReply = _str(r['vendor_reply']);
    final date = _str(r['createdAt']);
    final rating = _rating(r['rating_quality']);

    // AUDIT FIX (bug 3): review media is now actually rendered.
    final media = r['media'];
    final mediaUrls = media is List
        ? media
            .map((m) {
              if (m is String) return m;
              if (m is Map) {
                return _str(m['url'] ?? m['path'] ?? m['image']);
              }
              return '';
            })
            .where((u) => u.isNotEmpty)
            .toList()
        : const <String>[];

    final replying = reviewId != null && _replyingIds.contains(reviewId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            // AUDIT FIX: the shadow was `Colors.pink.withOpacity(0.15)` — a
            // pink glow under every card in an otherwise all-blue app.
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 USER HEADER
            Row(
              children: [
                AppNetworkAvatar(
                  url: _str(userMap['profileImage']),
                  radius: 22,
                  fallbackText: user,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h3,
                      ),
                      if (date.isNotEmpty)
                        Text(_formatDate(date), style: AppTextStyles.caption),
                    ],
                  ),
                ),
                _ratingPill(rating),
              ],
            ),

            const SizedBox(height: 12),

            // 🔹 STARS
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.rating,
                  size: 20,
                );
              }),
            ),

            if (title.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(title, style: AppTextStyles.h3),
            ],

            if (comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(comment, style: AppTextStyles.bodySecondary),
            ],

            // 🔹 REVIEW PHOTOS (bug 3 — previously fetched and discarded)
            if (mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: mediaUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => AppNetworkImage(
                    url: mediaUrls[i],
                    width: 84,
                    height: 84,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],

            // 🔹 VENDOR REPLY
            if (vendorReply.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  // AUDIT FIX (bug 1): brand tint + dark text. The previous
                  // combination (white on #BBDEFB) made every reply invisible.
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Your reply',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vendorReply,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 🔹 ACTION BUTTON
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: vendorReply.isEmpty ? 'Reply' : 'Edit Reply',
                icon: Icons.reply_rounded,
                fullWidth: false,
                size: AppButtonSize.small,
                isLoading: replying,
                onPressed: () => _showReplyDialog(reviewId, vendorReply),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingPill(int rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.rating.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFB8860B)),
          const SizedBox(width: 3),
          Text(
            '$rating.0',
            style: AppTextStyles.labelSmall.copyWith(
              color: const Color(0xFFB8860B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// AUDIT FIX: the old card did `date.split('T').first`, which printed
  /// "2026-02-14" — an ISO fragment rather than a formatted date — and threw
  /// if `createdAt` was not a String.
  static String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.split('T').first;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }
}

/// Carries user-facing copy for a failed reviews load.
class ReviewsException implements Exception {
  final String message;
  const ReviewsException(this.message);

  @override
  String toString() => message;
}
