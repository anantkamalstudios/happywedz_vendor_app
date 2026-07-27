import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class PreWeddingPhotographerFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const PreWeddingPhotographerFacilities({super.key, required this.attributes});

  @override
  State<PreWeddingPhotographerFacilities> createState() =>
      PreWeddingPhotographerFacilitiesState();
}

class PreWeddingPhotographerFacilitiesState
    extends State<PreWeddingPhotographerFacilities>
    with FacilitiesHelpersMixin<PreWeddingPhotographerFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  String?      _vendorType;
  final        _brandNameCtrl = TextEditingController();
  List<String> _servicePresence = [];
  final        _cityCtrl      = TextEditingController();
  String?      _yearsOfExperience;
  String?      _teamSize;

  // ── services ──────────────────────────────────────────────────────────────
  List<String> _shootTypes               = [];
  List<String> _photographyCoverage      = [];
  String?      _droneShooting;
  String?      _cinematicVideography;
  String?      _conceptPlanningSupport;
  String?      _locationAssistance;
  String?      _stylingAssistance;
  String?      _outfitCoordinationSupport;
  String?      _travelIncluded;

  // ── core_intelligence ─────────────────────────────────────────────────────
  List<String> _photographyStyle    = [];
  List<String> _shootStyleThemes     = [];
  List<String> _lightingStyle        = [];
  List<String> _editingStyle         = [];
  List<String> _reelStyleCapability  = [];
  List<String> _bestTimePreference   = [];

  // ── technical ─────────────────────────────────────────────────────────────
  List<String> _cameraType             = [];
  String?      _droneEquipmentLevel;
  String?      _videoResolution;
  List<String> _stabilizationEquipment = [];
  String?      _audioCapture;
  String?      _backupEquipmentAvailable;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _priceRange;
  String?      _pricingModel;
  String?      _travelCharges;
  String?      _stayCharges;
  String?      _droneCharges;
  String?      _editingCharges;
  String?      _advancePaymentPercentage;

  // ── scale_capacity ────────────────────────────────────────────────────────
  String?      _shootsPerMonth;
  String?      _simultaneousProjects;
  String?      _teamScalability;

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _bookingWindow;
  String?      _conceptFinalizationTimeline;
  List<String> _shootDurationOptions     = [];
  String?      _rawDataDelivery;
  String?      _editedPhotosDeliveryTimeline;
  String?      _videoDeliveryTimeline;
  List<String> _paymentModes             = [];

  // ── portfolio_tagging ─────────────────────────────────────────────────────
  List<String> _visualStyleTags = [];
  List<String> _audienceTags    = [];
  List<String> _usageTags       = [];
  String?      _priceSegmentTags;

  // ── section expansion ─────────────────────────────────────────────────────
  bool _ps1 = true;
  bool _ps2 = false;
  bool _ps3 = false;
  bool _ps4 = false;
  bool _ps5 = false;
  bool _ps6 = false;
  bool _ps7 = false;
  bool _ps8 = false;

  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _brandNameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final pm = asMap(attrs['pre_wedding_photographer_master']);

    final id = asMap(pm['identity']);
    _vendorType         = id['vendor_type'] as String?;
    _brandNameCtrl.text = id['brand_name']?.toString() ?? '';
    _servicePresence    = toList(id['service_presence']);
    _cityCtrl.text      = id['city']?.toString() ?? '';
    _yearsOfExperience  = id['years_of_experience'] as String?;
    _teamSize           = id['team_size'] as String?;

    final sv = asMap(pm['services']);
    _shootTypes                = toList(sv['shoot_types']);
    _photographyCoverage       = toList(sv['photography_coverage']);
    _droneShooting             = sv['drone_shooting'] as String?;
    _cinematicVideography      = sv['cinematic_videography'] as String?;
    _conceptPlanningSupport    = sv['concept_planning_support'] as String?;
    _locationAssistance        = sv['location_assistance'] as String?;
    _stylingAssistance         = sv['styling_assistance'] as String?;
    _outfitCoordinationSupport = sv['outfit_coordination_support'] as String?;
    _travelIncluded            = sv['travel_included'] as String?;

    final ci = asMap(pm['core_intelligence']);
    _photographyStyle   = toList(ci['photography_style']);
    _shootStyleThemes   = toList(ci['shoot_style_themes']);
    _lightingStyle      = toList(ci['lighting_style']);
    _editingStyle       = toList(ci['editing_style']);
    _reelStyleCapability = toList(ci['reel_style_capability']);
    _bestTimePreference = toList(ci['best_time_preference']);

    final te = asMap(pm['technical']);
    _cameraType              = toList(te['camera_type']);
    _droneEquipmentLevel     = te['drone_equipment_level'] as String?;
    _videoResolution         = te['video_resolution'] as String?;
    _stabilizationEquipment  = toList(te['stabilization_equipment']);
    _audioCapture            = te['audio_capture'] as String?;
    _backupEquipmentAvailable = te['backup_equipment_available'] as String?;

    final pr = asMap(pm['pricing']);
    _priceRange               = pr['price_range'] as String?;
    _pricingModel             = pr['pricing_model'] as String?;
    _travelCharges            = pr['travel_charges'] as String?;
    _stayCharges              = pr['stay_charges'] as String?;
    _droneCharges             = pr['drone_charges'] as String?;
    _editingCharges           = pr['editing_charges'] as String?;
    _advancePaymentPercentage = pr['advance_payment_percentage'] as String?;

    final sc = asMap(pm['scale_capacity']);
    _shootsPerMonth       = sc['shoots_per_month'] as String?;
    _simultaneousProjects = sc['simultaneous_projects'] as String?;
    _teamScalability      = sc['team_scalability'] as String?;

    final wf = asMap(pm['workflow']);
    _bookingWindow                = wf['booking_window'] as String?;
    _conceptFinalizationTimeline  = wf['concept_finalization_timeline'] as String?;
    _shootDurationOptions         = toList(wf['shoot_duration_options']);
    _rawDataDelivery              = wf['raw_data_delivery'] as String?;
    _editedPhotosDeliveryTimeline = wf['edited_photos_delivery_timeline'] as String?;
    _videoDeliveryTimeline        = wf['video_delivery_timeline'] as String?;
    _paymentModes                 = toList(wf['payment_modes']);

    final pt = asMap(pm['portfolio_tagging']);
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
        "vendor_type":         _vendorType,
        "brand_name":          _brandNameCtrl.text,
        "service_presence":    _servicePresence,
        "city":                _cityCtrl.text,
        "years_of_experience": _yearsOfExperience,
        "team_size":           _teamSize,
      },
      "services": {
        ...asMap(ex["services"]),
        "shoot_types":                 _shootTypes,
        "photography_coverage":        _photographyCoverage,
        "drone_shooting":              _droneShooting,
        "cinematic_videography":       _cinematicVideography,
        "concept_planning_support":    _conceptPlanningSupport,
        "location_assistance":         _locationAssistance,
        "styling_assistance":          _stylingAssistance,
        "outfit_coordination_support": _outfitCoordinationSupport,
        "travel_included":             _travelIncluded,
      },
      "core_intelligence": {
        ...asMap(ex["core_intelligence"]),
        "photography_style":    _photographyStyle,
        "shoot_style_themes":   _shootStyleThemes,
        "lighting_style":       _lightingStyle,
        "editing_style":        _editingStyle,
        "reel_style_capability": _reelStyleCapability,
        "best_time_preference": _bestTimePreference,
      },
      "technical": {
        ...asMap(ex["technical"]),
        "camera_type":               _cameraType,
        "drone_equipment_level":     _droneEquipmentLevel,
        "video_resolution":          _videoResolution,
        "stabilization_equipment":   _stabilizationEquipment,
        "audio_capture":             _audioCapture,
        "backup_equipment_available": _backupEquipmentAvailable,
      },
      "pricing": {
        ...asMap(ex["pricing"]),
        "price_range":                _priceRange,
        "pricing_model":              _pricingModel,
        "travel_charges":             _travelCharges,
        "stay_charges":               _stayCharges,
        "drone_charges":              _droneCharges,
        "editing_charges":            _editingCharges,
        "advance_payment_percentage": _advancePaymentPercentage,
      },
      "scale_capacity": {
        ...asMap(ex["scale_capacity"]),
        "shoots_per_month":      _shootsPerMonth,
        "simultaneous_projects": _simultaneousProjects,
        "team_scalability":      _teamScalability,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "booking_window":                  _bookingWindow,
        "concept_finalization_timeline":   _conceptFinalizationTimeline,
        "shoot_duration_options":          _shootDurationOptions,
        "raw_data_delivery":               _rawDataDelivery,
        "edited_photos_delivery_timeline": _editedPhotosDeliveryTimeline,
        "video_delivery_timeline":         _videoDeliveryTimeline,
        "payment_modes":                   _paymentModes,
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
        const Text("Pre-Wedding Photographer Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured photographer attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _ps1,
            () => setState(() => _ps1 = !_ps1)),
        if (_ps1) ...[
          const SizedBox(height: 16),
          buildDropdown("Vendor Type",
            ["Solo Photographer", "Photographer + Team",
             "Studio Brand", "Boutique Photography Agency"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildMultiSelect("Service Presence",
            ["Local", "Outstation", "International"],
            _servicePresence,
            (o, c) => setState(() => c ? _servicePresence.add(o) : _servicePresence.remove(o))),
          buildTextArea("City", _cityCtrl, maxLines: 1),
          buildDropdown("Years of Experience",
            ["0–2", "3–5", "6–10", "10+"],
            _yearsOfExperience, (v) => setState(() => _yearsOfExperience = v)),
          buildDropdown("Team Size",
            ["Solo", "2–3", "4–6", "6+"],
            _teamSize, (v) => setState(() => _teamSize = v)),
        ],
        dividerLine(),

        // ── Section 2: Services Offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _ps2,
            () => setState(() => _ps2 = !_ps2)),
        if (_ps2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Shoot Types",
            ["Pre-Wedding Photoshoot", "Pre-Wedding Cinematic Video",
             "Save-the-Date Video", "Reel / Short Content"],
            _shootTypes,
            (o, c) => setState(() => c ? _shootTypes.add(o) : _shootTypes.remove(o))),
          buildMultiSelect("Photography Coverage",
            ["Photos Only", "Video Only", "Both",
             "Complete End to End Pre-wedding package with travel & photography team coverage"],
            _photographyCoverage,
            (o, c) => setState(() => c ? _photographyCoverage.add(o) : _photographyCoverage.remove(o))),
          buildYesNo("Drone Shooting", _droneShooting,
              (v) => setState(() => _droneShooting = v)),
          buildYesNo("Cinematic Videography", _cinematicVideography,
              (v) => setState(() => _cinematicVideography = v)),
          buildYesNo("Concept Planning Support", _conceptPlanningSupport,
              (v) => setState(() => _conceptPlanningSupport = v)),
          buildYesNo("Location Assistance", _locationAssistance,
              (v) => setState(() => _locationAssistance = v)),
          buildYesNo("Styling Assistance", _stylingAssistance,
              (v) => setState(() => _stylingAssistance = v)),
          buildYesNo("Outfit Coordination Support", _outfitCoordinationSupport,
              (v) => setState(() => _outfitCoordinationSupport = v)),
          buildYesNo("Travel Included", _travelIncluded,
              (v) => setState(() => _travelIncluded = v)),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _ps3,
            () => setState(() => _ps3 = !_ps3)),
        if (_ps3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Photography Style",
            ["Candid", "Cinematic", "Traditional", "Fine Art", "Documentary"],
            _photographyStyle,
            (o, c) => setState(() => c ? _photographyStyle.add(o) : _photographyStyle.remove(o))),
          buildMultiSelect("Shoot Style Themes",
            ["Romantic", "Fun / Playful", "Royal", "Travel / Destination", "Minimal"],
            _shootStyleThemes,
            (o, c) => setState(() => c ? _shootStyleThemes.add(o) : _shootStyleThemes.remove(o))),
          buildMultiSelect("Lighting Style",
            ["Natural Light", "Artificial Light", "Mixed"],
            _lightingStyle,
            (o, c) => setState(() => c ? _lightingStyle.add(o) : _lightingStyle.remove(o))),
          buildMultiSelect("Editing Style",
            ["Light & Airy", "Dark & Moody", "Vibrant", "Vintage"],
            _editingStyle,
            (o, c) => setState(() => c ? _editingStyle.add(o) : _editingStyle.remove(o))),
          buildMultiSelect("Reel Style Capability",
            ["Instagram Reels", "Story Format", "Cinematic Highlights"],
            _reelStyleCapability,
            (o, c) => setState(() => c ? _reelStyleCapability.add(o) : _reelStyleCapability.remove(o))),
          buildMultiSelect("Best Time Preference",
            ["Sunrise", "Sunset", "Night", "Full Day"],
            _bestTimePreference,
            (o, c) => setState(() => c ? _bestTimePreference.add(o) : _bestTimePreference.remove(o))),
        ],
        dividerLine(),

        // ── Section 4: Technical / Skill ───────────────────────────────────
        sectionHeader("Section 4 — Technical & skill", _ps4,
            () => setState(() => _ps4 = !_ps4)),
        if (_ps4) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Camera Type Used",
            ["DSLR", "Mirrorless", "Cinema Camera"],
            _cameraType,
            (o, c) => setState(() => c ? _cameraType.add(o) : _cameraType.remove(o))),
          buildDropdown("Drone Equipment Level",
            ["Basic", "Advanced", "Not Available"],
            _droneEquipmentLevel, (v) => setState(() => _droneEquipmentLevel = v)),
          buildDropdown("Video Resolution",
            ["Full HD", "4K", "6K+"],
            _videoResolution, (v) => setState(() => _videoResolution = v)),
          buildMultiSelect("Stabilization Equipment",
            ["Gimbal", "Slider", "Drone", "Handheld"],
            _stabilizationEquipment,
            (o, c) => setState(() => c ? _stabilizationEquipment.add(o) : _stabilizationEquipment.remove(o))),
          buildYesNo("Audio Capture (For Video)", _audioCapture,
              (v) => setState(() => _audioCapture = v)),
          buildYesNo("Backup Equipment Available", _backupEquipmentAvailable,
              (v) => setState(() => _backupEquipmentAvailable = v)),
        ],
        dividerLine(),

        // ── Section 5: Pricing Logic ───────────────────────────────────────
        sectionHeader("Section 5 — Pricing logic", _ps5,
            () => setState(() => _ps5 = !_ps5)),
        if (_ps5) ...[
          const SizedBox(height: 16),
          buildDropdown("Price Range (INR)",
            ["5K–15K", "15K–30K", "30K–60K", "60K–1.5L", "1.5L+"],
            _priceRange, (v) => setState(() => _priceRange = v)),
          buildDropdown("Pricing Model",
            ["Per Shoot", "Per Day", "Package Based"],
            _pricingModel, (v) => setState(() => _pricingModel = v)),
          buildDropdown("Travel Charges",
            ["Included", "Extra"],
            _travelCharges, (v) => setState(() => _travelCharges = v)),
          buildDropdown("Stay Charges",
            ["Included", "Extra"],
            _stayCharges, (v) => setState(() => _stayCharges = v)),
          buildDropdown("Drone Charges",
            ["Included", "Extra"],
            _droneCharges, (v) => setState(() => _droneCharges = v)),
          buildDropdown("Editing Charges",
            ["Included", "Extra"],
            _editingCharges, (v) => setState(() => _editingCharges = v)),
          buildDropdown("Advance Payment Percentage",
            ["25%", "50%", "75%", "100%"],
            _advancePaymentPercentage,
            (v) => setState(() => _advancePaymentPercentage = v)),
        ],
        dividerLine(),

        // ── Section 6: Scale & Capacity ────────────────────────────────────
        sectionHeader("Section 6 — Scale & capacity", _ps6,
            () => setState(() => _ps6 = !_ps6)),
        if (_ps6) ...[
          const SizedBox(height: 16),
          buildDropdown("Shoots per Month Capacity",
            ["<10", "10–20", "20–40", "40+"],
            _shootsPerMonth, (v) => setState(() => _shootsPerMonth = v)),
          buildDropdown("Simultaneous Projects Capacity",
            ["1", "2–3", "3–5", "5+"],
            _simultaneousProjects, (v) => setState(() => _simultaneousProjects = v)),
          buildDropdown("Team Scalability",
            ["Fixed Team", "Scalable Team"],
            _teamScalability, (v) => setState(() => _teamScalability = v)),
        ],
        dividerLine(),

        // ── Section 7: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 7 — Workflow & booking", _ps7,
            () => setState(() => _ps7 = !_ps7)),
        if (_ps7) ...[
          const SizedBox(height: 16),
          buildDropdown("Booking Window",
            ["<7 days", "7–30 days", "1–3 months", "3+ months"],
            _bookingWindow, (v) => setState(() => _bookingWindow = v)),
          buildDropdown("Concept Finalization Timeline",
            ["Same Day", "1–3 days", "3–7 days"],
            _conceptFinalizationTimeline,
            (v) => setState(() => _conceptFinalizationTimeline = v)),
          buildMultiSelect("Shoot Duration Options",
            ["2–4 hours", "Half Day", "Full Day", "Multi-Day"],
            _shootDurationOptions,
            (o, c) => setState(() => c ? _shootDurationOptions.add(o) : _shootDurationOptions.remove(o))),
          buildYesNo("Raw Data Delivery", _rawDataDelivery,
              (v) => setState(() => _rawDataDelivery = v)),
          buildDropdown("Edited Photos Delivery Timeline",
            ["1–3 days", "3–7 days", "7–15 days", "15+ days"],
            _editedPhotosDeliveryTimeline,
            (v) => setState(() => _editedPhotosDeliveryTimeline = v)),
          buildDropdown("Video Delivery Timeline",
            ["3–7 days", "7–15 days", "15–30 days", "30+ days"],
            _videoDeliveryTimeline, (v) => setState(() => _videoDeliveryTimeline = v)),
          buildMultiSelect("Payment Modes",
            ["UPI", "Cash", "Card", "Bank Transfer"],
            _paymentModes,
            (o, c) => setState(() => c ? _paymentModes.add(o) : _paymentModes.remove(o))),
        ],
        dividerLine(),

        // ── Section 8: Portfolio Tagging ────────────────────────────────────
        sectionHeader("Section 8 — Portfolio tagging (AI layer)", _ps8,
            () => setState(() => _ps8 = !_ps8)),
        if (_ps8) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Visual Style Tags",
            ["Cinematic", "Romantic", "Travel Story", "Royal", "Minimal"],
            _visualStyleTags,
            (o, c) => setState(() => c ? _visualStyleTags.add(o) : _visualStyleTags.remove(o))),
          buildMultiSelect("Audience Tags",
            ["Couple", "Engagement", "Save-the-Date"],
            _audienceTags,
            (o, c) => setState(() => c ? _audienceTags.add(o) : _audienceTags.remove(o))),
          buildMultiSelect("Usage Tags",
            ["Instagram", "YouTube", "Wedding Invite Video"],
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
