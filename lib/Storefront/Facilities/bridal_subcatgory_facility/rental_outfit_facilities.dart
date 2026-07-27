import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class RentalOutfitFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const RentalOutfitFacilities({super.key, required this.attributes});

  @override
  State<RentalOutfitFacilities> createState() => RentalOutfitFacilitiesState();
}

class RentalOutfitFacilitiesState extends State<RentalOutfitFacilities>
    with FacilitiesHelpersMixin<RentalOutfitFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  String?      _vendorType;
  final        _brandNameCtrl = TextEditingController();
  List<String> _storePresence = [];
  final        _cityCtrl      = TextEditingController();
  String?      _storeAccessType;
  String?      _yearsOfExperience;
  List<String> _inventorySpecialization = [];

  // ── services ──────────────────────────────────────────────────────────────
  List<String> _rentalTypes           = [];
  String?      _trialAvailability;
  String?      _customizationAlteration;
  String?      _stylingAssistance;
  List<String> _accessoryRental        = [];
  String?      _dryCleaningIncluded;
  String?      _pickupDeliveryService;
  String?      _urgentRentalAvailability;

  // ── core_intelligence ─────────────────────────────────────────────────────
  List<String> _lehengaStyles        = [];
  List<String> _occasionSuitability  = [];
  List<String> _workType             = [];
  List<String> _fabricOptions        = [];
  List<String> _colorPalette         = [];
  List<String> _designerAvailability = [];
  List<String> _dupattaStyles        = [];

  // ── technical / product ───────────────────────────────────────────────────
  String?      _sizeRange;
  String?      _adjustabilityRange;
  String?      _weightCategory;
  List<String> _blouseType   = [];
  String?      _canCanIncluded;
  String?      _dupattaLength;
  String?      _conditionQuality;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _rentalPriceRange;
  String?      _securityDepositRequired;
  String?      _depositAmountRange;
  String?      _lateReturnCharges;
  String?      _damagePolicy;
  String?      _cleaningCharges;
  String?      _trialCharges;

  // ── scale & capacity ──────────────────────────────────────────────────────
  String?      _inventorySize;
  String?      _dailyTrialCapacity;
  String?      _simultaneousRentalsCapacity;

  // ── workflow & booking ────────────────────────────────────────────────────
  String?      _advanceBookingRequired;
  String?      _bookingWindow;
  String?      _trialAppointmentRequired;
  String?      _fittingTimeline;
  String?      _pickupTiming;
  String?      _returnTimeline;
  List<String> _paymentModes = [];
  String?      _advancePaymentPercent;

  // ── portfolio tagging ─────────────────────────────────────────────────────
  List<String> _styleTags    = [];
  List<String> _audienceTags = [];
  List<String> _usageTags    = [];
  String?      _priceSegmentTags;

  // ── section expansion ─────────────────────────────────────────────────────
  bool _rs1 = true;
  bool _rs2 = false;
  bool _rs3 = false;
  bool _rs4 = false;
  bool _rs5 = false;
  bool _rs6 = false;
  bool _rs7 = false;
  bool _rs8 = false;

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

  // First non-null/non-empty string among candidates.
  String? _pick(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c is String && c.isNotEmpty) return c;
    }
    return null;
  }

  void _setFields(Map<String, dynamic> attrs) {
    final rm = asMap(attrs['rental_outfit_master']);

    final id = asMap(rm['identity']);
    _vendorType         = id['vendor_type'] as String?;
    _brandNameCtrl.text = id['brand_name']?.toString() ?? '';
    _storePresence      = toList(id['store_presence']);
    _cityCtrl.text      = id['city']?.toString() ?? '';
    _storeAccessType    = id['store_access_type'] as String?;
    _yearsOfExperience  = id['years_of_experience'] as String?;
    _inventorySpecialization = toList(id['inventory_specialization']);

    final sv = asMap(rm['services']);
    _rentalTypes             = toList(sv['rental_types']);
    _trialAvailability       = sv['trial_availability'] as String?;
    _customizationAlteration = sv['customization_alteration'] as String?;
    _stylingAssistance       = sv['styling_assistance'] as String?;
    _accessoryRental         = toList(sv['accessory_rental']);
    _dryCleaningIncluded     = sv['dry_cleaning_included'] as String?;
    _pickupDeliveryService   = _pick([sv['pickup_delivery_service'], sv['pickup_delivery']]);
    _urgentRentalAvailability = _pick([sv['urgent_rental_availability'], sv['urgent_rental']]);

    final ci = asMap(rm['core_intelligence']);
    _lehengaStyles        = toList(ci['lehenga_styles']);
    _occasionSuitability  = toList(ci['occasion_suitability']);
    _workType             = toList(ci['work_type']);
    _fabricOptions        = toList(ci['fabric_options']);
    _colorPalette         = toList(ci['color_palette']);
    _designerAvailability = toList(ci['designer_availability']);
    _dupattaStyles        = toList(ci['dupatta_styles']);

    final tp = asMap(rm['technical_product']);
    final te = asMap(rm['technical']);
    _sizeRange          = _pick([tp['size_range'], (te['size_range'] is List && (te['size_range'] as List).isNotEmpty) ? (te['size_range'] as List).first.toString() : null]);
    _adjustabilityRange = _pick([tp['adjustability_range'], te['adjustability_range']]);
    _weightCategory     = _pick([tp['weight_category'], te['lehenga_weight']]);
    _blouseType         = toList(tp['blouse_type'].toString().isEmpty ? te['blouse_type'] : tp['blouse_type']);
    if (_blouseType.isEmpty) _blouseType = toList(te['blouse_type']);
    _canCanIncluded     = _pick([tp['can_can_included'], te['can_can_included']]);
    _dupattaLength      = _pick([tp['dupatta_length'], te['dupatta_length']]);
    _conditionQuality   = _pick([tp['condition_quality'], te['condition_quality']]);

    final pl = asMap(rm['pricing_logic']);
    final pr = asMap(rm['pricing']);
    _rentalPriceRange        = _pick([pl['price_range'], pr['rental_price_range']]);
    _securityDepositRequired = _pick([pl['security_deposit_required'], pr['security_deposit_required']]);
    _depositAmountRange      = _pick([pl['deposit_amount_range'], pr['deposit_amount_range']]);
    _lateReturnCharges       = _pick([pl['late_return_charges'], pr['late_return_charges']]);
    _damagePolicy            = _pick([pl['damage_policy'], pr['damage_policy']]);
    _cleaningCharges         = _pick([pl['cleaning_charges'], pr['cleaning_charges']]);
    _trialCharges            = _pick([pl['trial_charges'], pr['trial_charges']]);

    final scp = asMap(rm['scale_capacity']);
    final sc  = asMap(rm['scale']);
    _inventorySize               = _pick([scp['inventory_size'], sc['inventory_size']]);
    _dailyTrialCapacity          = _pick([scp['daily_trial_capacity'], sc['daily_trial_capacity']]);
    _simultaneousRentalsCapacity = _pick([scp['simultaneous_rentals_capacity'], sc['simultaneous_rentals']]);

    final wb = asMap(rm['workflow_booking']);
    final wf = asMap(rm['workflow']);
    _advanceBookingRequired   = _pick([wb['advance_booking_required'], wf['advance_booking_required']]);
    _bookingWindow            = _pick([wb['booking_window'], wf['booking_window']]);
    _trialAppointmentRequired = _pick([wb['trial_appointment_required'], wf['trial_appointment_required']]);
    _fittingTimeline          = _pick([wb['fitting_timeline'], wf['fitting_timeline']]);
    _pickupTiming             = _pick([wb['pickup_timing'], wf['pickup_timing']]);
    _returnTimeline           = _pick([wb['return_timeline'], wf['return_timeline']]);
    _paymentModes             = toList(wb['payment_modes'].toString().isEmpty ? wf['payment_modes'] : wb['payment_modes']);
    if (_paymentModes.isEmpty) _paymentModes = toList(wf['payment_modes']);
    _advancePaymentPercent    = _pick([wb['advance_payment_percent'], wf['advance_payment_percentage']]);

    final po = asMap(rm['portfolio']);
    final tags = asMap(rm['ai_tags']);
    _styleTags    = toList(po['style_tags'].toString().isEmpty ? tags['style_tags'] : po['style_tags']);
    if (_styleTags.isEmpty) _styleTags = toList(tags['style_tags']);
    _audienceTags = toList(po['audience_tags'].toString().isEmpty ? tags['audience_tags'] : po['audience_tags']);
    if (_audienceTags.isEmpty) _audienceTags = toList(tags['audience_tags']);
    _usageTags    = toList(po['usage_tags'].toString().isEmpty ? tags['usage_tags'] : po['usage_tags']);
    if (_usageTags.isEmpty) _usageTags = toList(tags['usage_tags']);
    final ps = po['price_segment_tags'];
    _priceSegmentTags = ps is List
        ? (ps.isNotEmpty ? ps.first.toString() : null)
        : (ps as String?) ?? (tags['price_segment_tags'] as String?);
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "vendor_type":              _vendorType,
        "brand_name":               _brandNameCtrl.text,
        "store_presence":           _storePresence,
        "city":                     _cityCtrl.text,
        "store_access_type":        _storeAccessType,
        "years_of_experience":      _yearsOfExperience,
        "inventory_specialization": _inventorySpecialization,
      },
      "services": {
        ...asMap(ex["services"]),
        "rental_types":               _rentalTypes,
        "trial_availability":         _trialAvailability,
        "customization_alteration":   _customizationAlteration,
        "styling_assistance":         _stylingAssistance,
        "accessory_rental":           _accessoryRental,
        "dry_cleaning_included":      _dryCleaningIncluded,
        "pickup_delivery_service":    _pickupDeliveryService,
        "pickup_delivery":            _pickupDeliveryService,
        "urgent_rental_availability": _urgentRentalAvailability,
        "urgent_rental":              _urgentRentalAvailability,
      },
      "core_intelligence": {
        ...asMap(ex["core_intelligence"]),
        "lehenga_styles":        _lehengaStyles,
        "occasion_suitability":  _occasionSuitability,
        "work_type":             _workType,
        "fabric_options":        _fabricOptions,
        "color_palette":         _colorPalette,
        "designer_availability": _designerAvailability,
        "dupatta_styles":        _dupattaStyles,
      },
      // technical_product (canonical) + technical (mirror, legacy key shapes)
      "technical_product": {
        ...asMap(ex["technical_product"]),
        "size_range":          _sizeRange,
        "adjustability_range": _adjustabilityRange,
        "weight_category":     _weightCategory,
        "blouse_type":         _blouseType,
        "can_can_included":    _canCanIncluded,
        "dupatta_length":      _dupattaLength,
        "condition_quality":   _conditionQuality,
      },
      "technical": {
        ...asMap(ex["technical"]),
        "size_range":          _sizeRange == null ? [] : [_sizeRange],
        "adjustability_range": _adjustabilityRange,
        "lehenga_weight":      _weightCategory,
        "blouse_type":         _blouseType,
        "can_can_included":    _canCanIncluded,
        "dupatta_length":      _dupattaLength,
        "condition_quality":   _conditionQuality,
      },
      // pricing_logic (canonical) + pricing (mirror)
      "pricing_logic": {
        ...asMap(ex["pricing_logic"]),
        "price_range":               _rentalPriceRange,
        "security_deposit_required": _securityDepositRequired,
        "deposit_amount_range":      _depositAmountRange,
        "late_return_charges":       _lateReturnCharges,
        "damage_policy":             _damagePolicy,
        "cleaning_charges":          _cleaningCharges,
        "trial_charges":             _trialCharges,
      },
      "pricing": {
        ...asMap(ex["pricing"]),
        "rental_price_range":        _rentalPriceRange,
        "security_deposit_required": _securityDepositRequired,
        "deposit_amount_range":      _depositAmountRange,
        "late_return_charges":       _lateReturnCharges,
        "damage_policy":             _damagePolicy,
        "cleaning_charges":          _cleaningCharges,
        "trial_charges":             _trialCharges,
      },
      // scale_capacity (canonical) + scale (mirror)
      "scale_capacity": {
        ...asMap(ex["scale_capacity"]),
        "inventory_size":                _inventorySize,
        "daily_trial_capacity":          _dailyTrialCapacity,
        "simultaneous_rentals_capacity": _simultaneousRentalsCapacity,
      },
      "scale": {
        ...asMap(ex["scale"]),
        "inventory_size":       _inventorySize,
        "daily_trial_capacity": _dailyTrialCapacity,
        "simultaneous_rentals": _simultaneousRentalsCapacity,
      },
      // workflow_booking (canonical) + workflow (mirror)
      "workflow_booking": {
        ...asMap(ex["workflow_booking"]),
        "advance_booking_required":   _advanceBookingRequired,
        "booking_window":             _bookingWindow,
        "trial_appointment_required": _trialAppointmentRequired,
        "fitting_timeline":           _fittingTimeline,
        "pickup_timing":              _pickupTiming,
        "return_timeline":            _returnTimeline,
        "payment_modes":              _paymentModes,
        "advance_payment_percent":    _advancePaymentPercent,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "advance_booking_required":    _advanceBookingRequired,
        "booking_window":              _bookingWindow,
        "trial_appointment_required":  _trialAppointmentRequired,
        "fitting_timeline":            _fittingTimeline,
        "pickup_timing":               _pickupTiming,
        "return_timeline":             _returnTimeline,
        "payment_modes":               _paymentModes,
        "advance_payment_percentage":  _advancePaymentPercent,
      },
      // portfolio (canonical) + ai_tags (mirror)
      "portfolio": {
        ...asMap(ex["portfolio"]),
        "style_tags":         _styleTags,
        "audience_tags":      _audienceTags,
        "usage_tags":         _usageTags,
        "price_segment_tags": _priceSegmentTags == null ? [] : [_priceSegmentTags],
      },
      "ai_tags": {
        ...asMap(ex["ai_tags"]),
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
        const Text("Bridal Outfit On Rent Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured rental outfit attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _rs1,
            () => setState(() => _rs1 = !_rs1)),
        if (_rs1) ...[
          const SizedBox(height: 16),
          buildDropdown("Vendor Type",
            ["Rental Boutique", "Designer Rental Studio",
             "Multi-Designer Rental Platform", "Home-Based Rental Vendor"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildTextArea("Brand Name", _brandNameCtrl, maxLines: 1),
          buildMultiSelect("Store Presence",
            ["Physical Store", "Online Rental Platform", "Both"],
            _storePresence,
            (o, c) => setState(() => c ? _storePresence.add(o) : _storePresence.remove(o))),
          buildTextArea("City", _cityCtrl, maxLines: 1),
          buildDropdown("Store Access Type",
            ["Walk-in Store", "Appointment Only", "Hybrid"],
            _storeAccessType, (v) => setState(() => _storeAccessType = v)),
          buildDropdown("Years of Experience",
            ["0–2", "3–5", "6–10", "10+"],
            _yearsOfExperience, (v) => setState(() => _yearsOfExperience = v)),
          buildMultiSelect("Inventory Specialization",
            ["Bridal Lehenga", "Reception Lehenga", "Cocktail Lehenga", "Pre-Wedding Lehenga"],
            _inventorySpecialization,
            (o, c) => setState(() => c ? _inventorySpecialization.add(o) : _inventorySpecialization.remove(o))),
        ],
        dividerLine(),

        // ── Section 2: Services Offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _rs2,
            () => setState(() => _rs2 = !_rs2)),
        if (_rs2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Rental Types",
            ["Single Event Rental", "Multi-Day Rental", "Try-at-Home Rental"],
            _rentalTypes,
            (o, c) => setState(() => c ? _rentalTypes.add(o) : _rentalTypes.remove(o))),
          buildDropdown("Trial Availability",
            ["In-store Only", "Home Trial", "Both", "Not Available"],
            _trialAvailability, (v) => setState(() => _trialAvailability = v)),
          buildDropdown("Customization / Alteration",
            ["Minor Alterations Only", "Full Custom Fit", "Not Available"],
            _customizationAlteration, (v) => setState(() => _customizationAlteration = v)),
          buildYesNo("Styling Assistance", _stylingAssistance,
              (v) => setState(() => _stylingAssistance = v)),
          buildMultiSelect("Accessory Rental Available",
            ["Dupatta", "Jewellery", "Veil", "Can-Can", "Blouse"],
            _accessoryRental,
            (o, c) => setState(() => c ? _accessoryRental.add(o) : _accessoryRental.remove(o))),
          buildYesNo("Dry Cleaning Included", _dryCleaningIncluded,
              (v) => setState(() => _dryCleaningIncluded = v)),
          buildYesNo("Pickup & Delivery Service", _pickupDeliveryService,
              (v) => setState(() => _pickupDeliveryService = v)),
          buildYesNo("Urgent Rental Availability", _urgentRentalAvailability,
              (v) => setState(() => _urgentRentalAvailability = v)),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _rs3,
            () => setState(() => _rs3 = !_rs3)),
        if (_rs3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Lehenga Styles Available",
            ["A-Line", "Circular / Flared", "Mermaid", "Panelled",
             "Jacket Lehenga", "Indo-Western"],
            _lehengaStyles,
            (o, c) => setState(() => c ? _lehengaStyles.add(o) : _lehengaStyles.remove(o))),
          buildMultiSelect("Occasion Suitability",
            ["Wedding Ceremony", "Reception", "Engagement", "Cocktail", "Sangeet"],
            _occasionSuitability,
            (o, c) => setState(() => c ? _occasionSuitability.add(o) : _occasionSuitability.remove(o))),
          buildMultiSelect("Work Type",
            ["Zari", "Zardozi", "Sequins", "Thread Work", "Mirror Work", "Minimal"],
            _workType,
            (o, c) => setState(() => c ? _workType.add(o) : _workType.remove(o))),
          buildMultiSelect("Fabric Options",
            ["Velvet", "Silk", "Net", "Organza", "Georgette", "Raw Silk"],
            _fabricOptions,
            (o, c) => setState(() => c ? _fabricOptions.add(o) : _fabricOptions.remove(o))),
          buildMultiSelect("Color Palette",
            ["Red / Maroon", "Pastels", "Jewel Tones", "Ivory / White", "Dual Tone"],
            _colorPalette,
            (o, c) => setState(() => c ? _colorPalette.add(o) : _colorPalette.remove(o))),
          buildMultiSelect("Designer Availability",
            ["In-house Designs", "Multi-Designer", "Replica Designer Wear"],
            _designerAvailability,
            (o, c) => setState(() => c ? _designerAvailability.add(o) : _designerAvailability.remove(o))),
          buildMultiSelect("Dupatta Styles",
            ["Single Dupatta", "Double Dupatta", "Veil Style"],
            _dupattaStyles,
            (o, c) => setState(() => c ? _dupattaStyles.add(o) : _dupattaStyles.remove(o))),
        ],
        dividerLine(),

        // ── Section 4: Technical / Product ─────────────────────────────────
        sectionHeader("Section 4 — Technical & product", _rs4,
            () => setState(() => _rs4 = !_rs4)),
        if (_rs4) ...[
          const SizedBox(height: 16),
          buildDropdown("Size Range Available",
            ["XS–S", "M–L", "XL–XXL", "Custom Fit"],
            _sizeRange, (v) => setState(() => _sizeRange = v)),
          buildDropdown("Adjustability Range",
            ["±1 Size", "±2 Sizes", "Not Adjustable"],
            _adjustabilityRange, (v) => setState(() => _adjustabilityRange = v)),
          buildDropdown("Lehenga Weight Category",
            ["Lightweight", "Medium", "Heavy Bridal"],
            _weightCategory, (v) => setState(() => _weightCategory = v)),
          buildMultiSelect("Blouse Type",
            ["Padded", "Non-Padded", "Custom Fit"],
            _blouseType,
            (o, c) => setState(() => c ? _blouseType.add(o) : _blouseType.remove(o))),
          buildYesNo("Can-Can Included", _canCanIncluded,
              (v) => setState(() => _canCanIncluded = v)),
          buildDropdown("Dupatta Length Options",
            ["Standard", "Extended Bridal"],
            _dupattaLength, (v) => setState(() => _dupattaLength = v)),
          buildDropdown("Condition Quality",
            ["Like New", "Lightly Used", "Moderate Wear"],
            _conditionQuality, (v) => setState(() => _conditionQuality = v)),
        ],
        dividerLine(),

        // ── Section 5: Pricing Logic ───────────────────────────────────────
        sectionHeader("Section 5 — Pricing logic", _rs5,
            () => setState(() => _rs5 = !_rs5)),
        if (_rs5) ...[
          const SizedBox(height: 16),
          buildDropdown("Rental Price Range (INR)",
            ["2K–10K", "10K–25K", "25K–50K", "50K–1L", "1L+"],
            _rentalPriceRange, (v) => setState(() => _rentalPriceRange = v)),
          buildYesNo("Security Deposit Required", _securityDepositRequired,
              (v) => setState(() => _securityDepositRequired = v)),
          buildDropdown("Deposit Amount Range",
            ["0–5K", "5K–20K", "20K–50K", "50K+"],
            _depositAmountRange, (v) => setState(() => _depositAmountRange = v)),
          buildYesNo("Late Return Charges", _lateReturnCharges,
              (v) => setState(() => _lateReturnCharges = v)),
          buildDropdown("Damage Policy",
            ["Minor Damage Fee", "Full Replacement Cost", "Case-by-case"],
            _damagePolicy, (v) => setState(() => _damagePolicy = v)),
          buildDropdown("Cleaning Charges",
            ["Included", "Extra"],
            _cleaningCharges, (v) => setState(() => _cleaningCharges = v)),
          buildDropdown("Trial Charges",
            ["Free", "Adjustable in Final Bill", "Paid Non-Adjustable"],
            _trialCharges, (v) => setState(() => _trialCharges = v)),
        ],
        dividerLine(),

        // ── Section 6: Scale & Capacity ────────────────────────────────────
        sectionHeader("Section 6 — Scale & capacity", _rs6,
            () => setState(() => _rs6 = !_rs6)),
        if (_rs6) ...[
          const SizedBox(height: 16),
          buildDropdown("Inventory Size",
            ["<50", "50–150", "150–300", "300+"],
            _inventorySize, (v) => setState(() => _inventorySize = v)),
          buildDropdown("Daily Trial Capacity",
            ["1–5", "5–10", "10–20", "20+"],
            _dailyTrialCapacity, (v) => setState(() => _dailyTrialCapacity = v)),
          buildDropdown("Simultaneous Rentals Capacity",
            ["<20", "20–50", "50–100", "100+"],
            _simultaneousRentalsCapacity,
            (v) => setState(() => _simultaneousRentalsCapacity = v)),
        ],
        dividerLine(),

        // ── Section 7: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 7 — Workflow & booking", _rs7,
            () => setState(() => _rs7 = !_rs7)),
        if (_rs7) ...[
          const SizedBox(height: 16),
          buildYesNo("Advance Booking Required", _advanceBookingRequired,
              (v) => setState(() => _advanceBookingRequired = v)),
          buildDropdown("Booking Window",
            ["0–7 days prior", "7–30 days", "1–3 months", "3+ months"],
            _bookingWindow, (v) => setState(() => _bookingWindow = v)),
          buildYesNo("Trial Appointment Required", _trialAppointmentRequired,
              (v) => setState(() => _trialAppointmentRequired = v)),
          buildDropdown("Fitting Timeline Before Event",
            ["Same Day", "1–3 days prior", "3–7 days prior"],
            _fittingTimeline, (v) => setState(() => _fittingTimeline = v)),
          buildDropdown("Pickup Timing",
            ["1 day before event", "Same day", "Flexible"],
            _pickupTiming, (v) => setState(() => _pickupTiming = v)),
          buildDropdown("Return Timeline",
            ["Next Day", "Within 2 days", "Within 3 days"],
            _returnTimeline, (v) => setState(() => _returnTimeline = v)),
          buildMultiSelect("Payment Modes",
            ["UPI", "Cash", "Card", "Bank Transfer"],
            _paymentModes,
            (o, c) => setState(() => c ? _paymentModes.add(o) : _paymentModes.remove(o))),
          buildDropdown("Advance Payment Percentage",
            ["25%", "50%", "75%", "100%"],
            _advancePaymentPercent, (v) => setState(() => _advancePaymentPercent = v)),
        ],
        dividerLine(),

        // ── Section 8: Portfolio Tagging ───────────────────────────────────
        sectionHeader("Section 8 — Portfolio tagging (AI layer)", _rs8,
            () => setState(() => _rs8 = !_rs8)),
        if (_rs8) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Style Tags",
            ["Royal Bridal", "Modern Bride", "Minimal Bride", "Bollywood Inspired"],
            _styleTags,
            (o, c) => setState(() => c ? _styleTags.add(o) : _styleTags.remove(o))),
          buildMultiSelect("Audience Tags",
            ["Bride", "Sister of Bride", "Bridesmaid"],
            _audienceTags,
            (o, c) => setState(() => c ? _audienceTags.add(o) : _audienceTags.remove(o))),
          buildMultiSelect("Usage Tags",
            ["Wedding", "Reception", "Cocktail", "Pre-Wedding"],
            _usageTags,
            (o, c) => setState(() => c ? _usageTags.add(o) : _usageTags.remove(o))),
          buildDropdown("Price Segment Tags",
            ["Budget Rental", "Mid-range Rental", "Premium Rental", "Luxury Rental"],
            _priceSegmentTags, (v) => setState(() => _priceSegmentTags = v)),
        ],
      ],
    );
  }
}
