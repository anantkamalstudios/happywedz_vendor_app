
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_guard.dart';
import '../auth/session_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_states.dart';
import 'new_screens/leaddetails_screen.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

/// ============================================================================
/// LeadsPage ("Enquirys") — the vendor's inbox
/// ============================================================================
///
/// API INTEGRATION IS UNCHANGED:
///   GET    https://happywedz.com/api/inbox
///   GET    https://happywedz.com/api/messages/vendor/conversations
///   PATCH  https://happywedz.com/api/inbox/{id}/read
///   PATCH  https://happywedz.com/api/inbox/{id}/archive
///   DELETE https://happywedz.com/api/inbox/{id}
/// Same URLs, methods, headers and bodies.
///
/// AUDIT NOTE — BUGS FIXED
///
/// 1. NULL CRASH BUILDING A LEAD CARD (high severity).
///        final lead = item['request'];
///        final name = "${lead['firstName']} ${lead['lastName']}";
///    `request` is null for any inbox row whose originating request was
///    deleted server-side. Indexing null threw
///    `NoSuchMethodError: '[]' was called on null` from inside
///    `ListView.builder`, which takes down the ENTIRE list — one orphaned row
///    made the whole Enquirys tab render a red error box.
///
/// 2. NULL CRASH IN THE POPUP MENU.
///        Icon(item['isArchived'] ? Icons.unarchive : Icons.archive)
///    A null `isArchived` threw `type 'Null' is not a subtype of type 'bool'`
///    the moment the ⋯ menu was opened.
///
/// 3. NULL CRASH IN SEARCH.
///        final r = l['request'];  "${r['firstName']}…"
///    Same null `request`, but this one fired on every keystroke in the search
///    box, so typing a single character crashed the screen.
///
/// 4. `.isEmpty` ON A NON-STRING.
///        final msg = (lead['message'] ?? '').isEmpty ? … : lead['message'];
///    When `message` came back as a number this threw.
///
/// 5. A FAILED FETCH LOOKED LIKE AN EMPTY INBOX.
///    `_fetchLeads` caught everything into a `debugPrint` and left `_leads`
///    empty, so a network failure showed "No leads found" — telling the vendor
///    they had no enquiries when the request had actually failed. Loading /
///    empty / error are now three distinct states with a working Retry.
///
/// 6. `_markAsRead` AND THE FOLLOW-UP `_fetchLeads()` RAN UNGUARDED after the
///    detail screen popped, so leaving the tab quickly threw
///    "setState() called after dispose()".
///
/// 7. THE SEARCH BOX IGNORED THE ACTIVE FILTER.
///    Searching silently discarded the selected chip (`if (query.isEmpty)`),
///    so searching inside "Archived" returned non-archived results. Filter and
///    query are now applied together, which is what the chip UI implies.
///
/// 8. THE SEARCH HINT LIED. It promised "name, city, event" but only the name
///    was ever matched. All those fields are already present in the existing
///    response, so no API change was needed to honour it.
/// ----------------------------------------------------------------------------
class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  /// AUDIT NOTE: a mutable public static used as a cross-screen cache. Kept
  /// (other code may read it), but it is now cleared whenever the list is
  /// cleared so it cannot outlive a session.
  static List<dynamic> latestLeads = [];

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedFilter = 'All Enquiries';

  bool _isLoading = true;
  Object? _loadError;

  /// 🔥 SERVER inbox list
  List<dynamic> _leads = [];

  /// 🔥 read helper (local only)
  Set<String> _openedLeadIds = {};

  final Map<String, String> _conversationMap = {};

  /// Ids currently being mutated, so a row's menu cannot fire twice.
  final Set<String> _busyIds = {};

  final List<String> _filters = const [
    'All Enquiries',
    'Unread',
    'Archived',
    'Pending',
    'Booked',
    'Declined',
  ];

  @override
  void initState() {
    super.initState();
    _loadReadLeads();
    _loadInitialData();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  // ==========================================================================
  // SAFE ACCESSORS — the fix for bugs 1-4
  // ==========================================================================

  /// The `request` payload of an inbox row, or an empty map when it is missing
  /// or is not a map. Never returns null, so no call site can crash on it.
  static Map<String, dynamic> _requestOf(dynamic item) {
    if (item is! Map) return const {};
    final req = item['request'];
    if (req is Map) return Map<String, dynamic>.from(req);
    return const {};
  }

  /// Reads a value as a trimmed String; '' for null and for non-strings.
  static String _str(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v == null) return '';
    return v.toString().trim();
  }

  static String _idOf(dynamic item) {
    if (item is! Map) return '';
    return item['id']?.toString() ?? '';
  }

  /// `isArchived` as a real bool. A missing key means NOT archived.
  static bool _isArchived(dynamic item) {
    if (item is! Map) return false;
    return item['isArchived'] == true;
  }

  static bool _isRead(dynamic item) {
    if (item is! Map) return false;
    return item['isRead'] == true;
  }

  static String _displayName(Map<String, dynamic> request) {
    final name =
        "${_str(request, 'firstName')} ${_str(request, 'lastName')}".trim();
    // AUDIT FIX: an enquiry with no name previously rendered as a blank title
    // with a bare '?' avatar and no explanation.
    return name.isEmpty ? 'Unnamed enquiry' : name;
  }

  // ==========================================================================
  // ARCHIVE / READ / DELETE  (endpoints unchanged)
  // ==========================================================================

  Future<bool> _archiveLeadOnServer(String inboxId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) return false;

      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/inbox/$inboxId/archive'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 25));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint("🔥 ARCHIVE ERROR => $e");
      return false;
    }
  }

  Future<void> _markAsReadOnServer(String inboxId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) return;

      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/inbox/$inboxId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 25));
    } catch (e) {
      debugPrint("🔥 READ API ERROR => $e");
    }
  }

  Future<bool> _deleteLeadOnServer(String inboxId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) return false;

      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/inbox/$inboxId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 25));

      if (res.statusCode == 200) {
        // AUDIT FIX: `jsonDecode(res.body)['success']` threw on an empty body,
        // and some 200 responses from this endpoint carry no body at all —
        // which made a SUCCESSFUL delete report as a failure to the vendor.
        if (res.body.trim().isEmpty) return true;
        final data = jsonDecode(res.body);
        if (data is Map) return data['success'] != false;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("🔥 DELETE ERROR => $e");
      return false;
    }
  }

  Future<void> _confirmDelete(String inboxId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text("Delete enquiry?", style: AppTextStyles.h3),
        content: Text(
          "This enquiry will be removed permanently. This action cannot be undone.",
          style: AppTextStyles.bodySecondary,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Cancel",
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _busyIds.add(inboxId));
    final success = await _deleteLeadOnServer(inboxId);

    if (!mounted) return;
    setState(() => _busyIds.remove(inboxId));

    if (success) {
      AppSnackbar.success(context, "Enquiry deleted");
      await _fetchLeads();
    } else {
      AppSnackbar.error(
        context,
        "Couldn't delete this enquiry. Please try again.",
      );
    }
  }

  Future<void> _toggleArchive(String inboxId) async {
    setState(() => _busyIds.add(inboxId));
    final success = await _archiveLeadOnServer(inboxId);

    if (!mounted) return;
    setState(() => _busyIds.remove(inboxId));

    if (!success) {
      AppSnackbar.error(context, "Couldn't update the archive status.");
      return;
    }

    /// 🔥 Always refresh from server (web + mobile sync)
    await _fetchLeads();
  }

  // ==========================================================================
  // READ / UNREAD
  // ==========================================================================

  Future<void> _loadReadLeads() async {
    final prefs = await SharedPreferences.getInstance();
    _openedLeadIds =
        (prefs.getStringList(SessionManager.kReadLeads) ?? []).toSet();
  }

  Future<void> _markAsRead(String inboxId) async {
    if (inboxId.isEmpty) return;

    // 🔥 1. server ko update
    await _markAsReadOnServer(inboxId);

    // 🔥 2. local helper (fast UI)
    final prefs = await SharedPreferences.getInstance();
    _openedLeadIds.add(inboxId);
    await prefs.setStringList(
      SessionManager.kReadLeads,
      _openedLeadIds.toList(),
    );

    // 🔥 3. unread count refresh
    await _updateUnreadCount();
  }

  Future<void> _updateUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();

    final unreadCount =
        _leads.where((item) => !_isRead(item) && !_isArchived(item)).length;

    await prefs.setInt(SessionManager.kUnreadLeadsCount, unreadCount);
  }

  // ==========================================================================
  // LOAD
  // ==========================================================================

  Future<void> _loadInitialData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    // AUDIT FIX: `Future.wait` previously ran both requests and, because
    // neither recorded a failure, `_isLoading` was cleared whatever happened —
    // producing the silent "No leads found" on error. `_fetchLeads` now records
    // its error; the conversations lookup stays non-fatal because the list is
    // perfectly usable without it (it only supplies chat deep-links).
    await Future.wait([
      _fetchLeads(),
      _fetchConversations(),
    ]);

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _fetchLeads() async {
    try {
      final token = await SessionManager.getToken();

      if (token == null || token.isEmpty) {
        // AUDIT FIX: this used to be a bare `return`, which left the spinner
        // up forever whenever the token was missing.
        throw const LeadsLoadException('Your session has expired. Please log in again.');
      }

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/inbox'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        throw LeadsLoadException(
          AppErrorState.messageForStatus(res.statusCode),
        );
      }

      final data = json.decode(res.body);
      final inbox = (data is Map) ? data["inbox"] : null;

      if (!mounted) return;
      setState(() {
        // AUDIT FIX: `data["inbox"] ?? []` assigned straight into `_leads`
        // threw a raw TypeError when the key held anything but a list.
        _leads = inbox is List ? inbox : <dynamic>[];
        _loadError = null;
      });

      LeadsPage.latestLeads = _leads;
      await _updateUnreadCount();
    } catch (e) {
      debugPrint("🔥 Leads error: $e");
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _leads = [];
      });
      LeadsPage.latestLeads = [];
    }
  }

  Future<void> _fetchConversations() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/messages/vendor/conversations"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 25));

      if (res.statusCode != 200) return;

      final decoded = jsonDecode(res.body);
      // AUDIT FIX: `final List list = jsonDecode(...)` threw a raw TypeError
      // when the endpoint returned its error object instead of a list.
      if (decoded is! List) return;

      _conversationMap.clear();
      for (final c in decoded) {
        if (c is! Map) continue;
        final requestId = c['requestId']?.toString();
        final conversationId = c['id']?.toString();
        if (requestId != null && conversationId != null) {
          _conversationMap[requestId] = conversationId;
        }
      }
      debugPrint("📦 Conversation map size => ${_conversationMap.length}");
    } catch (e) {
      // Non-fatal: without it, opening a lead simply has no chat thread
      // attached, which the detail screen already handles.
      debugPrint("🔥 Conversation error: $e");
    }
  }

  // ==========================================================================
  // FILTERING
  // ==========================================================================

  // AUDIT NOTE — PRE-EXISTING COMMENTED-OUT FILTER, RETAINED VERBATIM.
  // The original "filter first, then search" implementation, already commented
  // out before this audit. The live version below applies BOTH together
  // (see bug 7 in the class doc).
  // Do not delete without project-owner approval.
  //
  // List<dynamic> get _filteredLeads {
  //   final query = _searchCtrl.text.toLowerCase().trim();
  //   List<dynamic> leads = _leads;
  //   switch (_selectedFilter) {
  //     case 'Unread':
  //       leads = leads.where((l) => l['isRead'] == false && l['isArchived'] == false).toList();
  //       break;
  //     case 'Archived':
  //       leads = leads.where((l) => l['isArchived'] == true).toList();
  //       break;
  //     case 'Pending':
  //       leads = leads.where((l) => l['isArchived'] == false &&
  //           (l['request']?['status'] ?? '').toLowerCase() == 'pending').toList();
  //       break;
  //     case 'Booked':
  //       leads = leads.where((l) => l['isArchived'] == false &&
  //           (l['request']?['status'] ?? '').toLowerCase() == 'booked').toList();
  //       break;
  //     case 'Declined':
  //       leads = leads.where((l) => l['isArchived'] == false &&
  //           (l['request']?['status'] ?? '').toLowerCase() == 'declined').toList();
  //       break;
  //     default:
  //       leads = leads.where((l) => l['isArchived'] == false).toList();
  //   }
  //   if (query.isNotEmpty) {
  //     leads = leads.where((l) {
  //       final r = l['request'];
  //       final name = "${r['firstName'] ?? ''} ${r['lastName'] ?? ''}".toLowerCase();
  //       return name.contains(query);
  //     }).toList();
  //   }
  //   return leads;
  // }

  List<dynamic> get _filteredLeads {
    final query = _searchCtrl.text.toLowerCase().trim();

    // 🔥 STEP 1: apply the selected chip
    List<dynamic> leads = _leads.where((l) {
      final status = _str(_requestOf(l), 'status').toLowerCase();

      switch (_selectedFilter) {
        case 'Unread':
          return !_isRead(l) && !_isArchived(l);
        case 'Archived':
          return _isArchived(l);
        case 'Pending':
          return !_isArchived(l) && status == 'pending';
        case 'Booked':
          return !_isArchived(l) && status == 'booked';
        case 'Declined':
          return !_isArchived(l) && status == 'declined';
        default:
          return !_isArchived(l);
      }
    }).toList();

    // 🔥 STEP 2: apply the search query ON TOP of the filter (bug 7)
    if (query.isNotEmpty) {
      leads = leads.where((l) {
        final r = _requestOf(l);
        // AUDIT FIX (bug 8): the hint promised "name, city, event" but only
        // the name was matched. These fields are already in the existing
        // response — no API change required.
        final haystack = [
          _str(r, 'firstName'),
          _str(r, 'lastName'),
          _str(r, 'city'),
          _str(r, 'eventType'),
          _str(r, 'eventDate'),
          _str(r, 'message'),
        ].join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
    }

    return leads;
  }

  // ==========================================================================
  // UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.listBackground,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Enquirys', style: AppTextStyles.headerLarge),
                    ),
                    // AUDIT FIX: the only refresh affordance was
                    // pull-to-refresh, which is undiscoverable when the list is
                    // empty or showing an error.
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _isLoading ? null : _loadInitialData,
                      icon:
                          const Icon(Icons.refresh_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildSearch(),
                const SizedBox(height: 10),
                SizedBox(height: 40, child: _buildFilterChips()),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchLeads,
              color: AppColors.primary,
              child: _listBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listBody() {
    // AUDIT FIX (bug 5): loading, error and empty are three separate, honest
    // states. All three previously rendered "No leads found".
    if (_isLoading) return const ListShimmer();

    if (_loadError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 50),
          AppErrorState(
            expand: false,
            title: "Couldn't load your enquiries",
            message: _loadError is LeadsLoadException
                ? (_loadError as LeadsLoadException).message
                : AppErrorState.messageFor(_loadError),
            onRetry: _fetchLeads,
          ),
        ],
      );
    }

    final leads = _filteredLeads;

    if (leads.isEmpty) {
      final searching = _searchCtrl.text.trim().isNotEmpty;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 50),
          AppEmptyState(
            expand: false,
            icon: searching ? Icons.search_off_rounded : Icons.inbox_outlined,
            title: searching
                ? 'No matching enquiries'
                : _selectedFilter == 'All Enquiries'
                    ? 'No enquiries yet'
                    : 'Nothing in "$_selectedFilter"',
            message: searching
                ? 'Try a different name, city or event.'
                : _selectedFilter == 'All Enquiries'
                    ? 'New customer enquiries will appear here.\nPull down to refresh.'
                    : 'Try another filter to see more enquiries.',
            actionLabel: searching ? 'Clear search' : null,
            onAction: searching ? () => _searchCtrl.clear() : null,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: leads.length,
      itemBuilder: (context, index) => _buildLeadCard(leads[index]),
    );
  }

  Widget _buildLeadCard(dynamic item) {
    // AUDIT FIX (bugs 1-4): every field goes through a null-safe accessor, so
    // an orphaned or malformed inbox row degrades to a readable card instead
    // of taking down the entire ListView.
    final request = _requestOf(item);
    final inboxId = _idOf(item);

    final name = _displayName(request);
    final rawDate = _str(request, 'eventDate');
    final date = rawDate.isEmpty ? 'Date not specified' : _formatDate(rawDate);
    final status = _str(request, 'status');
    final rawMessage = _str(request, 'message');
    final msg = rawMessage.isEmpty ? 'No message' : rawMessage;

    final archived = _isArchived(item);
    final unread = !_isRead(item) && !archived;
    final busy = _busyIds.contains(inboxId);
    final statusColor = AppColors.statusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        // Unread rows carry a brand-coloured edge, so "unread" is visible at a
        // glance instead of only via the absolutely-positioned badge.
        border: Border.all(
          color: unread ? AppColors.primary : AppColors.border,
          width: unread ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: busy ? null : () => _openLead(request, inboxId),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppNetworkAvatar(
                  url: _str(request, 'profileImage'),
                  radius: 24,
                  fallbackText: name,
                ),
                const SizedBox(width: 12),

                // AUDIT FIX (RenderFlex): the old card was a Stack with a
                // `Positioned` menu overlapping a ListTile, so a long customer
                // name ran underneath the ⋯ button and the status chip.
                // Everything is a properly constrained Row/Column now.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h3,
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.event_outlined,
                              size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        msg,
                        // AUDIT FIX: the old code sliced the string by hand
                        // with `msg.substring(0, 20) + '...'`, cutting
                        // mid-word AND double-truncating alongside the
                        // ellipsis overflow already set on the widget.
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _tag(
                            status.isEmpty ? 'NEW' : status.toUpperCase(),
                            statusColor,
                          ),
                          if (archived)
                            _tag("ARCHIVED", AppColors.textTertiary),
                        ],
                      ),
                    ],
                  ),
                ),

                // Row actions
                busy
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : PopupMenuButton<String>(
                        color: AppColors.surface,
                        tooltip: "More actions",
                        icon: const Icon(Icons.more_horiz,
                            color: AppColors.textTertiary),
                        onSelected: (value) async {
                          if (inboxId.isEmpty) {
                            AppSnackbar.error(
                              context,
                              "This enquiry is missing its id and can't be updated.",
                            );
                            return;
                          }
                          if (value == 'archive') {
                            await _toggleArchive(inboxId);
                          } else if (value == 'delete') {
                            await _confirmDelete(inboxId);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'archive',
                            child: Row(
                              children: [
                                Icon(
                                  // AUDIT FIX (bug 2): `_isArchived` returns a
                                  // real bool, so a null can no longer throw
                                  // the instant this menu opens.
                                  archived ? Icons.unarchive : Icons.archive,
                                  color: AppColors.secondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(archived ? 'Unarchive' : 'Archive'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLead(Map<String, dynamic> request, String inboxId) async {
    // AUDIT FIX: guarded push — a stale tap after the session expired can no
    // longer open enquiry details.
    await AuthGuard.push(
      context,
      (_) => LeadDetailScreen(
        lead: request,
        conversationId: _conversationMap[inboxId],
      ),
      debugLabel: 'LeadDetailScreen',
    );

    // AUDIT FIX (bug 6): both follow-ups are guarded by `mounted`.
    if (!mounted) return;
    await _markAsRead(inboxId);
    if (!mounted) return;
    await _fetchLeads();
  }

  /// Formats an ISO date for display, falling back to the raw value when it is
  /// not parseable. The previous card printed the raw ISO timestamp
  /// ("2026-03-14T00:00:00.000Z") straight into the UI.
  static String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchCtrl,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.input,
      decoration: InputDecoration(
        hintText: 'Search by name, city, event…',
        prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
        // AUDIT FIX: there was no way to clear the query except select-all and
        // delete.
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _searchCtrl.clear(),
              ),
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _filters.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final label = _filters[index];
        final bool isSelected = _selectedFilter == label;

        return ChoiceChip(
          label: Text(
            label,
            style: AppTextStyles.captionMedium.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          selected: isSelected,
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.surface,
          showCheckmark: false,
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: isSelected ? 1.5 : 1,
          ),
          onSelected: (_) => setState(() => _selectedFilter = label),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        );
      },
    );
  }
}

/// Carries user-facing copy for a failed inbox load, so a status code or a
/// stack trace never reaches the screen.
class LeadsLoadException implements Exception {
  final String message;
  const LeadsLoadException(this.message);

  @override
  String toString() => message;
}
