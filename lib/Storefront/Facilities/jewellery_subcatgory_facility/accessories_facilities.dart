import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class AccessoriesFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const AccessoriesFacilities({super.key, required this.attributes});

  @override
  State<AccessoriesFacilities> createState() => AccessoriesFacilitiesState();
}

class AccessoriesFacilitiesState extends State<AccessoriesFacilities>
    with FacilitiesHelpersMixin<AccessoriesFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  final        _brandNameCtrl = TextEditingController();
  String?      _vendorType;
  final        _yearsExpCtrl  = TextEditingController();
  final        _cityCtrl      = TextEditingController();
  String?      _serviceMode;
  String?      _deliveryCoverage;

  // ── product_categories ────────────────────────────────────────────────────
  List<String> _accessoriesTypes = [];
  String?      _genderFocus;
  String?      _bridalAccessories;
  String?      _groomAccessories;

  // ── style_intelligence ────────────────────────────────────────────────────
  List<String> _styleCategories   = [];
  List<String> _bestKnownFor      = [];
  List<String> _suitableFor       = [];
  String?      _outfitMatching;
  String?      _stylingConsultation;

  // ── material_quality ──────────────────────────────────────────────────────
  List<String> _materialsUsed    = [];
  String?      _qualityTier;
  String?      _handmadeProducts;

  // ── sales_rental_logic ────────────────────────────────────────────────────
  String?      _productMode;
  String?      _rentalDuration;
  String?      _priceRange;
  String?      _securityDeposit;
  String?      _customOrders;
  String?      _customizationTime;

  // ── inventory ─────────────────────────────────────────────────────────────
  String?      _inventorySize;
  String?      _multiplePieces;
  String?      _realTimeTracking;

  // ── logistics ─────────────────────────────────────────────────────────────
  String?      _homeDelivery;
  String?      _storePickup;
  String?      _shippingCharges;
  String?      _tryAtHome;

  // ── event_suitability ─────────────────────────────────────────────────────
  List<String> _functionsSuitableFor = [];
  List<String> _bestFor              = [];

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _advanceRequired;
  String?      _advancePercentage;
  String?      _cancellationPolicy;
  String?      _returnPolicy;

  // ── section expansion ─────────────────────────────────────────────────────
  bool _as1 = true;
  bool _as2 = false;
  bool _as3 = false;
  bool _as4 = false;
  bool _as5 = false;
  bool _as6 = false;
  bool _as7 = false;
  bool _as8 = false;
  bool _as9 = false;

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
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final am = asMap(attrs['accessories_master']);

    final id = asMap(am['identity']);
    _brandNameCtrl.text = id['brand_name']?.toString() ?? '';
    _vendorType       = id['vendor_type'] as String?;
    _yearsExpCtrl.text = id['years_of_experience']?.toString() ?? '';
    _cityCtrl.text    = id['city']?.toString() ?? '';
    _serviceMode      = id['service_mode'] as String?;
    _deliveryCoverage = id['delivery_coverage'] as String?;

    final pc = asMap(am['product_categories']);
    _accessoriesTypes  = toList(pc['accessories_types']);
    _genderFocus       = pc['gender_focus'] as String?;
    _bridalAccessories = pc['bridal_accessories'] as String?;
    _groomAccessories  = pc['groom_accessories'] as String?;

    final si = asMap(am['style_intelligence']);
    _styleCategories     = toList(si['style_categories']);
    _bestKnownFor        = toList(si['best_known_for']);
    _suitableFor         = toList(si['suitable_for']);
    _outfitMatching      = si['outfit_matching'] as String?;
    _stylingConsultation = si['styling_consultation'] as String?;

    final mq = asMap(am['material_quality']);
    _materialsUsed    = toList(mq['materials_used']);
    _qualityTier      = mq['quality_tier'] as String?;
    _handmadeProducts = mq['handmade_products'] as String?;

    final sr = asMap(am['sales_rental_logic']);
    _productMode       = sr['product_mode'] as String?;
    _rentalDuration    = sr['rental_duration'] as String?;
    _priceRange        = sr['price_range'] as String?;
    _securityDeposit   = sr['security_deposit'] as String?;
    _customOrders      = sr['custom_orders'] as String?;
    _customizationTime = sr['customization_time'] as String?;

    final inv = asMap(am['inventory']);
    _inventorySize    = inv['inventory_size'] as String?;
    _multiplePieces   = inv['multiple_pieces'] as String?;
    _realTimeTracking = inv['real_time_tracking'] as String?;

    final lg = asMap(am['logistics']);
    _homeDelivery    = lg['home_delivery'] as String?;
    _storePickup     = lg['store_pickup'] as String?;
    _shippingCharges = lg['shipping_charges'] as String?;
    _tryAtHome       = lg['try_at_home'] as String?;

    final es = asMap(am['event_suitability']);
    _functionsSuitableFor = toList(es['functions_suitable_for']);
    _bestFor              = toList(es['best_for']);

    final wf = asMap(am['workflow']);
    _advanceRequired    = wf['advance_required'] as String?;
    _advancePercentage  = wf['advance_percentage'] as String?;
    _cancellationPolicy = wf['cancellation_policy'] as String?;
    _returnPolicy       = wf['return_policy'] as String?;
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
        "service_mode":        _serviceMode,
        "delivery_coverage":   _deliveryCoverage,
      },
      "product_categories": {
        ...asMap(ex["product_categories"]),
        "accessories_types":  _accessoriesTypes,
        "gender_focus":       _genderFocus,
        "bridal_accessories": _bridalAccessories,
        "groom_accessories":  _groomAccessories,
      },
      "style_intelligence": {
        ...asMap(ex["style_intelligence"]),
        "style_categories":     _styleCategories,
        "best_known_for":       _bestKnownFor,
        "suitable_for":         _suitableFor,
        "outfit_matching":      _outfitMatching,
        "styling_consultation": _stylingConsultation,
      },
      "material_quality": {
        ...asMap(ex["material_quality"]),
        "materials_used":    _materialsUsed,
        "quality_tier":      _qualityTier,
        "handmade_products": _handmadeProducts,
      },
      "sales_rental_logic": {
        ...asMap(ex["sales_rental_logic"]),
        "product_mode":       _productMode,
        "rental_duration":    _rentalDuration,
        "price_range":        _priceRange,
        "security_deposit":   _securityDeposit,
        "custom_orders":      _customOrders,
        "customization_time": _customizationTime,
      },
      "inventory": {
        ...asMap(ex["inventory"]),
        "inventory_size":     _inventorySize,
        "multiple_pieces":    _multiplePieces,
        "real_time_tracking": _realTimeTracking,
      },
      "logistics": {
        ...asMap(ex["logistics"]),
        "home_delivery":    _homeDelivery,
        "store_pickup":     _storePickup,
        "shipping_charges": _shippingCharges,
        "try_at_home":      _tryAtHome,
      },
      "event_suitability": {
        ...asMap(ex["event_suitability"]),
        "functions_suitable_for": _functionsSuitableFor,
        "best_for":               _bestFor,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "advance_required":    _advanceRequired,
        "advance_percentage":  _advancePercentage,
        "cancellation_policy": _cancellationPolicy,
        "return_policy":       _returnPolicy,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Accessories Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured accessories attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _as1,
            () => setState(() => _as1 = !_as1)),
        if (_as1) ...[
          const SizedBox(height: 16),
          buildTextArea("Brand / Store Name", _brandNameCtrl, maxLines: 1),
          buildDropdown("Vendor Type",
            ["Retail Store", "Online Store", "Rental Boutique",
             "Designer Studio", "Multi-Brand Store"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildNumberField("Years of Experience", _yearsExpCtrl),
          buildTextArea("City", _cityCtrl, maxLines: 1),
          buildDropdown("Service Mode",
            ["Store Visit", "Online", "Both"],
            _serviceMode, (v) => setState(() => _serviceMode = v)),
          buildDropdown("Delivery Coverage",
            ["Local Only", "Pan India", "International"],
            _deliveryCoverage, (v) => setState(() => _deliveryCoverage = v)),
        ],
        dividerLine(),

        // ── Section 2: Product Categories ──────────────────────────────────
        sectionHeader("Section 2 — Product categories", _as2,
            () => setState(() => _as2 = !_as2)),
        if (_as2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Accessories Types",
            ["Clutches / Potlis", "Footwear (Heels / Juttis / Mojris)",
             "Hair Accessories", "Veils", "Belts", "Dupatta Accessories",
             "Brooches", "Cufflinks", "Pocket Squares", "Safa / Pagdi",
             "Sunglasses", "Bridal Chooda", "Kaleere"],
            _accessoriesTypes,
            (o, c) => setState(() => c ? _accessoriesTypes.add(o) : _accessoriesTypes.remove(o))),
          buildDropdown("Gender Focus",
            ["Women", "Men", "Unisex"],
            _genderFocus, (v) => setState(() => _genderFocus = v)),
          buildDropdown("Bridal Accessories Available",
            ["Yes", "No"],
            _bridalAccessories, (v) => setState(() => _bridalAccessories = v)),
          buildDropdown("Groom Accessories Available",
            ["Yes", "No"],
            _groomAccessories, (v) => setState(() => _groomAccessories = v)),
        ],
        dividerLine(),

        // ── Section 3: Style & Design ──────────────────────────────────────
        sectionHeader("Section 3 — Style & design", _as3,
            () => setState(() => _as3 = !_as3)),
        if (_as3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Style Categories",
            ["Traditional", "Contemporary", "Fusion", "Minimal",
             "Statement", "Luxury", "Budget"],
            _styleCategories,
            (o, c) => setState(() => c ? _styleCategories.add(o) : _styleCategories.remove(o))),
          buildMultiSelect("Best Known For",
            ["Bridal Accessories", "Groom Styling", "Budget Products",
             "Luxury Pieces", "Custom Designs"],
            _bestKnownFor,
            (o, c) => setState(() => c ? _bestKnownFor.add(o) : _bestKnownFor.remove(o))),
          buildMultiSelect("Suitable For",
            ["Bridal", "Groom", "Bridesmaids", "Family Members", "Guests"],
            _suitableFor,
            (o, c) => setState(() => c ? _suitableFor.add(o) : _suitableFor.remove(o))),
          buildYesNo("Outfit Matching Support", _outfitMatching,
              (v) => setState(() => _outfitMatching = v)),
          buildYesNo("Styling Consultation", _stylingConsultation,
              (v) => setState(() => _stylingConsultation = v)),
        ],
        dividerLine(),

        // ── Section 4: Material & Quality ──────────────────────────────────
        sectionHeader("Section 4 — Material & quality", _as4,
            () => setState(() => _as4 = !_as4)),
        if (_as4) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Materials Used",
            ["Fabric", "Leather", "Metal", "Artificial", "Mixed"],
            _materialsUsed,
            (o, c) => setState(() => c ? _materialsUsed.add(o) : _materialsUsed.remove(o))),
          buildDropdown("Quality Tier",
            ["Budget", "Premium", "Luxury"],
            _qualityTier, (v) => setState(() => _qualityTier = v)),
          buildYesNo("Handmade Products", _handmadeProducts,
              (v) => setState(() => _handmadeProducts = v)),
        ],
        dividerLine(),

        // ── Section 5: Sales & Rental Logic ────────────────────────────────
        sectionHeader("Section 5 — Sales & rental logic", _as5,
            () => setState(() => _as5 = !_as5)),
        if (_as5) ...[
          const SizedBox(height: 16),
          buildDropdown("Product Mode",
            ["Sale Only", "Rental Only", "Both"],
            _productMode, (v) => setState(() => _productMode = v)),
          if (_productMode != "Sale Only")
            buildDropdown("Rental Duration",
              ["1 Day", "2 Days", "3 Days", "Custom"],
              _rentalDuration, (v) => setState(() => _rentalDuration = v)),
          buildDropdown("Price Range",
            ["Below ₹500", "₹500–₹1000", "₹1000–₹3000", "₹3000–₹5000", "₹5000+"],
            _priceRange, (v) => setState(() => _priceRange = v)),
          buildDropdown("Security Deposit",
            ["Yes", "No"],
            _securityDeposit, (v) => setState(() => _securityDeposit = v)),
          buildDropdown("Custom Orders",
            ["Yes", "No"],
            _customOrders, (v) => setState(() => _customOrders = v)),
          buildDropdown("Customization Time",
            ["2–3 Days", "1 Week", "2 Weeks", "1 Month"],
            _customizationTime, (v) => setState(() => _customizationTime = v)),
        ],
        dividerLine(),

        // ── Section 6: Inventory & Availability ────────────────────────────
        sectionHeader("Section 6 — Inventory & availability", _as6,
            () => setState(() => _as6 = !_as6)),
        if (_as6) ...[
          const SizedBox(height: 16),
          buildDropdown("Inventory Size",
            ["0–50 Products", "50–200 Products", "200–500 Products", "500+ Products"],
            _inventorySize, (v) => setState(() => _inventorySize = v)),
          buildYesNo("Multiple Pieces Available", _multiplePieces,
              (v) => setState(() => _multiplePieces = v)),
          buildYesNo("Real-Time Availability Tracking", _realTimeTracking,
              (v) => setState(() => _realTimeTracking = v)),
        ],
        dividerLine(),

        // ── Section 7: Delivery & Logistics ────────────────────────────────
        sectionHeader("Section 7 — Delivery & logistics", _as7,
            () => setState(() => _as7 = !_as7)),
        if (_as7) ...[
          const SizedBox(height: 16),
          buildYesNo("Home Delivery", _homeDelivery,
              (v) => setState(() => _homeDelivery = v)),
          buildYesNo("Store Pickup", _storePickup,
              (v) => setState(() => _storePickup = v)),
          buildDropdown("Shipping Charges",
            ["Included", "Extra", "Depends on Location"],
            _shippingCharges, (v) => setState(() => _shippingCharges = v)),
          buildYesNo("Try-at-Home", _tryAtHome,
              (v) => setState(() => _tryAtHome = v)),
        ],
        dividerLine(),

        // ── Section 8: Event Suitability ───────────────────────────────────
        sectionHeader("Section 8 — Event suitability", _as8,
            () => setState(() => _as8 = !_as8)),
        if (_as8) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Functions Suitable For",
            ["Haldi", "Mehendi", "Sangeet", "Wedding", "Reception", "Cocktail"],
            _functionsSuitableFor,
            (o, c) => setState(() => c ? _functionsSuitableFor.add(o) : _functionsSuitableFor.remove(o))),
          buildMultiSelect("Best For",
            ["Bridal Styling", "Groom Styling", "Budget Weddings",
             "Luxury Weddings", "Destination Weddings"],
            _bestFor,
            (o, c) => setState(() => c ? _bestFor.add(o) : _bestFor.remove(o))),
        ],
        dividerLine(),

        // ── Section 9: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 9 — Workflow & booking", _as9,
            () => setState(() => _as9 = !_as9)),
        if (_as9) ...[
          const SizedBox(height: 16),
          buildYesNo("Advance Required", _advanceRequired,
              (v) => setState(() => _advanceRequired = v)),
          buildDropdown("Advance Percentage",
            ["25%", "50%", "75%"],
            _advancePercentage, (v) => setState(() => _advancePercentage = v)),
          buildDropdown("Cancellation Policy",
            ["Non Refundable", "Partial Refund", "Flexible"],
            _cancellationPolicy, (v) => setState(() => _cancellationPolicy = v)),
          buildDropdown("Return Policy",
            ["No Return", "Return Within 24 Hours", "Return Within 48 Hours"],
            _returnPolicy, (v) => setState(() => _returnPolicy = v)),
        ],
      ],
    );
  }
}
