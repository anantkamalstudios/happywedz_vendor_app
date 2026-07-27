import 'package:flutter/material.dart';

import '../facilities_helpers.dart';


class WeddingEntertainerFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const WeddingEntertainerFacilities({super.key, required this.attributes});

  @override
  State<WeddingEntertainerFacilities> createState() =>
      WeddingEntertainerFacilitiesState();
}

class WeddingEntertainerFacilitiesState extends State<WeddingEntertainerFacilities>
    with FacilitiesHelpersMixin<WeddingEntertainerFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  String?      _vendorType;
  String?      _performerCategory;
  final        _performerCategoryOtherCtrl = TextEditingController();
  final        _brandNameCtrl   = TextEditingController();
  final        _yearsExpCtrl    = TextEditingController();
  final        _primaryCityCtrl = TextEditingController();
  List<String> _serviceCities   = [];
  String?      _travelPolicy;
  List<String> _languages       = [];

  // ── services ──────────────────────────────────────────────────────────────
  List<String> _eventTypes            = [];
  List<String> _performanceTypes      = [];
  List<String> _audienceTypeHandling  = [];

  // ── core_intelligence ─────────────────────────────────────────────────────
  String?      _engagementStyle;
  String?      _performanceDuration;
  String?      _performanceSlots;
  String?      _contentCustomization;
  List<String> _themeCompatibility    = [];
  String?      _energyLevel;
  String?      _stageRequirement;
  String?      _soundRequirement;
  String?      _lightingRequirement;

  // ── technical_setup ───────────────────────────────────────────────────────
  String?      _equipmentOwnership;
  String?      _setupTime;
  String?      _teamSize;
  String?      _powerRequirement;
  String?      _greenRoomRequirement;
  String?      _outdoorSuitability;
  String?      _indoorSuitability;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _pricingModel;
  String?      _startingPriceRange;
  List<String> _includes        = [];
  List<String> _addons          = [];
  String?      _peakPricing;
  String?      _negotiationFlexibility;

  // ── scale_capacity ────────────────────────────────────────────────────────
  String?      _audienceSizeCapability;
  String?      _multipleEventHandling;
  String?      _parallelPerformances;

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _advanceBookingTime;
  String?      _bookingAdvancePercent;
  String?      _cancellationPolicy;
  String?      _coordinationMode;
  String?      _preEventBriefing;

  // ── portfolio_tagging ─────────────────────────────────────────────────────
  List<String> _entertainmentTags = [];
  List<String> _performerTags     = [];
  List<String> _eventFitTags       = [];

  // ── section expansion ─────────────────────────────────────────────────────
  bool _ws1 = true;
  bool _ws2 = false;
  bool _ws3 = false;
  bool _ws4 = false;
  bool _ws5 = false;
  bool _ws6 = false;
  bool _ws7 = false;
  bool _ws8 = false;

  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _performerCategoryOtherCtrl.dispose();
    _brandNameCtrl.dispose();
    _yearsExpCtrl.dispose();
    _primaryCityCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final wm = asMap(attrs['wedding_entertainer_master']);

    final id = asMap(wm['identity']);
    _vendorType                    = id['vendor_type'] as String?;
    _performerCategory             = id['performer_category'] as String?;
    _performerCategoryOtherCtrl.text = id['performer_category_other']?.toString() ?? '';
    _brandNameCtrl.text            = id['brand_name']?.toString() ?? '';
    _yearsExpCtrl.text             = id['years_of_experience']?.toString() ?? '';
    _primaryCityCtrl.text          = id['primary_city']?.toString() ?? '';
    _serviceCities                 = toList(id['service_cities']);
    _travelPolicy                  = id['travel_policy'] as String?;
    _languages                     = toList(id['languages']);

    final sv = asMap(wm['services']);
    _eventTypes           = toList(sv['event_types']);
    _performanceTypes     = toList(sv['performance_types']);
    _audienceTypeHandling = toList(sv['audience_type_handling']);

    final ci = asMap(wm['core_intelligence']);
    _engagementStyle      = ci['engagement_style'] as String?;
    _performanceDuration  = ci['performance_duration'] as String?;
    _performanceSlots     = ci['performance_slots'] as String?;
    _contentCustomization = ci['content_customization'] as String?;
    _themeCompatibility   = toList(ci['theme_compatibility']);
    _energyLevel          = ci['energy_level'] as String?;
    _stageRequirement     = ci['stage_requirement'] as String?;
    _soundRequirement     = ci['sound_requirement'] as String?;
    _lightingRequirement  = ci['lighting_requirement'] as String?;

    final ts = asMap(wm['technical_setup']);
    _equipmentOwnership   = ts['equipment_ownership'] as String?;
    _setupTime            = ts['setup_time'] as String?;
    _teamSize             = ts['team_size'] as String?;
    _powerRequirement     = ts['power_requirement'] as String?;
    _greenRoomRequirement = ts['green_room_requirement'] as String?;
    _outdoorSuitability   = ts['outdoor_suitability'] as String?;
    _indoorSuitability    = ts['indoor_suitability'] as String?;

    final pr = asMap(wm['pricing']);
    _pricingModel          = pr['pricing_model'] as String?;
    _startingPriceRange    = pr['starting_price_range'] as String?;
    _includes              = toList(pr['includes']);
    _addons                = toList(pr['addons']);
    _peakPricing           = pr['peak_pricing'] as String?;
    _negotiationFlexibility = pr['negotiation_flexibility'] as String?;

    final sc = asMap(wm['scale_capacity']);
    _audienceSizeCapability = sc['audience_size_capability'] as String?;
    _multipleEventHandling  = sc['multiple_event_handling'] as String?;
    _parallelPerformances   = sc['parallel_performances'] as String?;

    final wf = asMap(wm['workflow']);
    _advanceBookingTime    = wf['advance_booking_time'] as String?;
    _bookingAdvancePercent = wf['booking_advance_percent'] as String?;
    _cancellationPolicy    = wf['cancellation_policy'] as String?;
    _coordinationMode      = wf['coordination_mode'] as String?;
    _preEventBriefing      = wf['pre_event_briefing'] as String?;

    final pt = asMap(wm['portfolio_tagging']);
    _entertainmentTags = toList(pt['entertainment_tags']);
    _performerTags     = toList(pt['performer_tags']);
    _eventFitTags      = toList(pt['event_fit_tags']);
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "vendor_type":              _vendorType,
        "performer_category":       _performerCategory,
        "performer_category_other": _performerCategoryOtherCtrl.text,
        "brand_name":               _brandNameCtrl.text,
        "years_of_experience":      _yearsExpCtrl.text,
        "primary_city":             _primaryCityCtrl.text,
        "service_cities":           _serviceCities,
        "travel_policy":            _travelPolicy,
        "languages":                _languages,
      },
      "services": {
        ...asMap(ex["services"]),
        "event_types":            _eventTypes,
        "performance_types":      _performanceTypes,
        "audience_type_handling": _audienceTypeHandling,
      },
      "core_intelligence": {
        ...asMap(ex["core_intelligence"]),
        "engagement_style":      _engagementStyle,
        "performance_duration":  _performanceDuration,
        "performance_slots":     _performanceSlots,
        "content_customization": _contentCustomization,
        "theme_compatibility":   _themeCompatibility,
        "energy_level":          _energyLevel,
        "stage_requirement":     _stageRequirement,
        "sound_requirement":     _soundRequirement,
        "lighting_requirement":  _lightingRequirement,
      },
      "technical_setup": {
        ...asMap(ex["technical_setup"]),
        "equipment_ownership":    _equipmentOwnership,
        "setup_time":             _setupTime,
        "team_size":              _teamSize,
        "power_requirement":      _powerRequirement,
        "green_room_requirement": _greenRoomRequirement,
        "outdoor_suitability":    _outdoorSuitability,
        "indoor_suitability":     _indoorSuitability,
      },
      "pricing": {
        ...asMap(ex["pricing"]),
        "pricing_model":           _pricingModel,
        "starting_price_range":    _startingPriceRange,
        "includes":                _includes,
        "addons":                  _addons,
        "peak_pricing":            _peakPricing,
        "negotiation_flexibility": _negotiationFlexibility,
      },
      "scale_capacity": {
        ...asMap(ex["scale_capacity"]),
        "audience_size_capability": _audienceSizeCapability,
        "multiple_event_handling":  _multipleEventHandling,
        "parallel_performances":    _parallelPerformances,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "advance_booking_time":    _advanceBookingTime,
        "booking_advance_percent": _bookingAdvancePercent,
        "cancellation_policy":     _cancellationPolicy,
        "coordination_mode":       _coordinationMode,
        "pre_event_briefing":      _preEventBriefing,
      },
      "portfolio_tagging": {
        ...asMap(ex["portfolio_tagging"]),
        "entertainment_tags": _entertainmentTags,
        "performer_tags":     _performerTags,
        "event_fit_tags":     _eventFitTags,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Wedding Entertainer Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured entertainer attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _ws1,
            () => setState(() => _ws1 = !_ws1)),
        if (_ws1) ...[
          const SizedBox(height: 16),
          buildDropdown("Vendor Type",
            ["Solo Performer", "Performer + Team", "Entertainment Agency", "Celebrity Act"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildDropdown("Performer Category (Primary)",
            ["Magician", "Live Band", "Singer", "Instrumentalist",
             "Stand-up Comedian", "Dance Troupe", "Fire Performer",
             "LED Performer", "Illusionist", "Mentalist", "Kids Entertainer",
             "Celebrity Artist", "Other"],
            _performerCategory, (v) => setState(() => _performerCategory = v)),
          if (_performerCategory == "Other")
            buildTextArea("Performer Category (specify)", _performerCategoryOtherCtrl, maxLines: 1),
          buildNumberField("Years of Experience", _yearsExpCtrl),
          buildTextArea("Primary City", _primaryCityCtrl, maxLines: 1),
          buildMultiSelect("Service Cities",
            ["Pan-India", "International", "Delhi NCR", "Mumbai", "Bangalore",
             "Hyderabad", "Chennai", "Kolkata", "Pune", "Ahmedabad",
             "Jaipur", "Chandigarh", "Lucknow", "Goa", "Other"],
            _serviceCities,
            (o, c) => setState(() => c ? _serviceCities.add(o) : _serviceCities.remove(o))),
          buildDropdown("Travel Policy",
            ["Included (local)", "Fixed Cost", "Per Km", "Case-by-case"],
            _travelPolicy, (v) => setState(() => _travelPolicy = v)),
          buildMultiSelect("Languages",
            ["English", "Hindi", "Marathi", "Punjabi", "Gujarati",
             "Tamil", "Telugu", "Bengali", "Multi-language"],
            _languages,
            (o, c) => setState(() => c ? _languages.add(o) : _languages.remove(o))),
        ],
        dividerLine(),

        // ── Section 2: Services Offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _ws2,
            () => setState(() => _ws2 = !_ws2)),
        if (_ws2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Event Types",
            ["Sangeet", "Cocktail", "Reception", "Mehendi", "Haldi",
             "Baraat", "After Party", "Kids Party", "Corporate"],
            _eventTypes,
            (o, c) => setState(() => c ? _eventTypes.add(o) : _eventTypes.remove(o))),
          buildMultiSelect("Performance Types",
            ["Live Singing", "Band Performance", "Instrumental", "Magic Show",
             "Comedy Act", "Dance Performance", "Interactive Games",
             "Roaming Acts", "Stage Show"],
            _performanceTypes,
            (o, c) => setState(() => c ? _performanceTypes.add(o) : _performanceTypes.remove(o))),
          buildMultiSelect("Audience Type Handling",
            ["Kids", "Family Audience", "Youth Crowd",
             "Mixed Audience", "Premium / Luxury Audience"],
            _audienceTypeHandling,
            (o, c) => setState(() => c ? _audienceTypeHandling.add(o) : _audienceTypeHandling.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _ws3,
            () => setState(() => _ws3 = !_ws3)),
        if (_ws3) ...[
          const SizedBox(height: 16),
          buildDropdown("Engagement Style",
            ["Interactive", "Passive Performance",
             "Crowd Participation Heavy", "Stage-Centric"],
            _engagementStyle, (v) => setState(() => _engagementStyle = v)),
          buildDropdown("Performance Duration",
            ["10–15 mins", "15–30 mins", "30–60 mins", "60–120 mins", "Custom"],
            _performanceDuration, (v) => setState(() => _performanceDuration = v)),
          buildDropdown("Performance Slots",
            ["Single Slot", "Multiple Slots", "Roaming Throughout Event"],
            _performanceSlots, (v) => setState(() => _performanceSlots = v)),
          buildDropdown("Content Customization",
            ["Fully Customizable", "Semi-Custom", "Fixed Script"],
            _contentCustomization, (v) => setState(() => _contentCustomization = v)),
          buildMultiSelect("Theme Compatibility",
            ["Royal Wedding", "Bollywood Theme", "Retro Night",
             "Carnival", "Modern Luxury", "Cultural Traditional"],
            _themeCompatibility,
            (o, c) => setState(() => c ? _themeCompatibility.add(o) : _themeCompatibility.remove(o))),
          buildDropdown("Energy Level",
            ["Low-key", "Balanced", "High Energy", "Ultra High Energy"],
            _energyLevel, (v) => setState(() => _energyLevel = v)),
          buildDropdown("Stage Requirement",
            ["Required", "Optional", "Not Required"],
            _stageRequirement, (v) => setState(() => _stageRequirement = v)),
          buildDropdown("Sound Requirement",
            ["Required", "Optional", "Not Required"],
            _soundRequirement, (v) => setState(() => _soundRequirement = v)),
          buildDropdown("Lighting Requirement",
            ["Basic", "Advanced", "Custom Production"],
            _lightingRequirement, (v) => setState(() => _lightingRequirement = v)),
        ],
        dividerLine(),

        // ── Section 4: Technical & Setup ───────────────────────────────────
        sectionHeader("Section 4 — Technical & setup", _ws4,
            () => setState(() => _ws4 = !_ws4)),
        if (_ws4) ...[
          const SizedBox(height: 16),
          buildDropdown("Equipment Ownership",
            ["Own", "Rental", "Hybrid"],
            _equipmentOwnership, (v) => setState(() => _equipmentOwnership = v)),
          buildDropdown("Setup Time",
            ["<30 mins", "30–60 mins", "1–3 hours", "3+ hours"],
            _setupTime, (v) => setState(() => _setupTime = v)),
          buildDropdown("Team Size",
            ["Solo", "2–5", "5–10", "10+"],
            _teamSize, (v) => setState(() => _teamSize = v)),
          buildYesNo("Power Requirement", _powerRequirement,
              (v) => setState(() => _powerRequirement = v)),
          buildYesNo("Green Room Requirement", _greenRoomRequirement,
              (v) => setState(() => _greenRoomRequirement = v)),
          buildYesNo("Outdoor Suitability", _outdoorSuitability,
              (v) => setState(() => _outdoorSuitability = v)),
          buildYesNo("Indoor Suitability", _indoorSuitability,
              (v) => setState(() => _indoorSuitability = v)),
        ],
        dividerLine(),

        // ── Section 5: Pricing Logic ───────────────────────────────────────
        sectionHeader("Section 5 — Pricing logic", _ws5,
            () => setState(() => _ws5 = !_ws5)),
        if (_ws5) ...[
          const SizedBox(height: 16),
          buildDropdown("Pricing Model",
            ["Per Act", "Per Hour", "Per Event", "Package"],
            _pricingModel, (v) => setState(() => _pricingModel = v)),
          buildDropdown("Starting Price Range",
            ["₹5k–₹15k", "₹15k–₹30k", "₹30k–₹75k", "₹75k–₹1.5L", "₹1.5L+"],
            _startingPriceRange, (v) => setState(() => _startingPriceRange = v)),
          buildMultiSelect("Includes",
            ["Performance", "Equipment", "Travel", "Setup", "Assistants"],
            _includes,
            (o, c) => setState(() => c ? _includes.add(o) : _includes.remove(o))),
          buildMultiSelect("Add-ons",
            ["Extra Duration", "Special Effects", "Costume Changes", "Custom Script"],
            _addons,
            (o, c) => setState(() => c ? _addons.add(o) : _addons.remove(o))),
          buildYesNo("Peak Pricing", _peakPricing,
              (v) => setState(() => _peakPricing = v)),
          buildDropdown("Negotiation Flexibility",
            ["Fixed", "Moderate", "Flexible"],
            _negotiationFlexibility, (v) => setState(() => _negotiationFlexibility = v)),
        ],
        dividerLine(),

        // ── Section 6: Scale & Capacity ────────────────────────────────────
        sectionHeader("Section 6 — Scale & capacity", _ws6,
            () => setState(() => _ws6 = !_ws6)),
        if (_ws6) ...[
          const SizedBox(height: 16),
          buildDropdown("Audience Size Capability",
            ["<50", "50–150", "150–500", "500–1000", "1000+"],
            _audienceSizeCapability, (v) => setState(() => _audienceSizeCapability = v)),
          buildYesNo("Multiple Event Handling", _multipleEventHandling,
              (v) => setState(() => _multipleEventHandling = v)),
          buildYesNo("Parallel Performances", _parallelPerformances,
              (v) => setState(() => _parallelPerformances = v)),
        ],
        dividerLine(),

        // ── Section 7: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 7 — Workflow & booking", _ws7,
            () => setState(() => _ws7 = !_ws7)),
        if (_ws7) ...[
          const SizedBox(height: 16),
          buildDropdown("Advance Booking Time",
            ["<1 week", "1–4 weeks", "1–3 months", "3–6 months"],
            _advanceBookingTime, (v) => setState(() => _advanceBookingTime = v)),
          buildDropdown("Booking Advance Percent",
            ["10%", "25%", "50%", "75%"],
            _bookingAdvancePercent, (v) => setState(() => _bookingAdvancePercent = v)),
          buildDropdown("Cancellation Policy",
            ["Non-refundable", "Partial refund", "Flexible"],
            _cancellationPolicy, (v) => setState(() => _cancellationPolicy = v)),
          buildDropdown("Client Coordination",
            ["WhatsApp", "Call", "In-person", "App-based"],
            _coordinationMode, (v) => setState(() => _coordinationMode = v)),
          buildYesNo("Pre-Event Briefing", _preEventBriefing,
              (v) => setState(() => _preEventBriefing = v)),
        ],
        dividerLine(),

        // ── Section 8: Portfolio Tagging ────────────────────────────────────
        sectionHeader("Section 8 — Portfolio tagging (AI layer)", _ws8,
            () => setState(() => _ws8 = !_ws8)),
        if (_ws8) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Entertainment Tags",
            ["Luxury Experience", "Interactive Fun", "Family Friendly",
             "High Energy Show", "Cultural Act", "Unique / Novelty"],
            _entertainmentTags,
            (o, c) => setState(() => c ? _entertainmentTags.add(o) : _entertainmentTags.remove(o))),
          buildMultiSelect("Performer Tags",
            ["Celebrity", "Viral Performer", "Premium Artist", "Budget Friendly"],
            _performerTags,
            (o, c) => setState(() => c ? _performerTags.add(o) : _performerTags.remove(o))),
          buildMultiSelect("Event Fit Tags",
            ["Sangeet Highlight", "Cocktail Feature",
             "Kids Engagement", "Reception Entertainment"],
            _eventFitTags,
            (o, c) => setState(() => c ? _eventFitTags.add(o) : _eventFitTags.remove(o))),
        ],
      ],
    );
  }
}
