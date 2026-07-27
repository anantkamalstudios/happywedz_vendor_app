import 'package:flutter/material.dart';
import 'facilities_helpers.dart';

// ─── Venue space repeatable entry ─────────────────────────────────────────────
class VenueSpaceEntry {
  final TextEditingController nameCtrl     = TextEditingController();
  final TextEditingController seatingCtrl  = TextEditingController();
  final TextEditingController floatingCtrl = TextEditingController();
  final TextEditingController notesCtrl    = TextEditingController();
  String? type;
  String? indoorOutdoor;
  String? ac;
  String? dedicatedKitchen;
  String? attachedRooms;

  void dispose() {
    nameCtrl.dispose();
    seatingCtrl.dispose();
    floatingCtrl.dispose();
    notesCtrl.dispose();
  }

  Map<String, dynamic> toMap() => {
    "space_name":        nameCtrl.text,
    "space_type":        type ?? '',
    "indoor_outdoor":    indoorOutdoor ?? '',
    "seating":           seatingCtrl.text,
    "floating":          floatingCtrl.text,
    "ac":                ac ?? '',
    "dedicated_kitchen": dedicatedKitchen ?? '',
    "attached_rooms":    attachedRooms ?? '',
    "notes":             notesCtrl.text,
  };

  static VenueSpaceEntry fromMap(Map<String, dynamic> m) {
    final e = VenueSpaceEntry();
    e.nameCtrl.text     = m['space_name']?.toString() ?? '';
    e.type              = m['space_type'] as String?;
    e.indoorOutdoor     = m['indoor_outdoor'] as String?;
    e.seatingCtrl.text  = m['seating']?.toString() ?? '';
    e.floatingCtrl.text = m['floating']?.toString() ?? '';
    e.ac                = m['ac'] as String?;
    e.dedicatedKitchen  = m['dedicated_kitchen'] as String?;
    e.attachedRooms     = m['attached_rooms'] as String?;
    e.notesCtrl.text    = m['notes']?.toString() ?? '';
    return e;
  }
}

// ─── Venue Facilities Widget ───────────────────────────────────────────────────
class VenueFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const VenueFacilities({super.key, required this.attributes});

  @override
  State<VenueFacilities> createState() => VenueFacilitiesState();
}

