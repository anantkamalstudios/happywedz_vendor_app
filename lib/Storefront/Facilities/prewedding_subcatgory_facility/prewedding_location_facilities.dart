import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class PreWeddingLocationFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const PreWeddingLocationFacilities({super.key, required this.attributes});

  @override
  State<PreWeddingLocationFacilities> createState() =>
      PreWeddingLocationFacilitiesState();
}

class PreWeddingLocationFacilitiesState extends State<PreWeddingLocationFacilities>
    with FacilitiesHelpersMixin<PreWeddingLocationFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  String?      _locationType;
  final        _locationNameCtrl = TextEditingController();
  String?      _ownershipType;
  final        _cityCtrl         = TextEditingController();
  String?      _accessibilityType;
  String?      _yearsOfOperation;

  // ── services ──────────────────────────────────────────────────────────────
  List<String> _bookingType            = [];
  String?      _photographyAllowed;
  String?      _videographyAllowed;
  String?      _droneUsageAllowed;
  String?      _permissionHandling;
  String?      _changingRoomsAvailable;
  String?      _makeupRoomAvailable;
  List<String> _propsAvailable         = [];
  String?      _powerSupplyAvailable;

  // ── core_intelligence ─────────────────────────────────────────────────────
  List<String> _locationThemes      = [];
  List<String> _bestShootTime       = [];
  String?      _lightingConditions;
  List<String> _weatherSuitability  = [];
  String?      _privacyLevel;
  String?      _noiseLevel;

  // ── technical ─────────────────────────────────────────────────────────────
  String?      _areaSize;
  String?      _shootingSpots;
  String?      _indoorAvailability;
  String?      _outdoorAvailability;
  List<String> _terrainType        = [];
  String?      _electricBackup;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _priceRange;
  String?      _pricingModel;
  String?      _outfitsOnRent;
  String?      _securityDepositRequired;
  String?      _permitCharges;
  String?      _cancellationPolicy;

  // ── scale_capacity ────────────────────────────────────────────────────────
  String?      _maxCrewSize;
  String?      _simultaneousShoots;
  String?      _parkingCapacity;

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _advanceBookingRequired;
  String?      _bookingWindow;
  String?      _timeSlotAllocation;
  String?      _onsiteCoordinatorAvailable;
  List<String> _paymentModes              = [];
  String?      _advancePaymentPercentage;

  // ── portfolio_tagging ─────────────────────────────────────────────────────
  List<String> _visualStyleTags = [];
  List<String> _audienceTags    = [];
  List<String> _usageTags       = [];
  String?      _priceSegmentTags;

  // ── section expansion ─────────────────────────────────────────────────────
  bool _ls1 = true;
  bool _ls2 = false;
  bool _ls3 = false;
  bool _ls4 = false;
  bool _ls5 = false;
  bool _ls6 = false;
  bool _ls7 = false;
  bool _ls8 = false;

  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _locationNameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final lm = asMap(attrs['pre_wedding_location_master']);

    final id = asMap(lm['identity']);
    _locationType         = id['location_type'] as String?;
    _locationNameCtrl.text = id['location_name']?.toString() ?? '';
    _ownershipType        = id['ownership_type'] as String?;
    _cityCtrl.text        = id['city']?.toString() ?? '';
    _accessibilityType    = id['accessibility_type'] as String?;
    _yearsOfOperation     = id['years_of_operation'] as String?;

    final sv = asMap(lm['services']);
    _bookingType            = toList(sv['booking_type']);
    _photographyAllowed     = sv['photography_allowed'] as String?;
    _videographyAllowed     = sv['videography_allowed'] as String?;
    _droneUsageAllowed      = sv['drone_usage_allowed'] as String?;
    _permissionHandling     = sv['permission_handling'] as String?;
    _changingRoomsAvailable = sv['changing_rooms_available'] as String?;
    _makeupRoomAvailable    = sv['makeup_room_available'] as String?;
    _propsAvailable         = toList(sv['props_available']);
    _powerSupplyAvailable   = sv['power_supply_available'] as String?;

    final ci = asMap(lm['core_intelligence']);
    _locationThemes     = toList(ci['location_themes']);
    _bestShootTime      = toList(ci['best_shoot_time']);
    _lightingConditions = ci['lighting_conditions'] as String?;
    _weatherSuitability = toList(ci['weather_suitability']);
    _privacyLevel       = ci['privacy_level'] as String?;
    _noiseLevel         = ci['noise_level'] as String?;

    final te = asMap(lm['technical']);
    _areaSize            = te['area_size'] as String?;
    _shootingSpots       = te['shooting_spots'] as String?;
    _indoorAvailability  = te['indoor_availability'] as String?;
    _outdoorAvailability = te['outdoor_availability'] as String?;
    _terrainType         = toList(te['terrain_type']);
    _electricBackup      = te['electric_backup'] as String?;

    final pr = asMap(lm['pricing']);
    _priceRange              = pr['price_range'] as String?;
    _pricingModel            = pr['pricing_model'] as String?;
    _outfitsOnRent           = pr['outfits_on_rent'] as String?;
    _securityDepositRequired = pr['security_deposit_required'] as String?;
    _permitCharges           = pr['permit_charges'] as String?;
    _cancellationPolicy      = pr['cancellation_policy'] as String?;

    final sc = asMap(lm['scale_capacity']);
    _maxCrewSize        = sc['max_crew_size'] as String?;
    _simultaneousShoots = sc['simultaneous_shoots'] as String?;
    _parkingCapacity    = sc['parking_capacity'] as String?;

    final wf = asMap(lm['workflow']);
    _advanceBookingRequired     = wf['advance_booking_required'] as String?;
    _bookingWindow              = wf['booking_window'] as String?;
    _timeSlotAllocation         = wf['time_slot_allocation'] as String?;
    _onsiteCoordinatorAvailable = wf['onsite_coordinator_available'] as String?;
    _paymentModes               = toList(wf['payment_modes']);
    _advancePaymentPercentage   = wf['advance_payment_percentage'] as String?;

    final pt = asMap(lm['portfolio_tagging']);
    _visualStyleTags  = toList(pt['visual_style_tags']);
    _audienceTags     = toList(pt['audience_tags']);
    _usageTags        = toList(pt['usage_tags']);
    _priceSegmentTags = pt['price_segment_tags'] as String?;
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "location_type":      _locationType,
        "location_name":      _locationNameCtrl.text,
        "ownership_type":     _ownershipType,
        "city":               _cityCtrl.text,
        "accessibility_type": _accessibilityType,
        "years_of_operation": _yearsOfOperation,
      },
      "services": {
        ...asMap(ex["services"]),
        "booking_type":             _bookingType,
        "photography_allowed":      _photographyAllowed,
        "videography_allowed":      _videographyAllowed,
        "drone_usage_allowed":      _droneUsageAllowed,
        "permission_handling":      _permissionHandling,
        "changing_rooms_available": _changingRoomsAvailable,
        "makeup_room_available":    _makeupRoomAvailable,
        "props_available":          _propsAvailable,
        "power_supply_available":   _powerSupplyAvailable,
      },
      "core_intelligence": {
        ...asMap(ex["core_intelligence"]),
        "location_themes":     _locationThemes,
        "best_shoot_time":     _bestShootTime,
        "lighting_conditions": _lightingConditions,
        "weather_suitability": _weatherSuitability,
        "privacy_level":       _privacyLevel,
        "noise_level":         _noiseLevel,
      },
      "technical": {
        ...asMap(ex["technical"]),
        "area_size":            _areaSize,
        "shooting_spots":       _shootingSpots,
        "indoor_availability":  _indoorAvailability,
        "outdoor_availability": _outdoorAvailability,
        "terrain_type":         _terrainType,
        "electric_backup":      _electricBackup,
      },
      "pricing": {
        ...asMap(ex["pricing"]),
        "price_range":               _priceRange,
        "pricing_model":             _pricingModel,
        "outfits_on_rent":           _outfitsOnRent,
        "security_deposit_required": _securityDepositRequired,
        "permit_charges":            _permitCharges,
        "cancellation_policy":       _cancellationPolicy,
      },
      "scale_capacity": {
        ...asMap(ex["scale_capacity"]),
        "max_crew_size":       _maxCrewSize,
        "simultaneous_shoots": _simultaneousShoots,
        "parking_capacity":    _parkingCapacity,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "advance_booking_required":     _advanceBookingRequired,
        "booking_window":               _bookingWindow,
        "time_slot_allocation":         _timeSlotAllocation,
        "onsite_coordinator_available": _onsiteCoordinatorAvailable,
        "payment_modes":                _paymentModes,
        "advance_payment_percentage":   _advancePaymentPercentage,
      },
      "portfolio_tagging": {
        ...asMap(ex["portfolio_tagging"]),
        "visual_style_tags":  _visualStyleTags,
        "audience_tags":      _audienceTags,
        "usage_tags":         _usageTags,
        "price_segment_tags": _priceSegmentTags,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pre-Wedding Shoot Location Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured location attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _ls1,
            () => setState(() => _ls1 = !_ls1)),
        if (_ls1) ...[
          const SizedBox(height: 16),
          buildDropdown("Location Type",
            ["Private Property", "Resort / Hotel", "Studio (Indoor)",
             "Outdoor Public Location", "Farmhouse", "Heritage Property"],
            _locationType, (v) => setState(() => _locationType = v)),
          buildTextArea("Location Name", _locationNameCtrl, maxLines: 1),
          buildDropdown("Ownership Type",
            ["Private Owned", "Government / Public", "Commercial Venue"],
            _ownershipType, (v) => setState(() => _ownershipType = v)),
          buildTextArea("City", _cityCtrl, maxLines: 1),
          buildDropdown("Accessibility Type",
            ["Easy Access (Roadside)", "Moderate Access", "Remote Location"],
            _accessibilityType, (v) => setState(() => _accessibilityType = v)),
          buildDropdown("Years of Operation",
            ["0–2", "3–5", "6–10", "10+"],
            _yearsOfOperation, (v) => setState(() => _yearsOfOperation = v)),
        ],
        dividerLine(),

        // ── Section 2: Services Offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _ls2,
            () => setState(() => _ls2 = !_ls2)),
        if (_ls2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Booking Type",
            ["Hourly Booking", "Half-Day Booking", "Full-Day Booking"],
            _bookingType,
            (o, c) => setState(() => c ? _bookingType.add(o) : _bookingType.remove(o))),
          buildYesNo("Photography Allowed", _photographyAllowed,
              (v) => setState(() => _photographyAllowed = v)),
          buildYesNo("Videography Allowed", _videographyAllowed,
              (v) => setState(() => _videographyAllowed = v)),
          buildYesNo("Drone Usage Allowed", _droneUsageAllowed,
              (v) => setState(() => _droneUsageAllowed = v)),
          buildDropdown("Permission Handling",
            ["Self-Managed", "Vendor Managed", "Not Required"],
            _permissionHandling, (v) => setState(() => _permissionHandling = v)),
          buildYesNo("Changing Rooms Available", _changingRoomsAvailable,
              (v) => setState(() => _changingRoomsAvailable = v)),
          buildYesNo("Makeup Room Available", _makeupRoomAvailable,
              (v) => setState(() => _makeupRoomAvailable = v)),
          buildMultiSelect("Props Available",
            ["Vintage Props", "Floral Setups", "Furniture", "Vehicles", "None"],
            _propsAvailable,
            (o, c) => setState(() => c ? _propsAvailable.add(o) : _propsAvailable.remove(o))),
          buildYesNo("Power Supply Available", _powerSupplyAvailable,
              (v) => setState(() => _powerSupplyAvailable = v)),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _ls3,
            () => setState(() => _ls3 = !_ls3)),
        if (_ls3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Location Themes",
            ["Royal / Palace", "Nature / Greenery", "Beach / Waterfront",
             "Urban / Modern", "Rustic / Village", "Studio Backdrop", "Luxury Resort"],
            _locationThemes,
            (o, c) => setState(() => c ? _locationThemes.add(o) : _locationThemes.remove(o))),
          buildMultiSelect("Best Shoot Time",
            ["Sunrise", "Daylight", "Sunset", "Night"],
            _bestShootTime,
            (o, c) => setState(() => c ? _bestShootTime.add(o) : _bestShootTime.remove(o))),
          buildDropdown("Lighting Conditions",
            ["Natural Light Dominant", "Artificial Lighting Available", "Mixed"],
            _lightingConditions, (v) => setState(() => _lightingConditions = v)),
          buildMultiSelect("Weather Suitability",
            ["Summer Friendly", "Winter Friendly", "Monsoon Friendly", "All Weather"],
            _weatherSuitability,
            (o, c) => setState(() => c ? _weatherSuitability.add(o) : _weatherSuitability.remove(o))),
          buildDropdown("Privacy Level",
            ["Exclusive Private", "Semi-Private", "Public Shared"],
            _privacyLevel, (v) => setState(() => _privacyLevel = v)),
          buildDropdown("Noise Level",
            ["Low", "Moderate", "High"],
            _noiseLevel, (v) => setState(() => _noiseLevel = v)),
        ],
        dividerLine(),

        // ── Section 4: Technical ───────────────────────────────────────────
        sectionHeader("Section 4 — Technical", _ls4,
            () => setState(() => _ls4 = !_ls4)),
        if (_ls4) ...[
          const SizedBox(height: 16),
          buildDropdown("Area Size",
            ["<1 Acre", "1–5 Acres", "5–10 Acres", "10+ Acres"],
            _areaSize, (v) => setState(() => _areaSize = v)),
          buildDropdown("Number of Shooting Spots",
            ["1–3", "3–7", "7–15", "15+"],
            _shootingSpots, (v) => setState(() => _shootingSpots = v)),
          buildYesNo("Indoor Availability", _indoorAvailability,
              (v) => setState(() => _indoorAvailability = v)),
          buildYesNo("Outdoor Availability", _outdoorAvailability,
              (v) => setState(() => _outdoorAvailability = v)),
          buildMultiSelect("Terrain Type",
            ["Garden", "Water Body", "Architecture", "Open Land", "Hills"],
            _terrainType,
            (o, c) => setState(() => c ? _terrainType.add(o) : _terrainType.remove(o))),
          buildYesNo("Electric Backup", _electricBackup,
              (v) => setState(() => _electricBackup = v)),
        ],
        dividerLine(),

        // ── Section 5: Pricing Logic ───────────────────────────────────────
        sectionHeader("Section 5 — Pricing logic", _ls5,
            () => setState(() => _ls5 = !_ls5)),
        if (_ls5) ...[
          const SizedBox(height: 16),
          buildDropdown("Price Range (INR)",
            ["0–5K", "5K–15K", "15K–30K", "30K–75K", "75K+"],
            _priceRange, (v) => setState(() => _priceRange = v)),
          buildDropdown("Pricing Model",
            ["Per Hour", "Half Day", "Full Day", "Package Based"],
            _pricingModel, (v) => setState(() => _pricingModel = v)),
          buildDropdown("Outfits Available on Rent",
            ["Yes - Included in the venue charge", "Not Available", "Available on Extra Charge"],
            _outfitsOnRent, (v) => setState(() => _outfitsOnRent = v)),
          buildYesNo("Security Deposit Required", _securityDepositRequired,
              (v) => setState(() => _securityDepositRequired = v)),
          buildDropdown("Permit Charges",
            ["Included", "Extra", "Not Applicable"],
            _permitCharges, (v) => setState(() => _permitCharges = v)),
          buildDropdown("Cancellation Policy",
            ["Refundable", "Partially Refundable", "Non-Refundable"],
            _cancellationPolicy, (v) => setState(() => _cancellationPolicy = v)),
        ],
        dividerLine(),

        // ── Section 6: Scale & Capacity ────────────────────────────────────
        sectionHeader("Section 6 — Scale & capacity", _ls6,
            () => setState(() => _ls6 = !_ls6)),
        if (_ls6) ...[
          const SizedBox(height: 16),
          buildDropdown("Max Crew Size Allowed",
            ["2–5", "5–10", "10–20", "20+"],
            _maxCrewSize, (v) => setState(() => _maxCrewSize = v)),
          buildDropdown("Simultaneous Shoots Allowed",
            ["1 (Exclusive)", "2–3", "3–5", "5+"],
            _simultaneousShoots, (v) => setState(() => _simultaneousShoots = v)),
          buildDropdown("Parking Capacity",
            ["0–5 Vehicles", "5–15", "15–30", "30+"],
            _parkingCapacity, (v) => setState(() => _parkingCapacity = v)),
        ],
        dividerLine(),

        // ── Section 7: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 7 — Workflow & booking", _ls7,
            () => setState(() => _ls7 = !_ls7)),
        if (_ls7) ...[
          const SizedBox(height: 16),
          buildYesNo("Advance Booking Required", _advanceBookingRequired,
              (v) => setState(() => _advanceBookingRequired = v)),
          buildDropdown("Booking Window",
            ["Same Day", "1–7 days", "7–30 days", "1+ month"],
            _bookingWindow, (v) => setState(() => _bookingWindow = v)),
          buildDropdown("Time Slot Allocation",
            ["Fixed Slots", "Flexible"],
            _timeSlotAllocation, (v) => setState(() => _timeSlotAllocation = v)),
          buildYesNo("On-site Coordinator Available", _onsiteCoordinatorAvailable,
              (v) => setState(() => _onsiteCoordinatorAvailable = v)),
          buildMultiSelect("Payment Modes",
            ["UPI", "Cash", "Card", "Bank Transfer"],
            _paymentModes,
            (o, c) => setState(() => c ? _paymentModes.add(o) : _paymentModes.remove(o))),
          buildDropdown("Advance Payment Percentage",
            ["0%", "25%", "50%", "100%"],
            _advancePaymentPercentage,
            (v) => setState(() => _advancePaymentPercentage = v)),
        ],
        dividerLine(),

        // ── Section 8: Portfolio Tagging ────────────────────────────────────
        sectionHeader("Section 8 — Portfolio tagging (AI layer)", _ls8,
            () => setState(() => _ls8 = !_ls8)),
        if (_ls8) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Visual Style Tags",
            ["Cinematic", "Natural", "Luxury", "Rustic", "Minimal"],
            _visualStyleTags,
            (o, c) => setState(() => c ? _visualStyleTags.add(o) : _visualStyleTags.remove(o))),
          buildMultiSelect("Audience Tags",
            ["Couple", "Pre-Wedding Shoot", "Engagement Shoot"],
            _audienceTags,
            (o, c) => setState(() => c ? _audienceTags.add(o) : _audienceTags.remove(o))),
          buildMultiSelect("Usage Tags",
            ["Pre-Wedding Photos", "Pre-Wedding Video", "Reel Shoot"],
            _usageTags,
            (o, c) => setState(() => c ? _usageTags.add(o) : _usageTags.remove(o))),
          buildDropdown("Price Segment Tags",
            ["Budget", "Mid-range", "Premium", "Luxury"],
            _priceSegmentTags, (v) => setState(() => _priceSegmentTags = v)),
        ],
      ],
    );
  }
}
