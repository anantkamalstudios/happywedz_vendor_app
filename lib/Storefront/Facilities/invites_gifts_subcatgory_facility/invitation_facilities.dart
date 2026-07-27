import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class InvitationFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const InvitationFacilities({super.key, required this.attributes});

  @override
  State<InvitationFacilities> createState() => InvitationFacilitiesState();
}

class InvitationFacilitiesState extends State<InvitationFacilities>
    with FacilitiesHelpersMixin<InvitationFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  final        _brandNameCtrl   = TextEditingController();
  String?      _vendorType;
  String?      _yearsOfExperience;
  final        _primaryCityCtrl = TextEditingController();
  List<String> _serviceCities   = [];
  String?      _serviceMode;
  String?      _deliveryModel;

  // ── services ──────────────────────────────────────────────────────────────
  List<String> _invitationTypes  = [];
  List<String> _eventCoverage     = [];
  String?      _designFormats;
  List<String> _languageOptions   = [];

  // ── intelligence ──────────────────────────────────────────────────────────
  List<String> _designStyle             = [];
  String?      _customizationLevel;
  String?      _themeMatchingCapability;
  List<String> _personalizationOptions  = [];
  List<String> _printMaterialOptions    = [];
  List<String> _specialFeatures         = [];

  // ── digital_intelligence ──────────────────────────────────────────────────
  String?      _eInviteFormats;
  List<String> _websiteInviteFeatures = [];
  String?      _rsvpTracking;
  String?      _whatsappIntegration;
  String?      _qrCodeIntegration;

  // ── production ────────────────────────────────────────────────────────────
  String?      _minimumOrderQuantity;
  String?      _maximumOrderCapacity;
  String?      _turnaroundTime;
  String?      _sampleAvailability;
  String?      _proofingProcess;
  String?      _packagingOptions;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _pricingModel;
  String?      _startingPriceRange;
  String?      _digitalInvitePricing;
  List<String> _includes = [];
  List<String> _addOns    = [];
  String?      _negotiationFlexibility;

  // ── scale ─────────────────────────────────────────────────────────────────
  String?      _ordersPerMonthCapacity;
  String?      _teamSize;
  String?      _parallelOrderHandling;

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _advanceBookingTime;
  String?      _bookingAdvancePercent;
  String?      _cancellationPolicy;
  String?      _clientCoordination;

  // ── portfolio ─────────────────────────────────────────────────────────────
  final        _designTagsCtrl = TextEditingController();
  final        _formatTagsCtrl = TextEditingController();
  final        _eventTagsCtrl  = TextEditingController();

  // ── section expansion ─────────────────────────────────────────────────────
  bool _is1 = true;
  bool _is2 = false;
  bool _is3 = false;
  bool _is4 = false;
  bool _is5 = false;
  bool _is6 = false;
  bool _is7 = false;
  bool _is8 = false;
  bool _is9 = false;

  String _clean(dynamic v) =>
      (v == null || v.toString() == 'na') ? '' : v.toString();

  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _brandNameCtrl.dispose();
    _primaryCityCtrl.dispose();
    _designTagsCtrl.dispose();
    _formatTagsCtrl.dispose();
    _eventTagsCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final im = asMap(attrs['invitation_master']);

    final id = asMap(im['identity']);
    _brandNameCtrl.text = id['brand_name']?.toString() ?? '';
    _vendorType         = id['vendor_type'] as String?;
    _yearsOfExperience  = id['years_of_experience'] as String?;
    _primaryCityCtrl.text = id['primary_city']?.toString() ?? '';
    _serviceCities      = toList(id['service_cities']);
    _serviceMode        = id['service_mode'] as String?;
    _deliveryModel      = id['delivery_model'] as String?;

    final sv = asMap(im['services']);
    _invitationTypes = toList(sv['invitation_types']);
    _eventCoverage   = toList(sv['event_coverage']);
    _designFormats   = sv['design_formats'] as String?;
    _languageOptions = toList(sv['language_options']);

    final ci = asMap(im['intelligence']);
    _designStyle            = toList(ci['design_style']);
    _customizationLevel     = ci['customization_level'] as String?;
    _themeMatchingCapability = ci['theme_matching_capability'] as String?;
    _personalizationOptions = toList(ci['personalization_options']);
    _printMaterialOptions   = toList(ci['print_material_options']);
    _specialFeatures        = toList(ci['special_features']);

    final di = asMap(im['digital_intelligence']);
    _eInviteFormats       = di['e_invite_formats'] as String?;
    _websiteInviteFeatures = toList(di['website_invite_features']);
    _rsvpTracking         = di['rsvp_tracking'] as String?;
    _whatsappIntegration  = di['whatsapp_integration'] as String?;
    _qrCodeIntegration    = di['qr_code_integration'] as String?;

    final pd = asMap(im['production']);
    _minimumOrderQuantity = pd['minimum_order_quantity'] as String?;
    _maximumOrderCapacity = pd['maximum_order_capacity'] as String?;
    _turnaroundTime       = pd['turnaround_time'] as String?;
    _sampleAvailability   = pd['sample_availability'] as String?;
    _proofingProcess      = pd['proofing_process'] as String?;
    _packagingOptions     = pd['packaging_options'] as String?;

    final pr = asMap(im['pricing']);
    _pricingModel          = pr['pricing_model'] as String?;
    _startingPriceRange    = pr['starting_price_range'] as String?;
    _digitalInvitePricing  = pr['digital_invite_pricing'] as String?;
    _includes              = toList(pr['includes']);
    _addOns                = toList(pr['add_ons']);
    _negotiationFlexibility = pr['negotiation_flexibility'] as String?;

    final sc = asMap(im['scale']);
    _ordersPerMonthCapacity = sc['orders_per_month_capacity'] as String?;
    _teamSize               = sc['team_size'] as String?;
    _parallelOrderHandling  = sc['parallel_order_handling'] as String?;

    final wf = asMap(im['workflow']);
    _advanceBookingTime    = wf['advance_booking_time'] as String?;
    _bookingAdvancePercent = wf['booking_advance_percent'] as String?;
    _cancellationPolicy    = wf['cancellation_policy'] as String?;
    _clientCoordination    = wf['client_coordination'] as String?;

    final po = asMap(im['portfolio']);
    _designTagsCtrl.text = _clean(po['design_tags']);
    _formatTagsCtrl.text = _clean(po['format_tags']);
    _eventTagsCtrl.text  = _clean(po['event_tags']);
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "brand_name":          _brandNameCtrl.text,
        "vendor_type":         _vendorType,
        "years_of_experience": _yearsOfExperience,
        "primary_city":        _primaryCityCtrl.text,
        "service_cities":      _serviceCities,
        "service_mode":        _serviceMode,
        "delivery_model":      _deliveryModel,
      },
      "services": {
        ...asMap(ex["services"]),
        "invitation_types": _invitationTypes,
        "event_coverage":   _eventCoverage,
        "design_formats":   _designFormats,
        "language_options": _languageOptions,
      },
      "intelligence": {
        ...asMap(ex["intelligence"]),
        "design_style":              _designStyle,
        "customization_level":       _customizationLevel,
        "theme_matching_capability": _themeMatchingCapability,
        "personalization_options":   _personalizationOptions,
        "print_material_options":    _printMaterialOptions,
        "special_features":          _specialFeatures,
      },
      "digital_intelligence": {
        ...asMap(ex["digital_intelligence"]),
        "e_invite_formats":        _eInviteFormats,
        "website_invite_features": _websiteInviteFeatures,
        "rsvp_tracking":           _rsvpTracking,
        "whatsapp_integration":    _whatsappIntegration,
        "qr_code_integration":     _qrCodeIntegration,
      },
      "production": {
        ...asMap(ex["production"]),
        "minimum_order_quantity": _minimumOrderQuantity,
        "maximum_order_capacity": _maximumOrderCapacity,
        "turnaround_time":        _turnaroundTime,
        "sample_availability":    _sampleAvailability,
        "proofing_process":       _proofingProcess,
        "packaging_options":      _packagingOptions,
      },
      "pricing": {
        ...asMap(ex["pricing"]),
        "pricing_model":           _pricingModel,
        "starting_price_range":    _startingPriceRange,
        "digital_invite_pricing":  _digitalInvitePricing,
        "includes":                _includes,
        "add_ons":                 _addOns,
        "negotiation_flexibility": _negotiationFlexibility,
      },
      "scale": {
        ...asMap(ex["scale"]),
        "orders_per_month_capacity": _ordersPerMonthCapacity,
        "team_size":                 _teamSize,
        "parallel_order_handling":   _parallelOrderHandling,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "advance_booking_time":    _advanceBookingTime,
        "booking_advance_percent": _bookingAdvancePercent,
        "cancellation_policy":     _cancellationPolicy,
        "client_coordination":     _clientCoordination,
      },
      "portfolio": {
        ...asMap(ex["portfolio"]),
        "design_tags": _designTagsCtrl.text,
        "format_tags": _formatTagsCtrl.text,
        "event_tags":  _eventTagsCtrl.text,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Invitations Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured invitation attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _is1,
            () => setState(() => _is1 = !_is1)),
        if (_is1) ...[
          const SizedBox(height: 16),
          buildDropdown("Vendor Type",
            ["Invitation Designer (Digital)", "Invitation Printer (Physical)",
             "Full-Service Invitation Studio", "Luxury Invitation Brand",
             "DIY Template Provider"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildTextArea("Brand Name", _brandNameCtrl, maxLines: 1),
          buildDropdown("Years of Experience",
            ["0–1", "1–3", "3–5", "5–10", "10+"],
            _yearsOfExperience, (v) => setState(() => _yearsOfExperience = v)),
          buildTextArea("Primary City", _primaryCityCtrl, maxLines: 1),
          buildMultiSelect("Service Cities",
            ["Pan-India", "International"],
            _serviceCities,
            (o, c) => setState(() => c ? _serviceCities.add(o) : _serviceCities.remove(o))),
          buildDropdown("Service Mode",
            ["Digital Only", "Physical Only", "Hybrid"],
            _serviceMode, (v) => setState(() => _serviceMode = v)),
          buildDropdown("Delivery Model",
            ["Courier", "Pickup", "Pan-India Shipping", "International Shipping"],
            _deliveryModel, (v) => setState(() => _deliveryModel = v)),
        ],
        dividerLine(),

        // ── Section 2: Services Offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _is2,
            () => setState(() => _is2 = !_is2)),
        if (_is2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Invitation Types",
            ["Save the Date", "Wedding Invite Card", "E-Invite", "Video Invite",
             "WhatsApp Invite", "Website Invite", "Box Invitations"],
            _invitationTypes,
            (o, c) => setState(() => c ? _invitationTypes.add(o) : _invitationTypes.remove(o))),
          buildMultiSelect("Event Coverage",
            ["Engagement", "Mehendi", "Haldi", "Sangeet", "Wedding",
             "Reception", "Multi-day Wedding Suite"],
            _eventCoverage,
            (o, c) => setState(() => c ? _eventCoverage.add(o) : _eventCoverage.remove(o))),
          buildDropdown("Design Formats",
            ["Static Design", "Animated Invite", "Video Invite", "Interactive Website"],
            _designFormats, (v) => setState(() => _designFormats = v)),
          buildMultiSelect("Language Options",
            ["English", "Hindi", "Marathi", "Gujarati", "Punjabi",
             "Tamil", "Telugu", "Bengali", "Multi-language"],
            _languageOptions,
            (o, c) => setState(() => c ? _languageOptions.add(o) : _languageOptions.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _is3,
            () => setState(() => _is3 = !_is3)),
        if (_is3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Design Style",
            ["Royal / Regal", "Minimal / Elegant", "Floral / Pastel",
             "Modern / Contemporary", "Traditional / Cultural", "Illustrated / Caricature"],
            _designStyle,
            (o, c) => setState(() => c ? _designStyle.add(o) : _designStyle.remove(o))),
          buildDropdown("Customization Level",
            ["Fully Custom", "Semi-Custom", "Template-Based"],
            _customizationLevel, (v) => setState(() => _customizationLevel = v)),
          buildDropdown("Theme Matching Capability",
            ["Yes (Full wedding theme sync)", "Partial", "No"],
            _themeMatchingCapability, (v) => setState(() => _themeMatchingCapability = v)),
          buildMultiSelect("Personalization Options",
            ["Names", "Monogram", "Couple Story", "Photos",
             "Venue Illustration", "Custom Artwork"],
            _personalizationOptions,
            (o, c) => setState(() => c ? _personalizationOptions.add(o) : _personalizationOptions.remove(o))),
          buildMultiSelect("Print Material Options",
            ["Paper (Matte / Gloss)", "Handmade Paper", "Acrylic",
             "Fabric (Silk)", "Wood", "Metal"],
            _printMaterialOptions,
            (o, c) => setState(() => c ? _printMaterialOptions.add(o) : _printMaterialOptions.remove(o))),
          buildMultiSelect("Special Features",
            ["Laser Cut", "Foil Printing", "Embossing / Debossing",
             "UV Print", "Scented Invites", "LED / Music Box Invites"],
            _specialFeatures,
            (o, c) => setState(() => c ? _specialFeatures.add(o) : _specialFeatures.remove(o))),
        ],
        dividerLine(),

        // ── Section 4: Digital Intelligence ────────────────────────────────
        sectionHeader("Section 4 — Digital intelligence", _is4,
            () => setState(() => _is4 = !_is4)),
        if (_is4) ...[
          const SizedBox(height: 16),
          buildDropdown("E-Invite Formats",
            ["PDF", "GIF", "MP4 Video", "Interactive Link"],
            _eInviteFormats, (v) => setState(() => _eInviteFormats = v)),
          buildMultiSelect("Website Invite Features",
            ["RSVP Management", "Event Schedule", "Google Maps Integration",
             "Photo Gallery", "Countdown Timer", "Guest Messaging"],
            _websiteInviteFeatures,
            (o, c) => setState(() => c ? _websiteInviteFeatures.add(o) : _websiteInviteFeatures.remove(o))),
          buildYesNo("RSVP Tracking", _rsvpTracking,
              (v) => setState(() => _rsvpTracking = v)),
          buildYesNo("WhatsApp Integration", _whatsappIntegration,
              (v) => setState(() => _whatsappIntegration = v)),
          buildYesNo("QR Code Integration", _qrCodeIntegration,
              (v) => setState(() => _qrCodeIntegration = v)),
        ],
        dividerLine(),

        // ── Section 5: Production & Logistics ──────────────────────────────
        sectionHeader("Section 5 — Production & logistics", _is5,
            () => setState(() => _is5 = !_is5)),
        if (_is5) ...[
          const SizedBox(height: 16),
          buildDropdown("Minimum Order Quantity (Physical)",
            ["1–50", "50–100", "100–300", "300+"],
            _minimumOrderQuantity, (v) => setState(() => _minimumOrderQuantity = v)),
          buildDropdown("Maximum Order Capacity",
            ["100", "100–500", "500–1000", "1000+"],
            _maximumOrderCapacity, (v) => setState(() => _maximumOrderCapacity = v)),
          buildDropdown("Turnaround Time",
            ["2–5 days (Digital)", "5–10 days", "10–20 days", "20+ days"],
            _turnaroundTime, (v) => setState(() => _turnaroundTime = v)),
          buildYesNo("Sample Availability", _sampleAvailability,
              (v) => setState(() => _sampleAvailability = v)),
          buildDropdown("Proofing Process",
            ["Digital Proof", "Physical Sample", "Both"],
            _proofingProcess, (v) => setState(() => _proofingProcess = v)),
          buildDropdown("Packaging Options",
            ["Basic Packaging", "Premium Boxes", "Customized Boxes"],
            _packagingOptions, (v) => setState(() => _packagingOptions = v)),
        ],
        dividerLine(),

        // ── Section 6: Pricing Logic ───────────────────────────────────────
        sectionHeader("Section 6 — Pricing logic", _is6,
            () => setState(() => _is6 = !_is6)),
        if (_is6) ...[
          const SizedBox(height: 16),
          buildDropdown("Pricing Model",
            ["Per Card", "Per Design", "Per Video", "Package"],
            _pricingModel, (v) => setState(() => _pricingModel = v)),
          buildDropdown("Starting Price Range",
            ["₹20–₹50/card", "₹50–₹150/card", "₹150–₹500/card",
             "₹500–₹2000/card", "₹2000+ (Luxury)"],
            _startingPriceRange, (v) => setState(() => _startingPriceRange = v)),
          buildDropdown("Digital Invite Pricing",
            ["₹500–₹2k", "₹2k–₹5k", "₹5k–₹15k", "₹15k+"],
            _digitalInvitePricing, (v) => setState(() => _digitalInvitePricing = v)),
          buildMultiSelect("Includes",
            ["Design", "Printing", "Packaging", "Delivery", "Revisions"],
            _includes,
            (o, c) => setState(() => c ? _includes.add(o) : _includes.remove(o))),
          buildMultiSelect("Add-ons",
            ["Extra Revisions", "Express Delivery", "Premium Materials", "Custom Artwork"],
            _addOns,
            (o, c) => setState(() => c ? _addOns.add(o) : _addOns.remove(o))),
          buildDropdown("Negotiation Flexibility",
            ["Fixed", "Moderate", "Flexible"],
            _negotiationFlexibility, (v) => setState(() => _negotiationFlexibility = v)),
        ],
        dividerLine(),

        // ── Section 7: Scale & Operations ──────────────────────────────────
        sectionHeader("Section 7 — Scale & operations", _is7,
            () => setState(() => _is7 = !_is7)),
        if (_is7) ...[
          const SizedBox(height: 16),
          buildDropdown("Orders Per Month Capacity",
            ["<50", "50–200", "200–500", "500+"],
            _ordersPerMonthCapacity, (v) => setState(() => _ordersPerMonthCapacity = v)),
          buildDropdown("Team Size",
            ["Solo", "2–5", "5–10", "10+"],
            _teamSize, (v) => setState(() => _teamSize = v)),
          buildYesNo("Parallel Order Handling", _parallelOrderHandling,
              (v) => setState(() => _parallelOrderHandling = v)),
        ],
        dividerLine(),

        // ── Section 8: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 8 — Workflow & booking", _is8,
            () => setState(() => _is8 = !_is8)),
        if (_is8) ...[
          const SizedBox(height: 16),
          buildDropdown("Advance Booking Time",
            ["<1 week", "1–2 weeks", "2–4 weeks", "1–2 months"],
            _advanceBookingTime, (v) => setState(() => _advanceBookingTime = v)),
          buildDropdown("Booking Advance %",
            ["25%", "50%", "75%", "100%"],
            _bookingAdvancePercent, (v) => setState(() => _bookingAdvancePercent = v)),
          buildDropdown("Cancellation Policy",
            ["Non-refundable", "Partial refund", "Flexible"],
            _cancellationPolicy, (v) => setState(() => _cancellationPolicy = v)),
          buildDropdown("Client Coordination",
            ["WhatsApp", "Call", "Email", "App-based"],
            _clientCoordination, (v) => setState(() => _clientCoordination = v)),
        ],
        dividerLine(),

        // ── Section 9: Portfolio Tagging ───────────────────────────────────
        sectionHeader("Section 9 — Portfolio tagging (AI layer)", _is9,
            () => setState(() => _is9 = !_is9)),
        if (_is9) ...[
          const SizedBox(height: 8),
          Text(
            "Tag your portfolio uploads to enable AI search. Design e.g. Luxury / Minimal / Royal; Format e.g. Digital First / Box Invites; Event e.g. Big Fat / Intimate / Destination Wedding.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          buildTextArea("Design Tags", _designTagsCtrl, maxLines: 2),
          buildTextArea("Format Tags", _formatTagsCtrl, maxLines: 2),
          buildTextArea("Event Tags", _eventTagsCtrl, maxLines: 2),
        ],
      ],
    );
  }
}
