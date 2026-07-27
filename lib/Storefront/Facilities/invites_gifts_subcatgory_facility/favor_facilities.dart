import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class FavorFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const FavorFacilities({super.key, required this.attributes});

  @override
  State<FavorFacilities> createState() => FavorFacilitiesState();
}

class FavorFacilitiesState extends State<FavorFacilities>
    with FacilitiesHelpersMixin<FavorFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  final        _brandNameCtrl   = TextEditingController();
  String?      _vendorType;
  String?      _yearsOfExperience;
  final        _primaryCityCtrl = TextEditingController();
  List<String> _serviceCities   = [];
  String?      _businessModel;

  // ── catalog ───────────────────────────────────────────────────────────────
  List<String> _favorCategories = [];
  List<String> _occasionMapping  = [];
  String?      _audienceTarget;

  // ── intelligence ──────────────────────────────────────────────────────────
  String?      _favorTypeClassification;
  List<String> _customizationOptions = [];
  String?      _themeCompatibility;
  String?      _shelfLife;
  List<String> _packagingType  = [];
  String?      _ecoFriendlyOption;
  String?      _reusability;

  // ── capacity ──────────────────────────────────────────────────────────────
  String?      _minimumOrderQuantity;
  String?      _maximumOrderCapacity;
  String?      _bulkHandling;
  String?      _readyStock;
  String?      _customizationTurnaround;

  // ── logistics ─────────────────────────────────────────────────────────────
  String?      _deliveryOptions;
  String?      _shippingCoverage;
  String?      _fragileHandling;
  String?      _temperatureSensitivityHandling;
  String?      _urgentOrders;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _pricingModel;
  String?      _startingPriceRange;
  List<String> _includes = [];
  List<String> _addOns    = [];
  String?      _negotiationFlexibility;

  // ── scale ─────────────────────────────────────────────────────────────────
  String?      _ordersPerDayCapacity;
  String?      _teamSize;
  String?      _parallelOrders;

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _advanceBookingTime;
  String?      _bookingAdvancePercent;
  String?      _cancellationPolicy;
  String?      _clientCoordination;
  String?      _sampleAvailability;

  // ── portfolio ─────────────────────────────────────────────────────────────
  final        _favorTagsCtrl    = TextEditingController();
  final        _occasionTagsCtrl = TextEditingController();
  final        _styleTagsCtrl    = TextEditingController();

  // ── section expansion ─────────────────────────────────────────────────────
  bool _fs1 = true;
  bool _fs2 = false;
  bool _fs3 = false;
  bool _fs4 = false;
  bool _fs5 = false;
  bool _fs6 = false;
  bool _fs7 = false;
  bool _fs8 = false;
  bool _fs9 = false;

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
    _favorTagsCtrl.dispose();
    _occasionTagsCtrl.dispose();
    _styleTagsCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final fm = asMap(attrs['favor_master']);

    final id = asMap(fm['identity']);
    _brandNameCtrl.text = id['brand_name']?.toString() ?? '';
    _vendorType         = id['vendor_type'] as String?;
    _yearsOfExperience  = id['years_of_experience'] as String?;
    _primaryCityCtrl.text = id['primary_city']?.toString() ?? '';
    _serviceCities      = toList(id['service_cities']);
    _businessModel      = id['business_model'] as String?;

    final cat = asMap(fm['catalog']);
    _favorCategories = toList(cat['favor_categories']);
    _occasionMapping = toList(cat['occasion_mapping']);
    _audienceTarget  = cat['audience_target'] as String?;

    final ci = asMap(fm['intelligence']);
    _favorTypeClassification = ci['favor_type_classification'] as String?;
    _customizationOptions    = toList(ci['customization_options']);
    _themeCompatibility      = ci['theme_compatibility'] as String?;
    _shelfLife               = ci['shelf_life'] as String?;
    _packagingType           = toList(ci['packaging_type']);
    _ecoFriendlyOption       = ci['eco_friendly_option'] as String?;
    _reusability             = ci['reusability'] as String?;

    final cap = asMap(fm['capacity']);
    _minimumOrderQuantity    = cap['minimum_order_quantity'] as String?;
    _maximumOrderCapacity    = cap['maximum_order_capacity']?.toString();
    _bulkHandling            = cap['bulk_handling'] as String?;
    _readyStock              = cap['ready_stock'] as String?;
    _customizationTurnaround = cap['customization_turnaround'] as String?;

    final lg = asMap(fm['logistics']);
    _deliveryOptions                = lg['delivery_options'] as String?;
    _shippingCoverage               = lg['shipping_coverage'] as String?;
    _fragileHandling                = lg['fragile_handling'] as String?;
    _temperatureSensitivityHandling = lg['temperature_sensitivity_handling'] as String?;
    _urgentOrders                   = lg['urgent_orders'] as String?;

    final pr = asMap(fm['pricing']);
    _pricingModel          = pr['pricing_model'] as String?;
    _startingPriceRange    = pr['starting_price_range'] as String?;
    _includes              = toList(pr['includes']);
    _addOns                = toList(pr['add_ons']);
    _negotiationFlexibility = pr['negotiation_flexibility'] as String?;

    final sc = asMap(fm['scale']);
    _ordersPerDayCapacity = sc['orders_per_day_capacity'] as String?;
    _teamSize             = sc['team_size'] as String?;
    _parallelOrders       = sc['parallel_orders'] as String?;

    final wf = asMap(fm['workflow']);
    _advanceBookingTime    = wf['advance_booking_time'] as String?;
    _bookingAdvancePercent = wf['booking_advance_percent'] as String?;
    _cancellationPolicy    = wf['cancellation_policy'] as String?;
    _clientCoordination    = wf['client_coordination'] as String?;
    _sampleAvailability    = wf['sample_availability'] as String?;

    final po = asMap(fm['portfolio']);
    _favorTagsCtrl.text    = _clean(po['favor_tags']);
    _occasionTagsCtrl.text = _clean(po['occasion_tags']);
    _styleTagsCtrl.text    = _clean(po['style_tags']);
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
        "business_model":      _businessModel,
      },
      "catalog": {
        ...asMap(ex["catalog"]),
        "favor_categories": _favorCategories,
        "occasion_mapping": _occasionMapping,
        "audience_target":  _audienceTarget,
      },
      "intelligence": {
        ...asMap(ex["intelligence"]),
        "favor_type_classification": _favorTypeClassification,
        "customization_options":     _customizationOptions,
        "theme_compatibility":       _themeCompatibility,
        "shelf_life":                _shelfLife,
        "packaging_type":            _packagingType,
        "eco_friendly_option":       _ecoFriendlyOption,
        "reusability":               _reusability,
      },
      "capacity": {
        ...asMap(ex["capacity"]),
        "minimum_order_quantity":   _minimumOrderQuantity,
        "maximum_order_capacity":   _maximumOrderCapacity,
        "bulk_handling":            _bulkHandling,
        "ready_stock":              _readyStock,
        "customization_turnaround": _customizationTurnaround,
      },
      "logistics": {
        ...asMap(ex["logistics"]),
        "delivery_options":                 _deliveryOptions,
        "shipping_coverage":                _shippingCoverage,
        "fragile_handling":                 _fragileHandling,
        "temperature_sensitivity_handling": _temperatureSensitivityHandling,
        "urgent_orders":                    _urgentOrders,
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
        "parallel_orders":         _parallelOrders,
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
        "favor_tags":    _favorTagsCtrl.text,
        "occasion_tags": _occasionTagsCtrl.text,
        "style_tags":    _styleTagsCtrl.text,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Favors Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured favor attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _fs1,
            () => setState(() => _fs1 = !_fs1)),
        if (_fs1) ...[
          const SizedBox(height: 16),
          buildDropdown("Vendor Type",
            ["Favor Specialist", "Gift Studio (Favors Focus)", "Bulk Supplier",
             "Luxury Favor Curator", "Eco-friendly Favor Brand"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildTextArea("Brand Name", _brandNameCtrl, maxLines: 1),
          buildDropdown("Years of Experience",
            ["0–1", "1–3", "3–5", "5–10", "10+"],
            _yearsOfExperience, (v) => setState(() => _yearsOfExperience = v)),
          buildTextArea("Primary City", _primaryCityCtrl, maxLines: 1),
          buildMultiSelect("Service Cities",
            ["Pan-India Shipping", "International Shipping"],
            _serviceCities,
            (o, c) => setState(() => c ? _serviceCities.add(o) : _serviceCities.remove(o))),
          buildDropdown("Business Model",
            ["Ready Stock", "Made-to-Order", "Hybrid"],
            _businessModel, (v) => setState(() => _businessModel = v)),
        ],
        dividerLine(),

        // ── Section 2: Product Catalog ─────────────────────────────────────
        sectionHeader("Section 2 — Product catalog", _fs2,
            () => setState(() => _fs2 = !_fs2)),
        if (_fs2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Favor Categories",
            ["Edible Favors", "Mini Hampers", "Scented Candles", "Soaps / Skincare Minis",
             "Seed / Plant Kits", "Religious Tokens", "Utility Items",
             "Decorative Items", "Personalized Keepsakes"],
            _favorCategories,
            (o, c) => setState(() => c ? _favorCategories.add(o) : _favorCategories.remove(o))),
          buildMultiSelect("Occasion Mapping",
            ["Mehendi Favors", "Haldi Favors", "Sangeet Favors",
             "Wedding Favors", "Reception Favors", "Kids Favors"],
            _occasionMapping,
            (o, c) => setState(() => c ? _occasionMapping.add(o) : _occasionMapping.remove(o))),
          buildDropdown("Audience Target",
            ["All Guests", "Ladies Only", "Kids Only", "VIP Guests", "Family"],
            _audienceTarget, (v) => setState(() => _audienceTarget = v)),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _fs3,
            () => setState(() => _fs3 = !_fs3)),
        if (_fs3) ...[
          const SizedBox(height: 16),
          buildDropdown("Favor Type Classification",
            ["Consumable", "Non-Consumable", "Eco-friendly", "Personalized", "Thematic"],
            _favorTypeClassification, (v) => setState(() => _favorTypeClassification = v)),
          buildMultiSelect("Customization Options",
            ["Name Tags", "Initials", "Event Name", "Date Print",
             "Custom Message", "Color Matching"],
            _customizationOptions,
            (o, c) => setState(() => c ? _customizationOptions.add(o) : _customizationOptions.remove(o))),
          buildDropdown("Theme Compatibility",
            ["Floral", "Royal", "Minimal", "Rustic", "Modern Luxury", "Cultural Traditional"],
            _themeCompatibility, (v) => setState(() => _themeCompatibility = v)),
          buildDropdown("Shelf Life (if edible)",
            ["<7 days", "7–15 days", "15–30 days", "30+ days"],
            _shelfLife, (v) => setState(() => _shelfLife = v)),
          buildMultiSelect("Packaging Type",
            ["Boxes", "Jars", "Bottles", "Pouches", "Baskets", "Trays"],
            _packagingType,
            (o, c) => setState(() => c ? _packagingType.add(o) : _packagingType.remove(o))),
          buildYesNo("Eco-Friendly Option", _ecoFriendlyOption,
              (v) => setState(() => _ecoFriendlyOption = v)),
          buildYesNo("Reusability", _reusability,
              (v) => setState(() => _reusability = v)),
        ],
        dividerLine(),

        // ── Section 4: Product & Capacity ──────────────────────────────────
        sectionHeader("Section 4 — Product & capacity", _fs4,
            () => setState(() => _fs4 = !_fs4)),
        if (_fs4) ...[
          const SizedBox(height: 16),
          buildDropdown("Minimum Order Quantity",
            ["10–50", "50–100", "100–300", "300–500", "500+"],
            _minimumOrderQuantity, (v) => setState(() => _minimumOrderQuantity = v)),
          buildDropdown("Maximum Order Capacity",
            ["100", "100–500", "500–1000", "1000+"],
            _maximumOrderCapacity, (v) => setState(() => _maximumOrderCapacity = v)),
          buildYesNo("Bulk Handling", _bulkHandling,
              (v) => setState(() => _bulkHandling = v)),
          buildYesNo("Ready Stock", _readyStock,
              (v) => setState(() => _readyStock = v)),
          buildDropdown("Customization Turnaround",
            ["1–3 days", "3–7 days", "7–14 days", "14+ days"],
            _customizationTurnaround, (v) => setState(() => _customizationTurnaround = v)),
        ],
        dividerLine(),

        // ── Section 5: Logistics & Fulfillment ─────────────────────────────
        sectionHeader("Section 5 — Logistics & fulfillment", _fs5,
            () => setState(() => _fs5 = !_fs5)),
        if (_fs5) ...[
          const SizedBox(height: 16),
          buildDropdown("Delivery Options",
            ["Pickup", "Home Delivery", "Courier"],
            _deliveryOptions, (v) => setState(() => _deliveryOptions = v)),
          buildDropdown("Shipping Coverage",
            ["Local", "Pan-India", "International"],
            _shippingCoverage, (v) => setState(() => _shippingCoverage = v)),
          buildYesNo("Fragile Handling", _fragileHandling,
              (v) => setState(() => _fragileHandling = v)),
          buildYesNo("Temperature Sensitivity Handling", _temperatureSensitivityHandling,
              (v) => setState(() => _temperatureSensitivityHandling = v)),
          buildYesNo("Urgent Orders", _urgentOrders,
              (v) => setState(() => _urgentOrders = v)),
        ],
        dividerLine(),

        // ── Section 6: Pricing Logic ───────────────────────────────────────
        sectionHeader("Section 6 — Pricing logic", _fs6,
            () => setState(() => _fs6 = !_fs6)),
        if (_fs6) ...[
          const SizedBox(height: 16),
          buildDropdown("Pricing Model",
            ["Per Unit", "Bulk Pricing", "Per Set", "Package"],
            _pricingModel, (v) => setState(() => _pricingModel = v)),
          buildDropdown("Starting Price Range (Per Unit)",
            ["₹50–₹150", "₹150–₹300", "₹300–₹700", "₹700–₹1500", "₹1500+"],
            _startingPriceRange, (v) => setState(() => _startingPriceRange = v)),
          buildMultiSelect("Includes",
            ["Product", "Packaging", "Tagging / Personalization", "Delivery"],
            _includes,
            (o, c) => setState(() => c ? _includes.add(o) : _includes.remove(o))),
          buildMultiSelect("Add-ons",
            ["Premium Packaging", "Custom Tags", "Express Delivery", "Special Materials"],
            _addOns,
            (o, c) => setState(() => c ? _addOns.add(o) : _addOns.remove(o))),
          buildDropdown("Negotiation Flexibility",
            ["Fixed", "Moderate", "Flexible"],
            _negotiationFlexibility, (v) => setState(() => _negotiationFlexibility = v)),
        ],
        dividerLine(),

        // ── Section 7: Scale & Operations ──────────────────────────────────
        sectionHeader("Section 7 — Scale & operations", _fs7,
            () => setState(() => _fs7 = !_fs7)),
        if (_fs7) ...[
          const SizedBox(height: 16),
          buildDropdown("Orders Per Day Capacity",
            ["50–100", "100–300", "300–700", "700+"],
            _ordersPerDayCapacity, (v) => setState(() => _ordersPerDayCapacity = v)),
          buildDropdown("Team Size",
            ["Solo", "2–5", "5–10", "10+"],
            _teamSize, (v) => setState(() => _teamSize = v)),
          buildYesNo("Parallel Orders", _parallelOrders,
              (v) => setState(() => _parallelOrders = v)),
        ],
        dividerLine(),

        // ── Section 8: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 8 — Workflow & booking", _fs8,
            () => setState(() => _fs8 = !_fs8)),
        if (_fs8) ...[
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
          buildYesNo("Sample Availability", _sampleAvailability,
              (v) => setState(() => _sampleAvailability = v)),
        ],
        dividerLine(),

        // ── Section 9: Portfolio Tagging ───────────────────────────────────
        sectionHeader("Section 9 — Portfolio tagging (AI layer)", _fs9,
            () => setState(() => _fs9 = !_fs9)),
        if (_fs9) ...[
          const SizedBox(height: 8),
          Text(
            "Tag your portfolio uploads. Favor e.g. Budget / Luxury / Eco-friendly; Occasion e.g. Mehendi Giveaways / Wedding Return; Style e.g. Floral / Rustic / Royal.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          buildTextArea("Favor Tags", _favorTagsCtrl, maxLines: 2),
          buildTextArea("Occasion Tags", _occasionTagsCtrl, maxLines: 2),
          buildTextArea("Style Tags", _styleTagsCtrl, maxLines: 2),
        ],
      ],
    );
  }
}
