import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class SherwaniFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const SherwaniFacilities({super.key, required this.attributes});

  @override
  State<SherwaniFacilities> createState() => SherwaniFacilitiesState();
}

class SherwaniFacilitiesState extends State<SherwaniFacilities>
    with FacilitiesHelpersMixin<SherwaniFacilities> {

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
  String?      _homeMeasurementService;
  String?      _alterationServices;
  String?      _expressDeliveryAvailable;
  List<String> _accessoryAddOns   = [];

  // ── intelligence ──────────────────────────────────────────────────────────
  List<String> _sherwaniTypes       = [];
  List<String> _occasionSuitability = [];
  List<String> _workType            = [];
  List<String> _fabricOptions       = [];
  List<String> _colorPalette        = [];
  List<String> _designStyle         = [];
  List<String> _layeringOptions     = [];

  // ── technical ─────────────────────────────────────────────────────────────
  List<String> _fitType           = [];
  List<String> _closureType       = [];
  String?      _lengthType;
  String?      _innerLayerIncluded;
  List<String> _bottomWearOptions = [];
  String?      _embroideryDensity;
  String?      _durabilityLevel;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _priceRange;
  String?      _customizationCharges;
  String?      _rentalPricingOption;
  String?      _accessoryBundlePricing;
  String?      _bulkDiscounts;

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
  bool _ss1 = true;
  bool _ss2 = false;
  bool _ss3 = false;
  bool _ss4 = false;
  bool _ss5 = false;
  bool _ss6 = false;
  bool _ss7 = false;
  bool _ss8 = false;

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
    final sm = asMap(attrs['sherwani_master']);

    final id = asMap(sm['identity']);
    _vendorType         = id['vendor_type'] as String?;
    _brandNameCtrl.text = id['brand_name']?.toString() ?? '';
    _sellOnEcommerce    = _ynFromBool(id['sell_on_ecommerce']);
    _storePresence      = toList(id['store_presence']);
    _cityCtrl.text      = id['city']?.toString() ?? '';
    _storeAccessType    = id['store_access_type'] as String?;
    _yearsOfExperience  = id['years_of_experience'] as String?;
    _specialization     = toList(id['specialization']);

    final sv = asMap(sm['services']);
    _serviceModes             = toList(sv['service_modes']);
    _trialAvailability        = sv['trial_availability'] as String?;
    _stylingConsultation      = sv['styling_consultation'] as String?;
    _homeMeasurementService   = sv['home_measurement_service'] as String?;
    _alterationServices       = sv['alteration_services'] as String?;
    _expressDeliveryAvailable = sv['express_delivery_available'] as String?;
    _accessoryAddOns          = toList(sv['accessory_add_ons']);

    final ci = asMap(sm['intelligence']);
    _sherwaniTypes       = toList(ci['sherwani_types']);
    _occasionSuitability = toList(ci['occasion_suitability']);
    _workType            = toList(ci['work_type']);
    _fabricOptions       = toList(ci['fabric_options']);
    _colorPalette        = toList(ci['color_palette']);
    _designStyle         = toList(ci['design_style']);
    _layeringOptions     = toList(ci['layering_options']);

    final te = asMap(sm['technical']);
    _fitType            = toList(te['fit_type']);
    _closureType        = toList(te['closure_type']);
    _lengthType         = te['length_type'] as String?;
    _innerLayerIncluded = te['inner_layer_included'] as String?;
    _bottomWearOptions  = toList(te['bottom_wear_options']);
    _embroideryDensity  = te['embroidery_density'] as String?;
    _durabilityLevel    = te['durability_level'] as String?;

    final pr = asMap(sm['pricing']);
    _priceRange             = pr['price_range'] as String?;
    _customizationCharges   = pr['customization_charges'] as String?;
    _rentalPricingOption    = pr['rental_pricing_option'] as String?;
    _accessoryBundlePricing = pr['accessory_bundle_pricing'] as String?;
    _bulkDiscounts          = pr['bulk_discounts'] as String?;

    final cap = asMap(sm['capacity']);
    _dailyClientCapacity       = cap['daily_client_capacity'] as String?;
    _monthlyProductionCapacity = cap['monthly_production_capacity'] as String?;
    _trialRoomAvailability     = cap['trial_room_availability'] as String?;

    final wf = asMap(sm['workflow']);
    _appointmentRequired = wf['appointment_required'] as String?;
    _measurementProcess  = toList(wf['measurement_process']);
    _leadTime            = wf['lead_time'] as String?;
    _trialRounds         = wf['trial_rounds']?.toString();
    _alterationTimeline  = wf['alteration_timeline'] as String?;
    _paymentModes        = toList(wf['payment_modes']);
    _advancePayment      = wf['advance_payment'] as String?;

    final po = asMap(sm['portfolio']);
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
        "service_modes":              _serviceModes,
        "trial_availability":         _trialAvailability,
        "styling_consultation":       _stylingConsultation,
        "home_measurement_service":   _homeMeasurementService,
        "alteration_services":        _alterationServices,
        "express_delivery_available": _expressDeliveryAvailable,
        "accessory_add_ons":          _accessoryAddOns,
      },
      "intelligence": {
        ...asMap(ex["intelligence"]),
        "sherwani_types":       _sherwaniTypes,
        "occasion_suitability": _occasionSuitability,
        "work_type":            _workType,
        "fabric_options":       _fabricOptions,
        "color_palette":        _colorPalette,
        "design_style":         _designStyle,
        "layering_options":     _layeringOptions,
      },
      "technical": {
        ...asMap(ex["technical"]),
        "fit_type":             _fitType,
        "closure_type":         _closureType,
        "length_type":          _lengthType,
        "inner_layer_included": _innerLayerIncluded,
        "bottom_wear_options":  _bottomWearOptions,
        "embroidery_density":   _embroideryDensity,
        "durability_level":     _durabilityLevel,
      },
      "pricing": {
        ...asMap(ex["pricing"]),
        "price_range":              _priceRange,
        "customization_charges":    _customizationCharges,
        "rental_pricing_option":    _rentalPricingOption,
        "accessory_bundle_pricing": _accessoryBundlePricing,
        "bulk_discounts":           _bulkDiscounts,
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
        const Text("Sherwani Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured sherwani attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _ss1,
            () => setState(() => _ss1 = !_ss1)),
        if (_ss1) ...[
          const SizedBox(height: 16),
          buildDropdown("Vendor Type",
            ["Designer Sherwani Studio", "Multi-Brand Retailer", "Bespoke Tailor",
             "Rental + Retail Hybrid", "Online Sherwani Brand"],
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
            ["Groom Sherwani", "Reception Sherwani", "Indo-Western Sherwani",
             "Prince Coat Sets", "Achkan"],
            _specialization,
            (o, c) => setState(() => c ? _specialization.add(o) : _specialization.remove(o))),
        ],
        dividerLine(),

        // ── Section 2: Services Offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _ss2,
            () => setState(() => _ss2 = !_ss2)),
        if (_ss2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Service Modes",
            ["Bespoke (Custom Tailored)", "Made-to-Measure", "Ready-to-Wear", "Rental Available"],
            _serviceModes,
            (o, c) => setState(() => c ? _serviceModes.add(o) : _serviceModes.remove(o))),
          buildYesNo("Trial Availability", _trialAvailability,
              (v) => setState(() => _trialAvailability = v)),
          buildYesNo("Styling Consultation", _stylingConsultation,
              (v) => setState(() => _stylingConsultation = v)),
          buildYesNo("Home Measurement Service", _homeMeasurementService,
              (v) => setState(() => _homeMeasurementService = v)),
          buildYesNo("Alteration Services", _alterationServices,
              (v) => setState(() => _alterationServices = v)),
          buildYesNo("Express Delivery Available", _expressDeliveryAvailable,
              (v) => setState(() => _expressDeliveryAvailable = v)),
          buildMultiSelect("Accessory Add-ons",
            ["Safa / Turban", "Stole / Dupatta", "Mojari", "Brooch", "Mala"],
            _accessoryAddOns,
            (o, c) => setState(() => c ? _accessoryAddOns.add(o) : _accessoryAddOns.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _ss3,
            () => setState(() => _ss3 = !_ss3)),
        if (_ss3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Sherwani Types",
            ["Traditional Sherwani", "Indo-Western Sherwani", "Jacket Style Sherwani",
             "Achkan", "Angrakha Style"],
            _sherwaniTypes,
            (o, c) => setState(() => c ? _sherwaniTypes.add(o) : _sherwaniTypes.remove(o))),
          buildMultiSelect("Occasion Suitability",
            ["Wedding Ceremony", "Reception", "Engagement", "Sangeet", "Baraat"],
            _occasionSuitability,
            (o, c) => setState(() => c ? _occasionSuitability.add(o) : _occasionSuitability.remove(o))),
          buildMultiSelect("Work Type",
            ["Zari", "Zardozi", "Thread Work", "Mirror Work", "Sequins", "Minimal"],
            _workType,
            (o, c) => setState(() => c ? _workType.add(o) : _workType.remove(o))),
          buildMultiSelect("Fabric Options",
            ["Silk", "Velvet", "Brocade", "Jacquard", "Cotton Silk", "Linen Blend"],
            _fabricOptions,
            (o, c) => setState(() => c ? _fabricOptions.add(o) : _fabricOptions.remove(o))),
          buildMultiSelect("Color Palette",
            ["Ivory / Cream", "Gold", "Pastel", "Maroon", "Navy", "Jewel Tones"],
            _colorPalette,
            (o, c) => setState(() => c ? _colorPalette.add(o) : _colorPalette.remove(o))),
          buildMultiSelect("Design Style",
            ["Heavy Bridal", "Semi-Bridal", "Minimal Elegant", "Royal Heritage"],
            _designStyle,
            (o, c) => setState(() => c ? _designStyle.add(o) : _designStyle.remove(o))),
          buildMultiSelect("Layering Options",
            ["With Dupatta", "Without Dupatta", "With Jacket Layer"],
            _layeringOptions,
            (o, c) => setState(() => c ? _layeringOptions.add(o) : _layeringOptions.remove(o))),
        ],
        dividerLine(),

        // ── Section 4: Technical / Product ─────────────────────────────────
        sectionHeader("Section 4 — Technical & product", _ss4,
            () => setState(() => _ss4 = !_ss4)),
        if (_ss4) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Fit Type",
            ["Slim Fit", "Regular Fit", "Custom Fit"],
            _fitType,
            (o, c) => setState(() => c ? _fitType.add(o) : _fitType.remove(o))),
          buildMultiSelect("Closure Type",
            ["Buttoned", "Hook", "Hidden Placket"],
            _closureType,
            (o, c) => setState(() => c ? _closureType.add(o) : _closureType.remove(o))),
          buildDropdown("Length Type",
            ["Knee Length", "Below Knee", "Ankle Length"],
            _lengthType, (v) => setState(() => _lengthType = v)),
          buildYesNo("Inner Layer Included", _innerLayerIncluded,
              (v) => setState(() => _innerLayerIncluded = v)),
          buildMultiSelect("Bottom Wear Options",
            ["Churidar", "Straight Pants", "Dhoti Pants", "Salwar"],
            _bottomWearOptions,
            (o, c) => setState(() => c ? _bottomWearOptions.add(o) : _bottomWearOptions.remove(o))),
          buildDropdown("Embroidery Density",
            ["Light", "Medium", "Heavy"],
            _embroideryDensity, (v) => setState(() => _embroideryDensity = v)),
          buildDropdown("Durability Level",
            ["Occasion Wear", "Premium Heirloom"],
            _durabilityLevel, (v) => setState(() => _durabilityLevel = v)),
        ],
        dividerLine(),

        // ── Section 5: Pricing Logic ───────────────────────────────────────
        sectionHeader("Section 5 — Pricing logic", _ss5,
            () => setState(() => _ss5 = !_ss5)),
        if (_ss5) ...[
          const SizedBox(height: 16),
          buildDropdown("Price Range per Sherwani (INR)",
            ["5K–20K", "20K–50K", "50K–1L", "1L–2L", "2L+"],
            _priceRange, (v) => setState(() => _priceRange = v)),
          buildDropdown("Customization Charges",
            ["Included", "Extra"],
            _customizationCharges, (v) => setState(() => _customizationCharges = v)),
          buildDropdown("Rental Pricing Option",
            ["Available", "Not Available"],
            _rentalPricingOption, (v) => setState(() => _rentalPricingOption = v)),
          buildDropdown("Accessory Bundle Pricing",
            ["Included", "Optional Add-on"],
            _accessoryBundlePricing, (v) => setState(() => _accessoryBundlePricing = v)),
          buildYesNo("Bulk Discounts (Groom Squad)", _bulkDiscounts,
              (v) => setState(() => _bulkDiscounts = v)),
        ],
        dividerLine(),

        // ── Section 6: Scale & Capacity ────────────────────────────────────
        sectionHeader("Section 6 — Scale & capacity", _ss6,
            () => setState(() => _ss6 = !_ss6)),
        if (_ss6) ...[
          const SizedBox(height: 16),
          buildDropdown("Daily Client Handling Capacity",
            ["1–5", "5–10", "10–20", "20+"],
            _dailyClientCapacity, (v) => setState(() => _dailyClientCapacity = v)),
          buildDropdown("Monthly Production Capacity",
            ["<20", "20–50", "50–100", "100+"],
            _monthlyProductionCapacity, (v) => setState(() => _monthlyProductionCapacity = v)),
          buildYesNo("Trial Room Availability", _trialRoomAvailability,
              (v) => setState(() => _trialRoomAvailability = v)),
        ],
        dividerLine(),

        // ── Section 7: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 7 — Workflow & booking", _ss7,
            () => setState(() => _ss7 = !_ss7)),
        if (_ss7) ...[
          const SizedBox(height: 16),
          buildYesNo("Appointment Required", _appointmentRequired,
              (v) => setState(() => _appointmentRequired = v)),
          buildMultiSelect("Measurement Process",
            ["In-store Measurement", "Home Visit", "Standard Size"],
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
        sectionHeader("Section 8 — Portfolio tagging (AI layer)", _ss8,
            () => setState(() => _ss8 = !_ss8)),
        if (_ss8) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Style Tags",
            ["Royal Groom", "Traditional Groom", "Modern Groom", "Minimal Groom"],
            _styleTags,
            (o, c) => setState(() => c ? _styleTags.add(o) : _styleTags.remove(o))),
          buildMultiSelect("Audience Tags",
            ["Groom", "Brother of Groom/Bride", "Wedding Party"],
            _audienceTags,
            (o, c) => setState(() => c ? _audienceTags.add(o) : _audienceTags.remove(o))),
          buildMultiSelect("Usage Tags",
            ["Wedding Ceremony", "Reception", "Baraat", "Sangeet"],
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
