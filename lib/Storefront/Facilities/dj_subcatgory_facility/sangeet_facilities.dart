import 'package:flutter/material.dart';

import '../facilities_helpers.dart';


class SangeetFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const SangeetFacilities({super.key, required this.attributes});

  @override
  State<SangeetFacilities> createState() => SangeetFacilitiesState();
}

class SangeetFacilitiesState extends State<SangeetFacilities>
    with FacilitiesHelpersMixin<SangeetFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  String?      _vendorType;
  final        _brandNameCtrl   = TextEditingController();
  final        _yearsExpCtrl    = TextEditingController();
  final        _primaryCityCtrl = TextEditingController();
  List<String> _serviceCities   = [];
  String?      _travelPolicy;
  List<String> _languages       = [];

  // ── services ──────────────────────────────────────────────────────────────
  List<String> _eventTypes        = [];
  List<String> _danceFormats      = [];
  List<String> _specialOfferings  = [];

  // ── core_intelligence ─────────────────────────────────────────────────────
  List<String> _danceStyles            = [];
  String?      _skillLevelHandling;
  List<String> _ageGroupHandling       = [];
  String?      _maxParticipantsPerAct;
  String?      _storyBasedChoreography;
  String?      _customizationLevel;
  String?      _musicSelectionSupport;
  String?      _rehearsalMode;
  String?      _performancePolishLevel;

  // ── training_rehearsal ────────────────────────────────────────────────────
  String?      _rehearsalDuration;
  String?      _sessionDuration;
  String?      _practiceLocation;
  String?      _travelForPractice;
  String?      _assistantAvailability;
  String?      _lastMinutePracticeSupport;

  // ── performance_execution ─────────────────────────────────────────────────
  String?      _onEventPresence;
  String?      _backstageCoordination;
  String?      _entryTransitionPlanning;
  String?      _musicEditingMixing;
  String?      _propsSupport;
  String?      _costumeGuidance;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _pricingModel;
  String?      _startingPriceRange;
  List<String> _includes        = [];
  List<String> _addonCharges    = [];
  String?      _peakSeasonPricing;
  String?      _negotiationFlexibility;

  // ── scale_capacity ────────────────────────────────────────────────────────
  String?      _maxEventsPerDay;
  String?      _parallelEventHandling;
  String?      _teamSize;

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _advanceBookingTime;
  String?      _bookingAdvancePercent;
  String?      _cancellationPolicy;
  String?      _coordinationMode;
  String?      _trialSessionAvailability;

  // ── portfolio_tagging ─────────────────────────────────────────────────────
  List<String> _performanceStyleTags  = [];
  List<String> _eventScaleTags        = [];
  List<String> _choreographyStyleTags = [];

  // ── section expansion ─────────────────────────────────────────────────────
  bool _ss1 = true;
  bool _ss2 = false;
  bool _ss3 = false;
  bool _ss4 = false;
  bool _ss5 = false;
  bool _ss6 = false;
  bool _ss7 = false;
  bool _ss8 = false;
  bool _ss9 = false;

  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _brandNameCtrl.dispose();
    _yearsExpCtrl.dispose();
    _primaryCityCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final cm = asMap(attrs['choreographer_master']);

    final id = asMap(cm['identity']);
    _vendorType           = id['vendor_type'] as String?;
    _brandNameCtrl.text   = id['brand_name']?.toString() ?? '';
    _yearsExpCtrl.text    = id['years_of_experience']?.toString() ?? '';
    _primaryCityCtrl.text = id['primary_city']?.toString() ?? '';
    _serviceCities        = toList(id['service_cities']);
    _travelPolicy         = id['travel_policy'] as String?;
    _languages            = toList(id['languages']);

    final sv = asMap(cm['services']);
    _eventTypes       = toList(sv['event_types']);
    _danceFormats     = toList(sv['dance_formats']);
    _specialOfferings = toList(sv['special_offerings']);

    final ci = asMap(cm['core_intelligence']);
    _danceStyles            = toList(ci['dance_styles']);
    _skillLevelHandling     = ci['skill_level_handling'] as String?;
    _ageGroupHandling       = toList(ci['age_group_handling']);
    _maxParticipantsPerAct  = ci['max_participants_per_act'] as String?;
    _storyBasedChoreography = ci['story_based_choreography'] as String?;
    _customizationLevel     = ci['customization_level'] as String?;
    _musicSelectionSupport  = ci['music_selection_support'] as String?;
    _rehearsalMode          = ci['rehearsal_mode'] as String?;
    _performancePolishLevel = ci['performance_polish_level'] as String?;

    final tr = asMap(cm['training_rehearsal']);
    _rehearsalDuration         = tr['rehearsal_duration'] as String?;
    _sessionDuration           = tr['session_duration'] as String?;
    _practiceLocation          = tr['practice_location'] as String?;
    _travelForPractice         = tr['travel_for_practice'] as String?;
    _assistantAvailability     = tr['assistant_availability'] as String?;
    _lastMinutePracticeSupport = tr['last_minute_practice_support'] as String?;

    final pe = asMap(cm['performance_execution']);
    _onEventPresence         = pe['on_event_presence'] as String?;
    _backstageCoordination   = pe['backstage_coordination'] as String?;
    _entryTransitionPlanning = pe['entry_transition_planning'] as String?;
    _musicEditingMixing      = pe['music_editing_mixing'] as String?;
    _propsSupport            = pe['props_support'] as String?;
    _costumeGuidance         = pe['costume_guidance'] as String?;

    final pr = asMap(cm['pricing']);
    _pricingModel          = pr['pricing_model'] as String?;
    _startingPriceRange    = pr['starting_price_range'] as String?;
    _includes              = toList(pr['includes']);
    _addonCharges          = toList(pr['addon_charges']);
    _peakSeasonPricing     = pr['peak_season_pricing'] as String?;
    _negotiationFlexibility = pr['negotiation_flexibility'] as String?;

    final sc = asMap(cm['scale_capacity']);
    _maxEventsPerDay       = sc['max_events_per_day'] as String?;
    _parallelEventHandling = sc['parallel_event_handling'] as String?;
    _teamSize              = sc['team_size'] as String?;

    final wf = asMap(cm['workflow']);
    _advanceBookingTime       = wf['advance_booking_time'] as String?;
    _bookingAdvancePercent    = wf['booking_advance_percent'] as String?;
    _cancellationPolicy       = wf['cancellation_policy'] as String?;
    _coordinationMode         = wf['coordination_mode'] as String?;
    _trialSessionAvailability = wf['trial_session_availability'] as String?;

    final pt = asMap(cm['portfolio_tagging']);
    _performanceStyleTags  = toList(pt['performance_style_tags']);
    _eventScaleTags        = toList(pt['event_scale_tags']);
    _choreographyStyleTags = toList(pt['choreography_style_tags']);
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "vendor_type":         _vendorType,
        "brand_name":          _brandNameCtrl.text,
        "years_of_experience": _yearsExpCtrl.text,
        "primary_city":        _primaryCityCtrl.text,
        "service_cities":      _serviceCities,
        "travel_policy":       _travelPolicy,
        "languages":           _languages,
      },
      "services": {
        ...asMap(ex["services"]),
        "event_types":       _eventTypes,
        "dance_formats":     _danceFormats,
        "special_offerings": _specialOfferings,
      },
      "core_intelligence": {
        ...asMap(ex["core_intelligence"]),
        "dance_styles":             _danceStyles,
        "skill_level_handling":     _skillLevelHandling,
        "age_group_handling":       _ageGroupHandling,
        "max_participants_per_act": _maxParticipantsPerAct,
        "story_based_choreography": _storyBasedChoreography,
        "customization_level":      _customizationLevel,
        "music_selection_support":  _musicSelectionSupport,
        "rehearsal_mode":           _rehearsalMode,
        "performance_polish_level": _performancePolishLevel,
      },
      "training_rehearsal": {
        ...asMap(ex["training_rehearsal"]),
        "rehearsal_duration":           _rehearsalDuration,
        "session_duration":             _sessionDuration,
        "practice_location":            _practiceLocation,
        "travel_for_practice":          _travelForPractice,
        "assistant_availability":       _assistantAvailability,
        "last_minute_practice_support": _lastMinutePracticeSupport,
      },
      "performance_execution": {
        ...asMap(ex["performance_execution"]),
        "on_event_presence":         _onEventPresence,
        "backstage_coordination":    _backstageCoordination,
        "entry_transition_planning": _entryTransitionPlanning,
        "music_editing_mixing":      _musicEditingMixing,
        "props_support":             _propsSupport,
        "costume_guidance":          _costumeGuidance,
      },
      "pricing": {
        ...asMap(ex["pricing"]),
        "pricing_model":           _pricingModel,
        "starting_price_range":    _startingPriceRange,
        "includes":                _includes,
        "addon_charges":           _addonCharges,
        "peak_season_pricing":     _peakSeasonPricing,
        "negotiation_flexibility": _negotiationFlexibility,
      },
      "scale_capacity": {
        ...asMap(ex["scale_capacity"]),
        "max_events_per_day":      _maxEventsPerDay,
        "parallel_event_handling": _parallelEventHandling,
        "team_size":               _teamSize,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "advance_booking_time":       _advanceBookingTime,
        "booking_advance_percent":    _bookingAdvancePercent,
        "cancellation_policy":        _cancellationPolicy,
        "coordination_mode":          _coordinationMode,
        "trial_session_availability": _trialSessionAvailability,
      },
      "portfolio_tagging": {
        ...asMap(ex["portfolio_tagging"]),
        "performance_style_tags":  _performanceStyleTags,
        "event_scale_tags":        _eventScaleTags,
        "choreography_style_tags": _choreographyStyleTags,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Sangeet Choreographer Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured choreographer attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _ss1,
            () => setState(() => _ss1 = !_ss1)),
        if (_ss1) ...[
          const SizedBox(height: 16),
          buildDropdown("Vendor Type",
            ["Solo Choreographer", "Choreographer + Assistant Team",
             "Dance Company", "Celebrity Choreography Team"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildTextArea("Brand Name", _brandNameCtrl, maxLines: 1),
          buildDropdown("Years of Experience",
            ["0–1", "1–3", "3–5", "5–10", "10+"],
            _yearsExpCtrl.text.isEmpty ? null : _yearsExpCtrl.text,
            (v) => setState(() => _yearsExpCtrl.text = v ?? '')),
          buildTextArea("Primary City", _primaryCityCtrl, maxLines: 1),
          buildMultiSelect("Service Cities",
            ["Pan-India", "International", "Delhi NCR", "Mumbai", "Pune",
             "Jaipur", "Chandigarh", "Lucknow", "Goa", "Other"],
            _serviceCities,
            (o, c) => setState(() => c ? _serviceCities.add(o) : _serviceCities.remove(o))),
          buildDropdown("Travel Policy",
            ["Included (local)", "Extra (fixed)", "Extra (per km)", "Case-by-case"],
            _travelPolicy, (v) => setState(() => _travelPolicy = v)),
          buildMultiSelect("Languages",
            ["English", "Hindi", "Marathi", "Punjabi", "Gujarati",
             "Tamil", "Telugu", "Bengali", "Multi-language"],
            _languages,
            (o, c) => setState(() => c ? _languages.add(o) : _languages.remove(o))),
        ],
        dividerLine(),

        // ── Section 2: Services Offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _ss2,
            () => setState(() => _ss2 = !_ss2)),
        if (_ss2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Event Types",
            ["Sangeet", "Cocktail Dance Night", "Engagement",
             "Wedding Performances", "Reception Performances",
             "Haldi Fun Performances", "Family Dance Acts"],
            _eventTypes,
            (o, c) => setState(() => c ? _eventTypes.add(o) : _eventTypes.remove(o))),
          buildMultiSelect("Dance Formats",
            ["Solo Performances", "Couple Performances", "Group Performances",
             "Family Acts", "Thematic Acts"],
            _danceFormats,
            (o, c) => setState(() => c ? _danceFormats.add(o) : _danceFormats.remove(o))),
          buildMultiSelect("Special Offerings",
            ["Bride Solo Performance", "Groom Solo Performance",
             "Couple Love Story Act", "Family Mashup", "Kids Performances",
             "Flash Mob", "Surprise Entries"],
            _specialOfferings,
            (o, c) => setState(() => c ? _specialOfferings.add(o) : _specialOfferings.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _ss3,
            () => setState(() => _ss3 = !_ss3)),
        if (_ss3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Dance Styles Expertise",
            ["Bollywood", "Semi-Classical", "Classical (Kathak / Bharatnatyam)",
             "Hip-Hop", "Contemporary", "Bhangra", "Garba / Dandiya",
             "Freestyle", "Fusion"],
            _danceStyles,
            (o, c) => setState(() => c ? _danceStyles.add(o) : _danceStyles.remove(o))),
          buildDropdown("Skill Level Handling",
            ["Beginner Friendly", "Intermediate", "Advanced Dancers"],
            _skillLevelHandling, (v) => setState(() => _skillLevelHandling = v)),
          buildMultiSelect("Age Group Handling",
            ["Kids", "Teens", "Adults", "Seniors"],
            _ageGroupHandling,
            (o, c) => setState(() => c ? _ageGroupHandling.add(o) : _ageGroupHandling.remove(o))),
          buildDropdown("Max Participants per Act",
            ["1–5", "5–10", "10–20", "20–50", "50+"],
            _maxParticipantsPerAct, (v) => setState(() => _maxParticipantsPerAct = v)),
          buildYesNo("Story-Based Choreography", _storyBasedChoreography,
              (v) => setState(() => _storyBasedChoreography = v)),
          buildDropdown("Customization Level",
            ["Fully Customized", "Semi-Customized", "Template-Based"],
            _customizationLevel, (v) => setState(() => _customizationLevel = v)),
          buildDropdown("Music Selection Support",
            ["Yes (Full curation)", "Yes (Partial)", "No"],
            _musicSelectionSupport, (v) => setState(() => _musicSelectionSupport = v)),
          buildDropdown("Rehearsal Mode",
            ["In-person", "Online", "Hybrid"],
            _rehearsalMode, (v) => setState(() => _rehearsalMode = v)),
          buildDropdown("Performance Polish Level",
            ["Basic", "Stage-Ready", "Professional Show-Level"],
            _performancePolishLevel, (v) => setState(() => _performancePolishLevel = v)),
        ],
        dividerLine(),

        // ── Section 4: Training & Rehearsal Logistics ─────────────────────
        sectionHeader("Section 4 — Training & rehearsal", _ss4,
            () => setState(() => _ss4 = !_ss4)),
        if (_ss4) ...[
          const SizedBox(height: 16),
          buildDropdown("Rehearsal Duration per Act",
            ["1–2 sessions", "3–5 sessions", "5–10 sessions", "10+ sessions"],
            _rehearsalDuration, (v) => setState(() => _rehearsalDuration = v)),
          buildDropdown("Session Duration",
            ["1 hour", "2 hours", "3+ hours"],
            _sessionDuration, (v) => setState(() => _sessionDuration = v)),
          buildDropdown("Practice Location",
            ["Client Venue", "Choreographer Studio", "Both"],
            _practiceLocation, (v) => setState(() => _practiceLocation = v)),
          buildDropdown("Travel for Practice",
            ["Included", "Chargeable"],
            _travelForPractice, (v) => setState(() => _travelForPractice = v)),
          buildYesNo("Assistant Availability", _assistantAvailability,
              (v) => setState(() => _assistantAvailability = v)),
          buildYesNo("Last-Minute Practice Support", _lastMinutePracticeSupport,
              (v) => setState(() => _lastMinutePracticeSupport = v)),
        ],
        dividerLine(),

        // ── Section 5: Performance Execution ───────────────────────────────
        sectionHeader("Section 5 — Performance execution", _ss5,
            () => setState(() => _ss5 = !_ss5)),
        if (_ss5) ...[
          const SizedBox(height: 16),
          buildDropdown("On-Event Presence",
            ["Full-time coordination", "Limited presence", "Not required"],
            _onEventPresence, (v) => setState(() => _onEventPresence = v)),
          buildYesNo("Backstage Coordination", _backstageCoordination,
              (v) => setState(() => _backstageCoordination = v)),
          buildYesNo("Entry & Transition Planning", _entryTransitionPlanning,
              (v) => setState(() => _entryTransitionPlanning = v)),
          buildDropdown("Music Editing & Mixing",
            ["Included", "Chargeable", "Not Provided"],
            _musicEditingMixing, (v) => setState(() => _musicEditingMixing = v)),
          buildYesNo("Props Support", _propsSupport,
              (v) => setState(() => _propsSupport = v)),
          buildYesNo("Costume Guidance", _costumeGuidance,
              (v) => setState(() => _costumeGuidance = v)),
        ],
        dividerLine(),

        // ── Section 6: Pricing Logic ───────────────────────────────────────
        sectionHeader("Section 6 — Pricing logic", _ss6,
            () => setState(() => _ss6 = !_ss6)),
        if (_ss6) ...[
          const SizedBox(height: 16),
          buildDropdown("Pricing Model",
            ["Per Performance", "Per Person", "Per Session", "Full Package"],
            _pricingModel, (v) => setState(() => _pricingModel = v)),
          buildDropdown("Starting Price Range",
            ["₹5k–₹15k", "₹15k–₹30k", "₹30k–₹60k", "₹60k–₹1L", "₹1L+"],
            _startingPriceRange, (v) => setState(() => _startingPriceRange = v)),
          buildMultiSelect("Includes",
            ["Choreography", "Practice Sessions", "Music Editing",
             "Event Day Coordination", "Assistants"],
            _includes,
            (o, c) => setState(() => c ? _includes.add(o) : _includes.remove(o))),
          buildMultiSelect("Add-on Charges",
            ["Travel", "Extra Sessions", "Props", "Costumes"],
            _addonCharges,
            (o, c) => setState(() => c ? _addonCharges.add(o) : _addonCharges.remove(o))),
          buildYesNo("Peak Season Pricing", _peakSeasonPricing,
              (v) => setState(() => _peakSeasonPricing = v)),
          buildDropdown("Negotiation Flexibility",
            ["Fixed", "Slightly Flexible", "Highly Flexible"],
            _negotiationFlexibility, (v) => setState(() => _negotiationFlexibility = v)),
        ],
        dividerLine(),

        // ── Section 7: Scale & Capacity ────────────────────────────────────
        sectionHeader("Section 7 — Scale & capacity", _ss7,
            () => setState(() => _ss7 = !_ss7)),
        if (_ss7) ...[
          const SizedBox(height: 16),
          buildDropdown("Max Events Per Day",
            ["1", "2", "3+"],
            _maxEventsPerDay, (v) => setState(() => _maxEventsPerDay = v)),
          buildYesNo("Parallel Event Handling", _parallelEventHandling,
              (v) => setState(() => _parallelEventHandling = v)),
          buildDropdown("Team Size",
            ["Solo", "2–5", "5–10", "10+"],
            _teamSize, (v) => setState(() => _teamSize = v)),
        ],
        dividerLine(),

        // ── Section 8: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 8 — Workflow & booking", _ss8,
            () => setState(() => _ss8 = !_ss8)),
        if (_ss8) ...[
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
          buildDropdown("Client Coordination Mode",
            ["WhatsApp", "Call", "In-person", "App-based"],
            _coordinationMode, (v) => setState(() => _coordinationMode = v)),
          buildYesNo("Trial Session Availability", _trialSessionAvailability,
              (v) => setState(() => _trialSessionAvailability = v)),
        ],
        dividerLine(),

        // ── Section 9: Portfolio Tagging ────────────────────────────────────
        sectionHeader("Section 9 — Portfolio tagging (AI layer)", _ss9,
            () => setState(() => _ss9 = !_ss9)),
        if (_ss9) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Performance Style Tags",
            ["Romantic", "High Energy", "Emotional",
             "Fun & Quirky", "Traditional", "Filmy"],
            _performanceStyleTags,
            (o, c) => setState(() => c ? _performanceStyleTags.add(o) : _performanceStyleTags.remove(o))),
          buildMultiSelect("Event Scale Tags",
            ["Intimate", "Mid-size", "Grand"],
            _eventScaleTags,
            (o, c) => setState(() => c ? _eventScaleTags.add(o) : _eventScaleTags.remove(o))),
          buildMultiSelect("Choreography Style Tags",
            ["Storytelling", "Beat-based", "Expression-driven", "Performance-heavy"],
            _choreographyStyleTags,
            (o, c) => setState(() => c ? _choreographyStyleTags.add(o) : _choreographyStyleTags.remove(o))),
        ],
      ],
    );
  }
}
