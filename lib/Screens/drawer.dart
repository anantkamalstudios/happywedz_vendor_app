import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../Storefront/StoreFront.dart';
// import '../movments_plus/bottom_bar.dart';
import 'Login.dart';
import 'crm/crm_clients_screen.dart';
import 'instagram_connect_screen.dart';
import 'subscription_history_screen.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';
import '../theme/app_colors.dart';
import '../providers/vendor_access_provider.dart';
import '../widgets/plan_feature_guard.dart';

class BusinessDrawer extends ConsumerStatefulWidget {
  const BusinessDrawer({Key? key}) : super(key: key);

  @override
  ConsumerState<BusinessDrawer> createState() => _BusinessDrawerState();
}

class _BusinessDrawerState extends ConsumerState<BusinessDrawer> {
  String userName = "";
  String userEmail = "";
  String coverImage = "";

  bool _isLoading = true;

  int leadCount = 0;
  int viewsCount = 0;
  int? vendorId;
  int? vendorTypeId;

  /// Moments+ is a photography-only feature (vendor_type_id == 1).
  bool get isPhotographer => vendorTypeId == 1;



  bool loadingLink = false;
  String? reviewLink;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Re-read plan access each time the drawer opens. The previous answer
    // stays on screen while it reloads, so nothing flashes.
    Future.microtask(() => ref.invalidate(vendorAccessProvider));
    _loadUserData();
    _loadVendorId();
  }

