import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/Screens/StatsScreen.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../Storefront/PhotosScreen.dart';
import '../Storefront/StoreFront.dart';
import '../api_services/api_service_vendor.dart';
import '../auth/auth_guard.dart';
import '../auth/session_manager.dart';
import '../movments_plus/bottom_bar.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_states.dart';
import 'FAQs/storefront_percentage_bar.dart';
import 'LeadsScreen.dart';
import 'ReviewScreen.dart';
import 'ViewPlanScreen.dart';
import 'drawer.dart';
import 'new_screens/review_collector.dart';

/// AUDIT NOTE — REMOVED IMPORTS (import lines only; NO code was deleted)
///
/// The 13 `FAQs/*.dart` imports and `movments_plus/dashboard_screen.dart` were
/// here for the `faqScreens` map inside `_HomeTabState`. That map is consumed
/// only by `_quickActionsBar`, which was ALREADY commented out before this
/// audit, so nothing referenced any of them — the analyzer flagged every one
/// as `unused_import`. FAQ routing in the live app happens in
/// `Storefront.openFaq`, which keys off `vendorTypeId` and carries its own
/// imports. The map itself is retained (commented) further down this file.

/// ============================================================================
/// HomeScreen — authenticated shell (bottom navigation + FAB)
/// ============================================================================
///
/// AUDIT NOTE:
/// This is the root of ALL authenticated UI. Every protected screen is reached
/// by an imperative push originating here or from the drawer, so wrapping this
/// in [AuthGuard] (done at the Splash and Login call sites) guards the entire
/// authenticated surface. There are no named routes and no deep links that
/// could bypass it — verified against AndroidManifest.xml, which declares only
/// the LAUNCHER intent-filter.
/// ----------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// AUDIT NOTE: exposing the private State type is what `_queriesCard` uses
  /// to switch to the Enquirys tab (`HomeScreen.of(context)?._onItemTapped(1)`).
  /// Both call sites live in this same library, so the pattern works. Changing
  /// it would mean introducing a controller/notifier — an architectural change
  /// the audit brief explicitly rules out ("do not over-refactor"), so the
  /// existing pattern is kept and the lint is silenced locally.
  // ignore: library_private_types_in_public_api
  static _HomeScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_HomeScreenState>();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  int? vendorTypeId;
  bool isLoadingVendor = true;

  final List<Widget> _pages = const [
    HomeTab(), // 0
    LeadsPage(), // 1
    ReviewsPage(), // 2
    StatsPage(), // 3
  ];

  /// ✅ Photographer check
  bool get isPhotographer => vendorTypeId == 1;

  @override
  void initState() {
    super.initState();
    _loadVendorType();
  }

  Future<void> _loadVendorType() async {
    final id = await SessionManager.getVendorTypeId();

    debugPrint("🏷 HomeScreen vendorTypeId = $id");

    // AUDIT FIX: the old setState here had no `mounted` guard. Backing out of
    // the Dashboard during the prefs read threw "setState() called after
    // dispose()".
    if (!mounted) return;
    setState(() {
      vendorTypeId = id;
      isLoadingVendor = false;
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingVendor) {
      // AUDIT FIX: was a bare centred CircularProgressIndicator on a blank
      // page. Now a skeleton of the dashboard that is about to appear.
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primaryDark,
          elevation: 0,
          title: Text("HappyWedz Business", style: AppTextStyles.appBarTitle),
        ),
        body: const HomeShimmer(),
      );
    }

    return Scaffold(
      body: _pages[_selectedIndex],

      /// 🔥 FLOATING + ONLY FOR PHOTOGRAPHER
      floatingActionButton: isPhotographer
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              elevation: 6,
              tooltip: "Open Moments+",
              onPressed: () {
                // AUDIT FIX: was a bare `Navigator.push`. `MainHomeScreen` is
                // a second authenticated root (dashboard, token sharing,
                // uploads, gallery), so it goes through the guard too.
                AuthGuard.push(
                  context,
                  (_) => const MainHomeScreen(),
                  debugLabel: 'MainHomeScreen',
                );
              },
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            )
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // AUDIT NOTE — PRE-EXISTING COMMENTED-OUT BOTTOM BAR, RETAINED VERBATIM.
      // Already commented out before this audit (it used spaceAround and did
      // not reserve the FAB notch). Superseded by `_bottomBar()` below.
      // Do not delete without project-owner approval.
      //
      // bottomNavigationBar: BottomAppBar(
      //   color: Colors.white,
      //   elevation: 10,
      //   shape: isPhotographer
      //       ? const CircularNotchedRectangle()
      //       : null,
      //   notchMargin: isPhotographer ? 8 : 0,
      //   child: SizedBox(
      //     height: 64,
      //     child: Row(
      //       mainAxisAlignment: MainAxisAlignment.spaceAround,
      //       children: [
      //         _bottomItem(index: 0, icon: "assets/icons/home.png", label: "Home"),
      //         _bottomItem(index: 1, icon: "assets/icons/leads.png", label: "Enquirys"),
      //         if (isPhotographer) const SizedBox(width: 40),
      //         _bottomItem(index: 2, icon: "assets/icons/reviews.png", label: "Reviews"),
      //         _bottomItem(index: 3, icon: "assets/icons/statistics.png", label: "Statistics"),
      //       ],
      //     ),
      //   ),
      // ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _bottomBar() {
    return BottomAppBar(
      color: AppColors.surface,
      elevation: 10,
      padding: EdgeInsets.zero,
      shape: isPhotographer ? const CircularNotchedRectangle() : null,
      notchMargin: isPhotographer ? 8 : 0,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              /// 🔹 LEFT ITEMS
              Expanded(
                child: Row(
                  children: [
                    _bottomItem(
                      index: 0,
                      icon: "assets/icons/home.png",
                      fallback: Icons.home_rounded,
                      label: "Home",
                    ),
                    _bottomItem(
                      index: 1,
                      icon: "assets/icons/leads.png",
                      fallback: Icons.inbox_rounded,
                      label: "Enquirys",
                    ),
                  ],
                ),
              ),

              /// 🔥 CENTER FAB SPACE
              if (isPhotographer) const SizedBox(width: 64),

              /// 🔹 RIGHT ITEMS
              Expanded(
                child: Row(
                  children: [
                    _bottomItem(
                      index: 2,
                      icon: "assets/icons/reviews.png",
                      fallback: Icons.star_rounded,
                      label: "Reviews",
                    ),
                    _bottomItem(
                      index: 3,
                      icon: "assets/icons/statistics.png",
                      fallback: Icons.bar_chart_rounded,
                      label: "Statistics",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 BOTTOM ITEM WIDGET
  Widget _bottomItem({
    required int index,
    required String icon,
    required IconData fallback,
    required String label,
  }) {
    final bool isSelected = _selectedIndex == index;
    final Color color = isSelected ? AppColors.primary : AppColors.textTertiary;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                icon,
                height: 21,
                color: color,
                // AUDIT FIX: a missing/renamed icon asset previously painted a
                // full-size Flutter image-error box inside the 64px bar and
                // threw a RenderFlex overflow across the whole nav bar.
                errorBuilder: (_, __, ___) =>
                    Icon(fallback, size: 21, color: color),
              ),
              const SizedBox(height: 4),
              // AUDIT FIX: at large system font scales "Statistics" overflowed
              // its slot. FittedBox scales it instead of overflowing.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// AUDIT NOTE — PRE-EXISTING COMMENTED-OUT HomeScreen, RETAINED VERBATIM.
// The earlier BottomNavigationBar-based implementation. Already commented out
// before this audit; superseded by the BottomAppBar version above, which
// supports the photographer FAB notch.
// Kept intentionally. Do not delete without project-owner approval.
// ============================================================================
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   static _HomeScreenState? of(BuildContext context) =>
//       context.findAncestorStateOfType<_HomeScreenState>();
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;
//
//   final List<Widget> _defaultPages = [
//     const HomeTab(),     // 0 - Home
//     const LeadsPage(),   // 1 - Leads
//     const ReviewsPage(), // 2 - Reviews
//     const StatsPage(),   // 3 - stats
//   ];
//
//   late List<Widget> _pages;
//
//   @override
//   void initState() {
//     super.initState();
//     _pages = List.from(_defaultPages);
//   }
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _pages[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: Colors.white,
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         selectedItemColor: const Color(0xFF00509D),
//         unselectedItemColor: Colors.grey,
//         type: BottomNavigationBarType.fixed,
//         items: [
//           BottomNavigationBarItem(
//             icon: Image.asset("assets/icons/home.png", height: 24,
//               color: _selectedIndex == 0 ? const Color(0xFF00509D) : Colors.grey),
//             label: "Home",
//           ),
//           BottomNavigationBarItem(
//             icon: Image.asset("assets/icons/leads.png", height: 24,
//               color: _selectedIndex == 1 ? const Color(0xFF00509D) : Colors.grey),
//             label: "Enquirys",
//           ),
//           BottomNavigationBarItem(
//             icon: Image.asset("assets/icons/reviews.png", height: 24,
//               color: _selectedIndex == 2 ? const Color(0xFF00509D) : Colors.grey),
//             label: "Reviews",
//           ),
//           BottomNavigationBarItem(
//             icon: Image.asset("assets/icons/statistics.png", height: 24,
//               color: _selectedIndex == 3 ? const Color(0xFF00509D) : Colors.grey),
//             label: "Statistics",
//           ),
//         ],
//       ),
//     );
//   }
// }

// ---------------- Home Tab ----------------

/// ============================================================================
/// HomeTab — the vendor dashboard
/// ============================================================================
///
/// API INTEGRATION IS UNCHANGED:
///   GET https://happywedz.com/api/inbox                              (unread)
///   GET https://happywedz.com/api/vendor-services/vendor/{vendorId}  (serviceId)
///   GET https://happywedz.com/api/vendor-services/{serviceId}/storefront-completion
///
/// AUDIT NOTE — BUGS FIXED
///
/// 1. THE UNREAD COUNT WAS FETCHED TWICE ON EVERY MOUNT.
///    `initState` called BOTH `_startUnreadPolling()` — which immediately
///    awaits `_refreshUnread()` — AND `_loadUnreadCount()`. Two identical GETs
///    to /api/inbox fired milliseconds apart on every visit to the dashboard.
///
/// 2. THE 20-SECOND POLL LEAKED PAST DISPOSE AND PAST LOGOUT.
///    The poll was a detached `Future.doWhile` with no handle. Its `mounted`
///    check ran only AFTER the 20s delay elapsed, so a disposed tab kept a
///    pending timer alive and — critically — could fire one more authenticated
///    request AFTER logout had cleared the session. It is now a cancellable
///    `Timer.periodic`, torn down in `dispose`, that also stops itself if the
///    session disappears.
///
/// 3. A FAILED PROFILE-COMPLETION FETCH WAS INVISIBLE.
///    `_loadServiceAndProgress` swallowed every failure into a `print` and
///    left `_progress` at 0.0, so a network error was indistinguishable from a
///    genuinely empty storefront — a vendor whose profile was 90% complete was
///    shown "0%". Loading / error / data are now three distinct states.
///
/// 4. NO PULL-TO-REFRESH — the dashboard could only be refreshed by switching
///    tabs or restarting the app.
///
/// 5. DEAD STATE FIELDS. `_recentLeads` and the old `_isLoading` were written
///    by `_fetchRecentLeads`, which was already commented out; `_recentLeads`
///    was never read by any live widget (flagged `unused_field`).
/// ----------------------------------------------------------------------------
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  double _progress = 0.0;

  /// AUDIT NOTE: read from storage but not rendered by any live widget — it is
  /// the lookup key for the retained (commented-out) `faqScreens` map further
  /// down this file. Kept, with the loader intact, so that map still works if
  /// the Quick Actions bar is ever restored.
  /// Do not delete without project-owner approval.
  // ignore: unused_field
  String _vendorTypeName = "";

  bool _isLoading = true;
  Object? _loadError;

  int _unreadCount = 0;

  final VendorServiceApi _vendorApi = VendorServiceApi();
  int? _serviceId;

  /// AUDIT FIX (bug 2): a real, cancellable handle.
  Timer? _unreadPollTimer;
  static const Duration _unreadPollInterval = Duration(seconds: 20);

  // ==========================================================================
  // AUDIT NOTE — RETAINED, CURRENTLY UNREFERENCED
  //
  // `faqScreens` was consumed only by `_quickActionsBar`, which was already
  // commented out before this audit. Live FAQ routing is `Storefront.openFaq`,
  // keyed on vendorTypeId. `_vendorTypeName` is still loaded below because
  // this map is keyed by it. Kept per the audit rules.
  //
  // Do not delete without project-owner approval.
  // ==========================================================================
  //
  // final Map<String, Widget Function()> faqScreens = {
  //   "photographers": () => const PhotographerFaqScreen(),
  //   "venues": () => const VenueFaqScreen(),
  //   "makeup": () => const BridalMakeupFaqScreen(),
  //   "planning and decor": () => DecoratorFaqScreen(),
  //   "caterers": () => CatererFaqScreen(),
  //   "invites and gifts": () => GiftsScreen(),
  //   "florists": () => FloristFaqScreen(),
  //   "pandits": () => PanditsFaqScreen(),
  //   "bridal": () => BridalwearFaqScreen(),
  //   "groom": () => GroomwearScreen(),
  //   "jewellery and accessories": () => JewelleryFaqScreen(),
  //   "mehndi": () => MehendiArtistsScreen(),
  //   "music and dance": () => WeddingDjScreen(),
  // };

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _startUnreadPolling();
  }

  @override
  void dispose() {
    // AUDIT FIX (bug 2): the poll is now actually stopped.
    _unreadPollTimer?.cancel();
    _unreadPollTimer = null;
    super.dispose();
  }

  // ==========================================================================
  // LOAD
  // ==========================================================================

  /// Single entry point for the whole dashboard: used by initState, by
  /// pull-to-refresh, and by the error state's Retry.
  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      await Future.wait([
        _loadVendorType(),
        _loadServiceAndProgress(),
        // AUDIT FIX (bug 1): the unread count is fetched exactly ONCE here,
        // not once here and again on the poller's first tick.
        _refreshUnread(),
      ]);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      debugPrint("❌ Dashboard load failed: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e;
      });
    }
  }

  Future<void> _loadVendorType() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(SessionManager.kVendorTypeName) ?? "";
    if (!mounted) return;
    setState(() => _vendorTypeName = name);
  }

  /// GET vendor-services/vendor/{id} → serviceId, then the completion GET.
  /// Endpoints, methods and headers unchanged.
  Future<void> _loadServiceAndProgress() async {
    final token = await SessionManager.getToken();
    final vendorId = await SessionManager.getVendorId();

    if (token == null || vendorId == null) {
      // AUDIT FIX: this used to `print` and return, leaving the bar silently
      // at 0%. A missing token/vendorId is a session problem — surface it.
      throw StateError('Session incomplete: token or vendorId missing');
    }

    // 🔥 Step 1: get serviceId
    final serviceId = await _vendorApi.getServiceIdByVendorId(
      vendorId: vendorId,
      token: token,
    );

    if (serviceId == null) {
      // A vendor who has not created their storefront yet legitimately has no
      // service record. That is genuinely 0%, not an error.
      debugPrint("ℹ️ No vendor-service yet for vendor $vendorId → 0% complete");
      if (!mounted) return;
      setState(() => _progress = 0.0);
      return;
    }

    _serviceId = serviceId;
    debugPrint("✅ Service ID: $_serviceId");

    // 🔥 Step 2: fetch profile completion
    final progress = await ProfileCompletionService.fetchCompletion(
      serviceId: _serviceId!,
    );

    if (!mounted) return;
    // AUDIT FIX: clamped. The endpoint returns an int percentage, and a value
    // above 100 (observed once every storefront section is filled) produced a
    // LinearProgressIndicator with value > 1.0, which asserts in debug.
    setState(() => _progress = progress.clamp(0.0, 1.0));
  }

  // ==========================================================================
  // UNREAD COUNT (GET /api/inbox — endpoint unchanged)
  // ==========================================================================

  Future<int> _fetchUnreadCountFromApi() async {
    final token = await SessionManager.getToken();
    if (token == null) return 0;

    final res = await http.get(
      Uri.parse('https://happywedz.com/api/inbox'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      debugPrint("⚠️ /api/inbox returned ${res.statusCode}");
      return 0;
    }

    final data = jsonDecode(res.body);
    // AUDIT FIX: `final List leads = data['inbox'] ?? []` threw a raw TypeError
    // whenever the key held anything other than a list (the endpoint returns
    // an object on error), and that TypeError surfaced as an unhandled
    // exception inside the 20s poll.
    final inbox = (data is Map) ? data['inbox'] : null;
    if (inbox is! List) return 0;

    return inbox.where((item) {
      if (item is! Map) return false;
      // Only an explicit `false` counts as unread; a missing key must not
      // inflate the badge.
      return item['isRead'] == false && item['isArchived'] == false;
    }).length;
  }

  void _startUnreadPolling() {
    _unreadPollTimer?.cancel();
    _unreadPollTimer = Timer.periodic(_unreadPollInterval, (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // AUDIT FIX (bug 2): never poll with a session that no longer exists —
      // this is what kept firing 401s after logout.
      if (!await SessionManager.isAuthenticated()) {
        debugPrint("🔒 Unread poll stopped — no valid session");
        timer.cancel();
        return;
      }
      await _refreshUnread();
    });
  }

  Future<void> _refreshUnread() async {
    try {
      final count = await _fetchUnreadCountFromApi();
      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (e) {
      // A failed BACKGROUND poll must not replace the dashboard with an error
      // screen — the badge simply keeps its last known value.
      debugPrint("🔥 UNREAD API ERROR => $e");
    }
  }

  // ==========================================================================
  // UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: "Menu",
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: Text("HappyWedz Business", style: AppTextStyles.appBarTitle),
      ),
      drawer: const BusinessDrawer(),
      body: RefreshIndicator(
        // AUDIT FIX (bug 4): pull-to-refresh on the dashboard.
        color: AppColors.primary,
        onRefresh: _loadDashboard,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_isLoading) return const HomeShimmer();

    if (_loadError != null) {
      // AUDIT FIX (bug 3): a real error state instead of a silent 0%.
      // Rendered inside a scrollable so pull-to-refresh still works here.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.10),
          AppErrorState(
            expand: false,
            message: AppErrorState.messageFor(_loadError),
            onRetry: _loadDashboard,
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        children: [
          ProfileCompletionBar(progress: _progress, onTap: _openStorefront),
          const SizedBox(height: 15),
          if (_unreadCount > 0) ...[
            _queriesCard(context),
            const SizedBox(height: 15),
          ],
          const SizedBox(height: 10),
          _uploadAlbumCard(context),
          const SizedBox(height: 24),
          _getReviewsCard(context),
          const SizedBox(height: 24),
          _membershipPlansCard(context),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _openStorefront() async {
    final vendorId = await SessionManager.getVendorId();

    if (!mounted) return;

    if (vendorId == null) {
      // AUDIT FIX: was a silent `debugPrint` + `return` — tapping the profile
      // completion bar did nothing at all and the vendor had no idea why.
      AppSnackbar.warning(
        context,
        "We couldn't find your vendor profile. Please log in again.",
      );
      return;
    }

    // Refresh the completion bar when the vendor returns from editing.
    await AuthGuard.push(
      context,
      (_) => Storefront(vendorId: vendorId),
      debugLabel: 'Storefront',
    );
    if (mounted) await _loadDashboard();
  }

  Widget _queriesCard(BuildContext context) {
    final int count = _unreadCount;

    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => HomeScreen.of(context)?._onItemTapped(1), // Leads tab
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              // AUDIT FIX (RenderFlex overflow): the label and the "View" link
              // were two unconstrained children of a spaceBetween Row. With a
              // three-digit count, or at a raised font scale, the text pushed
              // "View" past the right edge and threw a RenderFlex overflow.
              Expanded(
                child: Text(
                  count == 1
                      ? "You have 1 new query"
                      : "You have $count new queries",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "View",
                style: AppTextStyles.captionMedium.copyWith(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Feature cards ----------------

  Widget _uploadAlbumCard(BuildContext context) {
    return _FeatureCard(
      icon: Icons.image_outlined,
      title: "Upload Albums",
      subtitle: "Upload more pictures of your work to get more leads",
      child: AppButton(
        label: "Add Album",
        fullWidth: false,
        onPressed: () => AuthGuard.push(
          context,
          (_) => GalleryUploadPage(),
          debugLabel: 'GalleryUploadPage',
        ),
      ),
    );
  }

  Widget _getReviewsCard(BuildContext context) {
    return _FeatureCard(
      icon: Icons.star_border_rounded,
      title: "Get More Reviews",
      subtitle:
          "Improve your credibility by getting more reviews from your clients",
      // AUDIT FIX (RenderFlex overflow): the two pill buttons were direct
      // children of a centred Row with a fixed 16px gap. On a 320dp-wide
      // device — and at any raised font scale — they overflowed the card.
      // `Wrap` lets them stack instead of overflowing.
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          AppPillButton(
            label: "Ask for Reviews",
            onPressed: () => AuthGuard.push(
              context,
              (_) => const ReviewCollectorScreen(),
              debugLabel: 'ReviewCollectorScreen',
            ),
          ),
          AppPillButton(
            label: "Upload Reviews",
            onPressed: () async {
              await Share.share(
                "Hey! Please share your review about my work 😊",
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _membershipPlansCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_membership, color: AppColors.primary, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Upgrade to Premium Membership to get more leads & visibility",
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ViewPlansScreen()),
            ),
            child: Text(
              "View Plans",
              style: AppTextStyles.buttonSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared layout for the two large dashboard promo cards, so their padding,
/// radius, icon size and typography cannot drift apart again.
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// AUDIT NOTE — RETAINED, UNREFERENCED HELPERS
//
// `_profileCompletionCard` was never called from anywhere (the live dashboard
// uses `ProfileCompletionBar` from FAQs/storefront_percentage_bar.dart) and
// rendered a card with a title and nothing beneath it. `_buildCard` was used
// only by `_profileCompletionCard` and by the membership card, which now
// builds its own container from the design tokens.
//
// `_roundedOutlineButton` was this screen's ad-hoc pill button; it is
// superseded by the shared `AppPillButton`, which is visually identical and
// adds a loading state.
//
// `_quickActionsBar` and `_phoneUpdateCard` were ALREADY commented out before
// this audit and are reproduced verbatim below.
//
// All kept intentionally. Do not delete without project-owner approval.
// ============================================================================
//
// AUDIT NOTE — PRE-EXISTING COMMENTED-OUT METHOD FROM `_HomeTabState`,
// RETAINED VERBATIM.
//
// `_fetchRecentLeads` was already commented out before this audit. It is the
// reason the `_recentLeads` field existed (flagged `unused_field`), and it is
// the only consumer of the "recent leads" idea on the dashboard. Reproduced
// here unchanged so the implementation is not lost — note that it hits the
// SAME endpoint the live unread-count already calls
// (GET https://happywedz.com/api/inbox), so restoring it should reuse that
// response rather than issuing a second request.
//
// Kept intentionally. Do not delete without project-owner approval.
//
// Future<void> _fetchRecentLeads() async {
//   setState(() => _isLoading = true);
//   try {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString('token') ?? prefs.getString('authToken');
//
//     if (token == null || token.isEmpty) {
//       print("🔴 No token found");
//       setState(() => _isLoading = false);
//       return;
//     }
//
//     final response = await http.get(
//       Uri.parse("https://happywedz.com/api/inbox"),
//       headers: {
//         "Accept": "application/json",
//         "Authorization": "Bearer $token",
//       },
//     );
//
//     print("🟢 Recent Leads Status: ${response.statusCode}");
//     print(response.body);
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       setState(() {
//         final leads = data["inbox"] ?? data["data"] ?? [];
//         _recentLeads = leads.take(2).toList(); // show top 2
//         _isLoading = false;
//       });
//     } else {
//       print("❌ Failed: ${response.statusCode}");
//       setState(() => _isLoading = false);
//     }
//   } catch (e) {
//     print("⚠️ Error fetching recent leads: $e");
//     setState(() => _isLoading = false);
//   }
// }

// Widget _profileCompletionCard() {
//   return _buildCard(
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Complete your profile",
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//         const SizedBox(height: 8),
//       ],
//     ),
//   );
// }
//
// Widget _buildCard({required Widget child, Color? color}) {
//   return Container(
//     margin: const EdgeInsets.only(bottom: 12),
//     padding: const EdgeInsets.all(12),
//     decoration: BoxDecoration(
//       color: color ?? Colors.white,
//       borderRadius: BorderRadius.circular(12),
//     ),
//     child: child,
//   );
// }
//
// Widget _roundedOutlineButton({required String label, required VoidCallback onTap}) {
//   return OutlinedButton(
//     onPressed: onTap,
//     style: OutlinedButton.styleFrom(
//       side: const BorderSide(color: Colors.black54),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
//       padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 26),
//     ),
//     child: Text(label, textAlign: TextAlign.center,
//         style: const TextStyle(fontSize: 15, color: Colors.black87)),
//   );
// }
//
// Widget _quickActionsBar(
//     BuildContext context,
//     String vendorTypeName,
//     Map<String, Widget Function()> faqScreens,
//     ) {
//   final actions = [
//     {
//       "icon": Icons.question_answer_outlined,
//       "title": "Answer FAQs",
//       "onTap": () {
//         final screenBuilder = faqScreens[vendorTypeName.trim().toLowerCase()];
//         if (screenBuilder != null) {
//           Navigator.push(context, MaterialPageRoute(
//             builder: (_) => ProfilescreenWithNext(onNext: () {
//               Navigator.push(context, MaterialPageRoute(builder: (_) => screenBuilder()));
//             }),
//           ));
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("No FAQ screen available for your vendor type")),
//           );
//         }
//       }
//     },
//     {
//       "icon": Icons.link,
//       "title": "Link Facebook page /Website",
//       "onTap": () {
//         Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilescreenWithNext()));
//       }
//     },
//     // {
//     //   "icon": Icons.add_a_photo,
//     //   "title": "Add Images to portfolio",
//     //   "onTap": () {
//     //     Navigator.push(context, MaterialPageRoute(builder: (_) => PortfoliioPage()));
//     //   }
//     // },
//     {
//       "icon": Icons.cloud_upload,
//       "title": "Upload the first Album",
//       "onTap": () {
//         Navigator.push(context, MaterialPageRoute(builder: (_) => AlbumsPage()));
//       }
//     },
//     {
//       "icon": Icons.reviews,
//       "title": "Get Client Review to You",
//       "onTap": () async {
//         await Share.share("Hey! Please share your review about my work 😊",
//           subject: "Client Review Request");
//       },
//     },
//   ];
//
//   return Padding(
//     padding: const EdgeInsets.only(left: 12, top: 2, bottom: 4),
//     child: SizedBox(
//       height: 38,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: actions.length,
//         itemBuilder: (context, index) {
//           final item = actions[index];
//           return GestureDetector(
//             onTap: item["onTap"] as void Function()?,
//             child: Container(
//               margin: const EdgeInsets.only(right: 8),
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFE0F7FA),
//                 borderRadius: BorderRadius.circular(24),
//                 border: Border.all(color: const Color(0xFF00BCD4), width: 0.8),
//               ),
//               child: Row(
//                 children: [
//                   Icon(item["icon"] as IconData, size: 15, color: const Color(0xFF00BCD4)),
//                   const SizedBox(width: 4),
//                   Text(item["title"] as String,
//                     style: const TextStyle(fontSize: 11.5,
//                       fontWeight: FontWeight.w500, color: Colors.black87)),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     ),
//   );
// }
//
// Widget _phoneUpdateCard() {
//   return Container(
//     padding: const EdgeInsets.all(16),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(color: Colors.grey.shade300),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Have any queries? Speak to happy Weds Team",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//         const SizedBox(height: 16),
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton.icon(
//             onPressed: () {},
//             icon: const Icon(Icons.phone, color: Colors.white),
//             label: const Text("Request Call Back",
//               style: TextStyle(color: Colors.white, fontSize: 16)),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF00509D),
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

/// ============================================================================
/// GetNowPage
/// ============================================================================
///
/// AUDIT NOTE:
/// This screen is NOT referenced anywhere in the project (verified by grep
/// across lib/ — no import, no constructor call, no route). It duplicates
/// `ViewPlansScreen` (lib/Screens/ViewPlanScreen.dart), which IS the live
/// "Coming Soon" membership screen reached from the dashboard.
///
/// KEPT, not deleted, per the audit rules. It is left functional but moved
/// onto the brand palette: the original used a pink→cyan gradient
/// (#FFB6C1 → #00BCD4) that appears nowhere else in this app, and painted a
/// WHITE AppBar title on a #E0F7FA background — invisible in practice.
///
/// Its Lottie animation is fetched over the network with no error handling; an
/// `errorBuilder` is added so a failed fetch cannot break the page.
///
/// Do not delete without project-owner approval.
/// ----------------------------------------------------------------------------
class GetNowPage extends StatelessWidget {
  const GetNowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Boost Your Reviews", style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_x62chJ.json',
                width: 220,
                repeat: true,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.rocket_launch_outlined,
                  size: 120,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "Coming Soon!",
                style: AppTextStyles.h1.copyWith(
                  fontSize: 32,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Exciting Membership Plans are on the way.\nStay tuned for amazing benefits!",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 36),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  "Stay Tuned 💙",
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}