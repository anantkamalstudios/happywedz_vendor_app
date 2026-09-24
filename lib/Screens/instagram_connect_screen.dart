import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api_services/instagram_api.dart';
import '../utils/common_app_bar.dart';
import '../widgets/app_network_image.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/plan_feature_guard.dart';
import '../utils/plan_module_lock.dart';

/// Connect / disconnect the vendor's Instagram account.
///
/// The website runs the OAuth exchange in a popup and re-reads the connection
/// once that popup closes, because the callback lands on the main site rather
/// than in the dashboard. A phone has no popup to watch, so the same idea is
/// done with the lifecycle: the login opens in the browser, and the connection
/// is re-read when the vendor comes back to the app.
class InstagramConnectScreen extends ConsumerStatefulWidget {
  const InstagramConnectScreen({super.key});

  @override
  ConsumerState<InstagramConnectScreen> createState() =>
      _InstagramConnectScreenState();
}

class _InstagramConnectScreenState extends ConsumerState<InstagramConnectScreen>
    with WidgetsBindingObserver {
  final InstagramApi _api = InstagramApi();

  String? token;
  Map<String, dynamic>? connection;

  bool loading = true;
  bool connecting = false;
  String? error;

  /// True only between opening the browser and coming back, so an ordinary
  /// app switch does not trigger a reload.
  bool _awaitingReturn = false;

  bool get _isConnected => connection != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingReturn) {
      _awaitingReturn = false;
      setState(() => connecting = false);
      _fetchConnection();
    }
  }

  /// The server says Instagram is not in the vendor's plan: an answer, not an
  /// error — show the locked notice and let the navigation catch up.
  void _onLocked(PlanModuleLockedException e) {
    showPlanModuleLocked(context, ref,
        module: e.module.isEmpty ? 'instagram' : e.module, message: e.message);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? prefs.getString('authToken');

    if (token == null) {
      setState(() {
        loading = false;
        error = "Please log in again to manage your Instagram connection.";
      });
      return;
    }

    await _fetchConnection();
  }

  Future<void> _fetchConnection() async {
    if (token == null) return;
    if (mounted) setState(() => loading = true);

    final Map<String, dynamic>? result;
    try {
      result = await _api.getConnection(token: token!);
    } on PlanModuleLockedException catch (e) {
      if (mounted) _onLocked(e);
      return;
    }

    if (!mounted) return;
    setState(() {
      connection = result;
      loading = false;
    });
  }

  Future<void> _connect() async {
    if (token == null) return;

    setState(() {
      connecting = true;
      error = null;
    });

    final String? url;
    try {
      url = await _api.getAuthUrl(token: token!);
    } on PlanModuleLockedException catch (e) {
      if (mounted) _onLocked(e);
      return;
    }

    if (!mounted) return;
    if (url == null) {
      setState(() {
        connecting = false;
        error = "Could not start the Instagram connection. Please try again.";
      });
      return;
    }

    // External browser, so Instagram sees a real browser session and the
    // vendor can use a login they are already signed in to.
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) return;
    if (!opened) {
      setState(() {
        connecting = false;
        error = "Could not open Instagram. Please try again.";
      });
      return;
    }

    _awaitingReturn = true;
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Disconnect Instagram?"),
        content: const Text(
          "Your posts and stories will stop showing on your listing. "
          "You can connect again any time.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Disconnect"),
          ),
        ],
      ),
    );

    if (confirmed != true || token == null) return;

    final bool ok;
    try {
      ok = await _api.disconnect(token: token!);
    } on PlanModuleLockedException catch (e) {
      if (mounted) _onLocked(e);
      return;
    }

    if (!mounted) return;
    if (ok) {
      setState(() => connection = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Instagram disconnected")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not disconnect. Please try again.")),
      );
    }
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  /// The account's own picture once connected, otherwise the Instagram mark.
  Widget _avatar() {
    final picture = connection?['profile_picture_url']?.toString();
    if (picture != null && picture.startsWith('http')) {
      return ClipOval(
        child: AppNetworkImage(url: picture, width: 56, height: 56),
      );
    }
    return const InstagramGlyph(size: 56);
  }

  Widget _statusCard() {
    final username = connection?['username']?.toString();
    final accountType = connection?['account_type']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _avatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isConnected
                          ? "@${username?.isNotEmpty == true ? username : 'instagram'}"
                          : "Instagram",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isConnected
                          ? "${accountType?.isNotEmpty == true ? accountType : 'Business'} · Connected"
                          : "Not connected",
                      style: TextStyle(
                        fontSize: 13,
                        color: _isConnected
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _isConnected
                ? OutlinedButton(
                    onPressed: _disconnect,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Disconnect"),
                  )
                : ElevatedButton(
                    onPressed: connecting ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC13584),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: connecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Connect Instagram",
                            style: TextStyle(fontSize: 15),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _explainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What connecting does",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _bullet("Your recent posts and stories appear on your listing."),
          _bullet("Couples see your latest work without leaving Happy Wedz."),
          _bullet("You can disconnect whenever you like."),
          const SizedBox(height: 12),
          Text(
            "Instagram opens in your browser to sign in. Come back to the app "
            "once it is done and this page will update.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check, size: 15, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const CommonAppBar(title: "Instagram Connect"),
      body: loading
          ? const FormShimmer(fields: 2)
          : RefreshIndicator(
              onRefresh: _fetchConnection,
              child: ListView(
                // Edge to edge (targetSdk 36): the extra bottom keeps the last item
                // clear of the 3-button navigation bar.
                padding: EdgeInsets.fromLTRB(16, 16, 16,
                    16 + MediaQuery.of(context).padding.bottom),
                children: [
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF5C6C3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 18, color: Color(0xFFD32F2F)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              error!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _statusCard(),
                  const SizedBox(height: 16),
                  _explainer(),
                ],
              ),
            ),
    );
  }
}

/// The Instagram mark, from `assets/images/instagram.png`.
///
/// Kept as its own widget so the drawer row and this screen cannot drift
/// apart, and so the fallback lives in one place.
class InstagramGlyph extends StatelessWidget {
  final double size;

  const InstagramGlyph({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/instagram.png',
      width: size,
      height: size,
      // A missing asset would otherwise throw a grey box into the drawer.
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFFF09433),
              Color(0xFFDC2743),
              Color(0xFFBC1888),
            ],
          ),
        ),
        child: Icon(
          Icons.camera_alt_outlined,
          size: size * 0.58,
          color: Colors.white,
        ),
      ),
    );
  }
}
