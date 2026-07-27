import 'package:flutter/material.dart';
import 'facilities_helpers.dart';

class FloristFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const FloristFacilities({super.key, required this.attributes});

  @override
  State<FloristFacilities> createState() => FloristFacilitiesState();
}

class FloristFacilitiesState extends State<FloristFacilities>
    with FacilitiesHelpersMixin<FloristFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  final        _brandNameCtrl      = TextEditingController();
  String?      _vendorType;
  final        _cityCtrl           = TextEditingController();
  String?      _yearsOfExperience;
  List<String> _specialization     = [];
  List<String> _storePresence      = [];
  List<String> _servicePresence    = [];

  // ── services_offered ──────────────────────────────────────────────────────
  List<String> _serviceTypes         = [];
  String?      _customizationAvailable;
  String?      _sameDayDelivery;
  String?      _subscriptionServices;
  String?      _bulkOrderHandling;
  String?      _eventSetupSupport;
  List<String> _packagingOptions     = [];

  // ── core_intelligence ─────────────────────────────────────────────────────
  List<String> _flowerTypesAvailable = [];
  List<String> _usageTypes           = [];
  String?      _fragranceLevel;
  String?      _longevityType;
  List<String> _colorPalette         = [];
  String?      _seasonalAvailability;

  // ── technical ─────────────────────────────────────────────────────────────
  String?      _storageFacility;
  String?      _flowerFreshnessGuarantee;
  List<String> _sourcingType         = [];
  List<String> _arrangementTypes     = [];
  String?      _ecoFriendlyOptions;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _priceRange;
  String?      _pricingModel;
  String?      _deliveryCharges;
  String?      _setupCharges;
  String?      _bulkDiscounts;

  // ── scale_capacity ────────────────────────────────────────────────────────
  String?      _dailyOrderCapacity;
  String?      _eventHandlingCapacity;
  String?      _teamSize;

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _advanceBookingRequired;
  String?      _bookingWindow;
  String?      _customizationApprovalProcess;
  String?      _deliveryTimeSlots;
  List<String> _paymentModes          = [];
  String?      _advancePaymentPercentage;

  // ── portfolio_tagging ─────────────────────────────────────────────────────
  List<String> _styleTags            = [];
  List<String> _audienceTags         = [];
  List<String> _usageTags            = [];
  String?      _priceSegmentTags;

  // ── section expansion ─────────────────────────────────────────────────────
  bool _fls1 = true;
  bool _fls2 = false;
  bool _fls3 = false;
  bool _fls4 = false;
  bool _fls5 = false;
  bool _fls6 = false;
  bool _fls7 = false;
  bool _fls8 = false;


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
    final fm = asMap(attrs['florist_master']);

    final id = asMap(fm['identity']);
    _brandNameCtrl.text = id['brand_name']?.toString() ?? '';
    _vendorType         = id['vendor_type'] as String?;
    _cityCtrl.text      = id['city']?.toString() ?? '';
    _yearsOfExperience  = id['years_of_experience'] as String?;
    _specialization     = toList(id['specialization']);
    _storePresence      = toList(id['store_presence']);
    _servicePresence    = toList(id['service_presence']);

    final so = asMap(fm['services_offered']);
    _serviceTypes            = toList(so['service_types']);
    _customizationAvailable  = so['customization_available'] as String?;
    _sameDayDelivery         = so['same_day_delivery'] as String?;
    _subscriptionServices    = so['subscription_services'] as String?;
    _bulkOrderHandling       = so['bulk_order_handling'] as String?;
    _eventSetupSupport       = so['event_setup_support'] as String?;
    _packagingOptions        = toList(so['packaging_options']);

    final ci = asMap(fm['core_intelligence']);
    _flowerTypesAvailable = toList(ci['flower_types_available']);
    _usageTypes           = toList(ci['usage_types']);
    _fragranceLevel       = ci['fragrance_level'] as String?;
    _longevityType        = ci['longevity_type'] as String?;
    _colorPalette         = toList(ci['color_palette']);
    _seasonalAvailability = ci['seasonal_availability'] as String?;

    final te = asMap(fm['technical']);
    _storageFacility          = te['storage_facility'] as String?;
    _flowerFreshnessGuarantee = te['flower_freshness_guarantee'] as String?;
    _sourcingType             = toList(te['sourcing_type']);
    _arrangementTypes         = toList(te['arrangement_types']);
    _ecoFriendlyOptions       = te['eco_friendly_options'] as String?;

    final pr = asMap(fm['pricing']);
    _priceRange      = pr['price_range'] as String?;
    _pricingModel    = pr['pricing_model'] as String?;
    _deliveryCharges = pr['delivery_charges'] as String?;
    _setupCharges    = pr['setup_charges'] as String?;
    _bulkDiscounts   = pr['bulk_discounts'] as String?;

    final sc = asMap(fm['scale_capacity']);
    _dailyOrderCapacity   = sc['daily_order_capacity'] as String?;
    _eventHandlingCapacity = sc['event_handling_capacity'] as String?;
    _teamSize             = sc['team_size'] as String?;

    final wf = asMap(fm['workflow']);
    _advanceBookingRequired         = wf['advance_booking_required'] as String?;
    _bookingWindow                  = wf['booking_window'] as String?;
    _customizationApprovalProcess   = wf['customization_approval_process'] as String?;
    _deliveryTimeSlots              = wf['delivery_time_slots'] as String?;
    _paymentModes                   = toList(wf['payment_modes']);
    _advancePaymentPercentage       = wf['advance_payment_percentage'] as String?;

    final pt = asMap(fm['portfolio_tagging']);
    _styleTags       = toList(pt['style_tags']);
    _audienceTags    = toList(pt['audience_tags']);
    _usageTags       = toList(pt['usage_tags']);
    _priceSegmentTags = pt['price_segment_tags'] as String?;
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "brand_name":         _brandNameCtrl.text,
        "vendor_type":        _vendorType,
        "city":               _cityCtrl.text,
        "years_of_experience":_yearsOfExperience,
        "specialization":     _specialization,
        "store_presence":     _storePresence,
        "service_presence":   _servicePresence,
      },
      "services_offered": {
        ...asMap(ex["services_offered"]),
        "service_types":           _serviceTypes,
        "customization_available": _customizationAvailable,
        "same_day_delivery":       _sameDayDelivery,
        "subscription_services":   _subscriptionServices,
        "bulk_order_handling":     _bulkOrderHandling,
        "event_setup_support":     _eventSetupSupport,
        "packaging_options":       _packagingOptions,
      },
      "core_intelligence": {
        ...asMap(ex["core_intelligence"]),
        "flower_types_available": _flowerTypesAvailable,
        "usage_types":            _usageTypes,
        "fragrance_level":        _fragranceLevel,
        "longevity_type":         _longevityType,
        "color_palette":          _colorPalette,
        "seasonal_availability":  _seasonalAvailability,
      },
      "technical": {
        ...asMap(ex["technical"]),
        "storage_facility":          _storageFacility,
        "flower_freshness_guarantee":_flowerFreshnessGuarantee,
        "sourcing_type":             _sourcingType,
        "arrangement_types":         _arrangementTypes,
        "eco_friendly_options":      _ecoFriendlyOptions,
      },
      "pricing": {
        ...asMap(ex["pricing"]),
        "price_range":      _priceRange,
        "pricing_model":    _pricingModel,
        "delivery_charges": _deliveryCharges,
        "setup_charges":    _setupCharges,
        "bulk_discounts":   _bulkDiscounts,
      },
      "scale_capacity": {
        ...asMap(ex["scale_capacity"]),
        "daily_order_capacity":    _dailyOrderCapacity,
        "event_handling_capacity": _eventHandlingCapacity,
        "team_size":               _teamSize,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "advance_booking_required":         _advanceBookingRequired,
        "booking_window":                   _bookingWindow,
        "customization_approval_process":   _customizationApprovalProcess,
        "delivery_time_slots":              _deliveryTimeSlots,
        "payment_modes":                    _paymentModes,
        "advance_payment_percentage":       _advancePaymentPercentage,
      },
      "portfolio_tagging": {
        ...asMap(ex["portfolio_tagging"]),
        "style_tags":        _styleTags,
        "audience_tags":     _audienceTags,
        "usage_tags":        _usageTags,
        "price_segment_tags":_priceSegmentTags,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Florist Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured florist attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _fls1,
            () => setState(() => _fls1 = !_fls1)),
        if (_fls1) ...[
          const SizedBox(height: 16),
          buildTextArea("Brand Name", _brandNameCtrl, maxLines: 1),
          buildDropdown("Vendor Type",
            ["Retail Florist", "Wedding Florist Specialist",
             "Wholesale Florist", "Floral Designer Studio", "Online Flower Brand"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildTextArea("City", _cityCtrl, maxLines: 1),
          buildDropdown("Years of Experience",
            ["0–2", "3–5", "6–10", "10+"],
            _yearsOfExperience, (v) => setState(() => _yearsOfExperience = v)),
          buildMultiSelect("Specialization",
            ["Wedding Decor Florals", "Bouquets", "Garlands",
             "Floral Jewellery", "Car Decor Flowers"],
            _specialization,
            (o, c) => setState(() => c ? _specialization.add(o) : _specialization.remove(o))),
          buildMultiSelect("Store Presence",
            ["Physical Store", "Online Store", "Both"],
            _storePresence,
            (o, c) => setState(() => c ? _storePresence.add(o) : _storePresence.remove(o))),
          buildMultiSelect("Service Presence",
            ["Local Delivery", "Outstation Delivery", "Pan-India Shipping"],
            _servicePresence,
            (o, c) => setState(() => c ? _servicePresence.add(o) : _servicePresence.remove(o))),
        ],
        dividerLine(),

        // ── Section 2: Services Offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _fls2,
            () => setState(() => _fls2 = !_fls2)),
        if (_fls2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Service Types",
            ["Fresh Flowers", "Artificial Flowers", "Preserved Flowers", "Dry Flowers"],
            _serviceTypes,
            (o, c) => setState(() => c ? _serviceTypes.add(o) : _serviceTypes.remove(o))),
          buildYesNo("Customization Available", _customizationAvailable,
              (v) => setState(() => _customizationAvailable = v)),
          buildYesNo("Same-Day Delivery", _sameDayDelivery,
              (v) => setState(() => _sameDayDelivery = v)),
          buildYesNo("Subscription Services (Daily/Weekly)", _subscriptionServices,
              (v) => setState(() => _subscriptionServices = v)),
          buildYesNo("Bulk Order Handling", _bulkOrderHandling,
              (v) => setState(() => _bulkOrderHandling = v)),
          buildYesNo("Event Setup Support", _eventSetupSupport,
              (v) => setState(() => _eventSetupSupport = v)),
          buildMultiSelect("Packaging Options",
            ["Basic Wrap", "Premium Packaging", "Luxury Boxes"],
            _packagingOptions,
            (o, c) => setState(() => c ? _packagingOptions.add(o) : _packagingOptions.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _fls3,
            () => setState(() => _fls3 = !_fls3)),
        if (_fls3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Flower Types Available",
            ["Roses", "Orchids", "Marigold", "Lilies", "Carnations",
             "Baby's Breath", "Exotic Imports"],
            _flowerTypesAvailable,
            (o, c) => setState(() => c ? _flowerTypesAvailable.add(o) : _flowerTypesAvailable.remove(o))),
          buildMultiSelect("Usage Types",
            ["Bridal Bouquet", "Var Mala", "Car Decor", "Mandap Decor",
             "Table Centerpieces", "Entry Decor"],
            _usageTypes,
            (o, c) => setState(() => c ? _usageTypes.add(o) : _usageTypes.remove(o))),
          buildDropdown("Fragrance Level",
            ["Mild", "Medium", "Strong"],
            _fragranceLevel, (v) => setState(() => _fragranceLevel = v)),
          buildDropdown("Longevity Type",
            ["1 Day", "2–3 Days", "3–7 Days", "Preserved (Weeks/Months)"],
            _longevityType, (v) => setState(() => _longevityType = v)),
          buildMultiSelect("Color Palette",
            ["Red", "White", "Yellow", "Pink", "Pastel Mix", "Custom Mix"],
            _colorPalette,
            (o, c) => setState(() => c ? _colorPalette.add(o) : _colorPalette.remove(o))),
          buildDropdown("Seasonal Availability",
            ["All Year", "Seasonal Only", "Mixed"],
            _seasonalAvailability, (v) => setState(() => _seasonalAvailability = v)),
        ],
        dividerLine(),

        // ── Section 4: Technical / Product / Skill ─────────────────────────
        sectionHeader("Section 4 — Technical & product", _fls4,
            () => setState(() => _fls4 = !_fls4)),
        if (_fls4) ...[
          const SizedBox(height: 16),
          buildDropdown("Storage Facility",
            ["Cold Storage Available", "No Cold Storage"],
            _storageFacility, (v) => setState(() => _storageFacility = v)),
          buildYesNo("Flower Freshness Guarantee", _flowerFreshnessGuarantee,
              (v) => setState(() => _flowerFreshnessGuarantee = v)),
          buildMultiSelect("Sourcing Type",
            ["Local Farms", "Imported Flowers", "Wholesale Market"],
            _sourcingType,
            (o, c) => setState(() => c ? _sourcingType.add(o) : _sourcingType.remove(o))),
          buildMultiSelect("Arrangement Types",
            ["Hand-Tied", "Basket Arrangement", "Vase Arrangement", "Installation-Based"],
            _arrangementTypes,
            (o, c) => setState(() => c ? _arrangementTypes.add(o) : _arrangementTypes.remove(o))),
          buildYesNo("Eco-Friendly Options", _ecoFriendlyOptions,
              (v) => setState(() => _ecoFriendlyOptions = v)),
        ],
        dividerLine(),

        // ── Section 5: Pricing Logic ───────────────────────────────────────
        sectionHeader("Section 5 — Pricing logic", _fls5,
            () => setState(() => _fls5 = !_fls5)),
        if (_fls5) ...[
          const SizedBox(height: 16),
          buildDropdown("Price Range (INR)",
            ["500–2K", "2K–5K", "5K–15K", "15K–50K", "50K+"],
            _priceRange, (v) => setState(() => _priceRange = v)),
          buildDropdown("Pricing Model",
            ["Per Piece", "Per Kg", "Per Event", "Custom Quote"],
            _pricingModel, (v) => setState(() => _pricingModel = v)),
          buildDropdown("Delivery Charges",
            ["Included", "Extra"],
            _deliveryCharges, (v) => setState(() => _deliveryCharges = v)),
          buildDropdown("Setup Charges (Event)",
            ["Included", "Extra"],
            _setupCharges, (v) => setState(() => _setupCharges = v)),
          buildYesNo("Bulk Discounts", _bulkDiscounts,
              (v) => setState(() => _bulkDiscounts = v)),
        ],
        dividerLine(),

        // ── Section 6: Scale & Capacity ────────────────────────────────────
        sectionHeader("Section 6 — Scale & capacity", _fls6,
            () => setState(() => _fls6 = !_fls6)),
        if (_fls6) ...[
          const SizedBox(height: 16),
          buildDropdown("Daily Order Capacity",
            ["<20", "20–50", "50–100", "100+"],
            _dailyOrderCapacity, (v) => setState(() => _dailyOrderCapacity = v)),
          buildDropdown("Event Handling Capacity",
            ["1 Event", "2–3 Events", "3–5 Events", "5+ Events"],
            _eventHandlingCapacity, (v) => setState(() => _eventHandlingCapacity = v)),
          buildDropdown("Team Size",
            ["1–2", "3–5", "6–10", "10+"],
            _teamSize, (v) => setState(() => _teamSize = v)),
        ],
        dividerLine(),

        // ── Section 7: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 7 — Workflow & booking", _fls7,
            () => setState(() => _fls7 = !_fls7)),
        if (_fls7) ...[
          const SizedBox(height: 16),
          buildYesNo("Advance Booking Required", _advanceBookingRequired,
              (v) => setState(() => _advanceBookingRequired = v)),
          buildDropdown("Booking Window",
            ["Same Day", "1–3 days", "3–7 days", "7+ days"],
            _bookingWindow, (v) => setState(() => _bookingWindow = v)),
          buildDropdown("Customization Approval Process",
            ["Catalog Selection", "Sample Preview", "Mock Setup"],
            _customizationApprovalProcess,
            (v) => setState(() => _customizationApprovalProcess = v)),
          buildDropdown("Delivery Time Slots",
            ["Fixed", "Flexible"],
            _deliveryTimeSlots, (v) => setState(() => _deliveryTimeSlots = v)),
          buildMultiSelect("Payment Modes",
            ["UPI", "Cash", "Card", "Bank Transfer"],
            _paymentModes,
            (o, c) => setState(() => c ? _paymentModes.add(o) : _paymentModes.remove(o))),
          buildDropdown("Advance Payment Percentage",
            ["0%", "25%", "50%", "100%"],
            _advancePaymentPercentage,
            (v) => setState(() => _advancePaymentPercentage = v)),
        ],
        dividerLine(),

        // ── Section 8: Portfolio Tagging ────────────────────────────────────
        sectionHeader("Section 8 — Portfolio tagging (AI layer)", _fls8,
            () => setState(() => _fls8 = !_fls8)),
        if (_fls8) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Style Tags",
            ["Romantic", "Luxury Floral", "Traditional", "Minimal", "Exotic"],
            _styleTags,
            (o, c) => setState(() => c ? _styleTags.add(o) : _styleTags.remove(o))),
          buildMultiSelect("Audience Tags",
            ["Bride", "Groom", "Wedding Planner", "Decorator"],
            _audienceTags,
            (o, c) => setState(() => c ? _audienceTags.add(o) : _audienceTags.remove(o))),
          buildMultiSelect("Usage Tags",
            ["Wedding Decor", "Bouquets", "Gifting", "Car Decor"],
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
