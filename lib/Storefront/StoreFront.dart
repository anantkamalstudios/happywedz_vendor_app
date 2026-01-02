import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/common_app_bar.dart';
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


  static const Color steelAzure = Color(0xFF4682B4);

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
        MaterialPageRoute(builder: (_) => page()),
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Map<String, dynamic>> menuItems = [
      {
        "title": "Business Details",
        "icon": Icons.business_center_outlined,
        "page": BusinessDetailsPage()
      },
      {
        "title": "Basic Information",
        "icon": Icons.info_outline,
        "page": BasicInfoPage()
      },
      {"title": "FAQ", "icon": Icons.help_center_outlined, "page": "faq"},
      {
        "title": "Contact Details",
        "icon": Icons.call_outlined,
        "page": ContactDetailsPage(),

      },
      {
        "title": "Location & Service Areas",
        "icon": Icons.location_on_outlined,
        "page": LocationPage()
      },
      {
        "title": "Photos",
        "icon": Icons.photo_library_outlined,
        "page": GalleryUploadPage()
      },
      {
        "title": "Videos",
        "icon": Icons.video_collection_outlined,
        "page": VideoUploadPage()
      },
      {
        "title": "Preferred Vendors",
        "icon": Icons.group_outlined,
        "page": PreferredVendorsPage()
      },
      {
        "title": "Social Network",
        "icon": Icons.public_outlined,
        "page": SocialNetworkPage()
      },
      {
        "title": "Facilities & Features",
        "icon": Icons.widgets_outlined,
        "page": FacilitiesPage()
      },

      if (canShowMenus)
        {
          "title": "Menus",
          "icon": Icons.restaurant_menu,
          "page": MenusPage()
        },

      {
        "title": "Promotions",
        "icon": Icons.local_offer_outlined,
        "page": PromotionsPage()
      },
      {
        "title": "Policies & Terms",
        "icon": Icons.shield_outlined,
        "page": PoliciesPage()
      },
      {
        "title": "Availability & Slots",
        "icon": Icons.schedule_outlined,
        "page": SlotsPage()
      },
      {
        "title": "Pricing & Packages",
        "icon": Icons.attach_money,
        "page": PricingPage()
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: CommonAppBar(
        title: "Storefront",
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: Icon(item["icon"], color: steelAzure, size: 26),
              title: Text(
                item["title"],
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  color: steelAzure, size: 18),
              onTap: () {
                if (item["page"] == "faq") {
                  openFaq(context);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item["page"]),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
