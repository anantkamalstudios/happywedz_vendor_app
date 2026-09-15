// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'BasicInfo.dart';
// import 'BusinessDetailScreen.dart';
// import 'ContactDetailsScreen.dart';
// import '../Screens/FAQs/Florists.dart';
// import '../Screens/FAQs/Makeup.dart';
// import '../Screens/FAQs/Pandits.dart';
// import '../Screens/FAQs/Photographer.dart';
// import '../Screens/FAQs/Venues.dart';
// import '../Screens/FAQs/Decorator.dart';
// import '../Screens/FAQs/Caterars.dart';
// import '../Screens/FAQs/BridalWear.dart';
// import '../Screens/FAQs/GroomWear.dart';
// import '../Screens/FAQs/Jewellery and Accessories.dart';
// import '../Screens/FAQs/Mehnadi.dart';
// import '../Screens/FAQs/WeddingDj.dart';
// import '../Screens/FAQs/WeddingGift.dart';
// import 'FacalitiesPage.dart';
// import 'LocationScreen.dart';
// import 'MenusPage.dart';
// import 'PhotosScreen.dart';
// import 'PoliciesPage.dart';
// import 'PrefferedVendiors.dart';
// import 'PricingPage.dart';
// import 'PromotionsPage.dart';
// import 'Availability&SlotsPage.dart';
// import 'SocialNetwork.dart';
// import 'VideosScreen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class Storefront extends StatefulWidget {
//   final int vendorId;
//   const Storefront({super.key, required this.vendorId});
//
//   @override
//   State<Storefront> createState() => _StorefrontState();
// }
//
// class _StorefrontState extends State<Storefront> {
//   Map<String, dynamic>? vendorData;
//   bool isLoading = true;
//   int? vendorSubcategoryId;
//
//   static const Color steelAzure = Color(0xFF4682B4);
//
//   @override
//   void initState() {
//     super.initState();
//     fetchVendorApi();
//   }
//
//
//   Future<void> fetchVendorApi() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('authToken');
//
//       final response = await http.post(
//         Uri.parse("https://happywedz.com/api/vendor-services"),
//         headers: {
//           'Content-Type': 'application/json',
//           if (token != null) "Authorization": "Bearer $token"
//         },
//         body: jsonEncode({"vendor_id": widget.vendorId}),
//       );
//
//       if (response.statusCode == 200) {
//         final decode = jsonDecode(response.body);
//         final data = decode["data"][0];
//
//         debugPrint("FULL API DATA = ${jsonEncode(data)}");
//
//         setState(() {
//           vendorData = data["attributes"] ?? {};
//           vendorSubcategoryId = data["vendor_subcategory_id"];
//           isLoading = false;
//         });
//       } else {
//         debugPrint("Error Fetching");
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       debugPrint("Error Fetching");
//       setState(() => isLoading = false);
//     }
//   }
//
//   // final Map<String, Widget Function()> faqScreens = {
//   //   "photographers": () => const PhotographerFaqScreen(),
//   //   "venues": () => const VenueFaqScreen(),
//   //   "makeup": () => const BridalMakeupFaqScreen(),
//   //   "planning and decor": () => DecoratorFaqScreen(),
//   //   "caterers": () => CatererFaqScreen(),
//   //   "invites and gifts": () => GiftsScreen(),
//   //   "florists": () => FloristFaqScreen(),
//   //   "pandits": () => PanditsFaqScreen(),
//   //   "bridal": () => BridalwearFaqScreen(),
//   //   "groom": () => GroomwearScreen(),
//   //   "jewellery and accessories": () => JewelleryFaqScreen(),
//   //   "mehndi": () => MehendiArtistsScreen(),
//   //   "music and dance": () => WeddingDjScreen(),
//   // };
//
//
//   final Map<int, Widget Function()> faqBySubcategoryId = {
//     1: () => const PhotographerFaqScreen(),
//     2: () => const VenueFaqScreen(),
//     3: () => const BridalMakeupFaqScreen(),
//     4: () => DecoratorFaqScreen(),
//     5: () => MehendiArtistsScreen(),
//     6: () => JewelleryFaqScreen(),
//     7: () => CatererFaqScreen(),
//     8: () => WeddingDjScreen(),
//     9: () => GiftsScreen(),
//     10: () => BridalwearFaqScreen(),
//     11: () => GroomwearScreen(),
//     13: () => FloristFaqScreen(),
//     14: () => PanditsFaqScreen(),
//   };
//
//
//   // void openFaq(BuildContext context) {
//   //   String type = vendorData?["vendor_type"]?.toLowerCase().trim() ?? "";
//   //   final page = faqScreens[type];
//   //   if (page != null) {
//   //     Navigator.push(context, MaterialPageRoute(builder: (_) => page()));
//   //   } else {
//   //     ScaffoldMessenger.of(context)
//   //         .showSnackBar(const SnackBar(content: Text("FAQ not available")));
//   //   }
//   // }
//
//
//   void openFaq(BuildContext context) {
//     debugPrint("Vendor Subcategory ID = $vendorSubcategoryId");
//
//     final page = faqBySubcategoryId[vendorSubcategoryId];
//
//     if (page != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => page()),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("FAQ not available")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Scaffold(
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     final List<Map<String, dynamic>> menuItems = [
//       {
//         "title": "Business Details",
//         "icon": Icons.business_center_outlined,
//         "page": BusinessDetailsPage()
//       },
//       {
//         "title": "Basic Information",
//         "icon": Icons.info_outline,
//         "page": BasicInfoPage()
//       },
//       {"title": "FAQ", "icon": Icons.help_center_outlined, "page": "faq"},
//       {
//         "title": "Contact Details",
//         "icon": Icons.call_outlined,
//         "page": ContactDetailsPage(),
//       },
//       {
//         "title": "Location & Service Areas",
//         "icon": Icons.location_on_outlined,
//         "page": LocationPage()
//       },
//       {
//         "title": "Photos",
//         "icon": Icons.photo_library_outlined,
//         "page": GalleryUploadPage()
//       },
//       {
//         "title": "Videos",
//         "icon": Icons.video_collection_outlined,
//         "page": VideoUploadPage()
//       },
//       {
//         "title": "Preferred Vendors",
//         "icon": Icons.group_outlined,
//         "page": PreferredVendorsPage()
//       },
//       {
//         "title": "Social Network",
//         "icon": Icons.public_outlined,
//         "page": SocialNetworkPage()
//       },
//       {
//         "title": "Facilities & Features",
//         "icon": Icons.widgets_outlined,
//         "page": FacilitiesPage()
//       },
//       {
//         "title": "Menus",
//         "icon": Icons.restaurant_menu,
//         "page": MenusPage()
//       },
//       {
//         "title": "Promotions",
//         "icon": Icons.local_offer_outlined,
//         "page": PromotionsPage()
//       },
//       {
//         "title": "Policies & Terms",
//         "icon": Icons.shield_outlined,
//         "page": PoliciesPage()
//       },
//       {
//         "title": "Availability & Slots",
//         "icon": Icons.schedule_outlined,
//         "page": SlotsPage()
//       },
//       {
//         "title": "Pricing & Packages",
//         "icon": Icons.attach_money,
//         "page": PricingPage()
//       },
//     ];
//
//     return Scaffold(
//       backgroundColor: const Color(0xffF7F8FA),
//       appBar: AppBar(
//         backgroundColor: Color(0xFF00509D),
//         elevation: 0,
//         centerTitle: true,
//         title: const Text(
//           "Storefront",
//           style: TextStyle(
//               color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
//         ),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(14),
//         itemCount: menuItems.length,
//         itemBuilder: (context, index) {
//           final item = menuItems[index];
//           return Container(
//             margin: const EdgeInsets.symmetric(vertical: 7),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: ListTile(
//               leading: Icon(item["icon"], color: steelAzure, size: 26),
//               title: Text(item["title"],
//                   style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
//               trailing:
//               const Icon(Icons.arrow_forward_ios, color: steelAzure, size: 18),
//               onTap: () {
//                 if (item["page"] == "faq") {
//                   openFaq(context);
//                 } else {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => item["page"]),
//                   );
//                 }
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_guard.dart';
import '../providers/vendor_access_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/common_app_bar.dart';
import '../widgets/locked_tab_overlay.dart';
import 'BasicInfo.dart';
import 'BusinessDetailScreen.dart';
import 'ContactDetailsScreen.dart';
import '../Screens/FAQs/Florists.dart';
import '../Screens/FAQs/Makeup.dart';
import '../Screens/FAQs/Pandits.dart';
import '../Screens/FAQs/Photographer.dart';
import '../Screens/FAQs/Venues.dart';
import '../Screens/FAQs/Decorator.dart';
import '../Screens/FAQs/Caterars.dart';
import '../Screens/FAQs/BridalWear.dart';
import '../Screens/FAQs/GroomWear.dart';
import '../Screens/FAQs/Jewellery and Accessories.dart';
import '../Screens/FAQs/Mehnadi.dart';
import '../Screens/FAQs/WeddingDj.dart';
import '../Screens/FAQs/WeddingGift.dart';
import 'FacalitiesPage.dart';
import 'LocationScreen.dart';
import 'MenusPage.dart';
import 'PhotosScreen.dart';
import 'PoliciesPage.dart';
import 'PrefferedVendiors.dart';
import 'PricingPage.dart';
import 'PromotionsPage.dart';
import 'Availability&SlotsPage.dart';
import 'SocialNetwork.dart';
import 'VideosScreen.dart';
import '../widgets/app_shimmer.dart';

class Storefront extends StatefulWidget {
  final int vendorId;
  const Storefront({super.key, required this.vendorId});

  @override
  State<Storefront> createState() => _StorefrontState();
}

class _StorefrontState extends State<Storefront> {
  bool isLoading = true;
  int? vendorTypeId;
  bool get canShowMenus => vendorTypeId == 2 || vendorTypeId == 7;

  // AUDIT NOTE: kept as a named constant (several widgets below reference it)
  // but now sourced from the central palette instead of a re-typed hex.
  static const Color steelAzure = AppColors.secondary;

  @override
  void initState() {
    super.initState();
    _loadVendorType();
  }

  Future<void> _loadVendorType() async {
    final prefs = await SharedPreferences.getInstance();
    vendorTypeId = prefs.getInt('vendorTypeId');

    debugPrint("📌 Storefront vendorTypeId = $vendorTypeId");

    setState(() => isLoading = false);
  }

  /// 🔥 VendorTypeId → FAQ Screen mapping
  final Map<int, Widget Function()> faqByVendorTypeId = {
    1: () => const PhotographerFaqScreen(),
    2: () => const VenueFaqScreen(),
    3: () => const BridalMakeupFaqScreen(),
    4: () => DecoratorFaqScreen(),
    5: () => MehendiArtistsScreen(),
    6: () => JewelleryFaqScreen(),
    7: () => CatererFaqScreen(),
    8: () => WeddingDjScreen(),
    9: () => GiftsScreen(),
    10: () => BridalwearFaqScreen(),
    11: () => GroomwearScreen(),
    13: () => FloristFaqScreen(),
    14: () => PanditsFaqScreen(),
  };

  void openFaq(BuildContext context) {
    debugPrint("👉 Opening FAQ for vendorTypeId = $vendorTypeId");

    final page = faqByVendorTypeId[vendorTypeId];

    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LockedTabOverlay(tabId: 'faq', child: page()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("FAQ not available for this vendor")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: ListShimmer(itemCount: 8, showAvatar: false, itemHeight: 62),
      );
    }

    final List<Map<String, dynamic>> menuItems = [
      {
        "title": "Business Details",
        "icon": Icons.business_center_outlined,
        "tabId": "business",
        "page": BusinessDetailsPage(),
      },
      {
        "title": "Basic Information",
        "icon": Icons.info_outline,
        "tabId": "vendor-basic",
        "page": BasicInfoPage(),
      },
      {
        "title": "FAQ",
        "icon": Icons.help_center_outlined,
        "tabId": "faq",
        "page": "faq",
      },
      {
        "title": "Contact Details",
        "icon": Icons.call_outlined,
        "tabId": "vendor-contact",
        "page": ContactDetailsPage(),
      },
      {
        "title": "Location & Service Areas",
        "icon": Icons.location_on_outlined,
        "tabId": "vendor-location",
        "page": LocationPage(),
      },
      {
        "title": "Photos",
        "icon": Icons.photo_library_outlined,
        "tabId": "photos",
        "page": GalleryUploadPage(),
      },
      {
        "title": "Videos",
        "icon": Icons.video_collection_outlined,
        "tabId": "videos",
        "page": VideoUploadPage(),
      },
      {
        "title": "Preferred Vendors",
        "icon": Icons.group_outlined,
        "tabId": "preferred-vendors",
        "page": PreferredVendorsPage(),
      },
      {
        "title": "Social Network",
        "icon": Icons.public_outlined,
        "tabId": "social",
        "page": SocialNetworkPage(),
      },
      {
        "title": "Facilities & Features",
        "icon": Icons.widgets_outlined,
        "tabId": "vendor-facilities",
        "page": FacilitiesPage(),
      },

      if (canShowMenus)
        {
          "title": "Menus",
          "icon": Icons.restaurant_menu,
          "tabId": "vendor-menus",
          "page": MenusPage(),
        },

      {
        "title": "Promotions",
        "icon": Icons.local_offer_outlined,
        "tabId": "promotions",
        "page": PromotionsPage(),
      },
      {
        "title": "Policies & Terms",
        "icon": Icons.shield_outlined,
        "tabId": "vendor-policies",
        "page": PoliciesPage(),
      },
      {
        "title": "Availability & Slots",
        "icon": Icons.schedule_outlined,
        "tabId": "vendor-availability",
        "page": SlotsPage(),
      },
      {
        "title": "Pricing & Packages",
        "icon": Icons.attach_money,
        "tabId": "vendor-pricing",
        "page": PricingPage(),
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: "Storefront",
        onBack: () {
          Navigator.pop(context, true); // 🔥 notify refresh
        },
      ),
      body: Consumer(
        builder: (context, ref, _) {
          // A lock glyph on the rows the current plan does not cover, so the
          // vendor sees what is locked before opening it — same affordance the
          // website's sidebar uses.
          final access = ref.watch(vendorAccessProvider).value;

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              final locked =
                  access != null && !access.canEditTab(item["tabId"] as String);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: Icon(
                    item["icon"],
                    color: locked ? AppColors.textTertiary : steelAzure,
                    size: 24,
                  ),
                  title: Text(
                    item["title"],
                    // AUDIT FIX: long section names ("Location & Service Areas",
                    // "Facilities & Features") had no maxLines and wrapped
                    // awkwardly under the trailing chevron on narrow devices.
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: locked ? AppColors.textSecondary : null,
                    ),
                  ),
                  trailing: Icon(
                    locked
                        ? Icons.lock_outline_rounded
                        : Icons.arrow_forward_ios,
                    color: locked ? AppColors.textTertiary : steelAzure,
                    size: locked ? 18 : 16,
                  ),
                  // AUDIT FIX: every one of the 15 storefront sections reads and
                  // writes vendor-scoped data through authenticated endpoints, and
                  // all of them were opened with a bare `Navigator.push`. Routing
                  // them through [AuthGuard] here covers the whole subtree from a
                  // single call site — the guard verifies the session before
                  // pushing and re-verifies on every app resume, so a section left
                  // open in the background cannot survive a logout.
                  onTap: () {
                    if (item["page"] == "faq") {
                      openFaq(context);
                    } else if (item["tabId"] == "business") {
                      // Business Details always stays editable and shows its own
                      // richer verification banner, so it skips the generic lock
                      // wrapper — same as the website.
                      AuthGuard.push(
                        context,
                        (_) => item["page"] as Widget,
                        debugLabel: 'Storefront/${item["title"]}',
                      );
                    } else {
                      AuthGuard.push(
                        context,
                        (_) => LockedTabOverlay(
                          tabId: item["tabId"] as String,
                          child: item["page"] as Widget,
                        ),
                        debugLabel: 'Storefront/${item["title"]}',
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