Future<void> _loadVendorId() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    vendorId = prefs.getInt("vendorId");
    vendorTypeId = prefs.getInt("vendorTypeId");
  });
}
  Future<void> _contactSupport() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String fromEmail = prefs.getString('email') ?? "";

    final Uri emailUri = Uri(
      scheme: "mailto",
      path: "pranjal.anantkamal@gmail.com",
      query: "subject=Support Request"
          "&body=Hello,\n\nMy registered email is: $fromEmail\n\nWrite your query here...",
    );

    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("❌ Email launch error: $e");
    }
  }

  /// ✅ Load user data
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString('businessName') ?? "Vendor Name";
      userEmail = prefs.getString('email') ?? "vendor@example.com";
      coverImage = prefs.getString('coverImage') ?? "";
      leadCount = prefs.getInt('lead_count') ?? 0;
      viewsCount = prefs.getInt('views_count') ?? 0;
      _isLoading = false;
    });
  }

  /// ✅ Pick Image
  Future<void> _pickCoverImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coverImage', pickedFile.path);

    setState(() {
      coverImage = pickedFile.path;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cover image updated")),
    );
  }

  /// ✅ Remove Image
  Future<void> _removeCoverImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('coverImage');

    setState(() {
      coverImage = "";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cover image removed")),
    );
  }

  /// ✅ Show Edit Options
  // void _showEditOptions() {
  //   showModalBottomSheet(
  //     backgroundColor: Colors.white,
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (_) {
  //       return Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           ListTile(
  //             leading: const Icon(Icons.photo, color: Colors.blue),
  //             title: const Text("Change Photo"),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _pickCoverImage();
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.delete, color: Colors.red),
  //             title: const Text("Remove Photo"),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _removeCoverImage();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    // Plan-gated rows are left out entirely (hide, don't lock) and stay out
    // while access is still loading.
    final access = ref.watch(vendorAccessProvider).value;
    final showCrm = access?.hasModule(VendorModules.crm) ?? false;
    final showInstagram = access?.hasModule(VendorModules.instagram) ?? false;


    return Drawer(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // onTap: _showEditOptions,
          _drawerHeader(),


          /// MENU ITEMS
          Expanded(

            child: Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [

                  ListTile(
                    leading: _drawerIcon(Iconsax.shop_copy,
                        AppColors.primary, AppColors.primaryTint),
                    title: const Text("Storefront"),
                    onTap: () {
                      Navigator.pop(context);

                      if (vendorId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                              Text("Vendor ID not found. Please login again.")),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Storefront(vendorId: vendorId!),
                        ),
                      );
                    },
                  ),
                  if (showCrm)
                  ListTile(
                    leading: _drawerIcon(Iconsax.chart_square_copy,
                        AppColors.accentPink, AppColors.accentPinkTint),
                    title: Text(
                        access?.moduleInfo(VendorModules.crm)?.label ?? "CRM"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FeatureGuard(
                            module: VendorModules.crm,
                            child: CrmClientsScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: _drawerIcon(Iconsax.card_copy,
                        AppColors.success, AppColors.successTint),
                    title: const Text("Payments & Subscription"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  if (showInstagram)
                  ListTile(
                    // The real Instagram mark rather than a stand-in icon, so
                    // the row reads as the brand it links to. It goes through
                    // the same tile as every other row so it cannot outgrow
                    // them again.
                    leading: _brandTile(
                      const InstagramGlyph(size: _brandGlyph),
                    ),
                    title: Text(access
                            ?.moduleInfo(VendorModules.instagram)
                            ?.label ??
                        "Instagram Connect"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FeatureGuard(
                            module: VendorModules.instagram,
                            child: InstagramConnectScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: _drawerIcon(Iconsax.shopping_bag_copy,
                        AppColors.accentPink, AppColors.accentPinkTint),
                    title: const Text("Store"),
                    // The store lives on its own subdomain — the website's
                    // header opens it in a new tab rather than routing to it,
                    // so this hands off to the browser the same way.
                    trailing: Icon(Icons.open_in_new,
                        size: 16, color: Colors.grey.shade500),
                    onTap: () {
                      Navigator.pop(context);
                      _openStore();
                    },
                  ),
                  // if (isPhotographer)
                  //   ListTile(
                  //     leading: const Icon(
                  //       Icons.auto_awesome,
                  //       color: Color(0xFF4682B4),
                  //     ),
                  //     title: const Text("Moments+"),
                  //     onTap: () {
                  //       Navigator.pop(context);
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (_) => const MainHomeScreen(),
                  //         ),
                  //       );
                  //     },
                  //   ),
                  ListTile(
                    leading: _drawerIcon(Iconsax.message_favorite_copy,
                        AppColors.info, AppColors.infoTint),
                    title: const Text("Get Client Review to You"),
                    trailing: loadingLink
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : null,
                    onTap: () async {
                      await _generateReviewLinkOnce();

                      if (reviewLink == null || reviewLink!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Unable to generate review link")),
                        );
                        return;
                      }

                      await Share.share(
                        "Hey! 😊\n\n"
                            "Please take a moment to share your review about my work:\n\n"
                            "$reviewLink\n\n"
                            "Thank you so much! 🙏",
                      );
                    },
                  ),

                  // ListTile(
                  //   leading: const Icon(Icons.reviews,
                  //       color: Color(0xFF4682B4)),
                  //   title: const Text("Get Client Review to You"),
                  //   onTap: () async {
                  //     await Share.share(
                  //       "Hey! Please share your review about my work 😊",
                  //     );
                  //   },
                  // ),

                  // ListTile(
                  //   leading: const Icon(Icons.support_agent,
                  //       color: Color(0xFF4682B4)),
                  //   title: const Text("Contact Support"),
                  //   onTap: () async {
                  //     Navigator.pop(context);
                  //     _contactSupport();
                  //   },
                  // ),
                  ListTile(
                    leading: _drawerIcon(Iconsax.star_copy,
                        AppColors.rating, AppColors.warningTint),
                    title: const Text("Rate on Playstore"),
                    onTap: _rateOnPlayStore,
                  ),

                  // ListTile(
                  //   leading: const Icon(Icons.star_rate,
                  //       color: Color(0xFF4682B4)),
                  //   title: const Text("Rate on Playstore"),
                  //   onTap: () => _showRateDialog(context),
                  // ),
                ],
              ),
            ),
          ),

          const Divider(
            color: Colors.grey,
          ),

          /// Logout
          // Container(
          //   color: Colors.white,
          //   child: ListTile(
          //     leading: const Icon(Icons.logout,  color: Color(0xFF4682B4)),
          //     title: const Text('Logout'),
          //     onTap: () async {
          //       SharedPreferences prefs =
          //       await SharedPreferences.getInstance();
          //       await prefs.clear();
          //
          //       Navigator.pushReplacement(
          //         context,
          //         MaterialPageRoute(
          //           builder: (_) => Login(), // Login Page
          //         ),
          //       );
          //     },
          //   ),
          // ),
          // Logout reads as a footer rather than one more menu row, so it gets
          // a rule above it the way the app separates a destructive action.
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          Container(
            color: Colors.white,
            child: ListTile(
              leading: _drawerIcon(Iconsax.logout_copy,
                  AppColors.error, AppColors.errorTint),
              title: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();

                // 🔐 Check if Remember Me was enabled
                final rememberMe =
                    prefs.getString('savedPassword') != null &&
                        prefs.getString('rememberedEmail') != null;

                // ❌ Clear session data only
                await prefs.remove('isLoggedIn');
                await prefs.remove('authToken');
                await prefs.remove('token');
                await prefs.remove('vendorId');
                await prefs.remove('vendorTypeId');
                await prefs.remove('businessName');
                await prefs.remove('phone');
                await prefs.remove('profileImage');
                await prefs.remove('profileCompleted');
                await prefs.remove('vendorTypeName');
                await prefs.remove('email');

                // ❌ Clear remembered login credentials ONLY if remember me was OFF
                if (!rememberMe) {
                  await prefs.remove('rememberedEmail');
                  await prefs.remove('savedPassword');
                }

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Login()),
                );
              },
            ),
          ),

        ],
      ),
    );
  }


  /// The drawer header, in the same deep blue every other screen uses.
  ///
  /// It used to be `Colors.pink[100]` behind a `0xFFE0F7FA` cyan panel with
  /// black text, which matched nothing else in the app — every inner page runs
  /// `CommonAppBar` in `AppColors.primary`, and the Reviews header uses this
  /// exact gradient. A cover image still sits on top when the vendor has one,
  /// now under a scrim so the white text stays readable over any photo.
  Widget _drawerHeader() {
    final hasCover = coverImage.isNotEmpty;

    return Container(
      width: double.infinity,
      // Not a fixed height: at a large accessibility text size a locked 180px
      // clipped the email off the bottom.
      constraints: const BoxConstraints(minHeight: 176),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003F88), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: hasCover
            ? DecorationImage(
                image: coverImage.startsWith('http')
                    ? NetworkImage(coverImage)
                    : FileImage(File(coverImage)) as ImageProvider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Container(
        decoration: hasCover
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              )
            : null,
        padding: const EdgeInsets.fromLTRB(16, 44, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                _initialOf(userName),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              userEmail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The avatar letter. Guards a blank business name, which would otherwise
  /// throw a RangeError out of build.
  String _initialOf(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  /// Size of the tinted square behind every drawer icon.
  static const double _iconTile = 38;

  /// Size of the glyph inside it. Matching the tiles is not enough on its own —
  /// the Instagram logo was filling its whole 38px tile while the Material
  /// glyphs sat at 20px inside theirs, so the brand row looked oversized next
  /// to the rest even though every footprint was identical.
  static const double _iconGlyph = 20;

  /// The brand mark gets two extra pixels: its artwork is an inset rounded
  /// square, so at the same number it reads smaller than a line glyph.
  static const double _brandGlyph = 22;

  /// The one tile every drawer icon goes through, so none can drift again.
  Widget _iconTileWrap({required Color tint, required Widget child}) {
    return Container(
      width: _iconTile,
      height: _iconTile,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  /// A flat, tinted tile behind a drawer icon. The rows used to be bare glyphs
  /// in one blue, mixing filled and outlined shapes; the tint now carries the
  /// meaning — money is green, the shop is pink, ratings are amber.
  Widget _drawerIcon(IconData icon, Color color, Color tint) {
    return _iconTileWrap(
      tint: tint,
      child: Icon(icon, size: _iconGlyph, color: color),
    );
  }

  /// A brand logo in the same tile. The tint stays neutral so the logo's own
  /// colours are the only ones on the row.
  Widget _brandTile(Widget logo) {
    return _iconTileWrap(tint: AppColors.listBackground, child: logo);
  }

  /// Opens the HappyWedz Store in the browser.
  Future<void> _openStore() async {
    final uri = Uri.parse(ApiConfig.storeUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    // The drawer has already closed by this point, so guard the context.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Unable to open the store")),
    );
  }

  void _rateOnPlayStore() async {
    const playStoreUrl =
        "https://play.google.com/store/apps/details?id=com.happy.happy_weds_vendors";

    final uri = Uri.parse(playStoreUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // 🔥 opens Play Store app
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open Play Store")),
      );
    }
  }


  // ================= GET VENDOR SERVICE ID =================
  Future<int?> _getVendorServiceId(int vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final res = await http.get(
      Uri.parse(
          "${ApiConfig.baseUrl}/vendor-services/vendor/$vendorId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      if (data.isNotEmpty) {
        return data[0]['id'];
      }
    }
    return null;
  }

  Future<void> _generateReviewLinkOnce() async {
    if (reviewLink != null && reviewLink!.isNotEmpty) return; // 🔥 generate once

    final prefs = await SharedPreferences.getInstance();
    final vendorId = prefs.getInt("vendorId");
    if (vendorId == null) return;

    setState(() => loadingLink = true);

    final serviceId = await _getVendorServiceId(vendorId);

    setState(() {
      loadingLink = false;
      reviewLink = serviceId != null
          ? "${ApiConfig.websiteUrl}/write-review/$serviceId"
          : null;
    });
  }

  /// Stat Item
  static Widget _statItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  /// Drawer Item
  Widget _drawerItem(
      BuildContext context,
      IconData icon,
      String title,
      Widget page, {
        Color iconColor = Colors.blue,
      }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ).then((_) => _loadUserData());
      },
    );
  }

  /// Rate Sheet
  void _showRateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const SizedBox(
        height: 200,
        child: Center(child: Text("Rate bottom sheet")),
      ),
    );
  }
}

