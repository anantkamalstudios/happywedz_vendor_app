import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class DecoratorFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const DecoratorFacilities({super.key, required this.attributes});

  @override
  State<DecoratorFacilities> createState() => DecoratorFacilitiesState();
}

class DecoratorFacilitiesState extends State<DecoratorFacilities>
    with FacilitiesHelpersMixin<DecoratorFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  final        _brandCompanyNameCtrl = TextEditingController();
  String?      _decoratorType;
  final        _yearsExpCtrl   = TextEditingController();
  final        _cityCtrl       = TextEditingController();
  String?      _serviceCoverage;
  String?      _teamSize;

  // ── services ──────────────────────────────────────────────────────────────
  List<String> _servicesOffered = [];
  List<String> _decorScope      = [];

  // ── theme_style ───────────────────────────────────────────────────────────
  List<String> _themesExpertise   = [];
  List<String> _decorStyle        = [];
  List<String> _bestKnownFor      = [];
  List<String> _idealWeddingType  = [];

  // ── material_design ───────────────────────────────────────────────────────
  List<String> _materialsUsed     = [];
  String?      _floralExpertise;
  String?      _customFabrication;
  String?      _mockupProvided;
  String?      _moodboardSupport;

  // ── execution ─────────────────────────────────────────────────────────────
  String?      _maxGuestCapacity;
  String?      _setupTimeRequired;
  String?      _dismantlingIncluded;
  String?      _multipleFunctionsCapability;

  // ── function_expertise ────────────────────────────────────────────────────
  List<String> _functionsCovered      = [];
  List<String> _bestFunctionExpertise = [];

  // ── pricing ───────────────────────────────────────────────────────────────
  final        _startingDecorPriceCtrl = TextEditingController();
  String?      _pricingType;
  String?      _budgetRangeHandled;
  String?      _freshFlowerCost;
  String?      _transportationCharges;

  // ── logistics ─────────────────────────────────────────────────────────────
  String?      _indoorSetup;
  String?      _outdoorSetup;
  String?      _destinationWeddingSupport;
  String?      _travelStayRequirement;

  // ── lighting_tech ─────────────────────────────────────────────────────────
  String?      _lightingProvided;
  String?      _ledWallSetup;
  List<String> _specialEffects = [];

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _advanceRequired;
  String?      _advancePercentage;
  String?      _bookingTimeline;
  String?      _cancellationPolicy;
  String?      _revisionFlexibility;

  // ── portfolio ─────────────────────────────────────────────────────────────
  final        _tagsCtrl  = TextEditingController();
  final        _notesCtrl = TextEditingController();

  // ── section expansion ─────────────────────────────────────────────────────
  bool _ds1  = true;
  bool _ds2  = false;
  bool _ds3  = false;
  bool _ds4  = false;
  bool _ds5  = false;
  bool _ds6  = false;
  bool _ds7  = false;
  bool _ds8  = false;
  bool _ds9  = false;
  bool _ds10 = false;
  bool _ds11 = false;

  // "Other" free-text controllers, keyed by their JSON field name.
  final Map<String, TextEditingController> _otherCtrls = {};
  TextEditingController _oc(String key) =>
      _otherCtrls[key] ??= TextEditingController();

  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _brandCompanyNameCtrl.dispose();
    _yearsExpCtrl.dispose();
    _cityCtrl.dispose();
    _startingDecorPriceCtrl.dispose();
    _tagsCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _otherCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final dm = asMap(attrs['decorator_master']);

    final id = asMap(dm['identity']);
    _brandCompanyNameCtrl.text = id['brand_company_name']?.toString() ?? '';
    _decoratorType   = id['decorator_type'] as String?;
    _yearsExpCtrl.text = id['years_of_experience']?.toString() ?? '';
    _cityCtrl.text   = id['city']?.toString() ?? '';
    _serviceCoverage = id['service_coverage'] as String?;
    _teamSize        = id['team_size'] as String?;
    _oc('decorator_type_other').text   = id['decorator_type_other']?.toString() ?? '';
    _oc('service_coverage_other').text = id['service_coverage_other']?.toString() ?? '';
    _oc('team_size_other').text        = id['team_size_other']?.toString() ?? '';

    final sv = asMap(dm['services']);
    _servicesOffered = toList(sv['services_offered']);
    _decorScope      = toList(sv['decor_scope']);
    _oc('services_offered_other').text = sv['services_offered_other']?.toString() ?? '';
    _oc('decor_scope_other').text      = sv['decor_scope_other']?.toString() ?? '';

    final th = asMap(dm['theme_style']);
    _themesExpertise  = toList(th['themes_expertise']);
    _decorStyle       = toList(th['decor_style']);
    _bestKnownFor     = toList(th['best_known_for']);
    _idealWeddingType = toList(th['ideal_wedding_type']);
    _oc('themes_expertise_other').text   = th['themes_expertise_other']?.toString() ?? '';
    _oc('decor_style_other').text        = th['decor_style_other']?.toString() ?? '';
    _oc('best_known_for_other').text     = th['best_known_for_other']?.toString() ?? '';
    _oc('ideal_wedding_type_other').text = th['ideal_wedding_type_other']?.toString() ?? '';

    final md = asMap(dm['material_design']);
    _materialsUsed     = toList(md['materials_used']);
    _floralExpertise   = md['floral_expertise'] as String?;
    _customFabrication = md['custom_fabrication'] as String?;
    _mockupProvided    = md['mockup_provided'] as String?;
    _moodboardSupport  = md['moodboard_support'] as String?;
    _oc('materials_used_other').text   = md['materials_used_other']?.toString() ?? '';
    _oc('floral_expertise_other').text = md['floral_expertise_other']?.toString() ?? '';

    final ex = asMap(dm['execution']);
    _maxGuestCapacity            = ex['max_guest_capacity'] as String?;
    _setupTimeRequired           = ex['setup_time_required'] as String?;
    _dismantlingIncluded         = ex['dismantling_included'] as String?;
    _multipleFunctionsCapability = ex['multiple_functions_capability'] as String?;
    _oc('max_guest_capacity_other').text  = ex['max_guest_capacity_other']?.toString() ?? '';
    _oc('setup_time_required_other').text = ex['setup_time_required_other']?.toString() ?? '';

    final fe = asMap(dm['function_expertise']);
    _functionsCovered      = toList(fe['functions_covered']);
    _bestFunctionExpertise = toList(fe['best_function_expertise']);
    _oc('functions_covered_other').text       = fe['functions_covered_other']?.toString() ?? '';
    _oc('best_function_expertise_other').text = fe['best_function_expertise_other']?.toString() ?? '';

    final pr = asMap(dm['pricing']);
    _startingDecorPriceCtrl.text = pr['starting_decor_price']?.toString() ?? '';
    _pricingType           = pr['pricing_type'] as String?;
    _budgetRangeHandled    = pr['budget_range_handled'] as String?;
    _freshFlowerCost       = pr['fresh_flower_cost'] as String?;
    _transportationCharges = pr['transportation_charges'] as String?;
    _oc('pricing_type_other').text           = pr['pricing_type_other']?.toString() ?? '';
    _oc('budget_range_handled_other').text   = pr['budget_range_handled_other']?.toString() ?? '';
    _oc('fresh_flower_cost_other').text      = pr['fresh_flower_cost_other']?.toString() ?? '';
    _oc('transportation_charges_other').text = pr['transportation_charges_other']?.toString() ?? '';

    final lg = asMap(dm['logistics']);
    _indoorSetup               = lg['indoor_setup'] as String?;
    _outdoorSetup              = lg['outdoor_setup'] as String?;
    _destinationWeddingSupport = lg['destination_wedding_support'] as String?;
    _travelStayRequirement     = lg['travel_stay_requirement'] as String?;

    final lt = asMap(dm['lighting_tech']);
    _lightingProvided = lt['lighting_provided'] as String?;
    _ledWallSetup     = lt['led_wall_setup'] as String?;
    _specialEffects   = toList(lt['special_effects']);
    _oc('lighting_provided_other').text = lt['lighting_provided_other']?.toString() ?? '';
    _oc('special_effects_other').text   = lt['special_effects_other']?.toString() ?? '';

    final wf = asMap(dm['workflow']);
    _advanceRequired     = wf['advance_required'] as String?;
    _advancePercentage   = wf['advance_percentage'] as String?;
    _bookingTimeline     = wf['booking_timeline'] as String?;
    _cancellationPolicy  = wf['cancellation_policy'] as String?;
    _revisionFlexibility = wf['revision_flexibility'] as String?;
    _oc('advance_percentage_other').text   = wf['advance_percentage_other']?.toString() ?? '';
    _oc('booking_timeline_other').text     = wf['booking_timeline_other']?.toString() ?? '';
    _oc('cancellation_policy_other').text  = wf['cancellation_policy_other']?.toString() ?? '';
    _oc('revision_flexibility_other').text = wf['revision_flexibility_other']?.toString() ?? '';

    final pt = asMap(dm['portfolio']);
    _tagsCtrl.text  = pt['tags']?.toString() == 'na' ? '' : pt['tags']?.toString() ?? '';
    _notesCtrl.text = pt['notes']?.toString() == 'na' ? '' : pt['notes']?.toString() ?? '';
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "brand_company_name":  _brandCompanyNameCtrl.text,
        "decorator_type":      _decoratorType,
        "years_of_experience": _yearsExpCtrl.text,
        "city":                _cityCtrl.text,
        "service_coverage":    _serviceCoverage,
        "team_size":           _teamSize,
        "decorator_type_other":   _oc('decorator_type_other').text,
        "service_coverage_other": _oc('service_coverage_other').text,
        "team_size_other":        _oc('team_size_other').text,
      },
      "services": {
        ...asMap(ex["services"]),
        "services_offered": _servicesOffered,
        "decor_scope":      _decorScope,
        "services_offered_other": _oc('services_offered_other').text,
        "decor_scope_other":      _oc('decor_scope_other').text,
      },
      "theme_style": {
        ...asMap(ex["theme_style"]),
        "themes_expertise":   _themesExpertise,
        "decor_style":        _decorStyle,
        "best_known_for":     _bestKnownFor,
        "ideal_wedding_type": _idealWeddingType,
        "themes_expertise_other":   _oc('themes_expertise_other').text,
        "decor_style_other":        _oc('decor_style_other').text,
        "best_known_for_other":     _oc('best_known_for_other').text,
        "ideal_wedding_type_other": _oc('ideal_wedding_type_other').text,
      },
      "material_design": {
        ...asMap(ex["material_design"]),
        "materials_used":     _materialsUsed,
        "floral_expertise":   _floralExpertise,
        "custom_fabrication": _customFabrication,
        "mockup_provided":    _mockupProvided,
        "moodboard_support":  _moodboardSupport,
        "materials_used_other":   _oc('materials_used_other').text,
        "floral_expertise_other": _oc('floral_expertise_other').text,
      },
      "execution": {
        ...asMap(ex["execution"]),
        "max_guest_capacity":            _maxGuestCapacity,
        "setup_time_required":           _setupTimeRequired,
        "dismantling_included":          _dismantlingIncluded,
        "multiple_functions_capability": _multipleFunctionsCapability,
        "max_guest_capacity_other":  _oc('max_guest_capacity_other').text,
        "setup_time_required_other": _oc('setup_time_required_other').text,
      },
      "function_expertise": {
        ...asMap(ex["function_expertise"]),
        "functions_covered":       _functionsCovered,
        "best_function_expertise": _bestFunctionExpertise,
        "functions_covered_other":       _oc('functions_covered_other').text,
        "best_function_expertise_other": _oc('best_function_expertise_other').text,
      },
      "pricing": {
        ...asMap(ex["pricing"]),
        "starting_decor_price":   _startingDecorPriceCtrl.text,
        "pricing_type":           _pricingType,
        "budget_range_handled":   _budgetRangeHandled,
        "fresh_flower_cost":      _freshFlowerCost,
        "transportation_charges": _transportationCharges,
        "pricing_type_other":           _oc('pricing_type_other').text,
        "budget_range_handled_other":   _oc('budget_range_handled_other').text,
        "fresh_flower_cost_other":      _oc('fresh_flower_cost_other').text,
        "transportation_charges_other": _oc('transportation_charges_other').text,
      },
      "logistics": {
        ...asMap(ex["logistics"]),
        "indoor_setup":                _indoorSetup,
        "outdoor_setup":               _outdoorSetup,
        "destination_wedding_support": _destinationWeddingSupport,
        "travel_stay_requirement":     _travelStayRequirement,
      },
      "lighting_tech": {
        ...asMap(ex["lighting_tech"]),
        "lighting_provided": _lightingProvided,
        "led_wall_setup":    _ledWallSetup,
        "special_effects":   _specialEffects,
        "lighting_provided_other": _oc('lighting_provided_other').text,
        "special_effects_other":   _oc('special_effects_other').text,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "advance_required":     _advanceRequired,
        "advance_percentage":   _advancePercentage,
        "booking_timeline":     _bookingTimeline,
        "cancellation_policy":  _cancellationPolicy,
        "revision_flexibility": _revisionFlexibility,
        "advance_percentage_other":   _oc('advance_percentage_other').text,
        "booking_timeline_other":     _oc('booking_timeline_other').text,
        "cancellation_policy_other":  _oc('cancellation_policy_other').text,
        "revision_flexibility_other": _oc('revision_flexibility_other').text,
      },
      "portfolio": {
        ...asMap(ex["portfolio"]),
        "tags":  _tagsCtrl.text,
        "notes": _notesCtrl.text,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Decorator Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured decor attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _ds1,
            () => setState(() => _ds1 = !_ds1)),
        if (_ds1) ...[
          const SizedBox(height: 16),
          buildTextArea("Brand / Company Name", _brandCompanyNameCtrl, maxLines: 1),
          buildDropdownWithOther("Decorator Type",
            ["Individual", "Boutique Decor Studio",
             "Full-Service Decor Company", "Luxury Decor Specialist"],
            _decoratorType, (v) => setState(() => _decoratorType = v),
            _oc('decorator_type_other')),
          buildNumberField("Years of Experience", _yearsExpCtrl),
          buildTextArea("City", _cityCtrl, maxLines: 1),
          buildDropdownWithOther("Service Coverage",
            ["Local Only", "Pan India", "International"],
            _serviceCoverage, (v) => setState(() => _serviceCoverage = v),
            _oc('service_coverage_other')),
          buildDropdownWithOther("Team Size",
            ["1–5", "5–15", "15–30", "30+"],
            _teamSize, (v) => setState(() => _teamSize = v),
            _oc('team_size_other')),
        ],
        dividerLine(),

        // ── Section 2: Services Offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _ds2,
            () => setState(() => _ds2 = !_ds2)),
        if (_ds2) ...[
          const SizedBox(height: 16),
          buildMultiSelectWithOther("Services Offered",
            ["Wedding Decor", "Haldi Setup", "Mehendi Setup", "Sangeet Stage",
             "Reception Stage", "Mandap Decor", "Entry Decor", "Photo Booth",
             "Thematic Decor", "Lighting Decor", "Floral Decor"],
            _servicesOffered,
            (o, c) => setState(() => c ? _servicesOffered.add(o) : _servicesOffered.remove(o)),
            _oc('services_offered_other')),
          buildMultiSelectWithOther("Decor Scope",
            ["Full Venue Decor", "Stage Only", "Mandap Only",
             "Entry Decor Only", "Custom Setup"],
            _decorScope,
            (o, c) => setState(() => c ? _decorScope.add(o) : _decorScope.remove(o)),
            _oc('decor_scope_other')),
        ],
        dividerLine(),

        // ── Section 3: Theme & Style ───────────────────────────────────────
        sectionHeader("Section 3 — Theme & style", _ds3,
            () => setState(() => _ds3 = !_ds3)),
        if (_ds3) ...[
          const SizedBox(height: 16),
          buildMultiSelectWithOther("Themes Expertise",
            ["Royal", "Minimal", "Floral", "Bohemian", "Vintage", "Bollywood",
             "Rustic", "Contemporary", "Traditional", "Destination Theme"],
            _themesExpertise,
            (o, c) => setState(() => c ? _themesExpertise.add(o) : _themesExpertise.remove(o)),
            _oc('themes_expertise_other')),
          buildMultiSelectWithOther("Decor Style",
            ["Luxury", "Budget-Friendly", "Premium", "Designer", "Minimalistic"],
            _decorStyle,
            (o, c) => setState(() => c ? _decorStyle.add(o) : _decorStyle.remove(o)),
            _oc('decor_style_other')),
          buildMultiSelectWithOther("Best Known For",
            ["Floral Installations", "Grand Stage Designs", "Minimal Decor",
             "Unique Concepts", "Luxury Weddings", "Budget Transformations"],
            _bestKnownFor,
            (o, c) => setState(() => c ? _bestKnownFor.add(o) : _bestKnownFor.remove(o)),
            _oc('best_known_for_other')),
          buildMultiSelectWithOther("Ideal Wedding Type",
            ["Budget Weddings", "Luxury Weddings", "Destination Weddings",
             "Intimate Weddings", "Large Weddings"],
            _idealWeddingType,
            (o, c) => setState(() => c ? _idealWeddingType.add(o) : _idealWeddingType.remove(o)),
            _oc('ideal_wedding_type_other')),
        ],
        dividerLine(),

        // ── Section 4: Material & Design ───────────────────────────────────
        sectionHeader("Section 4 — Material & design", _ds4,
            () => setState(() => _ds4 = !_ds4)),
        if (_ds4) ...[
          const SizedBox(height: 16),
          buildMultiSelectWithOther("Materials Used",
            ["Fresh Flowers", "Artificial Flowers", "Fabric Drapes",
             "Wooden Structures", "Metal Structures", "LED Elements",
             "Props & Installations"],
            _materialsUsed,
            (o, c) => setState(() => c ? _materialsUsed.add(o) : _materialsUsed.remove(o)),
            _oc('materials_used_other')),
          buildDropdownWithOther("Floral Expertise",
            ["Fresh Only", "Artificial Only", "Both"],
            _floralExpertise, (v) => setState(() => _floralExpertise = v),
            _oc('floral_expertise_other')),
          buildYesNo("Custom Fabrication", _customFabrication,
              (v) => setState(() => _customFabrication = v)),
          buildYesNo("3D Design / Mockup Provided", _mockupProvided,
              (v) => setState(() => _mockupProvided = v)),
          buildYesNo("Moodboard Support", _moodboardSupport,
              (v) => setState(() => _moodboardSupport = v)),
        ],
        dividerLine(),

        // ── Section 5: Event Scale & Execution ─────────────────────────────
        sectionHeader("Section 5 — Event scale & execution", _ds5,
            () => setState(() => _ds5 = !_ds5)),
        if (_ds5) ...[
          const SizedBox(height: 16),
          buildDropdownWithOther("Max Guest Capacity Handled",
            ["Up to 100", "100–300", "300–500", "500–1000", "1000+"],
            _maxGuestCapacity, (v) => setState(() => _maxGuestCapacity = v),
            _oc('max_guest_capacity_other')),
          buildDropdownWithOther("Setup Time Required",
            ["Same Day", "1 Day", "2 Days", "3+ Days"],
            _setupTimeRequired, (v) => setState(() => _setupTimeRequired = v),
            _oc('setup_time_required_other')),
          buildYesNo("Dismantling Included", _dismantlingIncluded,
              (v) => setState(() => _dismantlingIncluded = v)),
          buildYesNo("Multiple Functions Setup Capability", _multipleFunctionsCapability,
              (v) => setState(() => _multipleFunctionsCapability = v)),
        ],
        dividerLine(),

        // ── Section 6: Function-Wise Expertise ─────────────────────────────
        sectionHeader("Section 6 — Function-wise expertise", _ds6,
            () => setState(() => _ds6 = !_ds6)),
        if (_ds6) ...[
          const SizedBox(height: 16),
          buildMultiSelectWithOther("Functions Covered",
            ["Haldi", "Mehendi", "Sangeet", "Wedding",
             "Reception", "Engagement", "Cocktail"],
            _functionsCovered,
            (o, c) => setState(() => c ? _functionsCovered.add(o) : _functionsCovered.remove(o)),
            _oc('functions_covered_other')),
          buildMultiSelectWithOther("Best Function Expertise",
            ["Haldi Decor", "Mandap Decor", "Sangeet Stage",
             "Reception Stage", "Entry Decor"],
            _bestFunctionExpertise,
            (o, c) => setState(() => c ? _bestFunctionExpertise.add(o) : _bestFunctionExpertise.remove(o)),
            _oc('best_function_expertise_other')),
        ],
        dividerLine(),

        // ── Section 7: Pricing & Budget ────────────────────────────────────
        sectionHeader("Section 7 — Pricing & budget", _ds7,
            () => setState(() => _ds7 = !_ds7)),
        if (_ds7) ...[
          const SizedBox(height: 16),
          buildNumberField("Starting Decor Price (₹)", _startingDecorPriceCtrl),
          buildDropdownWithOther("Pricing Type",
            ["Per Event", "Package Based", "Custom Quote"],
            _pricingType, (v) => setState(() => _pricingType = v),
            _oc('pricing_type_other')),
          buildDropdownWithOther("Budget Range Handled",
            ["Below ₹50K", "₹50K–₹1L", "₹1L–₹3L", "₹3L–₹5L", "₹5L+"],
            _budgetRangeHandled, (v) => setState(() => _budgetRangeHandled = v),
            _oc('budget_range_handled_other')),
          buildDropdownWithOther("Fresh Flower Cost",
            ["Included", "Extra", "Depends on Design"],
            _freshFlowerCost, (v) => setState(() => _freshFlowerCost = v),
            _oc('fresh_flower_cost_other')),
          buildDropdownWithOther("Transportation Charges",
            ["Included", "Extra", "Depends on Location"],
            _transportationCharges, (v) => setState(() => _transportationCharges = v),
            _oc('transportation_charges_other')),
        ],
        dividerLine(),

        // ── Section 8: Venue & Logistics ───────────────────────────────────
        sectionHeader("Section 8 — Venue & logistics", _ds8,
            () => setState(() => _ds8 = !_ds8)),
        if (_ds8) ...[
          const SizedBox(height: 16),
          buildYesNo("Indoor Setup Capability", _indoorSetup,
              (v) => setState(() => _indoorSetup = v)),
          buildYesNo("Outdoor Setup Capability", _outdoorSetup,
              (v) => setState(() => _outdoorSetup = v)),
          buildYesNo("Destination Wedding Support", _destinationWeddingSupport,
              (v) => setState(() => _destinationWeddingSupport = v)),
          buildYesNo("Travel & Stay Requirement", _travelStayRequirement,
              (v) => setState(() => _travelStayRequirement = v)),
        ],
        dividerLine(),

        // ── Section 9: Lighting & Tech ─────────────────────────────────────
        sectionHeader("Section 9 — Lighting & tech", _ds9,
            () => setState(() => _ds9 = !_ds9)),
        if (_ds9) ...[
          const SizedBox(height: 16),
          buildDropdownWithOther("Lighting Provided",
            ["Basic", "Advanced", "Full Production"],
            _lightingProvided, (v) => setState(() => _lightingProvided = v),
            _oc('lighting_provided_other')),
          buildYesNo("LED Wall Setup", _ledWallSetup,
              (v) => setState(() => _ledWallSetup = v)),
          buildMultiSelectWithOther("Special Effects",
            ["Cold Pyro", "Smoke Effects", "Bubble Machine", "Fireworks"],
            _specialEffects,
            (o, c) => setState(() => c ? _specialEffects.add(o) : _specialEffects.remove(o)),
            _oc('special_effects_other')),
        ],
        dividerLine(),

        // ── Section 10: Workflow & Booking ─────────────────────────────────
        sectionHeader("Section 10 — Workflow & booking", _ds10,
            () => setState(() => _ds10 = !_ds10)),
        if (_ds10) ...[
          const SizedBox(height: 16),
          buildYesNo("Advance Required", _advanceRequired,
              (v) => setState(() => _advanceRequired = v)),
          buildDropdownWithOther("Advance Percentage",
            ["25%", "50%", "75%"],
            _advancePercentage, (v) => setState(() => _advancePercentage = v),
            _oc('advance_percentage_other')),
          buildDropdownWithOther("Booking Timeline",
            ["1 Month Before", "3 Months Before", "6 Months Before"],
            _bookingTimeline, (v) => setState(() => _bookingTimeline = v),
            _oc('booking_timeline_other')),
          buildDropdownWithOther("Cancellation Policy",
            ["Non Refundable", "Partial Refund", "Flexible"],
            _cancellationPolicy, (v) => setState(() => _cancellationPolicy = v),
            _oc('cancellation_policy_other')),
          buildDropdownWithOther("Revision Flexibility",
            ["High", "Medium", "Limited"],
            _revisionFlexibility, (v) => setState(() => _revisionFlexibility = v),
            _oc('revision_flexibility_other')),
        ],
        dividerLine(),

        // ── Section 11: Portfolio Intelligence ─────────────────────────────
        sectionHeader("Section 11 — Portfolio intelligence", _ds11,
            () => setState(() => _ds11 = !_ds11)),
        if (_ds11) ...[
          const SizedBox(height: 8),
          Text(
            "Upload decor portfolio in the Photos tab. Tag each setup with Function Type, Theme, Budget Range, Guest Count, Venue Type, Color Palette.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          buildTextArea("Default Tags", _tagsCtrl, maxLines: 2),
          buildTextArea("Notes", _notesCtrl),
        ],
      ],
    );
  }
}
