import 'package:flutter/material.dart';
import 'facilities_helpers.dart';

class CatererFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const CatererFacilities({super.key, required this.attributes});

  @override
  State<CatererFacilities> createState() => CatererFacilitiesState();
}

class CatererFacilitiesState extends State<CatererFacilities>
    with FacilitiesHelpersMixin<CatererFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  final        _brandNameCtrl      = TextEditingController();
  String?      _catererType;
  final        _yearsExpCtrl       = TextEditingController();
  String?      _serviceCoverage;
  String?      _teamSize;
  List<String> _serviceLocations   = [];

  // ── service_type ──────────────────────────────────────────────────────────
  List<String> _cateringStyle          = [];
  List<String> _eventTypesCovered      = [];
  String?      _vegNonVeg;
  String?      _jainFood;
  List<String> _specialDietaryOptions  = [];

  // ── cuisine_intelligence ──────────────────────────────────────────────────
  List<String> _cuisineTypes       = [];
  final        _signatureDishesCtrl = TextEditingController();
  List<String> _bestKnownFor       = [];

  // ── menu_customization ────────────────────────────────────────────────────
  String?      _customMenuAvailable;
  String?      _menuTastingAvailable;
  String?      _tastingCharges;
  String?      _menuItemsOffered;
  String?      _liveCountersAvailable;
  List<String> _popularLiveCounters = [];

  // ── scale_execution ───────────────────────────────────────────────────────
  final        _minimumPaxCtrl     = TextEditingController();
  String?      _maximumPax;
  String?      _eventsPerDay;
  String?      _multipleEventHandling;

  // ── pricing_structure ─────────────────────────────────────────────────────
  final        _perPlateStartingPriceCtrl = TextEditingController();
  String?      _priceRange;
  String?      _pricingType;
  List<String> _extraCharges       = [];

  // ── infrastructure_equipment ──────────────────────────────────────────────
  String?      _kitchenSetup;
  String?      _servingStaffIncluded;
  String?      _servingStyle;
  String?      _utensilsCrockery;
  String?      _ecoFriendlyOptions;

  // ── hygiene_quality ───────────────────────────────────────────────────────
  List<String> _hygieneStandards       = [];
  String?      _foodQualityAssurance;

  // ── venue_logistics ───────────────────────────────────────────────────────
  String?      _outdoorCateringSupported;
  String?      _destinationWeddingsSupported;
  String?      _travelCharges;
  String?      _stayRequirement;

  // ── event_suitability ─────────────────────────────────────────────────────
  List<String> _functionsSuitableFor = [];
  List<String> _bestFor              = [];

  // ── workflow_booking ──────────────────────────────────────────────────────
  String?      _advanceRequired;
  String?      _advancePercentage;
  String?      _bookingTimeline;
  String?      _cancellationPolicy;
  String?      _refundTimeline;

  // ── menu_event_tagging ────────────────────────────────────────────────────
  final        _tagsCtrl  = TextEditingController();
  final        _notesCtrl = TextEditingController();

  // ── section expansion ─────────────────────────────────────────────────────
  bool _cs1  = true;
  bool _cs2  = false;
  bool _cs3  = false;
  bool _cs4  = false;
  bool _cs5  = false;
  bool _cs6  = false;
  bool _cs7  = false;
  bool _cs8  = false;
  bool _cs9  = false;
  bool _cs10 = false;
  bool _cs11 = false;
  bool _cs12 = false;

  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _brandNameCtrl.dispose();
    _yearsExpCtrl.dispose();
    _signatureDishesCtrl.dispose();
    _minimumPaxCtrl.dispose();
    _perPlateStartingPriceCtrl.dispose();
    _tagsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final cm = asMap(attrs['caterer_master']);

    final id = asMap(cm['identity']);
    _brandNameCtrl.text  = id['brand_name']?.toString() ?? '';
    _catererType         = id['caterer_type'] as String?;
    _yearsExpCtrl.text   = id['years_experience']?.toString() ?? '';
    _serviceCoverage     = id['service_coverage'] as String?;
    _teamSize            = id['team_size'] as String?;
    _serviceLocations    = toList(id['service_locations']);

    final st = asMap(cm['service_type']);
    _cateringStyle         = toList(st['catering_style']);
    _eventTypesCovered     = toList(st['event_types_covered']);
    _vegNonVeg             = st['veg_non_veg'] as String?;
    _jainFood              = st['jain_food'] as String?;
    _specialDietaryOptions = toList(st['special_dietary_options']);

    final ci = asMap(cm['cuisine_intelligence']);
    _cuisineTypes          = toList(ci['cuisine_types']);
    _signatureDishesCtrl.text = ci['signature_dishes']?.toString() == 'na'
        ? '' : ci['signature_dishes']?.toString() ?? '';
    _bestKnownFor          = toList(ci['best_known_for']);

    final mc = asMap(cm['menu_customization']);
    _customMenuAvailable   = mc['custom_menu_available'] as String?;
    _menuTastingAvailable  = mc['menu_tasting_available'] as String?;
    _tastingCharges        = mc['tasting_charges'] as String?;
    _menuItemsOffered      = mc['menu_items_offered'] as String?;
    _liveCountersAvailable = mc['live_counters_available'] as String?;
    _popularLiveCounters   = toList(mc['popular_live_counters']);

    final se = asMap(cm['scale_execution']);
    _minimumPaxCtrl.text    = se['minimum_pax']?.toString() ?? '';
    _maximumPax             = se['maximum_pax'] as String?;
    _eventsPerDay           = se['events_per_day'] as String?;
    _multipleEventHandling  = se['multiple_event_handling'] as String?;

    final ps = asMap(cm['pricing_structure']);
    _perPlateStartingPriceCtrl.text = ps['per_plate_starting_price']?.toString() ?? '';
    _priceRange    = ps['price_range'] as String?;
    _pricingType   = ps['pricing_type'] as String?;
    _extraCharges  = toList(ps['extra_charges']);

    final ie = asMap(cm['infrastructure_equipment']);
    _kitchenSetup         = ie['kitchen_setup'] as String?;
    _servingStaffIncluded = ie['serving_staff_included'] as String?;
    _servingStyle         = ie['serving_style'] as String?;
    _utensilsCrockery     = ie['utensils_crockery'] as String?;
    _ecoFriendlyOptions   = ie['eco_friendly_options'] as String?;

    final hq = asMap(cm['hygiene_quality']);
    _hygieneStandards     = toList(hq['hygiene_standards']);
    _foodQualityAssurance = hq['food_quality_assurance'] as String?;

    final vl = asMap(cm['venue_logistics']);
    _outdoorCateringSupported      = vl['outdoor_catering_supported'] as String?;
    _destinationWeddingsSupported  = vl['destination_weddings_supported'] as String?;
    _travelCharges                 = vl['travel_charges'] as String?;
    _stayRequirement               = vl['stay_requirement'] as String?;

    final ev = asMap(cm['event_suitability']);
    _functionsSuitableFor = toList(ev['functions_suitable_for']);
    _bestFor              = toList(ev['best_for']);

    final wb = asMap(cm['workflow_booking']);
    _advanceRequired    = wb['advance_required'] as String?;
    _advancePercentage  = wb['advance_percentage'] as String?;
    _bookingTimeline    = wb['booking_timeline'] as String?;
    _cancellationPolicy = wb['cancellation_policy'] as String?;
    _refundTimeline     = wb['refund_timeline'] as String?;

    final mt = asMap(cm['menu_event_tagging']);
    _tagsCtrl.text  = mt['tags']?.toString() == 'na' ? '' : mt['tags']?.toString() ?? '';
    _notesCtrl.text = mt['notes']?.toString() == 'na' ? '' : mt['notes']?.toString() ?? '';
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "brand_name":        _brandNameCtrl.text,
        "caterer_type":      _catererType,
        "years_experience":  _yearsExpCtrl.text,
        "service_coverage":  _serviceCoverage,
        "team_size":         _teamSize,
        "service_locations": _serviceLocations,
      },
      "service_type": {
        ...asMap(ex["service_type"]),
        "catering_style":          _cateringStyle,
        "event_types_covered":     _eventTypesCovered,
        "veg_non_veg":             _vegNonVeg,
        "jain_food":               _jainFood,
        "special_dietary_options": _specialDietaryOptions,
      },
      "cuisine_intelligence": {
        ...asMap(ex["cuisine_intelligence"]),
        "cuisine_types":    _cuisineTypes,
        "signature_dishes": _signatureDishesCtrl.text,
        "best_known_for":   _bestKnownFor,
      },
      "menu_customization": {
        ...asMap(ex["menu_customization"]),
        "custom_menu_available":   _customMenuAvailable,
        "menu_tasting_available":  _menuTastingAvailable,
        "tasting_charges":         _tastingCharges,
        "menu_items_offered":      _menuItemsOffered,
        "live_counters_available": _liveCountersAvailable,
        "popular_live_counters":   _popularLiveCounters,
      },
      "scale_execution": {
        ...asMap(ex["scale_execution"]),
        "minimum_pax":             _minimumPaxCtrl.text,
        "maximum_pax":             _maximumPax,
        "events_per_day":          _eventsPerDay,
        "multiple_event_handling": _multipleEventHandling,
      },
      "pricing_structure": {
        ...asMap(ex["pricing_structure"]),
        "per_plate_starting_price": _perPlateStartingPriceCtrl.text,
        "price_range":              _priceRange,
        "pricing_type":             _pricingType,
        "extra_charges":            _extraCharges,
      },
      "infrastructure_equipment": {
        ...asMap(ex["infrastructure_equipment"]),
        "kitchen_setup":          _kitchenSetup,
        "serving_staff_included": _servingStaffIncluded,
        "serving_style":          _servingStyle,
        "utensils_crockery":      _utensilsCrockery,
        "eco_friendly_options":   _ecoFriendlyOptions,
      },
      "hygiene_quality": {
        ...asMap(ex["hygiene_quality"]),
        "hygiene_standards":      _hygieneStandards,
        "food_quality_assurance": _foodQualityAssurance,
      },
      "venue_logistics": {
        ...asMap(ex["venue_logistics"]),
        "outdoor_catering_supported":     _outdoorCateringSupported,
        "destination_weddings_supported": _destinationWeddingsSupported,
        "travel_charges":                 _travelCharges,
        "stay_requirement":               _stayRequirement,
      },
      "event_suitability": {
        ...asMap(ex["event_suitability"]),
        "functions_suitable_for": _functionsSuitableFor,
        "best_for":               _bestFor,
      },
      "workflow_booking": {
        ...asMap(ex["workflow_booking"]),
        "advance_required":    _advanceRequired,
        "advance_percentage":  _advancePercentage,
        "booking_timeline":    _bookingTimeline,
        "cancellation_policy": _cancellationPolicy,
        "refund_timeline":     _refundTimeline,
      },
      "menu_event_tagging": {
        ...asMap(ex["menu_event_tagging"]),
        "tags":  _tagsCtrl.text,
        "notes": _notesCtrl.text,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Caterer Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured catering attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _cs1,
            () => setState(() => _cs1 = !_cs1)),
        if (_cs1) ...[
          const SizedBox(height: 16),
          buildTextArea("Brand / Catering Company Name", _brandNameCtrl, maxLines: 1),
          buildDropdown("Caterer Type",
            ["Individual Caterer", "Catering Company",
             "Luxury Catering Specialist", "Cloud Kitchen Caterer"],
            _catererType, (v) => setState(() => _catererType = v)),
          buildNumberField("Years of Experience", _yearsExpCtrl),
          buildDropdown("Service Coverage",
            ["Local Only", "Pan India", "International"],
            _serviceCoverage, (v) => setState(() => _serviceCoverage = v)),
          buildDropdown("Team Size",
            ["1–10", "10–30", "30–100", "100+"],
            _teamSize, (v) => setState(() => _teamSize = v)),
          buildMultiSelect("Service Locations",
            ["All Over India", "Western India", "Northern India",
             "Southern India", "Eastern India"],
            _serviceLocations,
            (o, c) => setState(() => c ? _serviceLocations.add(o) : _serviceLocations.remove(o))),
        ],
        dividerLine(),

        // ── Section 2: Service Type ────────────────────────────────────────
        sectionHeader("Section 2 — Service type", _cs2,
            () => setState(() => _cs2 = !_cs2)),
        if (_cs2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Catering Style",
            ["Buffet", "Plated Service", "Live Counters",
             "Food Stalls", "Fine Dining", "Traditional Service (Pangat)"],
            _cateringStyle,
            (o, c) => setState(() => c ? _cateringStyle.add(o) : _cateringStyle.remove(o))),
          buildMultiSelect("Event Types Covered",
            ["Breakfast", "Lunch", "Dinner", "Hi-Tea", "Cocktail"],
            _eventTypesCovered,
            (o, c) => setState(() => c ? _eventTypesCovered.add(o) : _eventTypesCovered.remove(o))),
          buildDropdown("Veg / Non-Veg",
            ["Pure Veg", "Veg + Non-Veg"],
            _vegNonVeg, (v) => setState(() => _vegNonVeg = v)),
          buildDropdown("Jain Food Available",
            ["Yes", "No"],
            _jainFood, (v) => setState(() => _jainFood = v)),
          buildMultiSelect("Special Dietary Options",
            ["Vegan", "Gluten-Free", "Satvik", "Jain"],
            _specialDietaryOptions,
            (o, c) => setState(() => c ? _specialDietaryOptions.add(o) : _specialDietaryOptions.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Cuisine Intelligence ───────────────────────────────
        sectionHeader("Section 3 — Cuisine intelligence", _cs3,
            () => setState(() => _cs3 = !_cs3)),
        if (_cs3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Cuisine Types",
            ["North Indian", "South Indian", "Maharashtrian", "Gujarati",
             "Rajasthani", "Punjabi", "Continental", "Italian",
             "Chinese", "Thai", "Mexican", "Street Food", "Fusion"],
            _cuisineTypes,
            (o, c) => setState(() => c ? _cuisineTypes.add(o) : _cuisineTypes.remove(o))),
          buildTextArea("Signature Dishes", _signatureDishesCtrl, maxLines: 3),
          buildMultiSelect("Best Known For",
            ["Taste", "Presentation", "Live Counters",
             "Variety", "Budget Catering", "Luxury Catering"],
            _bestKnownFor,
            (o, c) => setState(() => c ? _bestKnownFor.add(o) : _bestKnownFor.remove(o))),
        ],
        dividerLine(),

        // ── Section 4: Menu & Customization ───────────────────────────────
        sectionHeader("Section 4 — Menu & customization", _cs4,
            () => setState(() => _cs4 = !_cs4)),
        if (_cs4) ...[
          const SizedBox(height: 16),
          buildDropdown("Custom Menu Available",
            ["Yes", "No"],
            _customMenuAvailable, (v) => setState(() => _customMenuAvailable = v)),
          buildDropdown("Menu Tasting Available",
            ["Yes", "No"],
            _menuTastingAvailable, (v) => setState(() => _menuTastingAvailable = v)),
          buildDropdown("Tasting Charges",
            ["Free", "Paid", "Adjustable"],
            _tastingCharges, (v) => setState(() => _tastingCharges = v)),
          buildDropdown("Number of Menu Items Offered",
            ["10–20", "20–40", "40–60", "60+"],
            _menuItemsOffered, (v) => setState(() => _menuItemsOffered = v)),
          buildDropdown("Live Counters Available",
            ["Yes", "No"],
            _liveCountersAvailable, (v) => setState(() => _liveCountersAvailable = v)),
          if (_liveCountersAvailable == "Yes")
            buildMultiSelect("Popular Live Counters",
              ["Chaat", "Pasta", "Pizza", "Dosa",
               "Chinese", "Mocktails", "Desserts"],
              _popularLiveCounters,
              (o, c) => setState(() => c ? _popularLiveCounters.add(o) : _popularLiveCounters.remove(o))),
        ],
        dividerLine(),

        // ── Section 5: Scale & Execution Capability ───────────────────────
        sectionHeader("Section 5 — Scale & execution", _cs5,
            () => setState(() => _cs5 = !_cs5)),
        if (_cs5) ...[
          const SizedBox(height: 16),
          buildNumberField("Minimum Pax", _minimumPaxCtrl),
          buildDropdown("Maximum Pax",
            ["0–100", "100–300", "300–500", "500–1000", "1000+"],
            _maximumPax, (v) => setState(() => _maximumPax = v)),
          buildDropdown("Events Handled Per Day",
            ["1", "2–3", "3+"],
            _eventsPerDay, (v) => setState(() => _eventsPerDay = v)),
          buildDropdown("Multiple Event Handling",
            ["Yes", "No"],
            _multipleEventHandling, (v) => setState(() => _multipleEventHandling = v)),
        ],
        dividerLine(),

        // ── Section 6: Pricing Structure ──────────────────────────────────
        sectionHeader("Section 6 — Pricing structure", _cs6,
            () => setState(() => _cs6 = !_cs6)),
        if (_cs6) ...[
          const SizedBox(height: 16),
          buildNumberField("Per Plate Starting Price (₹)", _perPlateStartingPriceCtrl),
          buildDropdown("Price Range",
            ["Below ₹500", "₹500–₹1000", "₹1000–₹1500", "₹1500–₹2500", "₹2500+"],
            _priceRange, (v) => setState(() => _priceRange = v)),
          buildDropdown("Pricing Type",
            ["Per Plate", "Package Based", "Custom Quote"],
            _pricingType, (v) => setState(() => _pricingType = v)),
          buildMultiSelect("Extra Charges",
            ["Service Charges", "GST", "Setup Charges", "Staff Charges"],
            _extraCharges,
            (o, c) => setState(() => c ? _extraCharges.add(o) : _extraCharges.remove(o))),
        ],
        dividerLine(),

        // ── Section 7: Infrastructure & Equipment ─────────────────────────
        sectionHeader("Section 7 — Infrastructure & equipment", _cs7,
            () => setState(() => _cs7 = !_cs7)),
        if (_cs7) ...[
          const SizedBox(height: 16),
          buildDropdown("Kitchen Setup",
            ["In-House Kitchen", "On-Site Setup", "Both"],
            _kitchenSetup, (v) => setState(() => _kitchenSetup = v)),
          buildDropdown("Serving Staff Included",
            ["Yes", "No"],
            _servingStaffIncluded, (v) => setState(() => _servingStaffIncluded = v)),
          buildDropdown("Serving Style",
            ["Uniformed Staff", "Traditional Dress", "Custom Dress"],
            _servingStyle, (v) => setState(() => _servingStyle = v)),
          buildDropdown("Utensils & Crockery",
            ["Included", "Extra"],
            _utensilsCrockery, (v) => setState(() => _utensilsCrockery = v)),
          buildDropdown("Disposable / Eco-Friendly Options",
            ["Yes", "No"],
            _ecoFriendlyOptions, (v) => setState(() => _ecoFriendlyOptions = v)),
        ],
        dividerLine(),

        // ── Section 8: Hygiene & Quality Control ──────────────────────────
        sectionHeader("Section 8 — Hygiene & quality control", _cs8,
            () => setState(() => _cs8 = !_cs8)),
        if (_cs8) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Hygiene Standards",
            ["Gloves & Caps", "Sanitized Kitchen",
             "Food Safety Certified", "FSSAI Licensed"],
            _hygieneStandards,
            (o, c) => setState(() => c ? _hygieneStandards.add(o) : _hygieneStandards.remove(o))),
          buildDropdown("Food Quality Assurance",
            ["High", "Premium", "Luxury"],
            _foodQualityAssurance, (v) => setState(() => _foodQualityAssurance = v)),
        ],
        dividerLine(),

        // ── Section 9: Venue & Logistics Compatibility ────────────────────
        sectionHeader("Section 9 — Venue & logistics", _cs9,
            () => setState(() => _cs9 = !_cs9)),
        if (_cs9) ...[
          const SizedBox(height: 16),
          buildDropdown("Outdoor Catering Supported",
            ["Yes", "No"],
            _outdoorCateringSupported, (v) => setState(() => _outdoorCateringSupported = v)),
          buildDropdown("Destination Weddings Supported",
            ["Yes", "No"],
            _destinationWeddingsSupported,
            (v) => setState(() => _destinationWeddingsSupported = v)),
          buildDropdown("Travel Charges",
            ["Included", "Extra", "Depends"],
            _travelCharges, (v) => setState(() => _travelCharges = v)),
          buildDropdown("Stay Requirement",
            ["Yes", "No"],
            _stayRequirement, (v) => setState(() => _stayRequirement = v)),
        ],
        dividerLine(),

        // ── Section 10: Event Suitability ─────────────────────────────────
        sectionHeader("Section 10 — Event suitability", _cs10,
            () => setState(() => _cs10 = !_cs10)),
        if (_cs10) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Functions Suitable For",
            ["Haldi", "Mehendi", "Sangeet", "Wedding", "Reception", "Cocktail"],
            _functionsSuitableFor,
            (o, c) => setState(() => c ? _functionsSuitableFor.add(o) : _functionsSuitableFor.remove(o))),
          buildMultiSelect("Best For",
            ["Budget Weddings", "Luxury Weddings", "Large Gatherings",
             "Intimate Weddings", "Destination Weddings"],
            _bestFor,
            (o, c) => setState(() => c ? _bestFor.add(o) : _bestFor.remove(o))),
        ],
        dividerLine(),

        // ── Section 11: Workflow & Booking ─────────────────────────────────
        sectionHeader("Section 11 — Workflow & booking", _cs11,
            () => setState(() => _cs11 = !_cs11)),
        if (_cs11) ...[
          const SizedBox(height: 16),
          buildDropdown("Advance Required",
            ["Yes", "No"],
            _advanceRequired, (v) => setState(() => _advanceRequired = v)),
          buildDropdown("Advance Percentage",
            ["25%", "50%", "75%"],
            _advancePercentage, (v) => setState(() => _advancePercentage = v)),
          buildDropdown("Booking Timeline",
            ["1 Month Before", "3 Months Before", "6 Months Before"],
            _bookingTimeline, (v) => setState(() => _bookingTimeline = v)),
          buildDropdown("Cancellation Policy",
            ["Non Refundable", "Partial Refund", "Flexible"],
            _cancellationPolicy, (v) => setState(() => _cancellationPolicy = v)),
          buildDropdown("Refund Timeline",
            ["7 Days", "15 Days", "30 Days"],
            _refundTimeline, (v) => setState(() => _refundTimeline = v)),
        ],
        dividerLine(),

        // ── Section 12: Menu & Event Tagging ──────────────────────────────
        sectionHeader("Section 12 — Menu & event tagging (AI)", _cs12,
            () => setState(() => _cs12 = !_cs12)),
        if (_cs12) ...[
          const SizedBox(height: 8),
          Text(
            "Upload menu/event photos in the Photos tab. Tag each image with Cuisine, Event Type, Guest Count, Price Range, Service Style.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          buildTextArea("Default Tags", _tagsCtrl, maxLines: 2),
          buildTextArea("Notes", _notesCtrl),
        ],
      ],
    );
  }
}
