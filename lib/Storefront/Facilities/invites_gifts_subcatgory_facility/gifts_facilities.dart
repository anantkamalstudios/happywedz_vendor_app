import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class GiftsFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const GiftsFacilities({super.key, required this.attributes});

  @override
  State<GiftsFacilities> createState() => GiftsFacilitiesState();
}

class GiftsFacilitiesState extends State<GiftsFacilities>
    with FacilitiesHelpersMixin<GiftsFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  final        _brandNameCtrl    = TextEditingController();
  String?      _vendorType;
  final        _primaryCityCtrl  = TextEditingController();
  String?      _yearsOfExperience;
  List<String> _serviceCities    = [];
  String?      _businessModel;

  // ── catalog ───────────────────────────────────────────────────────────────
  List<String> _giftCategories       = [];
  String?      _targetAudience;
  List<String> _occasionSuitability  = [];

  // ── intelligence ──────────────────────────────────────────────────────────
  String?      _giftTypeClassification;
  List<String> _customizationOptions = [];
  String?      _themeCompatibility;
  String?      _shelfLife;
  String?      _packagingIncluded;
  String?      _ecoFriendlyOptions;
  String?      _premiumLuxuryTag;

  // ── capacity ──────────────────────────────────────────────────────────────
  String?      _minimumOrderQuantity;
  String?      _maximumOrderCapacity;
  String?      _bulkOrderHandling;
  String?      _readyStockAvailability;
  String?      _customizationTurnaround;

  // ── logistics ─────────────────────────────────────────────────────────────
  String?      _deliveryOptions;
  String?      _shippingCoverage;
  String?      _fragileHandling;
  String?      _temperatureControl;
  String?      _storageSupport;
  String?      _urgentOrders;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _pricingModel;
  String?      _startingPriceRange;
  List<String> _includes          = [];
  List<String> _addOns            = [];
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
  final        _giftTagsCtrl     = TextEditingController();
  final        _styleTagsCtrl    = TextEditingController();
  final        _occasionTagsCtrl = TextEditingController();

  // ── section expansion ─────────────────────────────────────────────────────
  bool _gs1  = true;
  bool _gs2  = false;
  bool _gs3  = false;
  bool _gs4  = false;
  bool _gs5  = false;
  bool _gs6  = false;
  bool _gs7  = false;
  bool _gs8  = false;
  bool _gs9  = false;


  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _brandNameCtrl.dispose();
    _primaryCityCtrl.dispose();
    _giftTagsCtrl.dispose();
    _styleTagsCtrl.dispose();
    _occasionTagsCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final gm = asMap(attrs['gift_master']);

    final id = asMap(gm['identity']);
    _brandNameCtrl.text  = id['brand_name']?.toString() ?? '';
    _vendorType          = id['vendor_type'] as String?;
    _primaryCityCtrl.text = id['primary_city']?.toString() ?? '';
    _yearsOfExperience   = id['years_of_experience'] as String?;
    _serviceCities       = toList(id['service_cities']);
    _businessModel       = id['business_model'] as String?;

    final cat = asMap(gm['catalog']);
    _giftCategories      = toList(cat['gift_categories']);
    _targetAudience      = cat['target_audience'] as String?;
    _occasionSuitability = toList(cat['occasion_suitability']);

    final intel = asMap(gm['intelligence']);
    _giftTypeClassification = intel['gift_type_classification'] as String?;
    _customizationOptions   = toList(intel['customization_options']);
    _themeCompatibility     = intel['theme_compatibility'] as String?;
    _shelfLife              = intel['shelf_life'] as String?;
    _packagingIncluded      = intel['packaging_included'] as String?;
    _ecoFriendlyOptions     = intel['eco_friendly_options'] as String?;
    _premiumLuxuryTag       = intel['premium_luxury_tag'] as String?;

    final cap = asMap(gm['capacity']);
    _minimumOrderQuantity    = cap['minimum_order_quantity'] as String?;
    _maximumOrderCapacity    = cap['maximum_order_capacity']?.toString();
    _bulkOrderHandling       = cap['bulk_order_handling'] as String?;
    _readyStockAvailability  = cap['ready_stock_availability'] as String?;
    _customizationTurnaround = cap['customization_turnaround'] as String?;

    final log = asMap(gm['logistics']);
    _deliveryOptions  = log['delivery_options'] as String?;
    _shippingCoverage = log['shipping_coverage'] as String?;
    _fragileHandling  = log['fragile_handling'] as String?;
    _temperatureControl = log['temperature_control'] as String?;
    _storageSupport   = log['storage_support'] as String?;
    _urgentOrders     = log['urgent_orders'] as String?;


    final pr = asMap(gm['pricing']);
    _pricingModel          = pr['pricing_model'] as String?;
    _startingPriceRange    = pr['starting_price_range'] as String?;
    _includes              = toList(pr['includes']);
    _addOns                = toList(pr['add_ons']);
    _negotiationFlexibility = pr['negotiation_flexibility'] as String?;

    final sc = asMap(gm['scale']);
    _ordersPerDayCapacity = sc['orders_per_day_capacity'] as String?;
    _teamSize             = sc['team_size'] as String?;
    _parallelOrders       = sc['parallel_orders'] as String?;

    final wf = asMap(gm['workflow']);
    _advanceBookingTime   = wf['advance_booking_time'] as String?;
    _bookingAdvancePercent = wf['booking_advance_percent'] as String?;
    _cancellationPolicy   = wf['cancellation_policy'] as String?;
    _clientCoordination   = wf['client_coordination'] as String?;
    _sampleAvailability   = wf['sample_availability'] as String?;

    final port = asMap(gm['portfolio']);
    _giftTagsCtrl.text     = _portfolioStr(port['gift_tags']);
    _styleTagsCtrl.text    = _portfolioStr(port['style_tags']);
    _occasionTagsCtrl.text = _portfolioStr(port['occasion_tags']);
  }

  String _portfolioStr(dynamic v) {
    if (v == null || v.toString() == 'na') return '';
    return v.toString();
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "brand_name":          _brandNameCtrl.text,
        "vendor_type":         _vendorType,
        "primary_city":        _primaryCityCtrl.text,
        "years_of_experience": _yearsOfExperience,
        "service_cities":      _serviceCities,
        "business_model":      _businessModel,
      },
      "catalog": {
        ...asMap(ex["catalog"]),
        "gift_categories":     _giftCategories,
        "target_audience":     _targetAudience,
        "occasion_suitability":_occasionSuitability,
      },
      "intelligence": {
        ...asMap(ex["intelligence"]),
        "gift_type_classification": _giftTypeClassification,
        "customization_options":    _customizationOptions,
        "theme_compatibility":      _themeCompatibility,
        "shelf_life":               _shelfLife,
        "packaging_included":       _packagingIncluded,
        "eco_friendly_options":     _ecoFriendlyOptions,
        "premium_luxury_tag":       _premiumLuxuryTag,
      },
      "capacity": {
        ...asMap(ex["capacity"]),
        "minimum_order_quantity":    _minimumOrderQuantity,
        "maximum_order_capacity":    _maximumOrderCapacity,
        "bulk_order_handling":       _bulkOrderHandling,
        "ready_stock_availability":  _readyStockAvailability,
        "customization_turnaround":  _customizationTurnaround,
      },
      "logistics": {
        ...asMap(ex["logistics"]),
        "delivery_options":   _deliveryOptions,
        "shipping_coverage":  _shippingCoverage,
        "fragile_handling":   _fragileHandling,
        "temperature_control":_temperatureControl,
        "storage_support":    _storageSupport,
        "urgent_orders":      _urgentOrders,
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
        "gift_tags":     _giftTagsCtrl.text,
        "style_tags":    _styleTagsCtrl.text,
        "occasion_tags": _occasionTagsCtrl.text,
      },
    };
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Gifts Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured gift vendor attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _gs1,
            () => setState(() => _gs1 = !_gs1)),
        if (_gs1) ...[
          const SizedBox(height: 16),

          buildDropdown("Years of Experience",
            ["0–1", "1–3", "3–5", "5–10", "10+"],
            _yearsOfExperience, (v) => setState(() => _yearsOfExperience = v)),
          buildTextArea("Primary City", _primaryCityCtrl, maxLines: 1),

          buildDropdown("Business Model",
            ["Ready Stock", "Made-to-Order", "Hybrid"],
            _businessModel, (v) => setState(() => _businessModel = v)),
        ],
        dividerLine(),

        // ── Section 2: Product Catalog ─────────────────────────────────────
        sectionHeader("Section 2 — Product catalog", _gs2,
            () => setState(() => _gs2 = !_gs2)),
        if (_gs2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Gift Categories",
            ["Dry Fruits", "Chocolates", "Gourmet Hampers", "Home Decor",
             "Utility Gifts", "Kitchenware", "Apparel Gifts",
             "Wellness Products", "Religious Items", "Luxury Items"],
            _giftCategories,
            (o, c) => setState(() => c ? _giftCategories.add(o) : _giftCategories.remove(o))),
          buildDropdown("Target Audience",
            ["Guests", "Close Family", "VIP Guests", "Corporate Guests", "Kids"],
            _targetAudience, (v) => setState(() => _targetAudience = v)),
          buildMultiSelect("Occasion Suitability",
            ["Wedding Return Gifts", "Mehendi Gifts", "Haldi Gifts",
             "Engagement Gifts", "Corporate Gifting", "Festive Gifting"],
            _occasionSuitability,
            (o, c) => setState(() => c ? _occasionSuitability.add(o) : _occasionSuitability.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _gs3,
            () => setState(() => _gs3 = !_gs3)),
        if (_gs3) ...[
          const SizedBox(height: 16),
          buildDropdown("Gift Type Classification",
            ["Consumable", "Non-Consumable", "Experience-Based", "Personalized"],
            _giftTypeClassification, (v) => setState(() => _giftTypeClassification = v)),
          buildMultiSelect("Customization Options",
            ["Name Personalization", "Initials / Monogram",
             "Photo Printing", "Custom Message", "Branding (for corporate)"],
            _customizationOptions,
            (o, c) => setState(() => c ? _customizationOptions.add(o) : _customizationOptions.remove(o))),
          buildDropdown("Theme Compatibility",
            ["Royal Wedding", "Minimal Elegant", "Traditional",
             "Modern Luxury", "Eco-friendly", "Destination Wedding"],
            _themeCompatibility, (v) => setState(() => _themeCompatibility = v)),
          buildDropdown("Shelf Life (consumables)",
            ["<7 days", "7–15 days", "15–30 days", "30–90 days", "90+ days"],
            _shelfLife, (v) => setState(() => _shelfLife = v)),
          buildYesNo("Packaging Included", _packagingIncluded,
              (v) => setState(() => _packagingIncluded = v)),
          buildYesNo("Eco-Friendly Options", _ecoFriendlyOptions,
              (v) => setState(() => _ecoFriendlyOptions = v)),
          buildDropdown("Premium / Luxury Tag",
            ["Budget", "Mid-range", "Premium", "Ultra Luxury"],
            _premiumLuxuryTag, (v) => setState(() => _premiumLuxuryTag = v)),
        ],
        dividerLine(),

        // ── Section 4: Product & Capacity ──────────────────────────────────
        sectionHeader("Section 4 — Product & capacity", _gs4,
            () => setState(() => _gs4 = !_gs4)),
        if (_gs4) ...[
          const SizedBox(height: 16),
          buildDropdown("Minimum Order Quantity",
            ["1–50", "50–100", "100–300", "300–500", "500+"],
            _minimumOrderQuantity, (v) => setState(() => _minimumOrderQuantity = v)),
          buildDropdown("Maximum Order Capacity",
            ["100", "100–500", "500–1000", "1000+"],
            _maximumOrderCapacity, (v) => setState(() => _maximumOrderCapacity = v)),
          buildYesNo("Bulk Order Handling", _bulkOrderHandling,
              (v) => setState(() => _bulkOrderHandling = v)),
          buildYesNo("Ready Stock Availability", _readyStockAvailability,
              (v) => setState(() => _readyStockAvailability = v)),
          buildDropdown("Customization Turnaround Time",
            ["1–3 days", "3–7 days", "7–14 days", "14+ days"],
            _customizationTurnaround, (v) => setState(() => _customizationTurnaround = v)),
        ],
        dividerLine(),

        // ── Section 5: Logistics & Fulfillment ─────────────────────────────
        sectionHeader("Section 5 — Logistics & fulfillment", _gs5,
            () => setState(() => _gs5 = !_gs5)),
        if (_gs5) ...[
          const SizedBox(height: 16),
          buildDropdown("Delivery Options",
            ["Pickup", "Home Delivery", "Courier"],
            _deliveryOptions, (v) => setState(() => _deliveryOptions = v)),
          buildDropdown("Shipping Coverage",
            ["Local", "Pan-India", "International"],
            _shippingCoverage, (v) => setState(() => _shippingCoverage = v)),
          buildYesNo("Fragile Handling", _fragileHandling,
              (v) => setState(() => _fragileHandling = v)),
          buildYesNo("Temperature-Control Available", _temperatureControl,
              (v) => setState(() => _temperatureControl = v)),
          buildYesNo("Storage Support", _storageSupport,
              (v) => setState(() => _storageSupport = v)),
          buildYesNo("Urgent Orders Accepted", _urgentOrders,
              (v) => setState(() => _urgentOrders = v)),
        ],
        dividerLine(),

        // ── Section 6: Pricing Logic ────────────────────────────────────────
        sectionHeader("Section 6 — Pricing logic", _gs6,
            () => setState(() => _gs6 = !_gs6)),
        if (_gs6) ...[
          const SizedBox(height: 16),
          buildDropdown("Pricing Model",
            ["Per Unit", "Per Hamper", "Bulk Pricing", "Package"],
            _pricingModel, (v) => setState(() => _pricingModel = v)),
          buildDropdown("Starting Price Range (Per Unit)",
            ["₹100–₹300", "₹300–₹700", "₹700–₹1500", "₹1500–₹5000", "₹5000+"],
            _startingPriceRange, (v) => setState(() => _startingPriceRange = v)),
          buildMultiSelect("Includes",
            ["Product", "Packaging", "Personalization", "Delivery"],
            _includes,
            (o, c) => setState(() => c ? _includes.add(o) : _includes.remove(o))),
          buildMultiSelect("Add-ons",
            ["Premium Packaging", "Custom Branding", "Express Delivery", "Gift Wrapping"],
            _addOns,
            (o, c) => setState(() => c ? _addOns.add(o) : _addOns.remove(o))),
          buildDropdown("Negotiation Flexibility",
            ["Fixed", "Moderate", "Flexible"],
            _negotiationFlexibility, (v) => setState(() => _negotiationFlexibility = v)),
        ],
        dividerLine(),

        // ── Section 7: Scale & Operations ──────────────────────────────────
        sectionHeader("Section 7 — Scale & operations", _gs7,
            () => setState(() => _gs7 = !_gs7)),
        if (_gs7) ...[
          const SizedBox(height: 16),
          buildDropdown("Orders Per Day Capacity",
            ["1–50", "50–200", "200–500", "500+"],
            _ordersPerDayCapacity, (v) => setState(() => _ordersPerDayCapacity = v)),
          buildDropdown("Team Size",
            ["Solo", "2–5", "5–10", "10+"],
            _teamSize, (v) => setState(() => _teamSize = v)),
          buildYesNo("Parallel Orders", _parallelOrders,
              (v) => setState(() => _parallelOrders = v)),
        ],
        dividerLine(),

        // ── Section 8: Workflow & Booking ───────────────────────────────────
        sectionHeader("Section 8 — Workflow & booking", _gs8,
            () => setState(() => _gs8 = !_gs8)),
        if (_gs8) ...[
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
        sectionHeader("Section 9 — Portfolio tagging (AI layer)", _gs9,
            () => setState(() => _gs9 = !_gs9)),
        if (_gs9) ...[
          const SizedBox(height: 8),
          Text(
            "Upload gift photos in the Photos tab. Tag each image to enable AI search.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          buildTextArea("Gift Tags (e.g. Luxury Gifts, Budget Gifts, Eco-friendly Gifts)",
            _giftTagsCtrl, maxLines: 2),
          buildTextArea("Style Tags (e.g. Traditional, Modern, Minimal, Royal)",
            _styleTagsCtrl, maxLines: 2),
          buildTextArea("Occasion Tags (e.g. Wedding Return, Mehendi Favours, Corporate Gifts)",
            _occasionTagsCtrl, maxLines: 2),
        ],
      ],
    );
  }
}