class VenueFacilitiesState extends State<VenueFacilities>
    with FacilitiesHelpersMixin<VenueFacilities> {

  // Categories
  List<String> _vCatPrimary   = [];
  List<String> _vCatPremium   = [];
  List<String> _vCatLocation  = [];
  List<String> _vCatCapacity  = [];
  List<String> _vCatBudget    = [];
  List<String> _vCatFunction  = [];
  List<String> _vCatFacility  = [];
  List<String> _vCatBooking   = [];
  List<String> _vCatTrend     = [];

  // Identity
  String? _vPropertyOwnership;
  final   _vYearsOperationCtrl    = TextEditingController();
  String? _vLocationType;
  String? _vChainProperty;
  final   _vChainBrandNameCtrl    = TextEditingController();
  String? _vChainBrandCategory;
  final   _vExactLocationCtrl     = TextEditingController();

  // Space & Capacity
  List<String>        _vSpaceTypes                 = [];
  final               _vNumEventSpacesCtrl         = TextEditingController();
  final               _vIndoorSpacesCountCtrl      = TextEditingController();
  final               _vOutdoorSpacesCountCtrl     = TextEditingController();
  final               _vIndoorSeatingCtrl          = TextEditingController();
  final               _vIndoorFloatingCtrl         = TextEditingController();
  final               _vOutdoorSeatingCtrl         = TextEditingController();
  final               _vOutdoorFloatingCtrl        = TextEditingController();
  final               _vMinGuestsCtrl              = TextEditingController();
  final               _vMaxGuestsCtrl              = TextEditingController();
  String?             _vSeparateFunctionAreas;
  String?             _vMultipleEventsSimultaneous;
  String?             _vExclusiveBooking;
  List<VenueSpaceEntry> _vSpaces                   = [];

  // Rooms
  final               _vNumRoomsCtrl               = TextEditingController();
  List<String>        _vRoomTypes                  = [];
  final Map<String, TextEditingController> _vRoomTypeCounts = {
    'Deluxe':             TextEditingController(),
    'Executive':          TextEditingController(),
    'Suite':              TextEditingController(),
    'Junior Suite':       TextEditingController(),
    'Presidential Suite': TextEditingController(),
    'Villa':              TextEditingController(),
    'Cottage':            TextEditingController(),
    'Dormitory':          TextEditingController(),
    'Family Room':        TextEditingController(),
    'Tent / Glamping':    TextEditingController(),
  };
  final  _vMaxOccupancyCtrl        = TextEditingController();
  String? _vExtraBed;
  String? _vRoomPriceRange;
  final   _vComplimentaryRoomsCtrl = TextEditingController();
  final   _vTotalStayCapacityCtrl  = TextEditingController();

  // Food
  String?      _vCateringPolicy;
  List<String> _vCuisines               = [];
  String?      _vVegNonVeg;
  String?      _vJainFood;
  String?      _vPerPlateCostRange;
  String?      _vOutsideCateringCharges;
  String?      _vKitchenForExternal;

  // Alcohol
  String?      _vAlcoholPolicy;
  String?      _vCorkage;
  List<String> _vBarSetup              = [];

  // Decor
  String?      _vDecorPolicy;
  List<String> _vDecorCapabilities     = [];
  List<String> _vStageSetup            = [];
  List<String> _vMandapSetup           = [];
  List<String> _vDecorLighting         = [];
  List<String> _vSoundSystem           = [];
  String?      _vOutsideDecorCharges;

  // Entertainment
  String?      _vDjPolicy;
  String?      _vNoiseRestrictions;
  String?      _vLiveBand;
  String?      _vFireworks;
  List<String> _vEntertainmentSupported = [];

  // Facilities
  String?      _vParkingAvailable;
  final        _vParkingCapacityCtrl   = TextEditingController();
  String?      _vValetParking;
  List<String> _vPowerBackup           = [];
  String?      _vAirConditioning;
  String?      _vBridalRoom;
  String?      _vGroomRoom;
  String?      _vWheelchairAccess;
  String?      _vWashroomQuality;
  String?      _vLiftAccess;
  String?      _vSecurity;
  List<String> _vAdditionalFacilities  = [];

  // Pricing & Booking
  List<String> _vPricingModel          = [];
  final        _vStartingVenuePriceCtrl = TextEditingController();
  String?      _vPeakSeasonPricing;
  String?      _vAdvanceBookingRequired;
  String?      _vAdvancePaymentRange;
  List<String> _vMinBookingDuration    = [];
  String?      _vCancellationPolicy;
  String?      _vRefundTimeline;

  // Suitability
  List<String> _vSuitableFor           = [];
  List<String> _vBestFor               = [];
  List<String> _vIdealGuestRange       = [];

  // Image Intelligence
  final _vDefaultFunctionTypeCtrl = TextEditingController();
  final _vDefaultThemeCtrl        = TextEditingController();
  final _vDefaultPaletteCtrl      = TextEditingController();
  final _vDefaultSetupCtrl        = TextEditingController();
  final _vDefaultBudgetRangeCtrl  = TextEditingController();
  final _vOtherTagsCtrl           = TextEditingController();
  final _vImageNotesCtrl          = TextEditingController();

  // Section expansion
  bool _vs1  = true;
  bool _vs2  = false;
  bool _vs3  = false;
  bool _vs4  = false;
  bool _vs5  = false;
  bool _vs6  = false;
  bool _vs7  = false;
  bool _vs8  = false;
  bool _vs9  = false;
  bool _vs10 = false;
  bool _vs11 = false;

  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _vYearsOperationCtrl.dispose();
    _vChainBrandNameCtrl.dispose();
    _vExactLocationCtrl.dispose();
    _vNumEventSpacesCtrl.dispose();
    _vIndoorSpacesCountCtrl.dispose();
    _vOutdoorSpacesCountCtrl.dispose();
    _vIndoorSeatingCtrl.dispose();
    _vIndoorFloatingCtrl.dispose();
    _vOutdoorSeatingCtrl.dispose();
    _vOutdoorFloatingCtrl.dispose();
    _vMinGuestsCtrl.dispose();
    _vMaxGuestsCtrl.dispose();
    for (final e in _vSpaces) { e.dispose(); }
    _vNumRoomsCtrl.dispose();
    for (final c in _vRoomTypeCounts.values) { c.dispose(); }
    _vMaxOccupancyCtrl.dispose();
    _vComplimentaryRoomsCtrl.dispose();
    _vTotalStayCapacityCtrl.dispose();
    _vParkingCapacityCtrl.dispose();
    _vStartingVenuePriceCtrl.dispose();
    _vDefaultFunctionTypeCtrl.dispose();
    _vDefaultThemeCtrl.dispose();
    _vDefaultPaletteCtrl.dispose();
    _vDefaultSetupCtrl.dispose();
    _vDefaultBudgetRangeCtrl.dispose();
    _vOtherTagsCtrl.dispose();
    _vImageNotesCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final vm = asMap(attrs['venue_master']);

    final cats = asMap(vm['categories']);
    _vCatPrimary  = toList(cats['primary']  ?? cats['primaryVenueTypes']);
    _vCatPremium  = toList(cats['premium']);
    _vCatLocation = toList(cats['locationBased']);
    _vCatCapacity = toList(cats['capacityBased']);
    _vCatBudget   = toList(cats['budgetBased']);
    _vCatFunction = toList(cats['functionSpecific']);
    _vCatFacility = toList(cats['facilityBased']);
    _vCatBooking  = toList(cats['bookingFlex']);
    _vCatTrend    = toList(cats['trendModern']);

    final id = asMap(vm['identity']);
    _vPropertyOwnership       = id['property_ownership'] as String?;
    _vYearsOperationCtrl.text = id['years_of_operation']?.toString() ?? '';
    _vLocationType            = id['location_type'] as String?;
    _vChainProperty           = id['chain_property'] as String?;
    _vChainBrandNameCtrl.text = id['chain_brand_name']?.toString() ?? '';
    _vChainBrandCategory      = id['chain_brand_category'] as String?;
    _vExactLocationCtrl.text  = id['exact_location_text']?.toString() ?? '';

    final sc = asMap(vm['space_capacity']);
    _vSpaceTypes                  = toList(sc['space_types']);
    _vNumEventSpacesCtrl.text     = sc['num_event_spaces']?.toString() ?? '';
    _vIndoorSpacesCountCtrl.text  = sc['indoor_spaces_count']?.toString() ?? '';
    _vOutdoorSpacesCountCtrl.text = sc['outdoor_spaces_count']?.toString() ?? '';
    _vIndoorSeatingCtrl.text      = sc['indoor_seating']?.toString() ?? '';
    _vIndoorFloatingCtrl.text     = sc['indoor_floating']?.toString() ?? '';
    _vOutdoorSeatingCtrl.text     = sc['outdoor_seating']?.toString() ?? '';
    _vOutdoorFloatingCtrl.text    = sc['outdoor_floating']?.toString() ?? '';
    _vMinGuestsCtrl.text          = sc['min_guests']?.toString() ?? '';
    _vMaxGuestsCtrl.text          = sc['max_guests']?.toString() ?? '';
    _vSeparateFunctionAreas       = sc['separate_function_areas'] as String?;
    _vMultipleEventsSimultaneous  = sc['multiple_events_simultaneous'] as String?;
    _vExclusiveBooking            = sc['exclusive_booking'] as String?;
    for (final e in _vSpaces) { e.dispose(); }
    _vSpaces = (sc['spaces'] as List? ?? [])
        .map((s) => VenueSpaceEntry.fromMap(Map<String, dynamic>.from(s)))
        .toList();

    final ro = asMap(vm['rooms']);
    _vNumRoomsCtrl.text           = ro['num_rooms']?.toString() ?? '';
    _vRoomTypes                   = toList(ro['room_types']);
    final rtc = asMap(ro['room_type_counts']);
    _vRoomTypeCounts.forEach((t, c) => c.text = rtc[t]?.toString() ?? '');
    _vMaxOccupancyCtrl.text       = ro['max_occupancy_per_room']?.toString() ?? '';
    _vExtraBed                    = ro['extra_bed'] as String?;
    _vRoomPriceRange              = ro['room_price_range'] as String?;
    _vComplimentaryRoomsCtrl.text = ro['complimentary_rooms']?.toString() ?? '';
    _vTotalStayCapacityCtrl.text  = ro['total_stay_capacity']?.toString() ?? '';

    final fo = asMap(vm['food']);
    _vCateringPolicy           = fo['catering_policy'] as String?;
    _vCuisines                 = toList(fo['cuisines']);
    _vVegNonVeg                = fo['veg_non_veg'] as String?;
    _vJainFood                 = fo['jain_food'] as String?;
    _vPerPlateCostRange        = fo['per_plate_cost_range'] as String?;
    _vOutsideCateringCharges   = fo['outside_catering_charges'] as String?;
    _vKitchenForExternal       = fo['kitchen_for_external'] as String?;

    final al = asMap(vm['alcohol']);
    _vAlcoholPolicy = al['policy'] as String?;
    _vCorkage       = al['corkage'] as String?;
    _vBarSetup      = toList(al['bar_setup']);

    final de = asMap(vm['decor']);
    _vDecorPolicy         = de['policy'] as String?;
    _vDecorCapabilities   = toList(de['capabilities']);
    _vStageSetup          = toList(de['stage']);
    _vMandapSetup         = toList(de['mandap']);
    _vDecorLighting       = toList(de['lighting']);
    _vSoundSystem         = toList(de['sound']);
    _vOutsideDecorCharges = de['outside_charges'] as String?;

    final en = asMap(vm['entertainment']);
    _vDjPolicy               = en['dj_policy'] as String?;
    _vNoiseRestrictions      = en['noise'] as String?;
    _vLiveBand               = en['live_band'] as String?;
    _vFireworks              = en['fireworks'] as String?;
    _vEntertainmentSupported = toList(en['supported']);

    final fa = asMap(vm['facilities']);
    _vParkingAvailable        = fa['parking'] as String?;
    _vParkingCapacityCtrl.text = fa['parking_capacity']?.toString() ?? '';
    _vValetParking            = fa['valet'] as String?;
    _vPowerBackup             = toList(fa['power_backup']);
    _vAirConditioning         = fa['ac'] as String?;
    _vBridalRoom              = fa['bridal_room'] as String?;
    _vGroomRoom               = fa['groom_room'] as String?;
    _vWheelchairAccess        = fa['wheelchair'] as String?;
    _vWashroomQuality         = fa['washroom'] as String?;
    _vLiftAccess              = fa['lift'] as String?;
    _vSecurity                = fa['security'] as String?;
    _vAdditionalFacilities    = toList(fa['additional']);

    final pb = asMap(vm['pricing_booking']);
    _vPricingModel              = toList(pb['pricing_model']);
    _vStartingVenuePriceCtrl.text = pb['starting_venue_price']?.toString() ?? '';
    _vPeakSeasonPricing         = pb['peak_season_pricing'] as String?;
    _vAdvanceBookingRequired    = pb['advance_booking_required'] as String?;
    _vAdvancePaymentRange       = pb['advance_payment_range'] as String?;
    _vMinBookingDuration        = toList(pb['min_booking_duration']);
    _vCancellationPolicy        = pb['cancellation'] as String?;
    _vRefundTimeline            = pb['refund_timeline'] as String?;

    final su = asMap(vm['suitability']);
    _vSuitableFor    = toList(su['suitable_for']);
    _vBestFor        = toList(su['best_for']);
    _vIdealGuestRange = toList(su['ideal_guest_range']);

    final ii = asMap(vm['image_intelligence']);
    _vDefaultFunctionTypeCtrl.text = ii['default_function_type']?.toString() ?? '';
    _vDefaultThemeCtrl.text        = ii['default_theme']?.toString() ?? '';
    _vDefaultPaletteCtrl.text      = ii['default_palette']?.toString() ?? '';
    _vDefaultSetupCtrl.text        = ii['default_setup']?.toString() ?? '';
    _vDefaultBudgetRangeCtrl.text  = ii['default_budget_range']?.toString() ?? '';
    _vOtherTagsCtrl.text           = ii['other_tags']?.toString() ?? '';
    _vImageNotesCtrl.text          = ii['notes']?.toString() ?? '';
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    final rtc = <String, String>{};
    for (final e in _vRoomTypeCounts.entries) {
      if (e.value.text.isNotEmpty) rtc[e.key] = e.value.text;
    }
    return {
      ...ex,
      "categories": {
        ...asMap(ex["categories"]),
        "primary":          _vCatPrimary,
        "premium":          _vCatPremium,
        "locationBased":    _vCatLocation,
        "capacityBased":    _vCatCapacity,
        "budgetBased":      _vCatBudget,
        "functionSpecific": _vCatFunction,
        "facilityBased":    _vCatFacility,
        "bookingFlex":      _vCatBooking,
        "trendModern":      _vCatTrend,
      },
      "identity": {
        ...asMap(ex["identity"]),
        "property_ownership":   _vPropertyOwnership,
        "years_of_operation":   _vYearsOperationCtrl.text,
        "location_type":        _vLocationType,
        "chain_property":       _vChainProperty,
        "chain_brand_name":     _vChainBrandNameCtrl.text,
        "chain_brand_category": _vChainBrandCategory,
        "exact_location_text":  _vExactLocationCtrl.text,
      },
      "space_capacity": {
        ...asMap(ex["space_capacity"]),
        "space_types":                   _vSpaceTypes,
        "num_event_spaces":              _vNumEventSpacesCtrl.text,
        "indoor_spaces_count":           _vIndoorSpacesCountCtrl.text,
        "outdoor_spaces_count":          _vOutdoorSpacesCountCtrl.text,
        "indoor_seating":                _vIndoorSeatingCtrl.text,
        "indoor_floating":               _vIndoorFloatingCtrl.text,
        "outdoor_seating":               _vOutdoorSeatingCtrl.text,
        "outdoor_floating":              _vOutdoorFloatingCtrl.text,
        "min_guests":                    _vMinGuestsCtrl.text,
        "max_guests":                    _vMaxGuestsCtrl.text,
        "separate_function_areas":       _vSeparateFunctionAreas,
        "multiple_events_simultaneous":  _vMultipleEventsSimultaneous,
        "exclusive_booking":             _vExclusiveBooking,
        "spaces":                        _vSpaces.map((e) => e.toMap()).toList(),
      },
      "rooms": {
        ...asMap(ex["rooms"]),
        "num_rooms":              _vNumRoomsCtrl.text,
        "room_types":             _vRoomTypes,
        "room_type_counts":       rtc,
        "max_occupancy_per_room": _vMaxOccupancyCtrl.text,
        "extra_bed":              _vExtraBed,
        "room_price_range":       _vRoomPriceRange,
        "complimentary_rooms":    _vComplimentaryRoomsCtrl.text,
        "total_stay_capacity":    _vTotalStayCapacityCtrl.text,
      },
      "food": {
        ...asMap(ex["food"]),
        "catering_policy":          _vCateringPolicy,
        "cuisines":                 _vCuisines,
        "veg_non_veg":              _vVegNonVeg,
        "jain_food":                _vJainFood,
        "per_plate_cost_range":     _vPerPlateCostRange,
        "outside_catering_charges": _vOutsideCateringCharges,
        "kitchen_for_external":     _vKitchenForExternal,
      },
      "alcohol": {
        ...asMap(ex["alcohol"]),
        "policy":    _vAlcoholPolicy,
        "corkage":   _vCorkage,
        "bar_setup": _vBarSetup,
      },
      "decor": {
        ...asMap(ex["decor"]),
        "policy":          _vDecorPolicy,
        "capabilities":    _vDecorCapabilities,
        "stage":           _vStageSetup,
        "mandap":          _vMandapSetup,
        "lighting":        _vDecorLighting,
        "sound":           _vSoundSystem,
        "outside_charges": _vOutsideDecorCharges,
      },
      "entertainment": {
        ...asMap(ex["entertainment"]),
        "dj_policy": _vDjPolicy,
        "noise":     _vNoiseRestrictions,
        "live_band": _vLiveBand,
        "fireworks": _vFireworks,
        "supported": _vEntertainmentSupported,
      },
      "facilities": {
        ...asMap(ex["facilities"]),
        "parking":          _vParkingAvailable,
        "parking_capacity": _vParkingCapacityCtrl.text,
        "valet":            _vValetParking,
        "power_backup":     _vPowerBackup,
        "ac":               _vAirConditioning,
        "bridal_room":      _vBridalRoom,
        "groom_room":       _vGroomRoom,
        "wheelchair":       _vWheelchairAccess,
        "washroom":         _vWashroomQuality,
        "lift":             _vLiftAccess,
        "security":         _vSecurity,
        "additional":       _vAdditionalFacilities,
      },
      "pricing_booking": {
        ...asMap(ex["pricing_booking"]),
        "pricing_model":            _vPricingModel,
        "starting_venue_price":     _vStartingVenuePriceCtrl.text,
        "peak_season_pricing":      _vPeakSeasonPricing,
        "advance_booking_required": _vAdvanceBookingRequired,
        "advance_payment_range":    _vAdvancePaymentRange,
        "min_booking_duration":     _vMinBookingDuration,
        "cancellation":             _vCancellationPolicy,
        "refund_timeline":          _vRefundTimeline,
      },
      "suitability": {
        ...asMap(ex["suitability"]),
        "suitable_for":      _vSuitableFor,
        "best_for":          _vBestFor,
        "ideal_guest_range": _vIdealGuestRange,
      },
      "image_intelligence": {
        ...asMap(ex["image_intelligence"]),
        "default_function_type": _vDefaultFunctionTypeCtrl.text,
        "default_theme":         _vDefaultThemeCtrl.text,
        "default_palette":       _vDefaultPaletteCtrl.text,
        "default_setup":         _vDefaultSetupCtrl.text,
        "default_budget_range":  _vDefaultBudgetRangeCtrl.text,
        "other_tags":            _vOtherTagsCtrl.text,
        "notes":                 _vImageNotesCtrl.text,
      },
    };
  }

  Widget _buildSpaceItem(int index) {
    final e = _vSpaces[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text("Space ${index + 1}", style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => setState(() {
                _vSpaces[index].dispose();
                _vSpaces.removeAt(index);
              }),
            ),
          ]),
          buildTextArea("Space name", e.nameCtrl, maxLines: 1),
          buildDropdown("Space type",
            ["Indoor","Outdoor","Poolside","Terrace","Garden","Ballroom","Rooftop","Waterfront"],
            e.type, (v) => setState(() => e.type = v)),
          buildDropdown("Indoor / Outdoor",
            ["Indoor","Outdoor","Hybrid"],
            e.indoorOutdoor, (v) => setState(() => e.indoorOutdoor = v)),
          buildTextArea("Seating capacity", e.seatingCtrl, maxLines: 1),
          buildTextArea("Floating capacity", e.floatingCtrl, maxLines: 1),
          buildYesNo("AC availability", e.ac, (v) => setState(() => e.ac = v)),
          buildYesNo("Dedicated kitchen", e.dedicatedKitchen,
              (v) => setState(() => e.dedicatedKitchen = v)),
          buildYesNo("Attached rooms", e.attachedRooms,
              (v) => setState(() => e.attachedRooms = v)),
          buildTextArea("Notes", e.notesCtrl, maxLines: 2),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Venue master profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured venue attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Identity ────────────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _vs1,
            () => setState(() => _vs1 = !_vs1)),
        if (_vs1) ...[
          const SizedBox(height: 16),
          buildDropdown("Property ownership type",
            ["Owned","Leased","Managed Property","Franchise"],
            _vPropertyOwnership, (v) => setState(() => _vPropertyOwnership = v)),
          buildNumberField("Years of operation", _vYearsOperationCtrl),
          buildDropdown("Location type",
            ["Central City","Suburban","Highway","Remote / Destination"],
            _vLocationType, (v) => setState(() => _vLocationType = v)),
          buildTextArea("Exact location / address", _vExactLocationCtrl, maxLines: 2),
          buildYesNo("Property belongs to a chain", _vChainProperty,
              (v) => setState(() => _vChainProperty = v)),
          if (_vChainProperty == 'Yes') ...[
            buildTextArea("Brand name", _vChainBrandNameCtrl, maxLines: 1),
            buildDropdown("Brand category",
              ["Luxury","Premium","Mid-Range","Budget"],
              _vChainBrandCategory, (v) => setState(() => _vChainBrandCategory = v)),
          ],
        ],
        dividerLine(),

        // ── Categories ─────────────────────────────────────────────────────
        sectionHeader("Venue category mapping", _vs2,
            () => setState(() => _vs2 = !_vs2)),
        if (_vs2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Premium & experience-based",
            ["Palace Wedding Venue","Heritage Property","Fort / Haveli Venue",
             "Luxury Resort Venue","Island / Private Property Venue","Vineyard / Winery Venue","Golf Course Venue"],
            _vCatPremium,
            (o, c) => setState(() => c ? _vCatPremium.add(o) : _vCatPremium.remove(o))),
          buildMultiSelect("Location-based",
            ["Beach Wedding Venue","Mountain / Hilltop Venue","Lake View Venue",
             "Riverside Venue","Forest / Nature Venue","Highway Venue","City Center Venue","Suburban Venue"],
            _vCatLocation,
            (o, c) => setState(() => c ? _vCatLocation.add(o) : _vCatLocation.remove(o))),
          buildMultiSelect("Capacity-based",
            ["Intimate Wedding Venues (0–100)","Mid-Size Wedding Venues (100–300)",
             "Large Wedding Venues (300–500)","Mega Wedding Venues (500–1000)","Ultra Large Wedding Venues (1000+)"],
            _vCatCapacity,
            (o, c) => setState(() => c ? _vCatCapacity.add(o) : _vCatCapacity.remove(o))),
          buildMultiSelect("Budget-based",
            ["Budget Wedding Venues","Mid-Range Wedding Venues","Premium Wedding Venues","Luxury Wedding Venues"],
            _vCatBudget,
            (o, c) => setState(() => c ? _vCatBudget.add(o) : _vCatBudget.remove(o))),
          buildMultiSelect("Function-specific",
            ["Haldi Venues","Mehendi Venues","Sangeet Venues","Engagement Venues",
             "Reception Venues","Cocktail Party Venues","Corporate Event Venues","Birthday / Private Party Venues"],
            _vCatFunction,
            (o, c) => setState(() => c ? _vCatFunction.add(o) : _vCatFunction.remove(o))),
          buildMultiSelect("Facility-based",
            ["Venues with Rooms","Venues with Large Parking","Venues with Poolside Setup",
             "Venues with In-house Catering","Pure Veg Venues","Venues Allowing Alcohol",
             "Venues with Outdoor Space","Venues with Indoor + Outdoor Combo"],
            _vCatFacility,
            (o, c) => setState(() => c ? _vCatFacility.add(o) : _vCatFacility.remove(o))),
          buildMultiSelect("Booking & usage flexibility",
            ["One-Day Wedding Venues","Multi-Day Wedding Venues","Exclusive Property Booking Venues","Shared Venue Spaces"],
            _vCatBooking,
            (o, c) => setState(() => c ? _vCatBooking.add(o) : _vCatBooking.remove(o))),
          buildMultiSelect("Trend & modern formats",
            ["Pre-Wedding Shoot Venues","Instagrammable Venues","Minimalist Wedding Venues",
             "Theme Wedding Venues","Eco-Friendly / Sustainable Venues","Glamping / Tent Wedding Venues"],
            _vCatTrend,
            (o, c) => setState(() => c ? _vCatTrend.add(o) : _vCatTrend.remove(o))),
        ],
        dividerLine(),

        // ── Section 2: Space & Capacity ────────────────────────────────────
        sectionHeader("Section 2 — Space & capacity", _vs3,
            () => setState(() => _vs3 = !_vs3)),
        if (_vs3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Space types available",
            ["Indoor","Outdoor","Poolside","Terrace","Garden","Ballroom","Rooftop","Waterfront","Amphitheatre","Courtyard"],
            _vSpaceTypes,
            (o, c) => setState(() => c ? _vSpaceTypes.add(o) : _vSpaceTypes.remove(o))),
          buildNumberField("Number of distinct event spaces", _vNumEventSpacesCtrl),
          buildNumberField("Indoor spaces count", _vIndoorSpacesCountCtrl),
          buildNumberField("Outdoor spaces count", _vOutdoorSpacesCountCtrl),
          buildNumberField("Indoor seating capacity", _vIndoorSeatingCtrl),
          buildNumberField("Indoor floating capacity", _vIndoorFloatingCtrl),
          buildNumberField("Outdoor seating capacity", _vOutdoorSeatingCtrl),
          buildNumberField("Outdoor floating capacity", _vOutdoorFloatingCtrl),
          buildNumberField("Minimum guest requirement", _vMinGuestsCtrl),
          buildNumberField("Maximum guest capacity", _vMaxGuestsCtrl),
          buildYesNo("Separate function areas available", _vSeparateFunctionAreas,
              (v) => setState(() => _vSeparateFunctionAreas = v)),
          buildYesNo("Can host multiple events simultaneously", _vMultipleEventsSimultaneous,
              (v) => setState(() => _vMultipleEventsSimultaneous = v)),
          buildYesNo("Exclusive venue booking available", _vExclusiveBooking,
              (v) => setState(() => _vExclusiveBooking = v)),
          fieldLabel("Space-wise configuration"),
          ..._vSpaces.asMap().entries.map((e) => _buildSpaceItem(e.key)),
          TextButton.icon(
            onPressed: () => setState(() => _vSpaces.add(VenueSpaceEntry())),
            icon: const Icon(Icons.add),
            label: const Text("Add Space"),
          ),
          const SizedBox(height: 8),
        ],
        dividerLine(),

        // ── Section 3: Rooms ───────────────────────────────────────────────
        sectionHeader("Section 3 — Rooms & accommodation", _vs4,
            () => setState(() => _vs4 = !_vs4)),
        if (_vs4) ...[
          const SizedBox(height: 16),
          buildNumberField("Number of rooms", _vNumRoomsCtrl),
          fieldLabel("Room types (select & enter count)"),
          ..._vRoomTypeCounts.keys.map((type) {
            final sel = _vRoomTypes.contains(type);
            return Row(children: [
              Checkbox(
                value: sel,
                onChanged: (v) => setState(
                    () => v == true ? _vRoomTypes.add(type) : _vRoomTypes.remove(type)),
                activeColor: FacilitiesHelpersMixin.kAccentBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 100) * 0.5,
                child: Text(type, style: const TextStyle(fontSize: 12)),
              ),
              if (sel)
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _vRoomTypeCounts[type],
                    keyboardType: TextInputType.number,
                    decoration: inputDec().copyWith(hintText: "Count"),
                  ),
                ),
            ]);
          }),
          const SizedBox(height: 18),
          buildNumberField("Max occupancy per room", _vMaxOccupancyCtrl),
          buildYesNo("Extra bed available", _vExtraBed,
              (v) => setState(() => _vExtraBed = v)),
          buildDropdown("Room price range",
            ["Below ₹3000","₹3000–₹5000","₹5000–₹8000","₹8000–₹12000","₹12000+"],
            _vRoomPriceRange, (v) => setState(() => _vRoomPriceRange = v)),
          buildNumberField("Complimentary rooms", _vComplimentaryRoomsCtrl),
          buildNumberField("Total stay capacity", _vTotalStayCapacityCtrl),
        ],
        dividerLine(),

        // ── Section 4: Food ────────────────────────────────────────────────
        sectionHeader("Section 4 — Food & catering", _vs5,
            () => setState(() => _vs5 = !_vs5)),
        if (_vs5) ...[
          const SizedBox(height: 16),
          buildDropdown("Catering policy",
            ["In-house Only","Outside Allowed","Both"],
            _vCateringPolicy, (v) => setState(() => _vCateringPolicy = v)),
          buildMultiSelect("Cuisine options",
            ["North Indian","South Indian","Jain","Gujarati","Rajasthani","Continental",
             "Chinese","Italian","Mexican","Thai","Mediterranean","Vegan","Live Counters","Fusion"],
            _vCuisines,
            (o, c) => setState(() => c ? _vCuisines.add(o) : _vCuisines.remove(o))),
          buildDropdown("Veg / Non-Veg",
            ["Pure Veg","Veg + Non-Veg"],
            _vVegNonVeg, (v) => setState(() => _vVegNonVeg = v)),
          buildYesNo("Jain food available", _vJainFood,
              (v) => setState(() => _vJainFood = v)),
          buildDropdown("Per plate cost range",
            ["Below ₹500","₹500–₹1000","₹1000–₹1500","₹1500–₹2500","₹2500–₹4000","₹4000+"],
            _vPerPlateCostRange, (v) => setState(() => _vPerPlateCostRange = v)),
          buildDropdown("Outside catering charges",
            ["Free","₹0–₹25K","₹25K–₹50K","₹50K+","Not Allowed"],
            _vOutsideCateringCharges,
            (v) => setState(() => _vOutsideCateringCharges = v)),
          buildYesNo("Kitchen available for external caterers", _vKitchenForExternal,
              (v) => setState(() => _vKitchenForExternal = v)),
        ],
        dividerLine(),

        // ── Section 5: Alcohol ─────────────────────────────────────────────
        sectionHeader("Section 5 — Alcohol policy", _vs6,
            () => setState(() => _vs6 = !_vs6)),
        if (_vs6) ...[
          const SizedBox(height: 16),
          buildDropdown("Alcohol policy",
            ["Not Allowed","Allowed with License","In-house Only","Outside Allowed","Both"],
            _vAlcoholPolicy, (v) => setState(() => _vAlcoholPolicy = v)),
          buildDropdown("Corkage charges",
            ["No","₹0–₹10K","₹10K–₹25K","₹25K+","Add from Vendor"],
            _vCorkage, (v) => setState(() => _vCorkage = v)),
          buildMultiSelect("Bar setup",
            ["Not Available","Basic","Premium","Custom","Add from Vendor"],
            _vBarSetup,
            (o, c) => setState(() => c ? _vBarSetup.add(o) : _vBarSetup.remove(o))),
        ],
        dividerLine(),

        // ── Section 6: Decor ───────────────────────────────────────────────
        sectionHeader("Section 6 — Decor & production", _vs7,
            () => setState(() => _vs7 = !_vs7)),
        if (_vs7) ...[
          const SizedBox(height: 16),
          buildDropdown("Decor policy",
            ["In-house Only","Panel Only","Outside Allowed","Both"],
            _vDecorPolicy, (v) => setState(() => _vDecorPolicy = v)),
          buildMultiSelect("Decor capabilities",
            ["Floral Decor","Theme Decor","Luxury Installations","LED Walls",
             "Entry Concepts","Stage Concepts","Mandap Design"],
            _vDecorCapabilities,
            (o, c) => setState(() => c ? _vDecorCapabilities.add(o) : _vDecorCapabilities.remove(o))),
          buildMultiSelect("Stage setup",
            ["Not Available","Basic","Premium","Custom","Add from Vendor"],
            _vStageSetup,
            (o, c) => setState(() => c ? _vStageSetup.add(o) : _vStageSetup.remove(o))),
          buildMultiSelect("Mandap setup",
            ["Not Available","Basic","Premium","Custom","Add from Vendor"],
            _vMandapSetup,
            (o, c) => setState(() => c ? _vMandapSetup.add(o) : _vMandapSetup.remove(o))),
          buildMultiSelect("Lighting setup",
            ["Basic","Advanced","Premium","Custom","Add from Vendor"],
            _vDecorLighting,
            (o, c) => setState(() => c ? _vDecorLighting.add(o) : _vDecorLighting.remove(o))),
          buildMultiSelect("Sound system",
            ["Not Available","Basic","Professional","Add from Vendor"],
            _vSoundSystem,
            (o, c) => setState(() => c ? _vSoundSystem.add(o) : _vSoundSystem.remove(o))),
          buildDropdown("Outside decor charges",
            ["Free","₹0–₹25K","₹25K–₹50K","₹50K+","Not Allowed"],
            _vOutsideDecorCharges, (v) => setState(() => _vOutsideDecorCharges = v)),
        ],
        dividerLine(),

        // ── Section 7: Entertainment ───────────────────────────────────────
        sectionHeader("Section 7 — Entertainment & DJ", _vs8,
            () => setState(() => _vs8 = !_vs8)),
        if (_vs8) ...[
          const SizedBox(height: 16),
          buildDropdown("DJ policy",
            ["In-house Only","Outside Allowed","Both"],
            _vDjPolicy, (v) => setState(() => _vDjPolicy = v)),
          buildDropdown("Noise restrictions",
            ["No Restriction","Till 10 PM","Till 12 AM","As per Government Rules"],
            _vNoiseRestrictions, (v) => setState(() => _vNoiseRestrictions = v)),
          buildYesNo("Live band allowed", _vLiveBand,
              (v) => setState(() => _vLiveBand = v)),
          buildDropdown("Fireworks allowed",
            ["Yes","No","With Permission"],
            _vFireworks, (v) => setState(() => _vFireworks = v)),
          buildMultiSelect("Entertainment supported",
            ["DJ","Live Band","Dhol","Celebrity Performance","Anchors / Hosts","Fireworks","Baraat Entry Concepts"],
            _vEntertainmentSupported,
            (o, c) => setState(() => c ? _vEntertainmentSupported.add(o) : _vEntertainmentSupported.remove(o))),
        ],
        dividerLine(),

        // ── Section 8: Facilities ──────────────────────────────────────────
        sectionHeader("Section 8 — Facilities", _vs9,
            () => setState(() => _vs9 = !_vs9)),
        if (_vs9) ...[
          const SizedBox(height: 16),
          buildYesNo("Parking available", _vParkingAvailable,
              (v) => setState(() => _vParkingAvailable = v)),
          buildNumberField("Parking capacity", _vParkingCapacityCtrl),
          buildYesNo("Valet parking", _vValetParking,
              (v) => setState(() => _vValetParking = v)),
          buildMultiSelect("Power backup",
            ["Full","Partial","None","Only Venue. Does not cover Decor."],
            _vPowerBackup,
            (o, c) => setState(() => c ? _vPowerBackup.add(o) : _vPowerBackup.remove(o))),
          buildDropdown("Air conditioning",
            ["Full Venue","Partial","None"],
            _vAirConditioning, (v) => setState(() => _vAirConditioning = v)),
          buildYesNo("Bridal room", _vBridalRoom,
              (v) => setState(() => _vBridalRoom = v)),
          buildYesNo("Groom room", _vGroomRoom,
              (v) => setState(() => _vGroomRoom = v)),
          buildYesNo("Wheelchair accessibility", _vWheelchairAccess,
              (v) => setState(() => _vWheelchairAccess = v)),
          buildDropdown("Washroom quality",
            ["Basic","Premium","Luxury"],
            _vWashroomQuality, (v) => setState(() => _vWashroomQuality = v)),
          buildYesNo("Lift access", _vLiftAccess,
              (v) => setState(() => _vLiftAccess = v)),
          buildDropdown("Security services",
            ["Not Available","Basic","Professional"],
            _vSecurity, (v) => setState(() => _vSecurity = v)),
          buildMultiSelect("Additional facilities",
            ["Swimming Pool","Spa","Gym","Kids Play Area","Helipad","Golf Course","Private Beach","Lake View","Mountain View"],
            _vAdditionalFacilities,
            (o, c) => setState(() => c ? _vAdditionalFacilities.add(o) : _vAdditionalFacilities.remove(o))),
        ],
        dividerLine(),

        // ── Section 9: Pricing & Booking ───────────────────────────────────
        sectionHeader("Section 9 — Pricing & booking", _vs10,
            () => setState(() => _vs10 = !_vs10)),
        if (_vs10) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Pricing model",
            ["Per Plate","Per Day Rental","Per Function","Per Hour","Package Based","Dynamic Pricing"],
            _vPricingModel,
            (o, c) => setState(() => c ? _vPricingModel.add(o) : _vPricingModel.remove(o))),
          buildNumberField("Starting venue price", _vStartingVenuePriceCtrl),
          buildYesNo("Peak season pricing", _vPeakSeasonPricing,
              (v) => setState(() => _vPeakSeasonPricing = v)),
          buildYesNo("Advance booking required", _vAdvanceBookingRequired,
              (v) => setState(() => _vAdvanceBookingRequired = v)),
          buildDropdown("Advance payment range",
            ["0–25%","25–50%","50–75%","75–100%"],
            _vAdvancePaymentRange, (v) => setState(() => _vAdvancePaymentRange = v)),
          buildMultiSelect("Minimum booking duration",
            ["2 Hours","4 Hours","6 Hours","Full Day","Shift Wise","Multiple Days"],
            _vMinBookingDuration,
            (o, c) => setState(() => c ? _vMinBookingDuration.add(o) : _vMinBookingDuration.remove(o))),
          buildDropdown("Cancellation policy",
            ["Non Refundable","Partial Refund","Flexible"],
            _vCancellationPolicy, (v) => setState(() => _vCancellationPolicy = v)),
          buildDropdown("Refund timeline",
            ["0–7 Days","7–15 Days","15–30 Days","30+ Days"],
            _vRefundTimeline, (v) => setState(() => _vRefundTimeline = v)),
        ],
        dividerLine(),

        // ── Section 10: Event Suitability ──────────────────────────────────
        sectionHeader("Section 10 — Event suitability", _vs11,
            () => setState(() => _vs11 = !_vs11)),
        if (_vs11) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Suitable for",
            ["Wedding","Reception","Haldi","Mehendi","Sangeet","Engagement","Cocktail",
             "Corporate Events","Birthday / Private Events"],
            _vSuitableFor,
            (o, c) => setState(() => c ? _vSuitableFor.add(o) : _vSuitableFor.remove(o))),
          buildMultiSelect("Best for",
            ["Budget Weddings","Mid-Range Weddings","Luxury Weddings","Destination Weddings","Intimate Weddings","Large Weddings"],
            _vBestFor,
            (o, c) => setState(() => c ? _vBestFor.add(o) : _vBestFor.remove(o))),
          buildMultiSelect("Ideal guest range",
            ["0–100","100–300","300–500","500–1000","1000+"],
            _vIdealGuestRange,
            (o, c) => setState(() => c ? _vIdealGuestRange.add(o) : _vIdealGuestRange.remove(o))),
        ],
      ],
    );
  }
}
