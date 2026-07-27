import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class TrousseauPackersFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const TrousseauPackersFacilities({super.key, required this.attributes});

  @override
  State<TrousseauPackersFacilities> createState() =>
      TrousseauPackersFacilitiesState();
}

class TrousseauPackersFacilitiesState extends State<TrousseauPackersFacilities>
    with FacilitiesHelpersMixin<TrousseauPackersFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  String?      _vendorType;
  final        _brandNameCtrl   = TextEditingController();
  String?      _yearsOfExperience;
  final        _primaryCityCtrl = TextEditingController();
  List<String> _serviceCities   = [];
  String?      _serviceMode;
  String?      _travelPolicy;

  // ── services ──────────────────────────────────────────────────────────────
  List<String> _packagingTypes   = [];
  List<String> _productFormats    = [];
  List<String> _occasionCoverage  = [];

  // ── intelligence ──────────────────────────────────────────────────────────
  List<String> _designStyle            = [];
  String?      _customizationLevel;
  List<String> _materialTypes          = [];
  String?      _colorPalette;
  List<String> _personalizationOptions = [];
  List<String> _embellishments         = [];

  // ── capacity ──────────────────────────────────────────────────────────────
  String?      _minimumOrderQuantity;
  String?      _maximumOrderHandling;
  String?      _bulkOrderCapability;
  String?      _readyStockAvailability;
  String?      _customizationTurnaround;

  // ── logistics ─────────────────────────────────────────────────────────────
  String?      _deliveryOptions;
  String?      _packagingAssembly;
  String?      _fragileHandling;
  String?      _storageSupport;
  String?      _urgentOrderHandling;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _pricingModel;
  String?      _startingPriceRange;
  List<String> _includes = [];
  List<String> _addOns    = [];
  String?      _negotiationFlexibility;

  // ── scale ─────────────────────────────────────────────────────────────────
  String?      _ordersPerDayCapacity;
  String?      _teamSize;
  String?      _parallelOrderHandling;

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _advanceBookingTime;
  String?      _bookingAdvancePercent;
  String?      _cancellationPolicy;
  String?      _clientCoordination;
  String?      _sampleAvailability;

  // ── portfolio ─────────────────────────────────────────────────────────────
  final        _packagingTagsCtrl = TextEditingController();
  final        _occasionTagsCtrl  = TextEditingController();
  final        _styleTagsCtrl     = TextEditingController();

  // ── section expansion ─────────────────────────────────────────────────────
  bool _ts1 = true;
  bool _ts2 = false;
  bool _ts3 = false;
  bool _ts4 = false;
  bool _ts5 = false;
  bool _ts6 = false;
  bool _ts7 = false;
  bool _ts8 = false;
  bool _ts9 = false;

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
    _packagingTagsCtrl.dispose();
    _occasionTagsCtrl.dispose();
    _styleTagsCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final tm = asMap(attrs['trousseau_master']);

    final id = asMap(tm['identity']);
    _vendorType         = id['vendor_type'] as String?;
    _brandNameCtrl.text = id['brand_name']?.toString() ?? '';
    _yearsOfExperience  = id['years_of_experience'] as String?;
    _primaryCityCtrl.text = id['primary_city']?.toString() ?? '';
    _serviceCities      = toList(id['service_cities']);
    _serviceMode        = id['service_mode'] as String?;
    _travelPolicy       = id['travel_policy'] as String?;

    final sv = asMap(tm['services']);
    _packagingTypes   = toList(sv['packaging_types']);
    _productFormats   = toList(sv['product_formats']);
    _occasionCoverage = toList(sv['occasion_coverage']);

    final ci = asMap(tm['intelligence']);
    _designStyle            = toList(ci['design_style']);
    _customizationLevel     = ci['customization_level'] as String?;
    _materialTypes          = toList(ci['material_types']);
    _colorPalette           = ci['color_palette'] as String?;
    _personalizationOptions = toList(ci['personalization_options']);
    _embellishments         = toList(ci['embellishments']);

    final cap = asMap(tm['capacity']);
    _minimumOrderQuantity    = cap['minimum_order_quantity'] as String?;
    _maximumOrderHandling    = cap['maximum_order_handling'] as String?;
    _bulkOrderCapability     = cap['bulk_order_capability'] as String?;
    _readyStockAvailability  = cap['ready_stock_availability'] as String?;
    _customizationTurnaround = cap['customization_turnaround'] as String?;

    final lg = asMap(tm['logistics']);
    _deliveryOptions     = lg['delivery_options'] as String?;
    _packagingAssembly   = lg['packaging_assembly'] as String?;
    _fragileHandling     = lg['fragile_handling'] as String?;
    _storageSupport      = lg['storage_support'] as String?;
    _urgentOrderHandling = lg['urgent_order_handling'] as String?;

    final pr = asMap(tm['pricing']);
    _pricingModel          = pr['pricing_model'] as String?;
    _startingPriceRange    = pr['starting_price_range'] as String?;
    _includes              = toList(pr['includes']);
    _addOns                = toList(pr['add_ons']);
    _negotiationFlexibility = pr['negotiation_flexibility'] as String?;

    final sc = asMap(tm['scale']);
    _ordersPerDayCapacity  = sc['orders_per_day_capacity'] as String?;
    _teamSize              = sc['team_size'] as String?;
    _parallelOrderHandling = sc['parallel_order_handling'] as String?;

    final wf = asMap(tm['workflow']);
    _advanceBookingTime    = wf['advance_booking_time'] as String?;
    _bookingAdvancePercent = wf['booking_advance_percent'] as String?;
    _cancellationPolicy    = wf['cancellation_policy'] as String?;
    _clientCoordination    = wf['client_coordination'] as String?;
    _sampleAvailability    = wf['sample_availability'] as String?;

    final po = asMap(tm['portfolio']);
    _packagingTagsCtrl.text = _clean(po['packaging_tags']);
    _occasionTagsCtrl.text  = _clean(po['occasion_tags']);
    _styleTagsCtrl.text     = _clean(po['style_tags']);
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "vendor_type":         _vendorType,
        "brand_name":          _brandNameCtrl.text,
        "years_of_experience": _yearsOfExperience,
        "primary_city":        _primaryCityCtrl.text,
        "service_cities":      _serviceCities,
        "service_mode":        _serviceMode,
        "travel_policy":       _travelPolicy,
      },
      "services": {
        ...asMap(ex["services"]),
        "packaging_types":   _packagingTypes,
        "product_formats":   _productFormats,
        "occasion_coverage": _occasionCoverage,
      },
      "intelligence": {
        ...asMap(ex["intelligence"]),
        "design_style":            _designStyle,
        "customization_level":     _customizationLevel,
        "material_types":          _materialTypes,
        "color_palette":           _colorPalette,
        "personalization_options": _personalizationOptions,
        "embellishments":          _embellishments,
      },
      "capacity": {
        ...asMap(ex["capacity"]),
        "minimum_order_quantity":   _minimumOrderQuantity,
        "maximum_order_handling":   _maximumOrderHandling,
        "bulk_order_capability":    _bulkOrderCapability,
        "ready_stock_availability": _readyStockAvailability,
        "customization_turnaround": _customizationTurnaround,
      },
      "logistics": {
        ...asMap(ex["logistics"]),
        "delivery_options":      _deliveryOptions,
        "packaging_assembly":    _packagingAssembly,
        "fragile_handling":      _fragileHandling,
        "storage_support":       _storageSupport,
        "urgent_order_handling": _urgentOrderHandling,
      },
      "pricing": {
        ...asMap(ex["pricing"]),
        "pricing_model":           _pricingModel,
        "starting_price_range":    _startingPriceRange,
        "includes":                _includes,
        "add_ons":                 _addOns,
        "negotiation_flexibility": _negotiationFlexibility,
      },
      "scale": {
        ...asMap(ex["scale"]),
        "orders_per_day_capacity": _ordersPerDayCapacity,
        "team_size":               _teamSize,
        "parallel_order_handling": _parallelOrderHandling,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "advance_booking_time":    _advanceBookingTime,
        "booking_advance_percent": _bookingAdvancePercent,
        "cancellation_policy":     _cancellationPolicy,
        "client_coordination":     _clientCoordination,
        "sample_availability":     _sampleAvailability,
      },
      "portfolio": {
        ...asMap(ex["portfolio"]),
        "packaging_tags": _packagingTagsCtrl.text,
        "occasion_tags":  _occasionTagsCtrl.text,
        "style_tags":     _styleTagsCtrl.text,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Trousseau Packers Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured trousseau packing attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _ts1,
            () => setState(() => _ts1 = !_ts1)),
        if (_ts1) ...[
          const SizedBox(height: 16),
          buildDropdown("Vendor Type",
            ["Individual Artist", "Packaging Studio", "Luxury Packaging Brand",
             "Bulk Supplier + Customization"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildTextArea("Brand Name", _brandNameCtrl, maxLines: 1),
          buildDropdown("Years of Experience",
            ["0–1", "1–3", "3–5", "5–10", "10+"],
            _yearsOfExperience, (v) => setState(() => _yearsOfExperience = v)),
          buildTextArea("Primary City", _primaryCityCtrl, maxLines: 1),
          buildMultiSelect("Service Cities",
            ["Pan-India (Courier)", "International Shipping"],
            _serviceCities,
            (o, c) => setState(() => c ? _serviceCities.add(o) : _serviceCities.remove(o))),
          buildDropdown("Service Mode",
            ["On-site Packing", "Studio-based Packing", "Pickup & Delivery", "Courier Only"],
            _serviceMode, (v) => setState(() => _serviceMode = v)),
          buildDropdown("Travel Policy",
            ["Included (local)", "Fixed Cost", "Per Km", "Not Applicable"],
            _travelPolicy, (v) => setState(() => _travelPolicy = v)),
        ],
        dividerLine(),

        // ── Section 2: Services Offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _ts2,
            () => setState(() => _ts2 = !_ts2)),
        if (_ts2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Packaging Types",
            ["Bridal Trousseau Packing", "Groom Trousseau Packing", "Saree Packing",
             "Lehenga Packing", "Jewelry Packing", "Gift Packing",
             "Dry Fruit Packing", "Return Gifts Packing"],
            _packagingTypes,
            (o, c) => setState(() => c ? _packagingTypes.add(o) : _packagingTypes.remove(o))),
          buildMultiSelect("Product Formats",
            ["Boxes", "Trunks", "Suitcases", "Baskets", "Potlis",
             "Hampers", "Trays", "Envelopes"],
            _productFormats,
            (o, c) => setState(() => c ? _productFormats.add(o) : _productFormats.remove(o))),
          buildMultiSelect("Occasion Coverage",
            ["Wedding", "Engagement", "Mehendi", "Haldi", "Baby Shower", "Festive Gifting"],
            _occasionCoverage,
            (o, c) => setState(() => c ? _occasionCoverage.add(o) : _occasionCoverage.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _ts3,
            () => setState(() => _ts3 = !_ts3)),
        if (_ts3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Design Style",
            ["Royal Traditional", "Minimal Elegant", "Floral Theme",
             "Modern Luxury", "Customized Theme", "Cultural Regional"],
            _designStyle,
            (o, c) => setState(() => c ? _designStyle.add(o) : _designStyle.remove(o))),
          buildDropdown("Customization Level",
            ["Fully Custom", "Semi-Custom", "Pre-designed Catalog"],
            _customizationLevel, (v) => setState(() => _customizationLevel = v)),
          buildMultiSelect("Material Types",
            ["Fabric (Silk, Velvet)", "MDF / Wood", "Acrylic", "Metal",
             "Paper / Cardboard", "Jute / Eco-friendly"],
            _materialTypes,
            (o, c) => setState(() => c ? _materialTypes.add(o) : _materialTypes.remove(o))),
          buildDropdown("Color Palette Options",
            ["Pastels", "Bright Traditional", "Metallic (Gold/Silver)", "Neutral Tones", "Custom"],
            _colorPalette, (v) => setState(() => _colorPalette = v)),
          buildMultiSelect("Personalization Options",
            ["Name Printing", "Initials / Monogram", "Photos",
             "Quotes / Messages", "Theme Matching"],
            _personalizationOptions,
            (o, c) => setState(() => c ? _personalizationOptions.add(o) : _personalizationOptions.remove(o))),
          buildMultiSelect("Embellishments",
            ["Gota Patti", "Zari Work", "Mirror Work", "Floral Decor",
             "Lace", "Tassels", "Beads"],
            _embellishments,
            (o, c) => setState(() => c ? _embellishments.add(o) : _embellishments.remove(o))),
        ],
        dividerLine(),

        // ── Section 4: Product & Capacity ──────────────────────────────────
        sectionHeader("Section 4 — Product & capacity", _ts4,
            () => setState(() => _ts4 = !_ts4)),
        if (_ts4) ...[
          const SizedBox(height: 16),
          buildDropdown("Minimum Order Quantity",
            ["1–10", "10–50", "50–100", "100+"],
            _minimumOrderQuantity, (v) => setState(() => _minimumOrderQuantity = v)),
          buildDropdown("Maximum Order Handling",
            ["Up to 50", "50–200", "200–500", "500+"],
            _maximumOrderHandling, (v) => setState(() => _maximumOrderHandling = v)),
          buildYesNo("Bulk Order Capability", _bulkOrderCapability,
              (v) => setState(() => _bulkOrderCapability = v)),
          buildYesNo("Ready Stock Availability", _readyStockAvailability,
              (v) => setState(() => _readyStockAvailability = v)),
          buildDropdown("Customization Turnaround Time",
            ["1–3 days", "3–7 days", "7–14 days", "14+ days"],
            _customizationTurnaround, (v) => setState(() => _customizationTurnaround = v)),
        ],
        dividerLine(),

        // ── Section 5: Logistics & Execution ───────────────────────────────
        sectionHeader("Section 5 — Logistics & execution", _ts5,
            () => setState(() => _ts5 = !_ts5)),
        if (_ts5) ...[
          const SizedBox(height: 16),
          buildDropdown("Delivery Options",
            ["Pickup", "Home Delivery", "Courier"],
            _deliveryOptions, (v) => setState(() => _deliveryOptions = v)),
          buildDropdown("Packaging Assembly",
            ["Vendor Studio", "On-site (Client Location)", "Hybrid"],
            _packagingAssembly, (v) => setState(() => _packagingAssembly = v)),
          buildYesNo("Fragile Handling", _fragileHandling,
              (v) => setState(() => _fragileHandling = v)),
          buildYesNo("Storage Support", _storageSupport,
              (v) => setState(() => _storageSupport = v)),
          buildYesNo("Urgent Order Handling", _urgentOrderHandling,
              (v) => setState(() => _urgentOrderHandling = v)),
        ],
        dividerLine(),

        // ── Section 6: Pricing Logic ───────────────────────────────────────
        sectionHeader("Section 6 — Pricing logic", _ts6,
            () => setState(() => _ts6 = !_ts6)),
        if (_ts6) ...[
          const SizedBox(height: 16),
          buildDropdown("Pricing Model",
            ["Per Piece", "Per Set", "Bulk Pricing", "Package"],
            _pricingModel, (v) => setState(() => _pricingModel = v)),
          buildDropdown("Starting Price Range (Per Unit)",
            ["₹200–₹500", "₹500–₹1000", "₹1000–₹3000", "₹3000–₹7000", "₹7000+"],
            _startingPriceRange, (v) => setState(() => _startingPriceRange = v)),
          buildMultiSelect("Includes",
            ["Base Packaging", "Decoration", "Personalization", "Packing Service"],
            _includes,
            (o, c) => setState(() => c ? _includes.add(o) : _includes.remove(o))),
          buildMultiSelect("Add-ons",
            ["Premium Materials", "Custom Design", "Urgent Delivery", "Logistics"],
            _addOns,
            (o, c) => setState(() => c ? _addOns.add(o) : _addOns.remove(o))),
          buildDropdown("Negotiation Flexibility",
            ["Fixed", "Moderate", "Flexible"],
            _negotiationFlexibility, (v) => setState(() => _negotiationFlexibility = v)),
        ],
        dividerLine(),

        // ── Section 7: Scale & Operations ──────────────────────────────────
        sectionHeader("Section 7 — Scale & operations", _ts7,
            () => setState(() => _ts7 = !_ts7)),
        if (_ts7) ...[
          const SizedBox(height: 16),
          buildDropdown("Orders Per Day Capacity",
            ["1–10", "10–50", "50–100", "100+"],
            _ordersPerDayCapacity, (v) => setState(() => _ordersPerDayCapacity = v)),
          buildDropdown("Team Size",
            ["Solo", "2–5", "5–10", "10+"],
            _teamSize, (v) => setState(() => _teamSize = v)),
          buildYesNo("Parallel Order Handling", _parallelOrderHandling,
              (v) => setState(() => _parallelOrderHandling = v)),
        ],
        dividerLine(),

        // ── Section 8: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 8 — Workflow & booking", _ts8,
            () => setState(() => _ts8 = !_ts8)),
        if (_ts8) ...[
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
            ["WhatsApp", "Call", "In-person", "App-based"],
            _clientCoordination, (v) => setState(() => _clientCoordination = v)),
          buildYesNo("Sample Availability", _sampleAvailability,
              (v) => setState(() => _sampleAvailability = v)),
        ],
        dividerLine(),

        // ── Section 9: Portfolio Tagging ───────────────────────────────────
        sectionHeader("Section 9 — Portfolio tagging (AI layer)", _ts9,
            () => setState(() => _ts9 = !_ts9)),
        if (_ts9) ...[
          const SizedBox(height: 8),
          Text(
            "Tag your portfolio uploads. Packaging e.g. Luxury / Budget / Eco-friendly; Occasion e.g. Bridal Trousseau / Return Gifts; Style e.g. Floral / Royal / Minimal.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          buildTextArea("Packaging Tags", _packagingTagsCtrl, maxLines: 2),
          buildTextArea("Occasion Tags", _occasionTagsCtrl, maxLines: 2),
          buildTextArea("Style Tags", _styleTagsCtrl, maxLines: 2),
        ],
      ],
    );
  }
}
