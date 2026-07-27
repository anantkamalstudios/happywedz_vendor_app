import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../utils/common_app_bar.dart';
import 'Facilities/dj_subcatgory_facility/dj_facilities.dart';
import 'Facilities/dj_subcatgory_facility/sangeet_facilities.dart';
import 'Facilities/dj_subcatgory_facility/wedding_entertainer_facilities.dart';
import 'Facilities/prewedding_subcatgory_facility/prewedding_location_facilities.dart';
import 'Facilities/prewedding_subcatgory_facility/prewedding_photographer_facilities.dart';
import 'Facilities/planning_decor_subcatgory_facility/wedding_planner_facilities.dart';
import 'Facilities/planning_decor_subcatgory_facility/decorator_facilities.dart';
import 'Facilities/jewellery_subcatgory_facility/jewellery_facilities.dart';
import 'Facilities/jewellery_subcatgory_facility/flower_jewellery_facilities.dart';
import 'Facilities/jewellery_subcatgory_facility/accessories_facilities.dart';
import 'Facilities/bridal_subcatgory_facility/bridal_lehenga_facilities.dart';
import 'Facilities/bridal_subcatgory_facility/cocktail_gown_facilities.dart';
import 'Facilities/bridal_subcatgory_facility/rental_outfit_facilities.dart';
import 'Facilities/groom_subcatgory_facility/sherwani_facilities.dart';
import 'Facilities/groom_subcatgory_facility/wedding_suit_facilities.dart';
import 'Facilities/invites_gifts_subcatgory_facility/invitation_facilities.dart';
import 'Facilities/invites_gifts_subcatgory_facility/favor_facilities.dart';
import 'Facilities/invites_gifts_subcatgory_facility/trousseau_packers_facilities.dart';
import 'Facilities/photographer_facilities.dart';
import 'Facilities/venue_facilities.dart';
import 'Facilities/mehendi_facilities.dart';
import 'Facilities/makeup_facilities.dart';
import 'Facilities/florist_facilities.dart';
import 'Facilities/invites_gifts_subcatgory_facility/gifts_facilities.dart';
import 'Facilities/pandit_facilities.dart';
import 'Facilities/caterer_facilities.dart';



