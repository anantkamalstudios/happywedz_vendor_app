import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class FlowerJewelleryFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const FlowerJewelleryFacilities({super.key, required this.attributes});

  @override
  State<FlowerJewelleryFacilities> createState() =>
      FlowerJewelleryFacilitiesState();
}

class FlowerJewelleryFacilitiesState extends State<FlowerJewelleryFacilities>
    with FacilitiesHelpersMixin<FlowerJewelleryFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  final        _brandNameCtrl = TextEditingController();
  String?      _vendorType;
  final        _yearsExpCtrl  = TextEditingController();
  final        _cityCtrl      = TextEditingController();
  String?      _serviceCoverage;
  String?      _deliveryMode;

  // ── product_categories ────────────────────────────────────────────────────
  List<String> _jewelleryItems  = [];
  String?      _bridalSetAvailable;
  List<String> _setIncludes      = [];

  // ── material_type ─────────────────────────────────────────────────────────
  String?      _flowerType;
  List<String> _freshFlowerTypes   = [];
  List<String> _artificialMaterial = [];
  String?      _durability;

  // ── style_design ──────────────────────────────────────────────────────────
  List<String> _styleCategories      = [];
  List<String> _bestKnownFor         = [];
  List<String> _suitableFor          = [];
  String?      _outfitMatchingSupport;
  String?      _customizationAvailable;
  List<String> _customDesignInputs   = [];

  // ── function_specific ─────────────────────────────────────────────────────
  List<String> _functionsSuitableFor = [];
  String?      _bestFunction;

  // ── pricing_logic ─────────────────────────────────────────────────────────
  final        _startingPriceCtrl = TextEditingController();
  String?      _pricingType;
  String?      _bridalSetPriceRange;
  String?      _bulkOrdersSupported;
  String?      _bulkPricing;

  // ── delivery_timing ───────────────────────────────────────────────────────
  String?      _orderPrepTime;
  String?      _deliveryTiming;
  String?      _timeSlotDelivery;
  String?      _earlyMorningDelivery;

  // ── storage_handling ──────────────────────────────────────────────────────
  String?      _storageInstructions;
  String?      _replacementPolicy;
  String?      _damageHandling;

  // ── inventory_availability ────────────────────────────────────────────────
  String?      _dailyOrderCapacity;
  String?      _advanceBookingRequired;
  String?      _peakSeasonAvailability;

  // ── workflow_booking ──────────────────────────────────────────────────────
  String?      _advanceRequired;
  String?      _advancePercentage;
  String?      _cancellationPolicy;
  String?      _refundTimeline;

  // ── section expansion ─────────────────────────────────────────────────────
  bool _fs1  = true;
  bool _fs2  = false;
  bool _fs3  = false;
  bool _fs4  = false;
  bool _fs5  = false;
  bool _fs6  = false;
  bool _fs7  = false;
  bool _fs8  = false;
  bool _fs9  = false;
  bool _fs10 = false;

  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _brandNameCtrl.dispose();
    _yearsExpCtrl.dispose();
    _cityCtrl.dispose();
    _startingPriceCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final fm = asMap(attrs['flower_jewellery_master']);

    final id = asMap(fm['identity']);
    _brandNameCtrl.text = id['brand_name']?.toString() ?? '';
    _vendorType       = id['vendor_type'] as String?;
    _yearsExpCtrl.text = id['years_of_experience']?.toString() ?? '';
    _cityCtrl.text    = id['city']?.toString() ?? '';
    _serviceCoverage  = id['service_coverage'] as String?;
    _deliveryMode     = id['delivery_mode'] as String?;

    final pc = asMap(fm['product_categories']);
    _jewelleryItems     = toList(pc['jewellery_items']);
    _bridalSetAvailable = pc['bridal_set_available'] as String?;
    _setIncludes        = toList(pc['set_includes']);

    final mt = asMap(fm['material_type']);
    _flowerType         = mt['flower_type'] as String?;
    _freshFlowerTypes   = toList(mt['fresh_flower_types']);
    _artificialMaterial = toList(mt['artificial_material']);
    _durability         = mt['durability'] as String?;

    final sd = asMap(fm['style_design']);
    _styleCategories        = toList(sd['style_categories']);
    _bestKnownFor           = toList(sd['best_known_for']);
    _suitableFor            = toList(sd['suitable_for']);
    _outfitMatchingSupport  = sd['outfit_matching_support'] as String?;
    _customizationAvailable = sd['customization_available'] as String?;
    _customDesignInputs     = toList(sd['custom_design_inputs']);

    final fsp = asMap(fm['function_specific']);
    _functionsSuitableFor = toList(fsp['functions_suitable_for']);
    _bestFunction         = fsp['best_function'] as String?;

    final pl = asMap(fm['pricing_logic']);
    _startingPriceCtrl.text = pl['starting_price']?.toString() ?? '';
    _pricingType         = pl['pricing_type'] as String?;
    _bridalSetPriceRange = pl['bridal_set_price_range'] as String?;
    _bulkOrdersSupported = pl['bulk_orders_supported'] as String?;
    _bulkPricing         = pl['bulk_pricing'] as String?;

    final dt = asMap(fm['delivery_timing']);
    _orderPrepTime        = dt['order_prep_time'] as String?;
    _deliveryTiming       = dt['delivery_timing'] as String?;
    _timeSlotDelivery     = dt['time_slot_delivery'] as String?;
    _earlyMorningDelivery = dt['early_morning_delivery'] as String?;

    final sh = asMap(fm['storage_handling']);
    _storageInstructions = sh['storage_instructions'] as String?;
    _replacementPolicy   = sh['replacement_policy'] as String?;
    _damageHandling      = sh['damage_handling'] as String?;

    final ia = asMap(fm['inventory_availability']);
    _dailyOrderCapacity     = ia['daily_order_capacity'] as String?;
    _advanceBookingRequired = ia['advance_booking_required'] as String?;
    _peakSeasonAvailability = ia['peak_season_availability'] as String?;

    final wb = asMap(fm['workflow_booking']);
    _advanceRequired    = wb['advance_required'] as String?;
    _advancePercentage  = wb['advance_percentage'] as String?;
    _cancellationPolicy = wb['cancellation_policy'] as String?;
    _refundTimeline     = wb['refund_timeline'] as String?;
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "brand_name":          _brandNameCtrl.text,
        "vendor_type":         _vendorType,
        "years_of_experience": _yearsExpCtrl.text,
        "city":                _cityCtrl.text,
        "service_coverage":    _serviceCoverage,
        "delivery_mode":       _deliveryMode,
      },
      "product_categories": {
        ...asMap(ex["product_categories"]),
        "jewellery_items":      _jewelleryItems,
        "bridal_set_available": _bridalSetAvailable,
        "set_includes":         _setIncludes,
      },
      "material_type": {
        ...asMap(ex["material_type"]),
        "flower_type":         _flowerType,
        "fresh_flower_types":  _freshFlowerTypes,
        "artificial_material": _artificialMaterial,
        "durability":          _durability,
      },
      "style_design": {
        ...asMap(ex["style_design"]),
        "style_categories":        _styleCategories,
        "best_known_for":          _bestKnownFor,
        "suitable_for":            _suitableFor,
        "outfit_matching_support": _outfitMatchingSupport,
        "customization_available": _customizationAvailable,
        "custom_design_inputs":    _customDesignInputs,
      },
      "function_specific": {
        ...asMap(ex["function_specific"]),
        "functions_suitable_for": _functionsSuitableFor,
        "best_function":          _bestFunction,
      },
      "pricing_logic": {
        ...asMap(ex["pricing_logic"]),
        "starting_price":         _startingPriceCtrl.text,
        "pricing_type":           _pricingType,
        "bridal_set_price_range": _bridalSetPriceRange,
        "bulk_orders_supported":  _bulkOrdersSupported,
        "bulk_pricing":           _bulkPricing,
      },
      "delivery_timing": {
        ...asMap(ex["delivery_timing"]),
        "order_prep_time":        _orderPrepTime,
        "delivery_timing":        _deliveryTiming,
        "time_slot_delivery":     _timeSlotDelivery,
        "early_morning_delivery": _earlyMorningDelivery,
      },
      "storage_handling": {
        ...asMap(ex["storage_handling"]),
        "storage_instructions": _storageInstructions,
        "replacement_policy":   _replacementPolicy,
        "damage_handling":      _damageHandling,
      },
      "inventory_availability": {
        ...asMap(ex["inventory_availability"]),
        "daily_order_capacity":     _dailyOrderCapacity,
        "advance_booking_required": _advanceBookingRequired,
        "peak_season_availability": _peakSeasonAvailability,
      },
      "workflow_booking": {
        ...asMap(ex["workflow_booking"]),
        "advance_required":    _advanceRequired,
        "advance_percentage":  _advancePercentage,
        "cancellation_policy": _cancellationPolicy,
        "refund_timeline":     _refundTimeline,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Flower Jewellery Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured flower jewellery attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _fs1,
            () => setState(() => _fs1 = !_fs1)),
        if (_fs1) ...[
          const SizedBox(height: 16),
          buildTextArea("Brand / Vendor Name", _brandNameCtrl, maxLines: 1),
          buildDropdown("Vendor Type",
            ["Individual Designer", "Home-Based Business", "Studio", "Boutique Brand"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildNumberField("Years of Experience", _yearsExpCtrl),
          buildTextArea("City", _cityCtrl, maxLines: 1),
          buildDropdown("Service Coverage",
            ["Local Only", "Pan India", "International"],
            _serviceCoverage, (v) => setState(() => _serviceCoverage = v)),
          buildDropdown("Delivery Mode",
            ["Pickup Only", "Home Delivery", "Both"],
            _deliveryMode, (v) => setState(() => _deliveryMode = v)),
        ],
        dividerLine(),

        // ── Section 2: Product Categories ──────────────────────────────────
        sectionHeader("Section 2 — Product categories", _fs2,
            () => setState(() => _fs2 = !_fs2)),
        if (_fs2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Jewellery Items Offered",
            ["Necklace", "Earrings", "Maang Tikka", "Matha Patti", "Bracelet",
             "Bangles", "Anklets", "Waist Belt (Kamarbandh)", "Hair Accessories", "Kaleere"],
            _jewelleryItems,
            (o, c) => setState(() => c ? _jewelleryItems.add(o) : _jewelleryItems.remove(o))),
          buildDropdown("Bridal Flower Jewellery Set",
            ["Yes", "No"],
            _bridalSetAvailable, (v) => setState(() => _bridalSetAvailable = v)),
          buildMultiSelect("Complete Set Includes",
            ["Necklace", "Earrings", "Maang Tikka", "Bangles", "Kaleere", "Customisable"],
            _setIncludes,
            (o, c) => setState(() => c ? _setIncludes.add(o) : _setIncludes.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Material & Type ─────────────────────────────────────
        sectionHeader("Section 3 — Material & type", _fs3,
            () => setState(() => _fs3 = !_fs3)),
        if (_fs3) ...[
          const SizedBox(height: 16),
          buildDropdown("Flower Type",
            ["Fresh Flowers", "Artificial Flowers", "Both"],
            _flowerType, (v) => setState(() => _flowerType = v)),
          if (_flowerType != "Artificial Flowers")
            buildMultiSelect("Fresh Flower Types",
              ["Roses", "Marigold", "Orchids", "Jasmine", "Baby's Breath",
               "Mixed Flowers", "Tagar", "Mogra"],
              _freshFlowerTypes,
              (o, c) => setState(() => c ? _freshFlowerTypes.add(o) : _freshFlowerTypes.remove(o))),
          if (_flowerType != "Fresh Flowers")
            buildMultiSelect("Artificial Material",
              ["Fabric Flowers", "Foam Flowers", "Paper Flowers"],
              _artificialMaterial,
              (o, c) => setState(() => c ? _artificialMaterial.add(o) : _artificialMaterial.remove(o))),
          buildDropdown("Durability",
            ["6–8 Hours", "8–12 Hours", "12–24 Hours", "Multi-Day"],
            _durability, (v) => setState(() => _durability = v)),
        ],
        dividerLine(),

        // ── Section 4: Style & Design ──────────────────────────────────────
        sectionHeader("Section 4 — Style & design", _fs4,
            () => setState(() => _fs4 = !_fs4)),
        if (_fs4) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Style Categories",
            ["Traditional", "Minimal", "Floral Heavy", "Pastel Theme",
             "Vibrant Theme", "Contemporary"],
            _styleCategories,
            (o, c) => setState(() => c ? _styleCategories.add(o) : _styleCategories.remove(o))),
          buildMultiSelect("Best Known For",
            ["Haldi Jewellery", "Mehendi Jewellery", "Fresh Flower Designs",
             "Lightweight Jewellery", "Custom Designs"],
            _bestKnownFor,
            (o, c) => setState(() => c ? _bestKnownFor.add(o) : _bestKnownFor.remove(o))),
          buildMultiSelect("Suitable For",
            ["Bride", "Bridesmaids", "Family Members", "Guests"],
            _suitableFor,
            (o, c) => setState(() => c ? _suitableFor.add(o) : _suitableFor.remove(o))),
          buildYesNo("Outfit Matching Support", _outfitMatchingSupport,
              (v) => setState(() => _outfitMatchingSupport = v)),
          buildYesNo("Customization Available", _customizationAvailable,
              (v) => setState(() => _customizationAvailable = v)),
          buildMultiSelect("Custom Design Inputs",
            ["Outfit Color", "Theme", "Function Type", "Personal Preference"],
            _customDesignInputs,
            (o, c) => setState(() => c ? _customDesignInputs.add(o) : _customDesignInputs.remove(o))),
        ],
        dividerLine(),

        // ── Section 5: Function-Specific ───────────────────────────────────
        sectionHeader("Section 5 — Function-specific", _fs5,
            () => setState(() => _fs5 = !_fs5)),
        if (_fs5) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Functions Suitable For",
            ["Haldi", "Mehendi", "Pre-Wedding Shoot", "Engagement", "Baby Shower"],
            _functionsSuitableFor,
            (o, c) => setState(() => c ? _functionsSuitableFor.add(o) : _functionsSuitableFor.remove(o))),
          buildDropdown("Best Function",
            ["Haldi", "Mehendi", "Both"],
            _bestFunction, (v) => setState(() => _bestFunction = v)),
        ],
        dividerLine(),

        // ── Section 6: Pricing & Package ───────────────────────────────────
        sectionHeader("Section 6 — Pricing & package", _fs6,
            () => setState(() => _fs6 = !_fs6)),
        if (_fs6) ...[
          const SizedBox(height: 16),
          buildNumberField("Starting Price (₹)", _startingPriceCtrl),
          buildDropdown("Pricing Type",
            ["Per Piece", "Per Set", "Package"],
            _pricingType, (v) => setState(() => _pricingType = v)),
          buildDropdown("Bridal Set Price Range",
            ["Below ₹1000", "₹1000–₹3000", "₹3000–₹5000", "₹5000+", "All Ranges Available"],
            _bridalSetPriceRange, (v) => setState(() => _bridalSetPriceRange = v)),
          buildDropdown("Bulk Orders Supported",
            ["Yes", "No"],
            _bulkOrdersSupported, (v) => setState(() => _bulkOrdersSupported = v)),
          buildDropdown("Bulk Pricing",
            ["Discount Available", "No Discount"],
            _bulkPricing, (v) => setState(() => _bulkPricing = v)),
        ],
        dividerLine(),

        // ── Section 7: Delivery & Timing ───────────────────────────────────
        sectionHeader("Section 7 — Delivery & timing", _fs7,
            () => setState(() => _fs7 = !_fs7)),
        if (_fs7) ...[
          const SizedBox(height: 16),
          buildDropdown("Order Preparation Time",
            ["Same Day", "1 Day", "2–3 Days", "5+ Days"],
            _orderPrepTime, (v) => setState(() => _orderPrepTime = v)),
          buildDropdown("Delivery Timing",
            ["Same Day", "Next Day", "Scheduled Delivery"],
            _deliveryTiming, (v) => setState(() => _deliveryTiming = v)),
          buildYesNo("Time Slot Delivery", _timeSlotDelivery,
              (v) => setState(() => _timeSlotDelivery = v)),
          buildYesNo("Early Morning Delivery", _earlyMorningDelivery,
              (v) => setState(() => _earlyMorningDelivery = v)),
        ],
        dividerLine(),

        // ── Section 8: Storage & Handling ──────────────────────────────────
        sectionHeader("Section 8 — Storage & handling", _fs8,
            () => setState(() => _fs8 = !_fs8)),
        if (_fs8) ...[
          const SizedBox(height: 16),
          buildYesNo("Storage Instructions Provided", _storageInstructions,
              (v) => setState(() => _storageInstructions = v)),
          buildYesNo("Replacement Policy", _replacementPolicy,
              (v) => setState(() => _replacementPolicy = v)),
          buildDropdown("Damage Handling",
            ["Replacement", "No Replacement", "Case-by-Case"],
            _damageHandling, (v) => setState(() => _damageHandling = v)),
        ],
        dividerLine(),

        // ── Section 9: Inventory & Availability ────────────────────────────
        sectionHeader("Section 9 — Inventory & availability", _fs9,
            () => setState(() => _fs9 = !_fs9)),
        if (_fs9) ...[
          const SizedBox(height: 16),
          buildDropdown("Daily Order Capacity",
            ["0–10 Orders", "10–30 Orders", "30–50 Orders", "50+ Orders"],
            _dailyOrderCapacity, (v) => setState(() => _dailyOrderCapacity = v)),
          buildYesNo("Advance Booking Required", _advanceBookingRequired,
              (v) => setState(() => _advanceBookingRequired = v)),
          buildDropdown("Peak Season Availability",
            ["Limited", "Moderate", "High"],
            _peakSeasonAvailability, (v) => setState(() => _peakSeasonAvailability = v)),
        ],
        dividerLine(),

        // ── Section 10: Workflow & Booking ─────────────────────────────────
        sectionHeader("Section 10 — Workflow & booking", _fs10,
            () => setState(() => _fs10 = !_fs10)),
        if (_fs10) ...[
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
            ["1 Day", "3 Days", "7 Days"],
            _refundTimeline, (v) => setState(() => _refundTimeline = v)),
        ],
      ],
    );
  }
}
