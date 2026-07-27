import 'package:flutter/material.dart';
import 'facilities_helpers.dart';

class MehendiFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const MehendiFacilities({super.key, required this.attributes});

  @override
  State<MehendiFacilities> createState() => MehendiFacilitiesState();
}

class MehendiFacilitiesState extends State<MehendiFacilities>
    with FacilitiesHelpersMixin<MehendiFacilities> {

  // identity
  final        _mhBrandNameCtrl    = TextEditingController();
  String?      _mhArtistType;
  final        _mhYearsExpCtrl     = TextEditingController();
  String?      _mhTravelAvailability;
  String?      _mhTeamSize;
  // services
  List<String> _mhServicesOffered  = [];
  List<String> _mhCoverageType     = [];
  // style_intelligence
  List<String> _mhMehendiStyle     = [];
  String?      _mhDesignComplexity;
  List<String> _mhBestKnownFor     = [];
  String?      _mhCustomDesigns;
  List<String> _mhPersonalization  = [];
  // bridal_details
  String?      _mhBridalCoverage;
  String?      _mhBridalDuration;
  final        _mhBridalPriceCtrl  = TextEditingController();
  // guest_capacity
  String?      _mhGuestsPerHour;
  String?      _mhMaxGuests;
  String?      _mhGuestPricingModel;
  String?      _mhTeamSupportGuests;
  // material_quality
  String?      _mhMehendiType;
  String?      _mhColorGuarantee;
  String?      _mhAftercare;
  String?      _mhAllergies;
  // event_suitability
  List<String> _mhFunctionsCovered = [];
  List<String> _mhBestFor          = [];
  // speed_execution
  String?      _mhApplicationSpeed;
  String?      _mhParallelArtists;
  String?      _mhMultipleEvents;
  // pricing_travel
  String?      _mhTravelCharges;
  String?      _mhStayRequirement;
  String?      _mhMinBookingValue;
  // workflow
  String?      _mhAdvanceRequired;
  String?      _mhAdvancePercentage;
  String?      _mhBookingTimeline;
  String?      _mhCancellationPolicy;
  // portfolio_tagging
  final        _mhTagsCtrl         = TextEditingController();
  final        _mhPortfolioNotes   = TextEditingController();

  // Section expansion
  bool _mhs1  = true;
  bool _mhs2  = false;
  bool _mhs3  = false;
  bool _mhs4  = false;
  bool _mhs5  = false;
  bool _mhs6  = false;
  bool _mhs7  = false;
  bool _mhs8  = false;
  bool _mhs9  = false;
  bool _mhs10 = false;
  bool _mhs11 = false;

  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _mhBrandNameCtrl.dispose();
    _mhYearsExpCtrl.dispose();
    _mhBridalPriceCtrl.dispose();
    _mhTagsCtrl.dispose();
    _mhPortfolioNotes.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final mm = asMap(attrs['mehndi_artist_master']);

    final identity = asMap(mm['identity']);
    _mhBrandNameCtrl.text = identity['brand_name']?.toString() ?? '';
    _mhArtistType         = identity['artist_type'] as String?;
    _mhYearsExpCtrl.text  = identity['years_of_experience']?.toString() ?? '';
    _mhTravelAvailability = identity['travel_availability'] as String?;
    _mhTeamSize           = identity['team_size'] as String?;

    final services = asMap(mm['services']);
    _mhServicesOffered = toList(services['services_offered']);
    _mhCoverageType    = toList(services['coverage_type']);

    final style = asMap(mm['style_intelligence']);
    _mhMehendiStyle     = toList(style['mehendi_style']);
    _mhDesignComplexity = style['design_complexity'] as String?;
    _mhBestKnownFor     = toList(style['best_known_for']);
    _mhCustomDesigns    = style['custom_designs_available'] as String?;
    _mhPersonalization  = toList(style['personalization_options']);

    final bridal = asMap(mm['bridal_details']);
    _mhBridalCoverage       = bridal['bridal_coverage'] as String?;
    _mhBridalDuration       = bridal['bridal_duration'] as String?;
    _mhBridalPriceCtrl.text = bridal['bridal_starting_price']?.toString() ?? '';

    final guest = asMap(mm['guest_capacity']);
    _mhGuestsPerHour     = guest['guests_per_hour'] as String?;
    _mhMaxGuests         = guest['max_guests_covered'] as String?;
    _mhGuestPricingModel = guest['guest_pricing_model'] as String?;
    _mhTeamSupportGuests = guest['team_support_for_guests'] as String?;

    final material = asMap(mm['material_quality']);
    _mhMehendiType    = material['mehendi_type'] as String?;
    _mhColorGuarantee = material['color_guarantee'] as String?;
    _mhAftercare      = material['aftercare_instructions_provided'] as String?;
    _mhAllergies      = material['allergies_consideration'] as String?;

    final event = asMap(mm['event_suitability']);
    _mhFunctionsCovered = toList(event['functions_covered']);
    _mhBestFor          = toList(event['best_for']);

    final speed = asMap(mm['speed_execution']);
    _mhApplicationSpeed = speed['application_speed'] as String?;
    _mhParallelArtists  = speed['parallel_artists_available'] as String?;
    _mhMultipleEvents   = speed['multiple_events_handling'] as String?;

    final pricing = asMap(mm['pricing_travel']);
    _mhTravelCharges   = pricing['travel_charges'] as String?;
    _mhStayRequirement = pricing['stay_requirement'] as String?;
    _mhMinBookingValue = pricing['minimum_booking_value'] as String?;

    final wf = asMap(mm['workflow']);
    _mhAdvanceRequired    = wf['advance_required'] as String?;
    _mhAdvancePercentage  = wf['advance_percentage'] as String?;
    _mhBookingTimeline    = wf['booking_timeline'] as String?;
    _mhCancellationPolicy = wf['cancellation_policy'] as String?;

    final portfolio = asMap(mm['portfolio_tagging']);
    _mhTagsCtrl.text       = portfolio['tags']?.toString() ?? '';
    _mhPortfolioNotes.text = portfolio['notes']?.toString() ?? '';
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "brand_name":          _mhBrandNameCtrl.text,
        "artist_type":         _mhArtistType,
        "years_of_experience": _mhYearsExpCtrl.text,
        "travel_availability": _mhTravelAvailability,
        "team_size":           _mhTeamSize,
      },
      "services": {
        ...asMap(ex["services"]),
        "services_offered": _mhServicesOffered,
        "coverage_type":    _mhCoverageType,
      },
      "style_intelligence": {
        ...asMap(ex["style_intelligence"]),
        "mehendi_style":            _mhMehendiStyle,
        "design_complexity":        _mhDesignComplexity,
        "best_known_for":           _mhBestKnownFor,
        "custom_designs_available": _mhCustomDesigns,
        "personalization_options":  _mhPersonalization,
      },
      "bridal_details": {
        ...asMap(ex["bridal_details"]),
        "bridal_coverage":       _mhBridalCoverage,
        "bridal_duration":       _mhBridalDuration,
        "bridal_starting_price": _mhBridalPriceCtrl.text,
      },
      "guest_capacity": {
        ...asMap(ex["guest_capacity"]),
        "guests_per_hour":         _mhGuestsPerHour,
        "max_guests_covered":      _mhMaxGuests,
        "guest_pricing_model":     _mhGuestPricingModel,
        "team_support_for_guests": _mhTeamSupportGuests,
      },
      "material_quality": {
        ...asMap(ex["material_quality"]),
        "mehendi_type":                    _mhMehendiType,
        "color_guarantee":                 _mhColorGuarantee,
        "aftercare_instructions_provided": _mhAftercare,
        "allergies_consideration":         _mhAllergies,
      },
      "event_suitability": {
        ...asMap(ex["event_suitability"]),
        "functions_covered": _mhFunctionsCovered,
        "best_for":          _mhBestFor,
      },
      "speed_execution": {
        ...asMap(ex["speed_execution"]),
        "application_speed":          _mhApplicationSpeed,
        "parallel_artists_available": _mhParallelArtists,
        "multiple_events_handling":   _mhMultipleEvents,
      },
      "pricing_travel": {
        ...asMap(ex["pricing_travel"]),
        "travel_charges":        _mhTravelCharges,
        "stay_requirement":      _mhStayRequirement,
        "minimum_booking_value": _mhMinBookingValue,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "advance_required":    _mhAdvanceRequired,
        "advance_percentage":  _mhAdvancePercentage,
        "booking_timeline":    _mhBookingTimeline,
        "cancellation_policy": _mhCancellationPolicy,
      },
      "portfolio_tagging": {
        ...asMap(ex["portfolio_tagging"]),
        "tags":  _mhTagsCtrl.text,
        "notes": _mhPortfolioNotes.text,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Mehendi Artist Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured mehendi artist attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _mhs1,
            () => setState(() => _mhs1 = !_mhs1)),
        if (_mhs1) ...[
          const SizedBox(height: 16),
          buildTextArea("Artist / Brand Name", _mhBrandNameCtrl, maxLines: 1),
          buildDropdown("Artist Type",
            ["Individual", "Team / Group", "Studio"],
            _mhArtistType, (v) => setState(() => _mhArtistType = v)),
          buildNumberField("Years of Experience", _mhYearsExpCtrl),
          buildDropdown("Travel Availability",
            ["Local Only", "Pan India", "International"],
            _mhTravelAvailability, (v) => setState(() => _mhTravelAvailability = v)),
          buildDropdown("Team Size",
            ["Solo", "2–5 Artists", "5–10 Artists", "10+ Artists"],
            _mhTeamSize, (v) => setState(() => _mhTeamSize = v)),
        ],
        dividerLine(),

        // ── Section 2: Services offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _mhs2,
            () => setState(() => _mhs2 = !_mhs2)),
        if (_mhs2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Services Offered",
            ["Bridal Mehendi", "Guest Mehendi", "Engagement Mehendi",
             "Baby Shower Mehendi", "Festive Mehendi"],
            _mhServicesOffered,
            (o, c) => setState(
                () => c ? _mhServicesOffered.add(o) : _mhServicesOffered.remove(o))),
          buildMultiSelect("Coverage Type",
            ["Bridal Only", "Guests Only", "Both"],
            _mhCoverageType,
            (o, c) => setState(
                () => c ? _mhCoverageType.add(o) : _mhCoverageType.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Design style intelligence ──────────────────────────
        sectionHeader("Section 3 — Design style intelligence", _mhs3,
            () => setState(() => _mhs3 = !_mhs3)),
        if (_mhs3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Mehendi Style",
            ["Traditional", "Arabic", "Indo-Arabic", "Moroccan", "Rajasthani",
             "Minimal", "Modern", "Portrait Mehendi"],
            _mhMehendiStyle,
            (o, c) => setState(
                () => c ? _mhMehendiStyle.add(o) : _mhMehendiStyle.remove(o))),
          buildDropdown("Design Complexity",
            ["Simple", "Moderate", "Intricate", "Highly Detailed"],
            _mhDesignComplexity, (v) => setState(() => _mhDesignComplexity = v)),
          buildMultiSelect("Best Known For",
            ["Intricate Bridal Designs", "Fast Guest Application",
             "Unique Concepts", "Portrait Mehendi", "Minimal Designs"],
            _mhBestKnownFor,
            (o, c) => setState(
                () => c ? _mhBestKnownFor.add(o) : _mhBestKnownFor.remove(o))),
          buildDropdown("Custom Designs Available",
            ["Yes", "No"],
            _mhCustomDesigns, (v) => setState(() => _mhCustomDesigns = v)),
          buildMultiSelect("Personalization Options",
            ["Couple Names", "Wedding Dates", "Story-Based Designs", "Portrait Designs"],
            _mhPersonalization,
            (o, c) => setState(
                () => c ? _mhPersonalization.add(o) : _mhPersonalization.remove(o))),
        ],
        dividerLine(),

        // ── Section 4: Bridal mehendi details ─────────────────────────────
        sectionHeader("Section 4 — Bridal mehendi details", _mhs4,
            () => setState(() => _mhs4 = !_mhs4)),
        if (_mhs4) ...[
          const SizedBox(height: 16),
          buildDropdown("Bridal Mehendi Coverage",
            ["Hands Only", "Hands + Feet", "Full Arms + Feet"],
            _mhBridalCoverage, (v) => setState(() => _mhBridalCoverage = v)),
          buildDropdown("Bridal Mehendi Duration",
            ["2–4 Hours", "4–6 Hours", "6–8 Hours", "8+ Hours"],
            _mhBridalDuration, (v) => setState(() => _mhBridalDuration = v)),
          buildNumberField("Bridal Mehendi Starting Price (₹)", _mhBridalPriceCtrl),
        ],
        dividerLine(),

        // ── Section 5: Guest handling capacity ────────────────────────────
        sectionHeader("Section 5 — Guest handling capacity", _mhs5,
            () => setState(() => _mhs5 = !_mhs5)),
        if (_mhs5) ...[
          const SizedBox(height: 16),
          buildDropdown("Guests Covered Per Hour",
            ["5–10", "10–20", "20–40", "40+"],
            _mhGuestsPerHour, (v) => setState(() => _mhGuestsPerHour = v)),
          buildDropdown("Max Guests Covered",
            ["Up to 20", "20–50", "50–100", "100+"],
            _mhMaxGuests, (v) => setState(() => _mhMaxGuests = v)),
          buildDropdown("Guest Mehendi Pricing",
            ["Per Hand", "Per Hour", "Package Based"],
            _mhGuestPricingModel, (v) => setState(() => _mhGuestPricingModel = v)),
          buildYesNo("Team Support for Guests", _mhTeamSupportGuests,
              (v) => setState(() => _mhTeamSupportGuests = v)),
        ],
        dividerLine(),

        // ── Section 6: Material & quality ─────────────────────────────────
        sectionHeader("Section 6 — Material & quality", _mhs6,
            () => setState(() => _mhs6 = !_mhs6)),
        if (_mhs6) ...[
          const SizedBox(height: 16),
          buildDropdown("Mehendi Type",
            ["Natural Henna", "Organic Henna", "Chemical-Based"],
            _mhMehendiType, (v) => setState(() => _mhMehendiType = v)),
          buildDropdown("Color Guarantee",
            ["Dark Color Guaranteed", "No Guarantee"],
            _mhColorGuarantee, (v) => setState(() => _mhColorGuarantee = v)),
          buildYesNo("Aftercare Instructions Provided", _mhAftercare,
              (v) => setState(() => _mhAftercare = v)),
          buildYesNo("Allergies Consideration", _mhAllergies,
              (v) => setState(() => _mhAllergies = v)),
        ],
        dividerLine(),

        // ── Section 7: Event suitability ──────────────────────────────────
        sectionHeader("Section 7 — Event suitability", _mhs7,
            () => setState(() => _mhs7 = !_mhs7)),
        if (_mhs7) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Functions Covered",
            ["Mehendi Ceremony", "Engagement", "Haldi", "Pre-Wedding Events"],
            _mhFunctionsCovered,
            (o, c) => setState(
                () => c ? _mhFunctionsCovered.add(o) : _mhFunctionsCovered.remove(o))),
          buildMultiSelect("Best For",
            ["Bridal Mehendi", "Large Guest Mehendi",
             "Intimate Functions", "Destination Weddings"],
            _mhBestFor,
            (o, c) => setState(
                () => c ? _mhBestFor.add(o) : _mhBestFor.remove(o))),
        ],
        dividerLine(),

        // ── Section 8: Speed & execution ──────────────────────────────────
        sectionHeader("Section 8 — Speed & execution", _mhs8,
            () => setState(() => _mhs8 = !_mhs8)),
        if (_mhs8) ...[
          const SizedBox(height: 16),
          buildDropdown("Application Speed",
            ["Fast", "Moderate", "Detailed (Time Intensive)"],
            _mhApplicationSpeed, (v) => setState(() => _mhApplicationSpeed = v)),
          buildYesNo("Parallel Artists Available", _mhParallelArtists,
              (v) => setState(() => _mhParallelArtists = v)),
          buildYesNo("Multiple Events Handling", _mhMultipleEvents,
              (v) => setState(() => _mhMultipleEvents = v)),
        ],
        dividerLine(),

        // ── Section 9: Pricing & travel ────────────────────────────────────
        sectionHeader("Section 9 — Pricing & travel", _mhs9,
            () => setState(() => _mhs9 = !_mhs9)),
        if (_mhs9) ...[
          const SizedBox(height: 16),
          buildDropdown("Travel Charges",
            ["Included", "Extra", "Depends on Location"],
            _mhTravelCharges, (v) => setState(() => _mhTravelCharges = v)),
          buildYesNo("Stay Requirement", _mhStayRequirement,
              (v) => setState(() => _mhStayRequirement = v)),
          buildDropdown("Minimum Booking Value",
            ["Below ₹5K", "₹5K–₹10K", "₹10K–₹20K", "₹20K+"],
            _mhMinBookingValue, (v) => setState(() => _mhMinBookingValue = v)),
        ],
        dividerLine(),

        // ── Section 10: Workflow & booking ────────────────────────────────
        sectionHeader("Section 10 — Workflow & booking", _mhs10,
            () => setState(() => _mhs10 = !_mhs10)),
        if (_mhs10) ...[
          const SizedBox(height: 16),
          buildYesNo("Advance Required", _mhAdvanceRequired,
              (v) => setState(() => _mhAdvanceRequired = v)),
          buildDropdown("Advance Percentage", ["25%", "50%", "75%"],
            _mhAdvancePercentage, (v) => setState(() => _mhAdvancePercentage = v)),
          buildDropdown("Booking Timeline",
            ["1 Week Before", "1 Month Before", "3 Months Before"],
            _mhBookingTimeline, (v) => setState(() => _mhBookingTimeline = v)),
          buildDropdown("Cancellation Policy",
            ["Non Refundable", "Partial Refund", "Flexible"],
            _mhCancellationPolicy, (v) => setState(() => _mhCancellationPolicy = v)),
        ],
        dividerLine(),

        // ── Section 11: Portfolio intelligence ────────────────────────────
        sectionHeader("Section 11 — Portfolio intelligence", _mhs11,
            () => setState(() => _mhs11 = !_mhs11)),
        if (_mhs11) ...[
          const SizedBox(height: 8),
          Text(
            "Upload designs in the Photos tab. Use this block for default portfolio tagging.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          buildTextArea("Default Portfolio Tags", _mhTagsCtrl, maxLines: 2),
          buildTextArea("Portfolio Notes", _mhPortfolioNotes),
        ],
      ],
    );
  }
}
