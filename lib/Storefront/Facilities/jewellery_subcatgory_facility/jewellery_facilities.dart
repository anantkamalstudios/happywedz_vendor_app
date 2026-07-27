import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class JewelleryFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const JewelleryFacilities({super.key, required this.attributes});

  @override
  State<JewelleryFacilities> createState() => JewelleryFacilitiesState();
}

class JewelleryFacilitiesState extends State<JewelleryFacilities>
    with FacilitiesHelpersMixin<JewelleryFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  final        _brandStoreNameCtrl = TextEditingController();
  String?      _vendorType;
  final        _yearsExpCtrl  = TextEditingController();
  List<String> _cities        = [];
  String?      _serviceMode;
  String?      _deliveryCoverage;

  // ── product_categories ────────────────────────────────────────────────────
  List<String> _jewelleryTypesOffered = [];
  String?      _bridalPackageAvailable;
  List<String> _completeSetIncludes   = [];

  // ── style_design_intelligence ─────────────────────────────────────────────
  List<String> _jewelleryStyle      = [];
  List<String> _bestKnownFor        = [];
  List<String> _suitableFor         = [];
  String?      _outfitMatchingSupport;
  String?      _stylingConsultation;

  // ── material_quality ──────────────────────────────────────────────────────
  List<String> _baseMaterial   = [];
  String?      _finishQuality;
  String?      _realVsImitation;

  // ── rental_logic ──────────────────────────────────────────────────────────
  String?      _rentalDuration;
  String?      _rentalPriceRange;
  String?      _securityDeposit;
  String?      _depositAmountRange;
  String?      _lateReturnCharges;

  // ── availability_inventory ────────────────────────────────────────────────
  String?      _advanceBookingRequired;
  String?      _inventorySize;
  String?      _multiplePiecesAvailable;
  String?      _realtimeAvailabilityTracking;

  // ── delivery_logistics ────────────────────────────────────────────────────
  String?      _homeDeliveryAvailable;
  String?      _pickupRequired;
  String?      _shippingCharges;
  String?      _tryAtHomeService;

  // ── hygiene_quality ───────────────────────────────────────────────────────
  String?      _sanitizationProcess;
  String?      _damagePolicy;
  String?      _replacementAvailable;

  // ── event_suitability ─────────────────────────────────────────────────────
  List<String> _functionsSuitableFor = [];
  List<String> _bestFor              = [];

  // ── workflow_booking ──────────────────────────────────────────────────────
  String?      _advanceRequired;
  String?      _advancePercentage;
  String?      _cancellationPolicy;
  String?      _refundTimeline;

  // ── portfolio_tagging ─────────────────────────────────────────────────────
  final        _taggingGuidanceCtrl = TextEditingController();
  final        _notesCtrl           = TextEditingController();

  // ── section expansion ─────────────────────────────────────────────────────
  bool _js1  = true;
  bool _js2  = false;
  bool _js3  = false;
  bool _js4  = false;
  bool _js5  = false;
  bool _js6  = false;
  bool _js7  = false;
  bool _js8  = false;
  bool _js9  = false;
  bool _js10 = false;
  bool _js11 = false;

  static const List<String> _kCities = [
    "Mumbai", "Delhi", "Bangalore", "Hyderabad", "Chennai", "Kolkata",
    "Pune", "Ahmedabad", "Jaipur", "Surat", "Lucknow", "Nagpur",
    "Nashik", "Indore", "Bhopal", "Chandigarh", "Coimbatore",
    "Kochi", "Agra", "Varanasi", "Udaipur", "Jodhpur", "Goa",
  ];

  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _brandStoreNameCtrl.dispose();
    _yearsExpCtrl.dispose();
    _taggingGuidanceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final jm = asMap(attrs['jewellery_master']);

    final id = asMap(jm['identity']);
    _brandStoreNameCtrl.text = id['brand_store_name']?.toString() ?? '';
    _vendorType       = id['vendor_type'] as String?;
    _yearsExpCtrl.text = id['years_of_experience']?.toString() ?? '';
    _cities           = toList(id['cities']);
    _serviceMode      = id['service_mode'] as String?;
    _deliveryCoverage = id['delivery_coverage'] as String?;

    final pc = asMap(jm['product_categories']);
    _jewelleryTypesOffered  = toList(pc['jewellery_types_offered']);
    _bridalPackageAvailable = pc['bridal_package_available'] as String?;
    _completeSetIncludes    = toList(pc['complete_set_includes']);

    final sd = asMap(jm['style_design_intelligence']);
    _jewelleryStyle        = toList(sd['jewellery_style']);
    _bestKnownFor          = toList(sd['best_known_for']);
    _suitableFor           = toList(sd['suitable_for']);
    _outfitMatchingSupport = sd['outfit_matching_support'] as String?;
    _stylingConsultation   = sd['styling_consultation'] as String?;

    final mq = asMap(jm['material_quality']);
    _baseMaterial    = toList(mq['base_material']);
    _finishQuality   = mq['finish_quality'] as String?;
    _realVsImitation = mq['real_vs_imitation'] as String?;

    final rl = asMap(jm['rental_logic']);
    _rentalDuration     = rl['rental_duration'] as String?;
    _rentalPriceRange   = rl['rental_price_range'] as String?;
    _securityDeposit    = rl['security_deposit'] as String?;
    _depositAmountRange = rl['deposit_amount_range'] as String?;
    _lateReturnCharges  = rl['late_return_charges'] as String?;

    final ai = asMap(jm['availability_inventory']);
    _advanceBookingRequired       = ai['advance_booking_required'] as String?;
    _inventorySize                = ai['inventory_size'] as String?;
    _multiplePiecesAvailable      = ai['multiple_pieces_available'] as String?;
    _realtimeAvailabilityTracking = ai['realtime_availability_tracking'] as String?;

    final dl = asMap(jm['delivery_logistics']);
    _homeDeliveryAvailable = dl['home_delivery_available'] as String?;
    _pickupRequired        = dl['pickup_required'] as String?;
    _shippingCharges       = dl['shipping_charges'] as String?;
    _tryAtHomeService      = dl['try_at_home_service'] as String?;

    final hq = asMap(jm['hygiene_quality']);
    _sanitizationProcess  = hq['sanitization_process'] as String?;
    _damagePolicy         = hq['damage_policy'] as String?;
    _replacementAvailable = hq['replacement_available'] as String?;

    final es = asMap(jm['event_suitability']);
    _functionsSuitableFor = toList(es['functions_suitable_for']);
    _bestFor              = toList(es['best_for']);

    final wb = asMap(jm['workflow_booking']);
    _advanceRequired    = wb['advance_required'] as String?;
    _advancePercentage  = wb['advance_percentage'] as String?;
    _cancellationPolicy = wb['cancellation_policy'] as String?;
    _refundTimeline     = wb['refund_timeline'] as String?;

    final pt = asMap(jm['portfolio_tagging']);
    _taggingGuidanceCtrl.text = pt['tagging_guidance']?.toString() ?? '';
    _notesCtrl.text           = pt['notes']?.toString() ?? '';
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "brand_store_name":    _brandStoreNameCtrl.text,
        "vendor_type":         _vendorType,
        "years_of_experience": _yearsExpCtrl.text,
        "cities":              _cities,
        "service_mode":        _serviceMode,
        "delivery_coverage":   _deliveryCoverage,
      },
      "product_categories": {
        ...asMap(ex["product_categories"]),
        "jewellery_types_offered":  _jewelleryTypesOffered,
        "bridal_package_available": _bridalPackageAvailable,
        "complete_set_includes":    _completeSetIncludes,
      },
      "style_design_intelligence": {
        ...asMap(ex["style_design_intelligence"]),
        "jewellery_style":         _jewelleryStyle,
        "best_known_for":          _bestKnownFor,
        "suitable_for":            _suitableFor,
        "outfit_matching_support": _outfitMatchingSupport,
        "styling_consultation":    _stylingConsultation,
      },
      "material_quality": {
        ...asMap(ex["material_quality"]),
        "base_material":     _baseMaterial,
        "finish_quality":    _finishQuality,
        "real_vs_imitation": _realVsImitation,
      },
      "rental_logic": {
        ...asMap(ex["rental_logic"]),
        "rental_duration":      _rentalDuration,
        "rental_price_range":   _rentalPriceRange,
        "security_deposit":     _securityDeposit,
        "deposit_amount_range": _depositAmountRange,
        "late_return_charges":  _lateReturnCharges,
      },
      "availability_inventory": {
        ...asMap(ex["availability_inventory"]),
        "advance_booking_required":       _advanceBookingRequired,
        "inventory_size":                 _inventorySize,
        "multiple_pieces_available":      _multiplePiecesAvailable,
        "realtime_availability_tracking": _realtimeAvailabilityTracking,
      },
      "delivery_logistics": {
        ...asMap(ex["delivery_logistics"]),
        "home_delivery_available": _homeDeliveryAvailable,
        "pickup_required":         _pickupRequired,
        "shipping_charges":        _shippingCharges,
        "try_at_home_service":     _tryAtHomeService,
      },
      "hygiene_quality": {
        ...asMap(ex["hygiene_quality"]),
        "sanitization_process":  _sanitizationProcess,
        "damage_policy":         _damagePolicy,
        "replacement_available": _replacementAvailable,
      },
      "event_suitability": {
        ...asMap(ex["event_suitability"]),
        "functions_suitable_for": _functionsSuitableFor,
        "best_for":               _bestFor,
      },
      "workflow_booking": {
        ...asMap(ex["workflow_booking"]),
        "advance_required":    _advanceRequired,
        "advance_percentage":  _advancePercentage,
        "cancellation_policy": _cancellationPolicy,
        "refund_timeline":     _refundTimeline,
      },
      "portfolio_tagging": {
        ...asMap(ex["portfolio_tagging"]),
        "tagging_guidance": _taggingGuidanceCtrl.text,
        "notes":            _notesCtrl.text,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Jewellery Rental Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured jewellery attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _js1,
            () => setState(() => _js1 = !_js1)),
        if (_js1) ...[
          const SizedBox(height: 16),
          buildTextArea("Brand / Store Name", _brandStoreNameCtrl, maxLines: 1),
          buildDropdown("Vendor Type",
            ["Individual Curator", "Rental Boutique",
             "Designer Rental Studio", "Online Rental Platform"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildNumberField("Years of Experience", _yearsExpCtrl),
          buildMultiSelect("Cities Served", _kCities, _cities,
            (o, c) => setState(() => c ? _cities.add(o) : _cities.remove(o))),
          buildDropdown("Service Mode",
            ["Store Visit", "Online Rental", "Both"],
            _serviceMode, (v) => setState(() => _serviceMode = v)),
          buildDropdown("Delivery Coverage",
            ["Local Only", "Pan India", "International"],
            _deliveryCoverage, (v) => setState(() => _deliveryCoverage = v)),
        ],
        dividerLine(),

        // ── Section 2: Product Categories ──────────────────────────────────
        sectionHeader("Section 2 — Product categories", _js2,
            () => setState(() => _js2 = !_js2)),
        if (_js2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Jewellery Types Offered",
            ["Bridal Sets", "Necklace Sets", "Choker Sets", "Long Haar",
             "Earrings", "Maang Tikka", "Matha Patti", "Nath", "Bangles",
             "Finger Ring", "Hath phool", "Kada", "Anklets", "Waist Belt (Kamarbandh)"],
            _jewelleryTypesOffered,
            (o, c) => setState(() => c ? _jewelleryTypesOffered.add(o) : _jewelleryTypesOffered.remove(o))),
          buildDropdown("Bridal Package Available",
            ["Yes", "No"],
            _bridalPackageAvailable, (v) => setState(() => _bridalPackageAvailable = v)),
          buildMultiSelect("Complete Set Includes",
            ["Necklace", "Earrings", "Maang Tikka", "Nath", "Bangles", "Waist Belt"],
            _completeSetIncludes,
            (o, c) => setState(() => c ? _completeSetIncludes.add(o) : _completeSetIncludes.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Style & Design ──────────────────────────────────────
        sectionHeader("Section 3 — Style & design", _js3,
            () => setState(() => _js3 = !_js3)),
        if (_js3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Jewellery Style",
            ["Traditional", "Contemporary", "Temple Jewellery", "Polki",
             "Kundan", "Moti (Pearl)", "American Diamond", "Oxidized",
             "Antique Finish", "Minimal", "Statement"],
            _jewelleryStyle,
            (o, c) => setState(() => c ? _jewelleryStyle.add(o) : _jewelleryStyle.remove(o))),
          buildMultiSelect("Best Known For",
            ["Bridal Sets", "Luxury Jewellery", "Budget Rentals",
             "Statement Pieces", "Custom Styling"],
            _bestKnownFor,
            (o, c) => setState(() => c ? _bestKnownFor.add(o) : _bestKnownFor.remove(o))),
          buildMultiSelect("Suitable For",
            ["Bridal", "Bridesmaids", "Family", "Reception Looks", "Cocktail Looks"],
            _suitableFor,
            (o, c) => setState(() => c ? _suitableFor.add(o) : _suitableFor.remove(o))),
          buildYesNo("Outfit Matching Support", _outfitMatchingSupport,
              (v) => setState(() => _outfitMatchingSupport = v)),
          buildYesNo("Styling Consultation", _stylingConsultation,
              (v) => setState(() => _stylingConsultation = v)),
        ],
        dividerLine(),

        // ── Section 4: Material & Quality ──────────────────────────────────
        sectionHeader("Section 4 — Material & quality", _js4,
            () => setState(() => _js4 = !_js4)),
        if (_js4) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Base Material",
            ["Gold Plated", "Silver Based", "Alloy", "Mixed"],
            _baseMaterial,
            (o, c) => setState(() => c ? _baseMaterial.add(o) : _baseMaterial.remove(o))),
          buildDropdown("Finish Quality",
            ["Premium Finish", "Standard Finish"],
            _finishQuality, (v) => setState(() => _finishQuality = v)),
          buildDropdown("Real vs Imitation",
            ["Imitation Jewellery", "Semi-Precious", "Both"],
            _realVsImitation, (v) => setState(() => _realVsImitation = v)),
        ],
        dividerLine(),

        // ── Section 5: Rental Logic ────────────────────────────────────────
        sectionHeader("Section 5 — Rental logic", _js5,
            () => setState(() => _js5 = !_js5)),
        if (_js5) ...[
          const SizedBox(height: 16),
          buildDropdown("Rental Duration",
            ["1 Day", "2 Days", "3 Days", "Custom"],
            _rentalDuration, (v) => setState(() => _rentalDuration = v)),
          buildDropdown("Rental Price Range",
            ["Below ₹1K", "₹1K–₹3K", "₹3K–₹5K", "₹5K–₹10K", "₹10K+"],
            _rentalPriceRange, (v) => setState(() => _rentalPriceRange = v)),
          buildDropdown("Security Deposit",
            ["Yes (Refundable)", "No"],
            _securityDeposit, (v) => setState(() => _securityDeposit = v)),
          buildDropdown("Deposit Amount Range",
            ["Below ₹5K", "₹5K–₹10K", "₹10K–₹20K", "₹20K+"],
            _depositAmountRange, (v) => setState(() => _depositAmountRange = v)),
          buildDropdown("Late Return Charges",
            ["Yes", "No"],
            _lateReturnCharges, (v) => setState(() => _lateReturnCharges = v)),
        ],
        dividerLine(),

        // ── Section 6: Availability & Inventory ────────────────────────────
        sectionHeader("Section 6 — Availability & inventory", _js6,
            () => setState(() => _js6 = !_js6)),
        if (_js6) ...[
          const SizedBox(height: 16),
          buildYesNo("Advance Booking Required", _advanceBookingRequired,
              (v) => setState(() => _advanceBookingRequired = v)),
          buildDropdown("Inventory Size",
            ["0–50 Pieces", "50–200 Pieces", "200–500 Pieces", "500+ Pieces"],
            _inventorySize, (v) => setState(() => _inventorySize = v)),
          buildYesNo("Multiple Pieces Available", _multiplePiecesAvailable,
              (v) => setState(() => _multiplePiecesAvailable = v)),
          buildYesNo("Real-Time Availability Tracking", _realtimeAvailabilityTracking,
              (v) => setState(() => _realtimeAvailabilityTracking = v)),
        ],
        dividerLine(),

        // ── Section 7: Delivery & Logistics ────────────────────────────────
        sectionHeader("Section 7 — Delivery & logistics", _js7,
            () => setState(() => _js7 = !_js7)),
        if (_js7) ...[
          const SizedBox(height: 16),
          buildYesNo("Home Delivery Available", _homeDeliveryAvailable,
              (v) => setState(() => _homeDeliveryAvailable = v)),
          buildYesNo("Pickup Required", _pickupRequired,
              (v) => setState(() => _pickupRequired = v)),
          buildDropdown("Shipping Charges",
            ["Included", "Extra", "Depends on Location"],
            _shippingCharges, (v) => setState(() => _shippingCharges = v)),
          buildYesNo("Try-at-Home Service", _tryAtHomeService,
              (v) => setState(() => _tryAtHomeService = v)),
        ],
        dividerLine(),

        // ── Section 8: Hygiene & Quality Assurance ─────────────────────────
        sectionHeader("Section 8 — Hygiene & quality assurance", _js8,
            () => setState(() => _js8 = !_js8)),
        if (_js8) ...[
          const SizedBox(height: 16),
          buildYesNo("Sanitization Process", _sanitizationProcess,
              (v) => setState(() => _sanitizationProcess = v)),
          buildDropdown("Damage Policy",
            ["Full Charge", "Partial Charge", "Case-by-Case"],
            _damagePolicy, (v) => setState(() => _damagePolicy = v)),
          buildYesNo("Replacement Available", _replacementAvailable,
              (v) => setState(() => _replacementAvailable = v)),
        ],
        dividerLine(),

        // ── Section 9: Event Suitability ───────────────────────────────────
        sectionHeader("Section 9 — Event suitability", _js9,
            () => setState(() => _js9 = !_js9)),
        if (_js9) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Functions Suitable For",
            ["Haldi", "Mehendi", "Sangeet", "Wedding", "Reception", "Cocktail"],
            _functionsSuitableFor,
            (o, c) => setState(() => c ? _functionsSuitableFor.add(o) : _functionsSuitableFor.remove(o))),
          buildMultiSelect("Best For",
            ["Bridal Looks", "Budget Weddings", "Luxury Weddings", "Destination Weddings"],
            _bestFor,
            (o, c) => setState(() => c ? _bestFor.add(o) : _bestFor.remove(o))),
        ],
        dividerLine(),

        // ── Section 10: Workflow & Booking ─────────────────────────────────
        sectionHeader("Section 10 — Workflow & booking", _js10,
            () => setState(() => _js10 = !_js10)),
        if (_js10) ...[
          const SizedBox(height: 16),
          buildYesNo("Advance Required", _advanceRequired,
              (v) => setState(() => _advanceRequired = v)),
          buildDropdown("Advance Percentage",
            ["25%", "50%", "75%"],
            _advancePercentage, (v) => setState(() => _advancePercentage = v)),
          buildDropdown("Cancellation Policy",
            ["Non Refundable", "Partial Refund", "Flexible"],
            _cancellationPolicy, (v) => setState(() => _cancellationPolicy = v)),
          buildDropdown("Refund Timeline",
            ["3 Days", "7 Days", "15 Days"],
            _refundTimeline, (v) => setState(() => _refundTimeline = v)),
        ],
        dividerLine(),

        // ── Section 11: Portfolio & Product Tagging ────────────────────────
        sectionHeader("Section 11 — Portfolio & product tagging", _js11,
            () => setState(() => _js11 = !_js11)),
        if (_js11) ...[
          const SizedBox(height: 8),
          Text(
            "Upload your jewellery catalog in the Photos tab. Tag each product with Jewellery Type, Style, Occasion, Outfit Color Match, Budget Range.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          buildTextArea("Default Tagging Guidance", _taggingGuidanceCtrl, maxLines: 2),
          buildTextArea("Notes", _notesCtrl),
        ],
      ],
    );
  }
}
