import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class BridalLehengaFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const BridalLehengaFacilities({super.key, required this.attributes});

  @override
  State<BridalLehengaFacilities> createState() =>
      BridalLehengaFacilitiesState();
}

class BridalLehengaFacilitiesState extends State<BridalLehengaFacilities>
    with FacilitiesHelpersMixin<BridalLehengaFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  final        _brandNameCtrl   = TextEditingController();
  String?      _vendorType;
  String?      _ecommerceOnButton;
  String?      _contactTeam;
  String?      _yearsOfExperience;
  final        _primaryCityCtrl = TextEditingController();
  String?      _storePresence;
  List<String> _serviceCities   = [];
  String?      _appointmentRequirement;

  // ── product_catalog ───────────────────────────────────────────────────────
  List<String> _lehengaTypes  = [];
  String?      _collectionType;
  List<String> _designStyle   = [];
  List<String> _colorOptions  = [];

  // ── core_intelligence ─────────────────────────────────────────────────────
  List<String> _silhouetteTypes = [];
  List<String> _fabricOptions   = [];
  List<String> _workTypes       = [];
  String?      _weightCategory;
  String?      _dupattaOptions;
  String?      _customizationDepth;

  // ── fit_styling ───────────────────────────────────────────────────────────
  String?      _sizeRange;
  List<String> _bodyTypeStyling = [];
  String?      _trialAvailability;
  String?      _alterationSupport;
  String?      _stylingConsultation;
  String?      _blouseCustomization;

  // ── occasion_usage ────────────────────────────────────────────────────────
  List<String> _occasionSuitability = [];
  String?      _reusability;
  String?      _comfortLevel;
  String?      _seasonSuitability;

  // ── pricing_logic ─────────────────────────────────────────────────────────
  String?      _pricingModel;
  String?      _startingPriceRange;
  List<String> _includes      = [];
  List<String> _addOns        = [];
  String?      _negotiationFlexibility;

  // ── production_delivery ───────────────────────────────────────────────────
  String?      _productionTime;
  String?      _urgentOrders;
  List<String> _deliveryOptions = [];
  String?      _packaging;

  // ── scale_operations ──────────────────────────────────────────────────────
  String?      _ordersPerMonth;
  String?      _teamSize;

  // ── workflow_booking ──────────────────────────────────────────────────────
  String?      _advanceBookingTime;
  String?      _bookingAdvancePercent;
  String?      _cancellationPolicy;
  List<String> _clientCoordination = [];

  // ── ai_tags (portfolio) ───────────────────────────────────────────────────
  List<String> _lehengaTags   = [];
  List<String> _styleTags     = [];
  List<String> _brideTypeTags = [];

  // ── section expansion ─────────────────────────────────────────────────────
  bool _bs1  = true;
  bool _bs2  = false;
  bool _bs3  = false;
  bool _bs4  = false;
  bool _bs5  = false;
  bool _bs6  = false;
  bool _bs7  = false;
  bool _bs8  = false;
  bool _bs9  = false;
  bool _bs10 = false;

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
    _primaryCityCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final bm = asMap(attrs['bridal_outfit_master']);

    final id = asMap(bm['identity']);
    _brandNameCtrl.text = id['brand_name']?.toString() ?? '';
    _vendorType         = id['vendor_type'] as String?;
    _ecommerceOnButton  = _ynFromBool(id['ecommerce_on_button']);
    _contactTeam        = _ynFromBool(id['contact_team']);
    _yearsOfExperience  = id['years_of_experience'] as String?;
    _primaryCityCtrl.text = id['primary_city']?.toString() ?? '';
    _storePresence      = id['store_presence'] as String?;
    _serviceCities      = toList(id['service_cities']);
    _appointmentRequirement = id['appointment_requirement'] as String?;

    final pc = asMap(bm['product_catalog']);
    _lehengaTypes   = toList(pc['lehenga_types']);
    _collectionType = pc['collection_type'] as String?;
    _designStyle    = toList(pc['design_style']);
    _colorOptions   = toList(pc['color_options']);

    final ci = asMap(bm['core_intelligence']);
    _silhouetteTypes    = toList(ci['silhouette_types']);
    _fabricOptions      = toList(ci['fabric_options']);
    _workTypes          = toList(ci['work_types']);
    _weightCategory     = ci['weight_category'] as String?;
    _dupattaOptions     = ci['dupatta_options'] as String?;
    _customizationDepth = ci['customization_depth'] as String?;

    final fs = asMap(bm['fit_styling']);
    _sizeRange           = fs['size_range'] as String?;
    _bodyTypeStyling     = toList(fs['body_type_styling']);
    _trialAvailability   = fs['trial_availability'] as String?;
    _alterationSupport   = fs['alteration_support'] as String?;
    _stylingConsultation = fs['styling_consultation'] as String?;
    _blouseCustomization = fs['blouse_customization'] as String?;

    final ou = asMap(bm['occasion_usage']);
    _occasionSuitability = toList(ou['occasion_suitability']);
    _reusability         = ou['reusability'] as String?;
    _comfortLevel        = ou['comfort_level'] as String?;
    _seasonSuitability   = ou['season_suitability'] as String?;

    final pl = asMap(bm['pricing_logic']);
    _pricingModel          = pl['pricing_model'] as String?;
    _startingPriceRange    = pl['starting_price_range'] as String?;
    _includes              = toList(pl['includes']);
    _addOns                = toList(pl['add_ons']);
    _negotiationFlexibility = pl['negotiation_flexibility'] as String?;

    final pd = asMap(bm['production_delivery']);
    _productionTime  = pd['production_time'] as String?;
    _urgentOrders    = pd['urgent_orders'] as String?;
    _deliveryOptions = toList(pd['delivery_options']);
    _packaging       = pd['packaging'] as String?;

    final so = asMap(bm['scale_operations']);
    _ordersPerMonth = so['orders_per_month'] as String?;
    _teamSize       = so['team_size'] as String?;

    final wb = asMap(bm['workflow_booking']);
    _advanceBookingTime    = wb['advance_booking_time'] as String?;
    _bookingAdvancePercent = wb['booking_advance_percent'] as String?;
    _cancellationPolicy    = wb['cancellation_policy'] as String?;
    _clientCoordination    = toList(wb['client_coordination']);

    final tags = asMap(bm['ai_tags']);
    _lehengaTags   = toList(tags['lehenga_tags']);
    _styleTags     = toList(tags['style_tags']);
    _brideTypeTags = toList(tags['bride_type_tags']);
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "brand_name":              _brandNameCtrl.text,
        "vendor_type":             _vendorType,
        "ecommerce_on_button":     _ecommerceOnButton == "Yes",
        "contact_team":            _contactTeam == "Yes",
        "years_of_experience":     _yearsOfExperience,
        "primary_city":            _primaryCityCtrl.text,
        "store_presence":          _storePresence,
        "service_cities":          _serviceCities,
        "appointment_requirement": _appointmentRequirement,
      },
      "product_catalog": {
        ...asMap(ex["product_catalog"]),
        "lehenga_types":   _lehengaTypes,
        "collection_type": _collectionType,
        "design_style":    _designStyle,
        "color_options":   _colorOptions,
      },
      "core_intelligence": {
        ...asMap(ex["core_intelligence"]),
        "silhouette_types":    _silhouetteTypes,
        "fabric_options":      _fabricOptions,
        "work_types":          _workTypes,
        "weight_category":     _weightCategory,
        "dupatta_options":     _dupattaOptions,
        "customization_depth": _customizationDepth,
      },
      "fit_styling": {
        ...asMap(ex["fit_styling"]),
        "size_range":           _sizeRange,
        "body_type_styling":    _bodyTypeStyling,
        "trial_availability":   _trialAvailability,
        "alteration_support":   _alterationSupport,
        "styling_consultation": _stylingConsultation,
        "blouse_customization": _blouseCustomization,
      },
      "occasion_usage": {
        ...asMap(ex["occasion_usage"]),
        "occasion_suitability": _occasionSuitability,
        "reusability":          _reusability,
        "comfort_level":        _comfortLevel,
        "season_suitability":   _seasonSuitability,
      },
      "pricing_logic": {
        ...asMap(ex["pricing_logic"]),
        "pricing_model":           _pricingModel,
        "starting_price_range":    _startingPriceRange,
        "includes":                _includes,
        "add_ons":                 _addOns,
        "negotiation_flexibility": _negotiationFlexibility,
      },
      "production_delivery": {
        ...asMap(ex["production_delivery"]),
        "production_time":  _productionTime,
        "urgent_orders":    _urgentOrders,
        "delivery_options": _deliveryOptions,
        "packaging":        _packaging,
      },
      "scale_operations": {
        ...asMap(ex["scale_operations"]),
        "orders_per_month": _ordersPerMonth,
        "team_size":        _teamSize,
      },
      "workflow_booking": {
        ...asMap(ex["workflow_booking"]),
        "advance_booking_time":    _advanceBookingTime,
        "booking_advance_percent": _bookingAdvancePercent,
        "cancellation_policy":     _cancellationPolicy,
        "client_coordination":     _clientCoordination,
      },
      "ai_tags": {
        ...asMap(ex["ai_tags"]),
        "lehenga_tags":    _lehengaTags,
        "style_tags":      _styleTags,
        "bride_type_tags": _brideTypeTags,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Bridal Lehenga Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured bridal outfit attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _bs1,
            () => setState(() => _bs1 = !_bs1)),
        if (_bs1) ...[
          const SizedBox(height: 16),
          buildDropdown("Vendor Type",
            ["Designer Boutique", "Multi-Designer Store", "Custom Lehenga Studio",
             "Retail Brand", "Luxury Couture House"],
            _vendorType, (v) => setState(() => _vendorType = v)),
          buildTextArea("Brand Name", _brandNameCtrl, maxLines: 1),
          buildDropdown("Sell on E-commerce",
            ["Yes", "No"],
            _ecommerceOnButton, (v) => setState(() => _ecommerceOnButton = v)),
          buildDropdown("Contact Our Team",
            ["Yes", "No"],
            _contactTeam, (v) => setState(() => _contactTeam = v)),
          buildDropdown("Years of Experience",
            ["0–1", "1–3", "3–5", "5–10", "10+"],
            _yearsOfExperience, (v) => setState(() => _yearsOfExperience = v)),
          buildTextArea("Primary City", _primaryCityCtrl, maxLines: 1),
          buildDropdown("Store Presence",
            ["Studio Only", "Retail Store", "Both"],
            _storePresence, (v) => setState(() => _storePresence = v)),
          buildMultiSelect("Service Cities",
            ["Pan-India Shipping", "International Shipping"],
            _serviceCities,
            (o, c) => setState(() => c ? _serviceCities.add(o) : _serviceCities.remove(o))),
          buildDropdown("Appointment Requirement",
            ["Mandatory", "Optional", "Walk-in Allowed"],
            _appointmentRequirement, (v) => setState(() => _appointmentRequirement = v)),
        ],
        dividerLine(),

        // ── Section 2: Product Catalog ─────────────────────────────────────
        sectionHeader("Section 2 — Product catalog", _bs2,
            () => setState(() => _bs2 = !_bs2)),
        if (_bs2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Lehenga Types",
            ["Bridal Wedding Lehenga", "Reception Lehenga", "Engagement Lehenga",
             "Sangeet Lehenga", "Pre-Wedding Shoot Lehenga"],
            _lehengaTypes,
            (o, c) => setState(() => c ? _lehengaTypes.add(o) : _lehengaTypes.remove(o))),
          buildDropdown("Collection Type",
            ["Ready-to-Wear", "Made-to-Order", "Custom Designed", "Hybrid"],
            _collectionType, (v) => setState(() => _collectionType = v)),
          buildMultiSelect("Design Style",
            ["Royal / Traditional", "Mughal Inspired", "Minimal / Elegant",
             "Contemporary / Modern", "Indo-Western", "Fusion"],
            _designStyle,
            (o, c) => setState(() => c ? _designStyle.add(o) : _designStyle.remove(o))),
          buildMultiSelect("Color Options",
            ["Red", "Maroon", "Pink", "Pastels", "Ivory / White", "Gold", "Custom"],
            _colorOptions,
            (o, c) => setState(() => c ? _colorOptions.add(o) : _colorOptions.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _bs3,
            () => setState(() => _bs3 = !_bs3)),
        if (_bs3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Silhouette Types",
            ["A-line", "Circular / Flared", "Panelled", "Mermaid / Fish Cut", "Straight Cut"],
            _silhouetteTypes,
            (o, c) => setState(() => c ? _silhouetteTypes.add(o) : _silhouetteTypes.remove(o))),
          buildMultiSelect("Fabric Options",
            ["Silk", "Velvet", "Net", "Georgette", "Organza", "Satin", "Tissue"],
            _fabricOptions,
            (o, c) => setState(() => c ? _fabricOptions.add(o) : _fabricOptions.remove(o))),
          buildMultiSelect("Work Types",
            ["Zari", "Zardozi", "Mirror Work", "Sequins", "Thread Work",
             "Resham", "Gota Patti", "Stone Work"],
            _workTypes,
            (o, c) => setState(() => c ? _workTypes.add(o) : _workTypes.remove(o))),
          buildDropdown("Weight Category",
            ["Lightweight", "Medium", "Heavy", "Very Heavy"],
            _weightCategory, (v) => setState(() => _weightCategory = v)),
          buildDropdown("Dupatta Options",
            ["Single Dupatta", "Double Dupatta", "Custom Styling"],
            _dupattaOptions, (v) => setState(() => _dupattaOptions = v)),
          buildDropdown("Customization Depth",
            ["Full Custom Design", "Semi Custom", "Size Alterations Only"],
            _customizationDepth, (v) => setState(() => _customizationDepth = v)),
        ],
        dividerLine(),

        // ── Section 4: Fit & Styling ───────────────────────────────────────
        sectionHeader("Section 4 — Fit & styling", _bs4,
            () => setState(() => _bs4 = !_bs4)),
        if (_bs4) ...[
          const SizedBox(height: 16),
          buildDropdown("Size Range",
            ["XS", "S", "M", "L", "XL", "XXL", "Custom Size"],
            _sizeRange, (v) => setState(() => _sizeRange = v)),
          buildMultiSelect("Body Type Styling Support",
            ["Petite", "Tall", "Plus Size", "Hourglass", "Pear Shape", "Rectangle"],
            _bodyTypeStyling,
            (o, c) => setState(() => c ? _bodyTypeStyling.add(o) : _bodyTypeStyling.remove(o))),
          buildYesNo("Trial Availability", _trialAvailability,
              (v) => setState(() => _trialAvailability = v)),
          buildDropdown("Alteration Support",
            ["Included", "Chargeable", "Not Available"],
            _alterationSupport, (v) => setState(() => _alterationSupport = v)),
          buildYesNo("Styling Consultation", _stylingConsultation,
              (v) => setState(() => _stylingConsultation = v)),
          buildYesNo("Blouse Customization", _blouseCustomization,
              (v) => setState(() => _blouseCustomization = v)),
        ],
        dividerLine(),

        // ── Section 5: Occasion & Usage ────────────────────────────────────
        sectionHeader("Section 5 — Occasion & usage", _bs5,
            () => setState(() => _bs5 = !_bs5)),
        if (_bs5) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Primary Occasion Suitability",
            ["Wedding", "Reception", "Engagement", "Sangeet"],
            _occasionSuitability,
            (o, c) => setState(() => c ? _occasionSuitability.add(o) : _occasionSuitability.remove(o))),
          buildDropdown("Reusability",
            ["High", "Medium", "Low"],
            _reusability, (v) => setState(() => _reusability = v)),
          buildDropdown("Comfort Level",
            ["High", "Moderate", "Heavy Wear"],
            _comfortLevel, (v) => setState(() => _comfortLevel = v)),
          buildDropdown("Season Suitability",
            ["Summer", "Winter", "All Season"],
            _seasonSuitability, (v) => setState(() => _seasonSuitability = v)),
        ],
        dividerLine(),

        // ── Section 6: Pricing Logic ───────────────────────────────────────
        sectionHeader("Section 6 — Pricing logic", _bs6,
            () => setState(() => _bs6 = !_bs6)),
        if (_bs6) ...[
          const SizedBox(height: 16),
          buildDropdown("Pricing Model",
            ["Per Outfit", "Custom Pricing", "Designer Tier Pricing"],
            _pricingModel, (v) => setState(() => _pricingModel = v)),
          buildDropdown("Starting Price Range",
            ["₹20k–₹50k", "₹50k–₹1L", "₹1L–₹3L", "₹3L–₹7L", "₹7L+"],
            _startingPriceRange, (v) => setState(() => _startingPriceRange = v)),
          buildMultiSelect("Includes",
            ["Lehenga", "Blouse", "Dupatta", "Customization", "Alterations"],
            _includes,
            (o, c) => setState(() => c ? _includes.add(o) : _includes.remove(o))),
          buildMultiSelect("Add-ons",
            ["Extra Dupatta", "Premium Fabric", "Rush Orders", "Styling"],
            _addOns,
            (o, c) => setState(() => c ? _addOns.add(o) : _addOns.remove(o))),
          buildDropdown("Negotiation Flexibility",
            ["Fixed", "Moderate", "Flexible"],
            _negotiationFlexibility, (v) => setState(() => _negotiationFlexibility = v)),
        ],
        dividerLine(),

        // ── Section 7: Production & Delivery ───────────────────────────────
        sectionHeader("Section 7 — Production & delivery", _bs7,
            () => setState(() => _bs7 = !_bs7)),
        if (_bs7) ...[
          const SizedBox(height: 16),
          buildDropdown("Production Time",
            ["Ready Stock", "2–4 weeks", "4–8 weeks", "8–12 weeks"],
            _productionTime, (v) => setState(() => _productionTime = v)),
          buildYesNo("Urgent Orders", _urgentOrders,
              (v) => setState(() => _urgentOrders = v)),
          buildMultiSelect("Delivery Options",
            ["Store Pickup", "Home Delivery", "International Shipping"],
            _deliveryOptions,
            (o, c) => setState(() => c ? _deliveryOptions.add(o) : _deliveryOptions.remove(o))),
          buildDropdown("Packaging",
            ["Basic", "Premium Box", "Luxury Packaging"],
            _packaging, (v) => setState(() => _packaging = v)),
        ],
        dividerLine(),

        // ── Section 8: Scale & Operations ──────────────────────────────────
        sectionHeader("Section 8 — Scale & operations", _bs8,
            () => setState(() => _bs8 = !_bs8)),
        if (_bs8) ...[
          const SizedBox(height: 16),
          buildDropdown("Orders Per Month",
            ["<20", "20–50", "50–100", "100+"],
            _ordersPerMonth, (v) => setState(() => _ordersPerMonth = v)),
          buildDropdown("Team Size",
            ["Solo Designer", "2–5", "5–10", "10+"],
            _teamSize, (v) => setState(() => _teamSize = v)),
        ],
        dividerLine(),

        // ── Section 9: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 9 — Workflow & booking", _bs9,
            () => setState(() => _bs9 = !_bs9)),
        if (_bs9) ...[
          const SizedBox(height: 16),
          buildDropdown("Advance Booking Time",
            ["<2 weeks", "2–4 weeks", "1–3 months", "3–6 months"],
            _advanceBookingTime, (v) => setState(() => _advanceBookingTime = v)),
          buildDropdown("Booking Advance %",
            ["25%", "50%", "75%", "100%"],
            _bookingAdvancePercent, (v) => setState(() => _bookingAdvancePercent = v)),
          buildDropdown("Cancellation Policy",
            ["Non-refundable", "Partial refund", "Flexible"],
            _cancellationPolicy, (v) => setState(() => _cancellationPolicy = v)),
          buildMultiSelect("Client Coordination",
            ["WhatsApp", "Call", "In-person", "App-based"],
            _clientCoordination,
            (o, c) => setState(() => c ? _clientCoordination.add(o) : _clientCoordination.remove(o))),
        ],
        dividerLine(),

        // ── Section 10: Portfolio Tagging ──────────────────────────────────
        sectionHeader("Section 10 — Portfolio tagging (AI layer)", _bs10,
            () => setState(() => _bs10 = !_bs10)),
        if (_bs10) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Lehenga Tags",
            ["Luxury Bridal", "Budget Bridal", "Designer Couture", "Custom Bridal"],
            _lehengaTags,
            (o, c) => setState(() => c ? _lehengaTags.add(o) : _lehengaTags.remove(o))),
          buildMultiSelect("Style Tags",
            ["Royal", "Minimal", "Modern", "Traditional"],
            _styleTags,
            (o, c) => setState(() => c ? _styleTags.add(o) : _styleTags.remove(o))),
          buildMultiSelect("Bride Type Tags",
            ["Classic Bride", "Modern Bride", "Experimental Bride"],
            _brideTypeTags,
            (o, c) => setState(() => c ? _brideTypeTags.add(o) : _brideTypeTags.remove(o))),
        ],
      ],
    );
  }
}
