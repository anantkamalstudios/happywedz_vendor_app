import 'package:flutter/material.dart';
import '../facilities_helpers.dart';


class DjFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const DjFacilities({super.key, required this.attributes});

  @override
  State<DjFacilities> createState() => DjFacilitiesState();
}

class DjFacilitiesState extends State<DjFacilities>
    with FacilitiesHelpersMixin<DjFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  String?      _vendorType;
  final        _brandNameCtrl  = TextEditingController();
  final        _yearsExpCtrl   = TextEditingController();
  final        _primaryCityCtrl = TextEditingController();
  List<String> _serviceCities  = [];
  String?      _travelPolicy;
  List<String> _languages      = [];

  // ── services ──────────────────────────────────────────────────────────────
  List<String> _eventTypes        = [];
  List<String> _djFormats         = [];
  List<String> _additionalServices = [];

  // ── core_intelligence ─────────────────────────────────────────────────────
  List<String> _musicGenres             = [];
  String?      _crowdHandling;
  String?      _specializationStyle;
  String?      _liveMixingCapability;
  String?      _customPlaylistSupport;
  String?      _songRequestHandling;
  List<String> _entrySync               = [];
  String?      _baraatDjSetup;
  String?      _backupDjAvailable;

  // ── technical_setup ───────────────────────────────────────────────────────
  String?      _equipmentOwnership;
  String?      _soundSetupCapability;
  String?      _lightingSetup;
  List<String> _consoleTypes    = [];
  String?      _powerBackup;
  String?      _setupTimeRequired;
  String?      _technicalTeamSize;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _pricingModel;
  String?      _startingPriceRange;
  List<String> _includes        = [];
  List<String> _addonCharges    = [];
  String?      _peakSeasonPricing;
  String?      _negotiationFlexibility;

  // ── scale_capacity ────────────────────────────────────────────────────────
  String?      _maxEventsPerDay;
  String?      _concurrentEvents;
  String?      _teamMultiEvent;

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _advanceBookingTime;
  String?      _bookingAdvancePercent;
  String?      _cancellationPolicy;
  String?      _coordinationMode;
  String?      _preEventPlanningCall;

  // ── portfolio_tagging ─────────────────────────────────────────────────────
  List<String> _eventMoodTags              = [];
  List<String> _musicStyleTags             = [];
  String?      _celebrityBigEventExperience;

  // ── section expansion ─────────────────────────────────────────────────────
  bool _ds1 = true;
  bool _ds2 = false;
  bool _ds3 = false;
  bool _ds4 = false;
  bool _ds5 = false;
  bool _ds6 = false;
  bool _ds7 = false;
  bool _ds8 = false;

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
    final dm = asMap(attrs['dj_master']);

    final id = asMap(dm['identity']);
    _vendorType              = id['vendor_type'] as String?;
    _brandNameCtrl.text      = id['brand_name']?.toString() ?? '';
    _yearsExpCtrl.text       = id['years_of_experience']?.toString() ?? '';
    _primaryCityCtrl.text    = id['primary_city']?.toString() ?? '';
    _serviceCities           = toList(id['service_cities']);
    _travelPolicy            = id['travel_policy'] as String?;
    _languages               = toList(id['languages']);

    final sv = asMap(dm['services']);
    _eventTypes         = toList(sv['event_types']);
    _djFormats          = toList(sv['dj_formats']);
    _additionalServices = toList(sv['additional_services']);

    final ci = asMap(dm['core_intelligence']);
    _musicGenres           = toList(ci['music_genres']);
    _crowdHandling         = ci['crowd_handling'] as String?;
    _specializationStyle   = ci['specialization_style'] as String?;
    _liveMixingCapability  = ci['live_mixing_capability'] as String?;
    _customPlaylistSupport = ci['custom_playlist_support'] as String?;
    _songRequestHandling   = ci['song_request_handling'] as String?;
    _entrySync             = toList(ci['entry_sync']);
    _baraatDjSetup         = ci['baraat_dj_setup'] as String?;
    _backupDjAvailable     = ci['backup_dj_available'] as String?;

    final ts = asMap(dm['technical_setup']);
    _equipmentOwnership  = ts['equipment_ownership'] as String?;
    _soundSetupCapability = ts['sound_setup_capability'] as String?;
    _lightingSetup       = ts['lighting_setup'] as String?;
    _consoleTypes        = toList(ts['console_types']);
    _powerBackup         = ts['power_backup'] as String?;
    _setupTimeRequired   = ts['setup_time_required'] as String?;
    _technicalTeamSize   = ts['technical_team_size'] as String?;

    final pr = asMap(dm['pricing']);
    _pricingModel          = pr['pricing_model'] as String?;
    _startingPriceRange    = pr['starting_price_range'] as String?;
    _includes              = toList(pr['includes']);
    _addonCharges          = toList(pr['addon_charges']);
    _peakSeasonPricing     = pr['peak_season_pricing'] as String?;
    _negotiationFlexibility = pr['negotiation_flexibility'] as String?;

    final sc = asMap(dm['scale_capacity']);
    _maxEventsPerDay  = sc['max_events_per_day'] as String?;
    _concurrentEvents = sc['concurrent_events'] as String?;
    _teamMultiEvent   = sc['team_multi_event'] as String?;

    final wf = asMap(dm['workflow']);
    _advanceBookingTime    = wf['advance_booking_time'] as String?;
    _bookingAdvancePercent = wf['booking_advance_percent'] as String?;
    _cancellationPolicy    = wf['cancellation_policy'] as String?;
    _coordinationMode      = wf['coordination_mode'] as String?;
    _preEventPlanningCall  = wf['pre_event_planning_call'] as String?;

    final pt = asMap(dm['portfolio_tagging']);
    _eventMoodTags               = toList(pt['event_mood_tags']);
    _musicStyleTags              = toList(pt['music_style_tags']);
    _celebrityBigEventExperience = pt['celebrity_big_event_experience'] as String?;
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
        "event_types":         _eventTypes,
        "dj_formats":          _djFormats,
        "additional_services": _additionalServices,
      },
      "core_intelligence": {
        ...asMap(ex["core_intelligence"]),
        "music_genres":            _musicGenres,
        "crowd_handling":          _crowdHandling,
        "specialization_style":    _specializationStyle,
        "live_mixing_capability":  _liveMixingCapability,
        "custom_playlist_support": _customPlaylistSupport,
        "song_request_handling":   _songRequestHandling,
        "entry_sync":              _entrySync,
        "baraat_dj_setup":         _baraatDjSetup,
        "backup_dj_available":     _backupDjAvailable,
      },
      "technical_setup": {
        ...asMap(ex["technical_setup"]),
        "equipment_ownership":   _equipmentOwnership,
        "sound_setup_capability": _soundSetupCapability,
        "lighting_setup":        _lightingSetup,
        "console_types":         _consoleTypes,
        "power_backup":          _powerBackup,
        "setup_time_required":   _setupTimeRequired,
        "technical_team_size":   _technicalTeamSize,
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
        "max_events_per_day": _maxEventsPerDay,
        "concurrent_events":  _concurrentEvents,
        "team_multi_event":   _teamMultiEvent,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "advance_booking_time":    _advanceBookingTime,
        "booking_advance_percent": _bookingAdvancePercent,
        "cancellation_policy":     _cancellationPolicy,
        "coordination_mode":       _coordinationMode,
        "pre_event_planning_call": _preEventPlanningCall,
      },
      "portfolio_tagging": {
        ...asMap(ex["portfolio_tagging"]),
        "event_mood_tags":               _eventMoodTags,
        "music_style_tags":              _musicStyleTags,
        "celebrity_big_event_experience": _celebrityBigEventExperience,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DJ Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured DJ attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Identity ───────────────────────────────────────────
        sectionHeader("Section 1 — Identity", _ds1,
            () => setState(() => _ds1 = !_ds1)),
        if (_ds1) ...[
          const SizedBox(height: 16),
          buildDropdown("Vendor Type",
            ["Solo DJ", "DJ + Console Setup", "DJ + Full Sound & Light Team", "DJ Agency / Collective"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildNumberField("Years of Experience", _yearsExpCtrl),
          buildTextArea("Primary City", _primaryCityCtrl, maxLines: 1),
          buildMultiSelect("Service Cities",
            ["Pan-India", "International", "Delhi NCR", "Mumbai", "Bangalore",
             "Hyderabad", "Chennai", "Kolkata", "Pune", "Ahmedabad",
             "Jaipur", "Chandigarh", "Lucknow", "Goa", "Other"],
            _serviceCities,
            (o, c) => setState(() => c ? _serviceCities.add(o) : _serviceCities.remove(o))),
          buildDropdown("Travel Policy",
            ["Included within city", "Extra (fixed cost)", "Extra (per km)", "Case-by-case"],
            _travelPolicy, (v) => setState(() => _travelPolicy = v)),
          buildMultiSelect("Languages",
            ["English", "Hindi", "Marathi", "Punjabi", "Gujarati",
             "Tamil", "Telugu", "Bengali", "Multi-language"],
            _languages,
            (o, c) => setState(() => c ? _languages.add(o) : _languages.remove(o))),
        ],
        dividerLine(),

        // ── Section 2: Services ───────────────────────────────────────────
        sectionHeader("Section 2 — Services", _ds2,
            () => setState(() => _ds2 = !_ds2)),
        if (_ds2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Event Types",
            ["Wedding Sangeet", "Cocktail Night", "Reception", "Baraat",
             "After Party", "Engagement", "Haldi", "Mehendi", "Corporate", "Private Party"],
            _eventTypes,
            (o, c) => setState(() => c ? _eventTypes.add(o) : _eventTypes.remove(o))),
          buildMultiSelect("DJ Formats",
            ["Club Style", "Wedding Style", "Bollywood Specialist", "Open Format", "Regional Specialist"],
            _djFormats,
            (o, c) => setState(() => c ? _djFormats.add(o) : _djFormats.remove(o))),
          buildMultiSelect("Additional Services",
            ["Live Dhol Integration", "Saxophone with DJ", "LED Dance Floor",
             "Cold Pyros Sync", "CO2 Guns", "Smoke Effects", "Laser Show",
             "Visual LED Screen Sync", "Live Mashups", "Custom Entry Tracks"],
            _additionalServices,
            (o, c) => setState(() => c ? _additionalServices.add(o) : _additionalServices.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ─────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _ds3,
            () => setState(() => _ds3 = !_ds3)),
        if (_ds3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Music Genres",
            ["Bollywood", "Punjabi", "EDM", "House", "Commercial", "Hip-Hop",
             "Retro", "Techno", "Regional Folk", "Sufi", "International Pop"],
            _musicGenres,
            (o, c) => setState(() => c ? _musicGenres.add(o) : _musicGenres.remove(o))),
          buildDropdown("Crowd Handling Capacity",
            ["<100 guests", "100–300", "300–700", "700–1500", "1500+"],
            _crowdHandling, (v) => setState(() => _crowdHandling = v)),
          buildDropdown("Specialization Style",
            ["High Energy", "Classy / Lounge", "Fusion / Mashups",
             "Cultural Weddings", "Youth-centric"],
            _specializationStyle, (v) => setState(() => _specializationStyle = v)),
          buildDropdown("Live Mixing Capability",
            ["Basic", "Advanced", "Professional Club-Level"],
            _liveMixingCapability, (v) => setState(() => _liveMixingCapability = v)),
          buildDropdown("Custom Playlist Support",
            ["Yes (Full customization)", "Partial", "No"],
            _customPlaylistSupport, (v) => setState(() => _customPlaylistSupport = v)),
          buildDropdown("Song Request Handling",
            ["Real-time", "Curated only", "Restricted"],
            _songRequestHandling, (v) => setState(() => _songRequestHandling = v)),
          buildMultiSelect("Entry Sync",
            ["Bride Entry Sync", "Groom Entry Sync", "Couple Entry Sync", "Dance Performances Sync"],
            _entrySync,
            (o, c) => setState(() => c ? _entrySync.add(o) : _entrySync.remove(o))),
          buildYesNo("Baraat DJ Setup Available", _baraatDjSetup,
              (v) => setState(() => _baraatDjSetup = v)),
          buildYesNo("Backup DJ Available", _backupDjAvailable,
              (v) => setState(() => _backupDjAvailable = v)),
        ],
        dividerLine(),

        // ── Section 4: Technical Setup ────────────────────────────────────
        sectionHeader("Section 4 — Technical setup", _ds4,
            () => setState(() => _ds4 = !_ds4)),
        if (_ds4) ...[
          const SizedBox(height: 16),
          buildDropdown("Equipment Ownership",
            ["Own Equipment", "Rental Based", "Hybrid"],
            _equipmentOwnership, (v) => setState(() => _equipmentOwnership = v)),
          buildDropdown("Sound Setup Capability",
            ["Basic (up to 100 pax)", "Medium (100–500 pax)",
             "Large (500–1500 pax)", "Stadium Scale"],
            _soundSetupCapability, (v) => setState(() => _soundSetupCapability = v)),
          buildDropdown("Lighting Setup",
            ["Basic Lights", "Intelligent Moving Heads", "Full Production Lighting"],
            _lightingSetup, (v) => setState(() => _lightingSetup = v)),
          buildMultiSelect("Console Types",
            ["Pioneer", "Denon", "Numark", "Others"],
            _consoleTypes,
            (o, c) => setState(() => c ? _consoleTypes.add(o) : _consoleTypes.remove(o))),
          buildYesNo("Power Backup Available", _powerBackup,
              (v) => setState(() => _powerBackup = v)),
          buildDropdown("Setup Time Required",
            ["<1 hour", "1–3 hours", "3–6 hours"],
            _setupTimeRequired, (v) => setState(() => _setupTimeRequired = v)),
          buildDropdown("Technical Team Size",
            ["1–2", "3–5", "5–10", "10+"],
            _technicalTeamSize, (v) => setState(() => _technicalTeamSize = v)),
        ],
        dividerLine(),

        // ── Section 5: Pricing ────────────────────────────────────────────
        sectionHeader("Section 5 — Pricing", _ds5,
            () => setState(() => _ds5 = !_ds5)),
        if (_ds5) ...[
          const SizedBox(height: 16),
          buildDropdown("Pricing Model",
            ["Per Event", "Per Hour", "Per Day", "Package Based"],
            _pricingModel, (v) => setState(() => _pricingModel = v)),
          buildDropdown("Starting Price Range",
            ["₹10k–₹25k", "₹25k–₹50k", "₹50k–₹1L", "₹1L–₹2L", "₹2L+"],
            _startingPriceRange, (v) => setState(() => _startingPriceRange = v)),
          buildMultiSelect("Includes",
            ["DJ Only", "Console", "Sound", "Lights", "Setup & Dismantle", "Travel"],
            _includes,
            (o, c) => setState(() => c ? _includes.add(o) : _includes.remove(o))),
          buildMultiSelect("Add-on Charges",
            ["Travel", "Accommodation", "Extra Hours", "Special Effects"],
            _addonCharges,
            (o, c) => setState(() => c ? _addonCharges.add(o) : _addonCharges.remove(o))),
          buildYesNo("Peak Season Pricing", _peakSeasonPricing,
              (v) => setState(() => _peakSeasonPricing = v)),
          buildDropdown("Negotiation Flexibility",
            ["Fixed", "Slightly Flexible", "Highly Flexible"],
            _negotiationFlexibility, (v) => setState(() => _negotiationFlexibility = v)),
        ],
        dividerLine(),

        // ── Section 6: Scale Capacity ─────────────────────────────────────
        sectionHeader("Section 6 — Scale capacity", _ds6,
            () => setState(() => _ds6 = !_ds6)),
        if (_ds6) ...[
          const SizedBox(height: 16),
          buildDropdown("Max Events Per Day",
            ["1", "2", "3+"],
            _maxEventsPerDay, (v) => setState(() => _maxEventsPerDay = v)),
          buildYesNo("Concurrent Events Handled", _concurrentEvents,
              (v) => setState(() => _concurrentEvents = v)),
          buildYesNo("Team Available for Multi-Event", _teamMultiEvent,
              (v) => setState(() => _teamMultiEvent = v)),
        ],
        dividerLine(),

        // ── Section 7: Workflow ───────────────────────────────────────────
        sectionHeader("Section 7 — Workflow", _ds7,
            () => setState(() => _ds7 = !_ds7)),
        if (_ds7) ...[
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
          buildDropdown("Coordination Mode",
            ["WhatsApp", "Call", "In-person", "App-based"],
            _coordinationMode, (v) => setState(() => _coordinationMode = v)),
          buildYesNo("Pre-Event Planning Call", _preEventPlanningCall,
              (v) => setState(() => _preEventPlanningCall = v)),
        ],
        dividerLine(),

        // ── Section 8: Portfolio Tagging ──────────────────────────────────
        sectionHeader("Section 8 — Portfolio tagging", _ds8,
            () => setState(() => _ds8 = !_ds8)),
        if (_ds8) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Event Mood Tags",
            ["Royal", "Minimal", "High Energy", "Luxury", "Intimate", "Cultural"],
            _eventMoodTags,
            (o, c) => setState(() => c ? _eventMoodTags.add(o) : _eventMoodTags.remove(o))),
          buildMultiSelect("Music Style Tags",
            ["Bollywood Night", "EDM Night", "Punjabi Night", "Retro Night", "Fusion Night"],
            _musicStyleTags,
            (o, c) => setState(() => c ? _musicStyleTags.add(o) : _musicStyleTags.remove(o))),
          buildYesNo("Celebrity / Big Event Experience", _celebrityBigEventExperience,
              (v) => setState(() => _celebrityBigEventExperience = v)),
        ],
      ],
    );
  }
}
