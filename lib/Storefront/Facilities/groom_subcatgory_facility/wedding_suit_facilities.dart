import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class WeddingSuitFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const WeddingSuitFacilities({super.key, required this.attributes});

  @override
  State<WeddingSuitFacilities> createState() => WeddingSuitFacilitiesState();
}

class WeddingSuitFacilitiesState extends State<WeddingSuitFacilities>
    with FacilitiesHelpersMixin<WeddingSuitFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  String?      _vendorType;
  final        _brandNameCtrl = TextEditingController();
  String?      _sellOnEcommerce;
  List<String> _storePresence = [];
  final        _cityCtrl      = TextEditingController();
  String?      _storeAccessType;
  String?      _yearsOfExperience;
  List<String> _specialization = [];

  // ── services ──────────────────────────────────────────────────────────────
  List<String> _serviceModes      = [];
  String?      _trialAvailability;
  String?      _stylingConsultation;
  String?      _fabricSelectionAssistance;
  String?      _homeMeasurementService;
  String?      _alterationServices;
  String?      _expressDeliveryAvailable;
  List<String> _accessoryAddOns   = [];

  // ── intelligence ──────────────────────────────────────────────────────────
  List<String> _suitTypes           = [];
  List<String> _occasionSuitability = [];
  List<String> _fitType             = [];
  List<String> _fabricOptions       = [];
  List<String> _seasonSuitability   = [];
  List<String> _designStyle         = [];
  List<String> _colorPalette        = [];

  // ── technical ─────────────────────────────────────────────────────────────
  String?      _stitchingType;
  String?      _canvasConstruction;
  List<String> _customizationDepth = [];
  List<String> _lapelTypes         = [];
  List<String> _closureType        = [];
  String?      _numberOfButtons;
  String?      _durabilityLevel;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _priceRange;
  String?      _customizationCharges;
  String?      _fabricCostStructure;
  String?      _accessoryBundlePricing;
  String?      _bulkOrderDiscounts;

  // ── capacity ──────────────────────────────────────────────────────────────
  String?      _dailyClientCapacity;
  String?      _monthlyProductionCapacity;
  String?      _trialRoomAvailability;

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _appointmentRequired;
  List<String> _measurementProcess = [];
  String?      _leadTime;
  String?      _trialRounds;
  String?      _alterationTimeline;
  List<String> _paymentModes       = [];
  String?      _advancePayment;

  // ── portfolio ─────────────────────────────────────────────────────────────
  List<String> _styleTags    = [];
  List<String> _audienceTags = [];
  List<String> _usageTags    = [];
  String?      _priceSegmentTags;

  // ── section expansion ─────────────────────────────────────────────────────
  bool _ws1 = true;
  bool _ws2 = false;
  bool _ws3 = false;
  bool _ws4 = false;
  bool _ws5 = false;
  bool _ws6 = false;
  bool _ws7 = false;
  bool _ws8 = false;

  String? _ynFromBool(dynamic v) =>
      v == null ? null : (v == true ? "Yes" : "No");

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
    final wm = asMap(attrs['wedding_suit_master']);

    final id = asMap(wm['identity']);
    _vendorType         = id['vendor_type'] as String?;
    _brandNameCtrl.text = id['brand_name']?.toString() ?? '';
    _sellOnEcommerce    = _ynFromBool(id['sell_on_ecommerce']);
    _storePresence      = toList(id['store_presence']);
    _cityCtrl.text      = id['city']?.toString() ?? '';
    _storeAccessType    = id['store_access_type'] as String?;
    _yearsOfExperience  = id['years_of_experience'] as String?;
    _specialization     = toList(id['specialization']);

    final sv = asMap(wm['services']);
    _serviceModes              = toList(sv['service_modes']);
    _trialAvailability         = sv['trial_availability'] as String?;
    _stylingConsultation       = sv['styling_consultation'] as String?;
    _fabricSelectionAssistance = sv['fabric_selection_assistance'] as String?;
    _homeMeasurementService    = sv['home_measurement_service'] as String?;
    _alterationServices        = sv['alteration_services'] as String?;
    _expressDeliveryAvailable  = sv['express_delivery_available'] as String?;
    _accessoryAddOns           = toList(sv['accessory_add_ons']);

    final ci = asMap(wm['intelligence']);
    _suitTypes           = toList(ci['suit_types']);
    _occasionSuitability = toList(ci['occasion_suitability']);
    _fitType             = toList(ci['fit_type']);
    _fabricOptions       = toList(ci['fabric_options']);
    _seasonSuitability   = toList(ci['season_suitability']);
    _designStyle         = toList(ci['design_style']);
    _colorPalette        = toList(ci['color_palette']);

    final te = asMap(wm['technical']);
    _stitchingType      = te['stitching_type'] as String?;
    _canvasConstruction = te['canvas_construction'] as String?;
    _customizationDepth = toList(te['customization_depth']);
    _lapelTypes         = toList(te['lapel_types']);
    _closureType        = toList(te['closure_type']);
    _numberOfButtons    = te['number_of_buttons']?.toString();
    _durabilityLevel    = te['durability_level'] as String?;

    final pr = asMap(wm['pricing']);
    _priceRange             = pr['price_range'] as String?;
    _customizationCharges   = pr['customization_charges'] as String?;
    _fabricCostStructure    = pr['fabric_cost_structure'] as String?;
    _accessoryBundlePricing = pr['accessory_bundle_pricing'] as String?;
    _bulkOrderDiscounts     = pr['bulk_order_discounts'] as String?;

    final cap = asMap(wm['capacity']);
    _dailyClientCapacity       = cap['daily_client_capacity'] as String?;
    _monthlyProductionCapacity = cap['monthly_production_capacity'] as String?;
    _trialRoomAvailability     = cap['trial_room_availability'] as String?;

    final wf = asMap(wm['workflow']);
    _appointmentRequired = wf['appointment_required'] as String?;
    _measurementProcess  = toList(wf['measurement_process']);
    _leadTime            = wf['lead_time'] as String?;
    _trialRounds         = wf['trial_rounds']?.toString();
    _alterationTimeline  = wf['alteration_timeline'] as String?;
    _paymentModes        = toList(wf['payment_modes']);
    _advancePayment      = wf['advance_payment'] as String?;

    final po = asMap(wm['portfolio']);
    _styleTags        = toList(po['style_tags']);
    _audienceTags     = toList(po['audience_tags']);
    _usageTags        = toList(po['usage_tags']);
    _priceSegmentTags = po['price_segment_tags'] as String?;
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "vendor_type":         _vendorType,
        "brand_name":          _brandNameCtrl.text,
        "sell_on_ecommerce":   _sellOnEcommerce == "Yes",
        "store_presence":      _storePresence,
        "city":                _cityCtrl.text,
        "store_access_type":   _storeAccessType,
        "years_of_experience": _yearsOfExperience,
        "specialization":      _specialization,
      },
      "services": {
        ...asMap(ex["services"]),
        "service_modes":               _serviceModes,
        "trial_availability":          _trialAvailability,
        "styling_consultation":        _stylingConsultation,
        "fabric_selection_assistance": _fabricSelectionAssistance,
        "home_measurement_service":    _homeMeasurementService,
        "alteration_services":         _alterationServices,
        "express_delivery_available":  _expressDeliveryAvailable,
        "accessory_add_ons":           _accessoryAddOns,
      },
      "intelligence": {
        ...asMap(ex["intelligence"]),
        "suit_types":           _suitTypes,
        "occasion_suitability": _occasionSuitability,
        "fit_type":             _fitType,
        "fabric_options":       _fabricOptions,
        "season_suitability":   _seasonSuitability,
        "design_style":         _designStyle,
        "color_palette":        _colorPalette,
      },
      "technical": {
        ...asMap(ex["technical"]),
        "stitching_type":      _stitchingType,
        "canvas_construction": _canvasConstruction,
        "customization_depth": _customizationDepth,
        "lapel_types":         _lapelTypes,
        "closure_type":        _closureType,
        "number_of_buttons":   _numberOfButtons,
        "durability_level":    _durabilityLevel,
      },
      "pricing": {
        ...asMap(ex["pricing"]),
        "price_range":              _priceRange,
        "customization_charges":    _customizationCharges,
        "fabric_cost_structure":    _fabricCostStructure,
        "accessory_bundle_pricing": _accessoryBundlePricing,
        "bulk_order_discounts":     _bulkOrderDiscounts,
      },
      "capacity": {
        ...asMap(ex["capacity"]),
        "daily_client_capacity":       _dailyClientCapacity,
        "monthly_production_capacity": _monthlyProductionCapacity,
        "trial_room_availability":     _trialRoomAvailability,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "appointment_required": _appointmentRequired,
        "measurement_process":  _measurementProcess,
        "lead_time":            _leadTime,
        "trial_rounds":         _trialRounds,
        "alteration_timeline":  _alterationTimeline,
        "payment_modes":        _paymentModes,
        "advance_payment":      _advancePayment,
      },
      "portfolio": {
        ...asMap(ex["portfolio"]),
        "style_tags":         _styleTags,
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
        const Text("Wedding Suit Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured wedding suit attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _ws1,
            () => setState(() => _ws1 = !_ws1)),
        if (_ws1) ...[
          const SizedBox(height: 16),
          buildDropdown("Vendor Type",
            ["Tailor / Bespoke Studio", "Ready-to-Wear Retailer", "Designer Studio",
             "Multi-Brand Store", "Online Suit Brand"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildTextArea("Brand Name", _brandNameCtrl, maxLines: 1),
          buildDropdown("Sell on E-commerce",
            ["Yes", "No"],
            _sellOnEcommerce, (v) => setState(() => _sellOnEcommerce = v)),
          buildMultiSelect("Store Presence",
            ["Physical Store", "Online Store", "Both"],
            _storePresence,
            (o, c) => setState(() => c ? _storePresence.add(o) : _storePresence.remove(o))),
          buildTextArea("City", _cityCtrl, maxLines: 1),
          buildDropdown("Store Access Type",
            ["Walk-in", "Appointment Only", "Hybrid"],
            _storeAccessType, (v) => setState(() => _storeAccessType = v)),
          buildDropdown("Years of Experience",
            ["0–2", "3–5", "6–10", "10+"],
            _yearsOfExperience, (v) => setState(() => _yearsOfExperience = v)),
          buildMultiSelect("Specialization",
            ["Groom Wedding Suits", "Reception Suits", "Cocktail Suits",
             "Indo-Western Suits", "Formal Suits"],
            _specialization,
            (o, c) => setState(() => c ? _specialization.add(o) : _specialization.remove(o))),
        ],
        dividerLine(),

        // ── Section 2: Services Offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _ws2,
            () => setState(() => _ws2 = !_ws2)),
        if (_ws2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Service Modes",
            ["Bespoke (Custom Tailored)", "Made-to-Measure", "Ready-to-Wear"],
            _serviceModes,
            (o, c) => setState(() => c ? _serviceModes.add(o) : _serviceModes.remove(o))),
          buildYesNo("Trial Availability", _trialAvailability,
              (v) => setState(() => _trialAvailability = v)),
          buildYesNo("Styling Consultation", _stylingConsultation,
              (v) => setState(() => _stylingConsultation = v)),
          buildYesNo("Fabric Selection Assistance", _fabricSelectionAssistance,
              (v) => setState(() => _fabricSelectionAssistance = v)),
          buildYesNo("Home Measurement Service", _homeMeasurementService,
              (v) => setState(() => _homeMeasurementService = v)),
          buildYesNo("Alteration Services", _alterationServices,
              (v) => setState(() => _alterationServices = v)),
          buildYesNo("Express Delivery Available", _expressDeliveryAvailable,
              (v) => setState(() => _expressDeliveryAvailable = v)),
          buildMultiSelect("Accessory Add-ons",
            ["Shirt", "Tie / Bow Tie", "Pocket Square", "Belt", "Shoes"],
            _accessoryAddOns,
            (o, c) => setState(() => c ? _accessoryAddOns.add(o) : _accessoryAddOns.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _ws3,
            () => setState(() => _ws3 = !_ws3)),
        if (_ws3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Suit Types",
            ["Tuxedo", "Two-Piece Suit", "Three-Piece Suit", "Bandhgala Suit",
             "Jodhpuri Suit", "Indo-Western Suit"],
            _suitTypes,
            (o, c) => setState(() => c ? _suitTypes.add(o) : _suitTypes.remove(o))),
          buildMultiSelect("Occasion Suitability",
            ["Wedding Ceremony", "Reception", "Engagement", "Cocktail", "Formal Events"],
            _occasionSuitability,
            (o, c) => setState(() => c ? _occasionSuitability.add(o) : _occasionSuitability.remove(o))),
          buildMultiSelect("Fit Type",
            ["Slim Fit", "Regular Fit", "Relaxed Fit", "Custom Fit"],
            _fitType,
            (o, c) => setState(() => c ? _fitType.add(o) : _fitType.remove(o))),
          buildMultiSelect("Fabric Options",
            ["Wool", "Terry Rayon", "Velvet", "Linen", "Cotton", "Silk Blend"],
            _fabricOptions,
            (o, c) => setState(() => c ? _fabricOptions.add(o) : _fabricOptions.remove(o))),
          buildMultiSelect("Season Suitability",
            ["Summer", "Winter", "All-Season"],
            _seasonSuitability,
            (o, c) => setState(() => c ? _seasonSuitability.add(o) : _seasonSuitability.remove(o))),
          buildMultiSelect("Design Style",
            ["Plain", "Textured", "Patterned", "Embroidered"],
            _designStyle,
            (o, c) => setState(() => c ? _designStyle.add(o) : _designStyle.remove(o))),
          buildMultiSelect("Color Palette",
            ["Black", "Navy", "Grey", "Beige", "Pastel", "Jewel Tones"],
            _colorPalette,
            (o, c) => setState(() => c ? _colorPalette.add(o) : _colorPalette.remove(o))),
        ],
        dividerLine(),

        // ── Section 4: Technical / Product ─────────────────────────────────
        sectionHeader("Section 4 — Technical & product", _ws4,
            () => setState(() => _ws4 = !_ws4)),
        if (_ws4) ...[
          const SizedBox(height: 16),
          buildDropdown("Stitching Type",
            ["Machine Stitch", "Hand Finished", "Fully Handcrafted"],
            _stitchingType, (v) => setState(() => _stitchingType = v)),
          buildDropdown("Canvas Construction",
            ["Full Canvas", "Half Canvas", "Fused"],
            _canvasConstruction, (v) => setState(() => _canvasConstruction = v)),
          buildMultiSelect("Customization Depth",
            ["Lapel Style Selection", "Button Customization",
             "Lining Customization", "Monogramming"],
            _customizationDepth,
            (o, c) => setState(() => c ? _customizationDepth.add(o) : _customizationDepth.remove(o))),
          buildMultiSelect("Lapel Types",
            ["Notch Lapel", "Peak Lapel", "Shawl Lapel"],
            _lapelTypes,
            (o, c) => setState(() => c ? _lapelTypes.add(o) : _lapelTypes.remove(o))),
          buildMultiSelect("Closure Type",
            ["Single Breasted", "Double Breasted"],
            _closureType,
            (o, c) => setState(() => c ? _closureType.add(o) : _closureType.remove(o))),
          buildDropdown("Number of Buttons",
            ["1", "2", "3"],
            _numberOfButtons, (v) => setState(() => _numberOfButtons = v)),
          buildDropdown("Durability Level",
            ["Occasion Wear", "Premium Long-Term"],
            _durabilityLevel, (v) => setState(() => _durabilityLevel = v)),
        ],
        dividerLine(),

        // ── Section 5: Pricing Logic ───────────────────────────────────────
        sectionHeader("Section 5 — Pricing logic", _ws5,
            () => setState(() => _ws5 = !_ws5)),
        if (_ws5) ...[
          const SizedBox(height: 16),
          buildDropdown("Price Range per Suit (INR)",
            ["5K–15K", "15K–30K", "30K–75K", "75K–1.5L", "1.5L+"],
            _priceRange, (v) => setState(() => _priceRange = v)),
          buildDropdown("Customization Charges",
            ["Included", "Extra"],
            _customizationCharges, (v) => setState(() => _customizationCharges = v)),
          buildDropdown("Fabric Cost Structure",
            ["Included", "Separate"],
            _fabricCostStructure, (v) => setState(() => _fabricCostStructure = v)),
          buildDropdown("Accessory Bundle Pricing",
            ["Included", "Optional Add-on"],
            _accessoryBundlePricing, (v) => setState(() => _accessoryBundlePricing = v)),
          buildYesNo("Bulk Order Discounts", _bulkOrderDiscounts,
              (v) => setState(() => _bulkOrderDiscounts = v)),
        ],
        dividerLine(),

        // ── Section 6: Scale & Capacity ────────────────────────────────────
        sectionHeader("Section 6 — Scale & capacity", _ws6,
            () => setState(() => _ws6 = !_ws6)),
        if (_ws6) ...[
          const SizedBox(height: 16),
          buildDropdown("Daily Client Handling Capacity",
            ["1–5", "5–10", "10–20", "20+"],
            _dailyClientCapacity, (v) => setState(() => _dailyClientCapacity = v)),
          buildDropdown("Monthly Production Capacity",
            ["<20 Suits", "20–50", "50–100", "100+"],
            _monthlyProductionCapacity, (v) => setState(() => _monthlyProductionCapacity = v)),
          buildYesNo("Trial Room Availability", _trialRoomAvailability,
              (v) => setState(() => _trialRoomAvailability = v)),
        ],
        dividerLine(),

        // ── Section 7: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 7 — Workflow & booking", _ws7,
            () => setState(() => _ws7 = !_ws7)),
        if (_ws7) ...[
          const SizedBox(height: 16),
          buildYesNo("Appointment Required", _appointmentRequired,
              (v) => setState(() => _appointmentRequired = v)),
          buildMultiSelect("Measurement Process",
            ["In-store Measurement", "Home Visit Measurement", "Standard Size Selection"],
            _measurementProcess,
            (o, c) => setState(() => c ? _measurementProcess.add(o) : _measurementProcess.remove(o))),
          buildDropdown("Lead Time for Delivery",
            ["3–7 days", "7–15 days", "15–30 days", "30+ days"],
            _leadTime, (v) => setState(() => _leadTime = v)),
          buildDropdown("Trial Rounds",
            ["0", "1", "2", "3+"],
            _trialRounds, (v) => setState(() => _trialRounds = v)),
          buildDropdown("Alteration Timeline",
            ["Same Day", "1–3 days", "3–7 days"],
            _alterationTimeline, (v) => setState(() => _alterationTimeline = v)),
          buildMultiSelect("Payment Modes",
            ["UPI", "Cash", "Card", "Bank Transfer"],
            _paymentModes,
            (o, c) => setState(() => c ? _paymentModes.add(o) : _paymentModes.remove(o))),
          buildDropdown("Advance Payment Percentage",
            ["25%", "50%", "75%", "100%"],
            _advancePayment, (v) => setState(() => _advancePayment = v)),
        ],
        dividerLine(),

        // ── Section 8: Portfolio Tagging ───────────────────────────────────
        sectionHeader("Section 8 — Portfolio tagging (AI layer)", _ws8,
            () => setState(() => _ws8 = !_ws8)),
        if (_ws8) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Style Tags",
            ["Classic Groom", "Modern Groom", "Royal Groom", "Minimal Groom"],
            _styleTags,
            (o, c) => setState(() => c ? _styleTags.add(o) : _styleTags.remove(o))),
          buildMultiSelect("Audience Tags",
            ["Groom", "Best Man", "Family Members"],
            _audienceTags,
            (o, c) => setState(() => c ? _audienceTags.add(o) : _audienceTags.remove(o))),
          buildMultiSelect("Usage Tags",
            ["Wedding", "Reception", "Cocktail", "Formal"],
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