class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});
  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {

  // ─── Sub-widget keys ──────────────────────────────────────────────────────
  final _photographerKey = GlobalKey<PhotographerFacilitiesState>();
  final _venueKey        = GlobalKey<VenueFacilitiesState>();
  final _mehendiKey      = GlobalKey<MehendiFacilitiesState>();
  final _makeupKey       = GlobalKey<MakeupFacilitiesState>();
  final _floristKey      = GlobalKey<FloristFacilitiesState>();
  final _giftsKey        = GlobalKey<GiftsFacilitiesState>();
  final _panditKey       = GlobalKey<PanditFacilitiesState>();
  final _catererKey      = GlobalKey<CatererFacilitiesState>();
  final _djKey           = GlobalKey<DjFacilitiesState>();
  final _weddingEntKey   = GlobalKey<WeddingEntertainerFacilitiesState>();
  final _sangeetKey      = GlobalKey<SangeetFacilitiesState>();
  final _preWedLocKey    = GlobalKey<PreWeddingLocationFacilitiesState>();
  final _preWedPhotoKey  = GlobalKey<PreWeddingPhotographerFacilitiesState>();
  final _weddingPlannerKey = GlobalKey<WeddingPlannerFacilitiesState>();
  final _decoratorKey    = GlobalKey<DecoratorFacilitiesState>();
  final _jewelleryKey    = GlobalKey<JewelleryFacilitiesState>();
  final _flowerJewelleryKey = GlobalKey<FlowerJewelleryFacilitiesState>();
  final _accessoriesKey  = GlobalKey<AccessoriesFacilitiesState>();
  final _bridalLehengaKey = GlobalKey<BridalLehengaFacilitiesState>();
  final _cocktailGownKey  = GlobalKey<CocktailGownFacilitiesState>();
  final _rentalOutfitKey  = GlobalKey<RentalOutfitFacilitiesState>();
  final _sherwaniKey      = GlobalKey<SherwaniFacilitiesState>();
  final _weddingSuitKey   = GlobalKey<WeddingSuitFacilitiesState>();
  final _invitationKey    = GlobalKey<InvitationFacilitiesState>();
  final _favorKey         = GlobalKey<FavorFacilitiesState>();
  final _trousseauPackersKey = GlobalKey<TrousseauPackersFacilitiesState>();

  // ─── Legacy controllers (other vendor types) ──────────────────────────────
  final _offeringsCtrl      = TextEditingController();
  final _deliveryCtrl       = TextEditingController();
  final _travelCtrl         = TextEditingController();
  final _happyWedzSinceCtrl = TextEditingController();

  // ─── App state ────────────────────────────────────────────────────────────
  bool    loading                = false;
  bool    saving                 = false;
  int?    vendorId;
  int?    serviceId;
  int?    vendorSubcategoryId;
  int?    vendorTypeId;
  String? token;
  bool    isPhotographer         = false;
  bool    isFullFacilitiesVendor = false;
  bool    isMehendi              = false;
  bool    isMakeup               = false;
  bool    isFlorist              = false;
  bool    isGifts                = false;
  bool    isPandit               = false;
  bool    isCaterer              = false;
  bool    isDj                   = false;
  bool    isWeddingEntertainment = false;
  bool    isSangeet              = false;
  bool    isPreWedLocation       = false;
  bool    isPreWedPhotographer   = false;
  bool    isWeddingPlanner       = false;
  bool    isDecorator            = false;
  bool    isJewellery            = false;
  bool    isFlowerJewellery      = false;
  bool    isAccessories          = false;
  bool    isBridalLehenga        = false;
  bool    isCocktailGown         = false;
  bool    isRentalOutfit         = false;
  bool    isSherwani             = false;
  bool    isWeddingSuit          = false;
  bool    isInvitation           = false;
  bool    isFavor                = false;
  bool    isTrousseauPackers     = false;

  Map<String, dynamic> _currentAttributes = {};

  final VendorServiceApi _api = VendorServiceApi();

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadCredentialsAndData();
  }

  @override
  void dispose() {
    _offeringsCtrl.dispose();
    _deliveryCtrl.dispose();
    _travelCtrl.dispose();
    _happyWedzSinceCtrl.dispose();
    super.dispose();
  }

  // ─── Credentials & data load ──────────────────────────────────────────────
  Future<void> _loadCredentialsAndData() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId            = prefs.getInt('vendorId');
    serviceId           = prefs.getInt('serviceId');
    vendorSubcategoryId = prefs.getInt('vendor_subcategory_id');
    vendorTypeId        = prefs.getInt('vendorTypeId');
    token               = prefs.getString('token');

    _computeFlags();

    if (vendorId != null && token != null) {
      await _fetchData();
    }
    setState(() {});
  }

  // Vendor-type 8 (Music & Dance) routes by subcategory; the authoritative
  // subcategory only arrives after the API fetch, so this is called twice.
  void _computeFlags() {
    isPhotographer         = vendorTypeId == 1;
    isFullFacilitiesVendor = vendorTypeId == 2;
    isMehendi              = vendorTypeId == 5;
    isMakeup               = vendorTypeId == 3;
    isFlorist              = vendorTypeId == 13;
    isGifts                = vendorTypeId == 9 && vendorSubcategoryId == 23;
    isInvitation           = vendorTypeId == 9 && vendorSubcategoryId == 20;
    // Favors (21) also covers Mehndi favors (24) — same form & master.
    isFavor                = vendorTypeId == 9 &&
        (vendorSubcategoryId == 21 || vendorSubcategoryId == 24);
    isTrousseauPackers     = vendorTypeId == 9 && vendorSubcategoryId == 22;
    isPandit               = vendorTypeId == 14;
    isCaterer              = vendorTypeId == 7;
    isDj                   = vendorTypeId == 8 && vendorSubcategoryId == 14;
    isSangeet              = vendorTypeId == 8 && vendorSubcategoryId == 18;
    isWeddingEntertainment = vendorTypeId == 8 && vendorSubcategoryId == 19;
    isPreWedLocation       = vendorTypeId == 12 && vendorSubcategoryId == 31;
    isPreWedPhotographer   = vendorTypeId == 12 && vendorSubcategoryId == 32;
    isDecorator            = vendorTypeId == 4 && vendorSubcategoryId == 5;
    isWeddingPlanner       = vendorTypeId == 4 && vendorSubcategoryId == 17;
    isJewellery            = vendorTypeId == 6 && vendorSubcategoryId == 7;
    isFlowerJewellery      = vendorTypeId == 6 && vendorSubcategoryId == 8;
    isAccessories          = vendorTypeId == 6 && vendorSubcategoryId == 13;
    // Bridal Lehenga (15) also covers Trousseau Sarees (27) and
    // Kanjeevaram / Silk Sarees (25) — same form & master.
    isBridalLehenga        = vendorTypeId == 10 &&
        (vendorSubcategoryId == 15 ||
         vendorSubcategoryId == 27 ||
         vendorSubcategoryId == 25);
    isCocktailGown         = vendorTypeId == 10 && vendorSubcategoryId == 26;
    isRentalOutfit         = vendorTypeId == 10 && vendorSubcategoryId == 28;
    // Sherwani (16) and Sherwani On Rent (29) share the same form.
    isSherwani             = vendorTypeId == 11 &&
        (vendorSubcategoryId == 16 || vendorSubcategoryId == 29);
    isWeddingSuit          = vendorTypeId == 11 && vendorSubcategoryId == 30;
  }

  Future<void> _fetchData() async {
    setState(() => loading = true);
    try {
      final data = await _api.getByVendorId(vendorId: vendorId!, token: token!);
      if (data == null) return;

      serviceId           = data['id'];
      vendorSubcategoryId = data['vendor_subcategory_id'] ?? vendorSubcategoryId;

      final prefs = await SharedPreferences.getInstance();
      if (serviceId != null) await prefs.setInt('serviceId', serviceId!);
      if (vendorSubcategoryId != null) {
        await prefs.setInt('vendor_subcategory_id', vendorSubcategoryId!);
      }

      _currentAttributes = Map<String, dynamic>.from(data['attributes'] ?? {});

      // Subcategory is now authoritative — recompute subcategory-dependent flags.
      _computeFlags();

      // Legacy vendor types use direct text controllers
      if (!isPhotographer && !isFullFacilitiesVendor && !isMehendi && !isMakeup &&
          !isFlorist && !isGifts && !isPandit && !isCaterer &&
          !isDj && !isWeddingEntertainment && !isSangeet &&
          !isPreWedLocation && !isPreWedPhotographer &&
          !isWeddingPlanner && !isDecorator &&
          !isJewellery && !isFlowerJewellery && !isAccessories &&
          !isBridalLehenga && !isCocktailGown && !isRentalOutfit &&
          !isSherwani && !isWeddingSuit &&
          !isInvitation && !isFavor && !isTrousseauPackers) {
        _offeringsCtrl.text      = _currentAttributes['offerings'] ?? '';
        _deliveryCtrl.text       = _currentAttributes['delivery_time'] ?? '';
        _travelCtrl.text         = _currentAttributes['travel_info'] ?? '';
        _happyWedzSinceCtrl.text = _currentAttributes['happywedz_since'] ?? '';
      }
    } catch (e) {
      debugPrint("Facilities fetch error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────────────
  Future<void> _saveData() async {
    if (vendorId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please login again.")),
      );
      return;
    }
    setState(() => saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      if (serviceId == null) {
        final byVendor = await _api.getByVendorId(vendorId: vendorId!, token: token!);
        if (byVendor != null) {
          serviceId           = byVendor['id'];
          vendorSubcategoryId = byVendor['vendor_subcategory_id'] ?? vendorSubcategoryId;
          await prefs.setInt('serviceId', serviceId!);
          if (vendorSubcategoryId != null) {
            await prefs.setInt('vendor_subcategory_id', vendorSubcategoryId!);
          }
        } else {
          final created = await _api.createService(
            token: token!,
            body: {"vendor_id": vendorId, "vendor_subcategory_id": vendorSubcategoryId, "attributes": {}},
          );
          if (!created) throw "Service create failed";
          final fresh = await _api.getByVendorId(vendorId: vendorId!, token: token!);
          serviceId           = fresh?['id'];
          vendorSubcategoryId = fresh?['vendor_subcategory_id'] ?? vendorSubcategoryId;
          if (serviceId != null) await prefs.setInt('serviceId', serviceId!);
        }
      }

      final latest     = await _api.getByServiceId(serviceId: serviceId!, token: token!);
      final attributes = Map<String, dynamic>.from(latest?['attributes'] ?? {});
      vendorSubcategoryId ??= latest?['vendor_subcategory_id'];

      Map<String, dynamic> toMap(dynamic v) =>
          v is Map ? Map<String, dynamic>.from(v) : {};

      if (isPhotographer) {
        attributes["photographer_master"] =
            _photographerKey.currentState?.buildMaster(toMap(attributes["photographer_master"]))
            ?? attributes["photographer_master"];
      } else if (isFullFacilitiesVendor) {
        attributes["venue_master"] =
            _venueKey.currentState?.buildMaster(toMap(attributes["venue_master"]))
            ?? attributes["venue_master"];
      } else if (isMehendi) {
        attributes["mehndi_artist_master"] =
            _mehendiKey.currentState?.buildMaster(toMap(attributes["mehndi_artist_master"]))
            ?? attributes["mehndi_artist_master"];
      } else if (isMakeup) {
        attributes["makeup_artist_master"] =
            _makeupKey.currentState?.buildMaster(toMap(attributes["makeup_artist_master"]))
            ?? attributes["makeup_artist_master"];
      } else if (isFlorist) {
        attributes["florist_master"] =
            _floristKey.currentState?.buildMaster(toMap(attributes["florist_master"]))
            ?? attributes["florist_master"];
      } else if (isGifts) {
        attributes["gift_master"] =
            _giftsKey.currentState?.buildMaster(toMap(attributes["gift_master"]))
            ?? attributes["gift_master"];
      } else if (isInvitation) {
        attributes["invitation_master"] =
            _invitationKey.currentState?.buildMaster(toMap(attributes["invitation_master"]))
            ?? attributes["invitation_master"];
      } else if (isFavor) {
        attributes["favor_master"] =
            _favorKey.currentState?.buildMaster(toMap(attributes["favor_master"]))
            ?? attributes["favor_master"];
      } else if (isTrousseauPackers) {
        attributes["trousseau_master"] =
            _trousseauPackersKey.currentState?.buildMaster(toMap(attributes["trousseau_master"]))
            ?? attributes["trousseau_master"];
      } else if (isPandit) {
        attributes["pandit_master"] =
            _panditKey.currentState?.buildMaster(toMap(attributes["pandit_master"]))
            ?? attributes["pandit_master"];
      } else if (isCaterer) {
        attributes["caterer_master"] =
            _catererKey.currentState?.buildMaster(toMap(attributes["caterer_master"]))
            ?? attributes["caterer_master"];
      } else if (isDj) {
        attributes["dj_master"] =
            _djKey.currentState?.buildMaster(toMap(attributes["dj_master"]))
            ?? attributes["dj_master"];
      } else if (isWeddingEntertainment) {
        attributes["wedding_entertainer_master"] =
            _weddingEntKey.currentState?.buildMaster(toMap(attributes["wedding_entertainer_master"]))
            ?? attributes["wedding_entertainer_master"];
      } else if (isSangeet) {
        attributes["choreographer_master"] =
            _sangeetKey.currentState?.buildMaster(toMap(attributes["choreographer_master"]))
            ?? attributes["choreographer_master"];
      } else if (isPreWedLocation) {
        attributes["pre_wedding_location_master"] =
            _preWedLocKey.currentState?.buildMaster(toMap(attributes["pre_wedding_location_master"]))
            ?? attributes["pre_wedding_location_master"];
      } else if (isPreWedPhotographer) {
        attributes["pre_wedding_photographer_master"] =
            _preWedPhotoKey.currentState?.buildMaster(toMap(attributes["pre_wedding_photographer_master"]))
            ?? attributes["pre_wedding_photographer_master"];
      } else if (isWeddingPlanner) {
        attributes["wedding_planner_master"] =
            _weddingPlannerKey.currentState?.buildMaster(toMap(attributes["wedding_planner_master"]))
            ?? attributes["wedding_planner_master"];
      } else if (isDecorator) {
        attributes["decorator_master"] =
            _decoratorKey.currentState?.buildMaster(toMap(attributes["decorator_master"]))
            ?? attributes["decorator_master"];
      } else if (isJewellery) {
        attributes["jewellery_master"] =
            _jewelleryKey.currentState?.buildMaster(toMap(attributes["jewellery_master"]))
            ?? attributes["jewellery_master"];
      } else if (isFlowerJewellery) {
        attributes["flower_jewellery_master"] =
            _flowerJewelleryKey.currentState?.buildMaster(toMap(attributes["flower_jewellery_master"]))
            ?? attributes["flower_jewellery_master"];
      } else if (isAccessories) {
        attributes["accessories_master"] =
            _accessoriesKey.currentState?.buildMaster(toMap(attributes["accessories_master"]))
            ?? attributes["accessories_master"];
      } else if (isBridalLehenga) {
        attributes["bridal_outfit_master"] =
            _bridalLehengaKey.currentState?.buildMaster(toMap(attributes["bridal_outfit_master"]))
            ?? attributes["bridal_outfit_master"];
      } else if (isCocktailGown) {
        attributes["cocktail_gown_master"] =
            _cocktailGownKey.currentState?.buildMaster(toMap(attributes["cocktail_gown_master"]))
            ?? attributes["cocktail_gown_master"];
      } else if (isRentalOutfit) {
        attributes["rental_outfit_master"] =
            _rentalOutfitKey.currentState?.buildMaster(toMap(attributes["rental_outfit_master"]))
            ?? attributes["rental_outfit_master"];
      } else if (isSherwani) {
        attributes["sherwani_master"] =
            _sherwaniKey.currentState?.buildMaster(toMap(attributes["sherwani_master"]))
            ?? attributes["sherwani_master"];
      } else if (isWeddingSuit) {
        attributes["wedding_suit_master"] =
            _weddingSuitKey.currentState?.buildMaster(toMap(attributes["wedding_suit_master"]))
            ?? attributes["wedding_suit_master"];
      } else {
        attributes["offerings"]       = _offeringsCtrl.text;
        attributes["delivery_time"]   = _deliveryCtrl.text;
        attributes["travel_info"]     = _travelCtrl.text;
        attributes["happywedz_since"] = _happyWedzSinceCtrl.text;
      }

      final success = await _api.updateService(
        serviceId: serviceId!,
        token: token!,
        body: {
          "vendor_id":            vendorId,
          "vendor_subcategory_id":vendorSubcategoryId,
          "attributes":           attributes,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? "Facilities saved successfully"
              : "Failed to save. Please try again."),
        ));
      }
      if (success) {
        await StorefrontCompletionService.refreshCompletion(serviceId: serviceId!);
      }
    } catch (e) {
      debugPrint("Facilities save error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Save failed: $e")));
      }
    }

    setState(() => saving = false);
  }

  // ─── Legacy field helper ──────────────────────────────────────────────────
  Widget _field(String title, TextEditingController c, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: "Facilities & Features"),
      backgroundColor: Colors.white,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPhotographer)
                    PhotographerFacilities(
                      key: _photographerKey,
                      attributes: _currentAttributes,
                    )
                  else if (isFullFacilitiesVendor)
                    VenueFacilities(
                      key: _venueKey,
                      attributes: _currentAttributes,
                    )
                  else if (isMehendi)
                    MehendiFacilities(
                      key: _mehendiKey,
                      attributes: _currentAttributes,
                    )
                  else if (isMakeup)
                    MakeupFacilities(
                      key: _makeupKey,
                      attributes: _currentAttributes,
                    )
                  else if (isFlorist)
                    FloristFacilities(
                      key: _floristKey,
                      attributes: _currentAttributes,
                    )
                  else if (isGifts)
                    GiftsFacilities(
                      key: _giftsKey,
                      attributes: _currentAttributes,
                    )
                  else if (isInvitation)
                    InvitationFacilities(
                      key: _invitationKey,
                      attributes: _currentAttributes,
                    )
                  else if (isFavor)
                    FavorFacilities(
                      key: _favorKey,
                      attributes: _currentAttributes,
                    )
                  else if (isTrousseauPackers)
                    TrousseauPackersFacilities(
                      key: _trousseauPackersKey,
                      attributes: _currentAttributes,
                    )
                  else if (isPandit)
                    PanditFacilities(
                      key: _panditKey,
                      attributes: _currentAttributes,
                    )
                  else if (isCaterer)
                    CatererFacilities(
                      key: _catererKey,
                      attributes: _currentAttributes,
                    )
                  else if (isDj)
                    DjFacilities(
                      key: _djKey,
                      attributes: _currentAttributes,
                    )
                  else if (isWeddingEntertainment)
                    WeddingEntertainerFacilities(
                      key: _weddingEntKey,
                      attributes: _currentAttributes,
                    )
                  else if (isSangeet)
                    SangeetFacilities(
                      key: _sangeetKey,
                      attributes: _currentAttributes,
                    )
                  else if (isPreWedLocation)
                    PreWeddingLocationFacilities(
                      key: _preWedLocKey,
                      attributes: _currentAttributes,
                    )
                  else if (isPreWedPhotographer)
                    PreWeddingPhotographerFacilities(
                      key: _preWedPhotoKey,
                      attributes: _currentAttributes,
                    )
                  else if (isWeddingPlanner)
                    WeddingPlannerFacilities(
                      key: _weddingPlannerKey,
                      attributes: _currentAttributes,
                    )
                  else if (isDecorator)
                    DecoratorFacilities(
                      key: _decoratorKey,
                      attributes: _currentAttributes,
                    )
                  else if (isJewellery)
                    JewelleryFacilities(
                      key: _jewelleryKey,
                      attributes: _currentAttributes,
                    )
                  else if (isFlowerJewellery)
                    FlowerJewelleryFacilities(
                      key: _flowerJewelleryKey,
                      attributes: _currentAttributes,
                    )
                  else if (isAccessories)
                    AccessoriesFacilities(
                      key: _accessoriesKey,
                      attributes: _currentAttributes,
                    )
                  else if (isBridalLehenga)
                    BridalLehengaFacilities(
                      key: _bridalLehengaKey,
                      attributes: _currentAttributes,
                    )
                  else if (isCocktailGown)
                    CocktailGownFacilities(
                      key: _cocktailGownKey,
                      attributes: _currentAttributes,
                    )
                  else if (isRentalOutfit)
                    RentalOutfitFacilities(
                      key: _rentalOutfitKey,
                      attributes: _currentAttributes,
                    )
                  else if (isSherwani)
                    SherwaniFacilities(
                      key: _sherwaniKey,
                      attributes: _currentAttributes,
                    )
                  else if (isWeddingSuit)
                    WeddingSuitFacilities(
                      key: _weddingSuitKey,
                      attributes: _currentAttributes,
                    )
                  else ...[
                    _field("Offerings", _offeringsCtrl),
                    _field("Delivery Time", _deliveryCtrl),
                    _field("Travel Info", _travelCtrl),
                    _field("HappyWedz Since", _happyWedzSinceCtrl),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00509D),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save facilities & features",
                              style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
