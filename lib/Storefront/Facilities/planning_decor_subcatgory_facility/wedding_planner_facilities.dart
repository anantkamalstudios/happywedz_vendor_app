import 'package:flutter/material.dart';
import '../facilities_helpers.dart';

class WeddingPlannerFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const WeddingPlannerFacilities({super.key, required this.attributes});

  @override
  State<WeddingPlannerFacilities> createState() =>
      WeddingPlannerFacilitiesState();
}

class WeddingPlannerFacilitiesState extends State<WeddingPlannerFacilities>
    with FacilitiesHelpersMixin<WeddingPlannerFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  final        _companyNameCtrl = TextEditingController();
  String?      _plannerType;
  final        _yearsExpCtrl    = TextEditingController();
  final        _cityCtrl        = TextEditingController();
  String?      _serviceCoverage;
  String?      _teamSize;

  // ── services ──────────────────────────────────────────────────────────────
  List<String> _servicesOffered = [];
  List<String> _planningType    = [];
  String?      _vendorSourcing;

  // ── scale ─────────────────────────────────────────────────────────────────
  String?      _eventsManagedPerYear;
  String?      _guestHandlingCapacity;
  List<String> _expertiseIn        = [];
  List<String> _functionsManaged   = [];

  // ── logistics ─────────────────────────────────────────────────────────────
  String?      _destinationWeddingSupport;
  List<String> _destinationsCovered = [];
  String?      _travelLogisticsManagement;
  String?      _guestAccommodationManagement;
  String?      _transportationManagement;

  // ── budget ────────────────────────────────────────────────────────────────
  String?      _minimumBudgetHandled;
  String?      _maximumBudgetHandled;
  String?      _pricingModel;
  String?      _planningFeesRange;
  String?      _commissionFromVendors;

  // ── design ────────────────────────────────────────────────────────────────
  String?      _themePlanningSupport;
  List<String> _themesExpertise   = [];
  String?      _moodboardCreation;
  String?      _customConceptDesign;

  // ── vendor_management ─────────────────────────────────────────────────────
  List<String> _vendorCategoriesManaged = [];
  String?      _vendorNegotiationSupport;
  String?      _vendorBundling;

  // ── technology ────────────────────────────────────────────────────────────
  String?      _digitalPlanningTools;
  String?      _realTimeCoordinationTeam;
  String?      _timelinePlanning;
  String?      _checklistManagement;
  String?      _onGroundExecutionTeam;

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _advanceRequired;
  String?      _advancePercentage;
  String?      _bookingTimeline;
  String?      _cancellationPolicy;
  String?      _revisionFlexibility;

  // ── suitability ───────────────────────────────────────────────────────────
  List<String> _bestFor         = [];
  List<String> _idealClientType = [];

  // ── section expansion ─────────────────────────────────────────────────────
  bool _ws1  = true;
  bool _ws2  = false;
  bool _ws3  = false;
  bool _ws4  = false;
  bool _ws5  = false;
  bool _ws6  = false;
  bool _ws7  = false;
  bool _ws8  = false;
  bool _ws9  = false;
  bool _ws10 = false;

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
    _companyNameCtrl.dispose();
    _yearsExpCtrl.dispose();
    _cityCtrl.dispose();
    for (final c in _otherCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final wm = asMap(attrs['wedding_planner_master']);

    final id = asMap(wm['identity']);
    _companyNameCtrl.text = id['company_name']?.toString() ?? '';
    _plannerType          = id['planner_type'] as String?;
    _yearsExpCtrl.text    = id['years_of_experience']?.toString() ?? '';
    _cityCtrl.text        = id['city']?.toString() ?? '';
    _serviceCoverage      = id['service_coverage'] as String?;
    _teamSize             = id['team_size'] as String?;
    _oc('planner_type_other').text     = id['planner_type_other']?.toString() ?? '';
    _oc('service_coverage_other').text = id['service_coverage_other']?.toString() ?? '';
    _oc('team_size_other').text        = id['team_size_other']?.toString() ?? '';

    final sv = asMap(wm['services']);
    _servicesOffered = toList(sv['services_offered']);
    _planningType    = toList(sv['planning_type']);
    _vendorSourcing  = sv['vendor_sourcing'] as String?;
    _oc('services_offered_other').text = sv['services_offered_other']?.toString() ?? '';
    _oc('planning_type_other').text    = sv['planning_type_other']?.toString() ?? '';
    _oc('vendor_sourcing_other').text  = sv['vendor_sourcing_other']?.toString() ?? '';

    final sc = asMap(wm['scale']);
    _eventsManagedPerYear  = sc['events_managed_per_year'] as String?;
    _guestHandlingCapacity = sc['guest_handling_capacity'] as String?;
    _expertiseIn           = toList(sc['expertise_in']);
    _functionsManaged      = toList(sc['functions_managed']);
    _oc('events_managed_per_year_other').text  = sc['events_managed_per_year_other']?.toString() ?? '';
    _oc('guest_handling_capacity_other').text  = sc['guest_handling_capacity_other']?.toString() ?? '';
    _oc('expertise_in_other').text             = sc['expertise_in_other']?.toString() ?? '';
    _oc('functions_managed_other').text        = sc['functions_managed_other']?.toString() ?? '';

    final lg = asMap(wm['logistics']);
    _destinationWeddingSupport    = lg['destination_wedding_support'] as String?;
    _destinationsCovered          = toList(lg['destinations_covered']);
    _travelLogisticsManagement    = lg['travel_logistics_management'] as String?;
    _guestAccommodationManagement = lg['guest_accommodation_management'] as String?;
    _transportationManagement     = lg['transportation_management'] as String?;
    _oc('destinations_covered_other').text = lg['destinations_covered_other']?.toString() ?? '';

    final bd = asMap(wm['budget']);
    _minimumBudgetHandled  = bd['minimum_budget_handled'] as String?;
    _maximumBudgetHandled  = bd['maximum_budget_handled'] as String?;
    _pricingModel          = bd['pricing_model'] as String?;
    _planningFeesRange     = bd['planning_fees_range'] as String?;
    _commissionFromVendors = bd['commission_from_vendors'] as String?;
    _oc('minimum_budget_handled_other').text  = bd['minimum_budget_handled_other']?.toString() ?? '';
    _oc('maximum_budget_handled_other').text  = bd['maximum_budget_handled_other']?.toString() ?? '';
    _oc('pricing_model_other').text           = bd['pricing_model_other']?.toString() ?? '';
    _oc('planning_fees_range_other').text     = bd['planning_fees_range_other']?.toString() ?? '';
    _oc('commission_from_vendors_other').text = bd['commission_from_vendors_other']?.toString() ?? '';

    final dg = asMap(wm['design']);
    _themePlanningSupport = dg['theme_planning_support'] as String?;
    _themesExpertise      = toList(dg['themes_expertise']);
    _moodboardCreation    = dg['moodboard_creation'] as String?;
    _customConceptDesign  = dg['custom_concept_design'] as String?;
    _oc('themes_expertise_other').text = dg['themes_expertise_other']?.toString() ?? '';

    final vm = asMap(wm['vendor_management']);
    _vendorCategoriesManaged  = toList(vm['vendor_categories_managed']);
    _vendorNegotiationSupport = vm['vendor_negotiation_support'] as String?;
    _vendorBundling           = vm['vendor_bundling'] as String?;
    _oc('vendor_categories_managed_other').text = vm['vendor_categories_managed_other']?.toString() ?? '';

    final tc = asMap(wm['technology']);
    _digitalPlanningTools     = tc['digital_planning_tools'] as String?;
    _realTimeCoordinationTeam = tc['real_time_coordination_team'] as String?;
    _timelinePlanning         = tc['timeline_planning'] as String?;
    _checklistManagement      = tc['checklist_management'] as String?;
    _onGroundExecutionTeam    = tc['on_ground_execution_team'] as String?;

    final wf = asMap(wm['workflow']);
    _advanceRequired     = wf['advance_required'] as String?;
    _advancePercentage   = wf['advance_percentage'] as String?;
    _bookingTimeline     = wf['booking_timeline'] as String?;
    _cancellationPolicy  = wf['cancellation_policy'] as String?;
    _revisionFlexibility = wf['revision_flexibility'] as String?;
    _oc('advance_percentage_other').text   = wf['advance_percentage_other']?.toString() ?? '';
    _oc('booking_timeline_other').text     = wf['booking_timeline_other']?.toString() ?? '';
    _oc('cancellation_policy_other').text  = wf['cancellation_policy_other']?.toString() ?? '';
    _oc('revision_flexibility_other').text = wf['revision_flexibility_other']?.toString() ?? '';

    final su = asMap(wm['suitability']);
    _bestFor         = toList(su['best_for']);
    _idealClientType = toList(su['ideal_client_type']);
    _oc('best_for_other').text          = su['best_for_other']?.toString() ?? '';
    _oc('ideal_client_type_other').text = su['ideal_client_type_other']?.toString() ?? '';
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "company_name":          _companyNameCtrl.text,
        "planner_type":          _plannerType,
        "years_of_experience":   _yearsExpCtrl.text,
        "city":                  _cityCtrl.text,
        "service_coverage":      _serviceCoverage,
        "team_size":             _teamSize,
        "planner_type_other":     _oc('planner_type_other').text,
        "service_coverage_other": _oc('service_coverage_other').text,
        "team_size_other":        _oc('team_size_other').text,
      },
      "services": {
        ...asMap(ex["services"]),
        "services_offered": _servicesOffered,
        "planning_type":    _planningType,
        "vendor_sourcing":  _vendorSourcing,
        "services_offered_other": _oc('services_offered_other').text,
        "planning_type_other":    _oc('planning_type_other').text,
        "vendor_sourcing_other":  _oc('vendor_sourcing_other').text,
      },
      "scale": {
        ...asMap(ex["scale"]),
        "events_managed_per_year": _eventsManagedPerYear,
        "guest_handling_capacity": _guestHandlingCapacity,
        "expertise_in":            _expertiseIn,
        "functions_managed":       _functionsManaged,
        "events_managed_per_year_other": _oc('events_managed_per_year_other').text,
        "guest_handling_capacity_other": _oc('guest_handling_capacity_other').text,
        "expertise_in_other":            _oc('expertise_in_other').text,
        "functions_managed_other":       _oc('functions_managed_other').text,
      },
      "logistics": {
        ...asMap(ex["logistics"]),
        "destination_wedding_support":    _destinationWeddingSupport,
        "destinations_covered":           _destinationsCovered,
        "travel_logistics_management":    _travelLogisticsManagement,
        "guest_accommodation_management": _guestAccommodationManagement,
        "transportation_management":      _transportationManagement,
        "destinations_covered_other":     _oc('destinations_covered_other').text,
      },
      "budget": {
        ...asMap(ex["budget"]),
        "minimum_budget_handled":  _minimumBudgetHandled,
        "maximum_budget_handled":  _maximumBudgetHandled,
        "pricing_model":           _pricingModel,
        "planning_fees_range":     _planningFeesRange,
        "commission_from_vendors": _commissionFromVendors,
        "minimum_budget_handled_other":  _oc('minimum_budget_handled_other').text,
        "maximum_budget_handled_other":  _oc('maximum_budget_handled_other').text,
        "pricing_model_other":           _oc('pricing_model_other').text,
        "planning_fees_range_other":     _oc('planning_fees_range_other').text,
        "commission_from_vendors_other": _oc('commission_from_vendors_other').text,
      },
      "design": {
        ...asMap(ex["design"]),
        "theme_planning_support": _themePlanningSupport,
        "themes_expertise":       _themesExpertise,
        "moodboard_creation":     _moodboardCreation,
        "custom_concept_design":  _customConceptDesign,
        "themes_expertise_other": _oc('themes_expertise_other').text,
      },
      "vendor_management": {
        ...asMap(ex["vendor_management"]),
        "vendor_categories_managed":  _vendorCategoriesManaged,
        "vendor_negotiation_support": _vendorNegotiationSupport,
        "vendor_bundling":            _vendorBundling,
        "vendor_categories_managed_other": _oc('vendor_categories_managed_other').text,
      },
      "technology": {
        ...asMap(ex["technology"]),
        "digital_planning_tools":      _digitalPlanningTools,
        "real_time_coordination_team": _realTimeCoordinationTeam,
        "timeline_planning":           _timelinePlanning,
        "checklist_management":        _checklistManagement,
        "on_ground_execution_team":    _onGroundExecutionTeam,
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
      "suitability": {
        ...asMap(ex["suitability"]),
        "best_for":          _bestFor,
        "ideal_client_type": _idealClientType,
        "best_for_other":          _oc('best_for_other').text,
        "ideal_client_type_other": _oc('ideal_client_type_other').text,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Wedding Planner Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured planner attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _ws1,
            () => setState(() => _ws1 = !_ws1)),
        if (_ws1) ...[
          const SizedBox(height: 16),
          buildTextArea("Company / Planner Name", _companyNameCtrl, maxLines: 1),
          buildDropdownWithOther("Planner Type",
            ["Individual Planner", "Boutique Agency",
             "Full-Service Agency", "Luxury Wedding Planner"],
            _plannerType, (v) => setState(() => _plannerType = v),
            _oc('planner_type_other')),
          buildNumberField("Years of Experience", _yearsExpCtrl),
          buildTextArea("City", _cityCtrl, maxLines: 1),
          buildDropdownWithOther("Service Coverage",
            ["Local Only", "Pan India", "International"],
            _serviceCoverage, (v) => setState(() => _serviceCoverage = v),
            _oc('service_coverage_other')),
          buildDropdownWithOther("Team Size",
            ["1–3", "4–10", "10–25", "25+"],
            _teamSize, (v) => setState(() => _teamSize = v),
            _oc('team_size_other')),
        ],
        dividerLine(),

        // ── Section 2: Services Offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _ws2,
            () => setState(() => _ws2 = !_ws2)),
        if (_ws2) ...[
          const SizedBox(height: 16),
          buildMultiSelectWithOther("Services Offered",
            ["End-to-End Wedding Planning", "Partial Planning",
             "Wedding Day Coordination", "Destination Wedding Planning",
             "Vendor Management", "Budget Planning", "Guest Management",
             "RSVP Management", "Hospitality Management",
             "Logistics & Travel Planning", "Theme Planning",
             "Decor Coordination", "Entertainment Planning"],
            _servicesOffered,
            (o, c) => setState(() => c ? _servicesOffered.add(o) : _servicesOffered.remove(o)),
            _oc('services_offered_other')),
          buildMultiSelectWithOther("Planning Type",
            ["Full Planning", "Partial Planning", "Execution Only"],
            _planningType,
            (o, c) => setState(() => c ? _planningType.add(o) : _planningType.remove(o)),
            _oc('planning_type_other')),
          buildDropdownWithOther("Vendor Sourcing",
            ["Own Vendor Network", "Open to Client Vendors", "Both"],
            _vendorSourcing, (v) => setState(() => _vendorSourcing = v),
            _oc('vendor_sourcing_other')),
        ],
        dividerLine(),

        // ── Section 3: Event Scale & Expertise ─────────────────────────────
        sectionHeader("Section 3 — Event scale & expertise", _ws3,
            () => setState(() => _ws3 = !_ws3)),
        if (_ws3) ...[
          const SizedBox(height: 16),
          buildDropdownWithOther("Events Managed Per Year",
            ["0–10", "10–25", "25–50", "50+"],
            _eventsManagedPerYear, (v) => setState(() => _eventsManagedPerYear = v),
            _oc('events_managed_per_year_other')),
          buildDropdownWithOther("Guest Handling Capacity",
            ["Up to 100", "100–300", "300–500", "500–1000", "1000+"],
            _guestHandlingCapacity, (v) => setState(() => _guestHandlingCapacity = v),
            _oc('guest_handling_capacity_other')),
          buildMultiSelectWithOther("Expertise In",
            ["Destination Weddings", "Luxury Weddings", "Budget Weddings",
             "Intimate Weddings", "Big Fat Weddings", "Cross-Cultural Weddings"],
            _expertiseIn,
            (o, c) => setState(() => c ? _expertiseIn.add(o) : _expertiseIn.remove(o)),
            _oc('expertise_in_other')),
          buildMultiSelectWithOther("Functions Managed",
            ["Haldi", "Mehendi", "Sangeet", "Wedding",
             "Reception", "Cocktail", "Engagement"],
            _functionsManaged,
            (o, c) => setState(() => c ? _functionsManaged.add(o) : _functionsManaged.remove(o)),
            _oc('functions_managed_other')),
        ],
        dividerLine(),

        // ── Section 4: Destination & Logistics ─────────────────────────────
        sectionHeader("Section 4 — Destination & logistics", _ws4,
            () => setState(() => _ws4 = !_ws4)),
        if (_ws4) ...[
          const SizedBox(height: 16),
          buildYesNo("Destination Wedding Support", _destinationWeddingSupport,
              (v) => setState(() => _destinationWeddingSupport = v)),
          buildMultiSelectWithOther("Destinations Covered",
            ["Mumbai", "Pune", "Goa", "Udaipur", "Jaipur", "Delhi",
             "Bengaluru", "Hyderabad", "Nashik", "Ahmedabad", "Nagpur",
             "Jodhpur", "Chennai", "Kolkata", "Aurangabad", "Jaisalmer",
             "All Over India", "International"],
            _destinationsCovered,
            (o, c) => setState(() => c ? _destinationsCovered.add(o) : _destinationsCovered.remove(o)),
            _oc('destinations_covered_other')),
          buildYesNo("Travel & Logistics Management", _travelLogisticsManagement,
              (v) => setState(() => _travelLogisticsManagement = v)),
          buildYesNo("Guest Accommodation Management", _guestAccommodationManagement,
              (v) => setState(() => _guestAccommodationManagement = v)),
          buildYesNo("Transportation Management", _transportationManagement,
              (v) => setState(() => _transportationManagement = v)),
        ],
        dividerLine(),

        // ── Section 5: Budget & Pricing ────────────────────────────────────
        sectionHeader("Section 5 — Budget & pricing", _ws5,
            () => setState(() => _ws5 = !_ws5)),
        if (_ws5) ...[
          const SizedBox(height: 16),
          buildDropdownWithOther("Minimum Budget Handled",
            ["Below ₹5L", "₹5L–₹10L", "₹10L–₹25L", "₹25L–₹50L", "₹50L+"],
            _minimumBudgetHandled, (v) => setState(() => _minimumBudgetHandled = v),
            _oc('minimum_budget_handled_other')),
          buildDropdownWithOther("Maximum Budget Handled",
            ["₹10L", "₹25L", "₹50L", "₹1Cr", "₹1Cr+"],
            _maximumBudgetHandled, (v) => setState(() => _maximumBudgetHandled = v),
            _oc('maximum_budget_handled_other')),
          buildDropdownWithOther("Pricing Model",
            ["Fixed Fee", "Percentage of Budget", "Per Event"],
            _pricingModel, (v) => setState(() => _pricingModel = v),
            _oc('pricing_model_other')),
          buildDropdownWithOther("Planning Fees Range",
            ["Below ₹50K", "₹50K–₹1L", "₹1L–₹3L", "₹3L–₹5L", "₹5L+"],
            _planningFeesRange, (v) => setState(() => _planningFeesRange = v),
            _oc('planning_fees_range_other')),
          buildDropdownWithOther("Commission from Vendors",
            ["Yes", "No", "Depends"],
            _commissionFromVendors, (v) => setState(() => _commissionFromVendors = v),
            _oc('commission_from_vendors_other')),
        ],
        dividerLine(),

        // ── Section 6: Design & Theme ──────────────────────────────────────
        sectionHeader("Section 6 — Design & theme", _ws6,
            () => setState(() => _ws6 = !_ws6)),
        if (_ws6) ...[
          const SizedBox(height: 16),
          buildYesNo("Theme Planning Support", _themePlanningSupport,
              (v) => setState(() => _themePlanningSupport = v)),
          buildMultiSelectWithOther("Themes Expertise",
            ["Royal", "Minimal", "Floral", "Bohemian",
             "Bollywood", "Destination Theme", "Traditional"],
            _themesExpertise,
            (o, c) => setState(() => c ? _themesExpertise.add(o) : _themesExpertise.remove(o)),
            _oc('themes_expertise_other')),
          buildYesNo("Moodboard Creation", _moodboardCreation,
              (v) => setState(() => _moodboardCreation = v)),
          buildYesNo("Custom Concept Design", _customConceptDesign,
              (v) => setState(() => _customConceptDesign = v)),
        ],
        dividerLine(),

        // ── Section 7: Vendor Management ───────────────────────────────────
        sectionHeader("Section 7 — Vendor management", _ws7,
            () => setState(() => _ws7 = !_ws7)),
        if (_ws7) ...[
          const SizedBox(height: 16),
          buildMultiSelectWithOther("Vendor Categories Managed",
            ["Venue", "Decor", "Catering", "Photography",
             "Makeup", "Entertainment", "Logistics"],
            _vendorCategoriesManaged,
            (o, c) => setState(() => c ? _vendorCategoriesManaged.add(o) : _vendorCategoriesManaged.remove(o)),
            _oc('vendor_categories_managed_other')),
          buildYesNo("Vendor Negotiation Support", _vendorNegotiationSupport,
              (v) => setState(() => _vendorNegotiationSupport = v)),
          buildYesNo("Vendor Bundling", _vendorBundling,
              (v) => setState(() => _vendorBundling = v)),
        ],
        dividerLine(),

        // ── Section 8: Technology & Process ────────────────────────────────
        sectionHeader("Section 8 — Technology & process", _ws8,
            () => setState(() => _ws8 = !_ws8)),
        if (_ws8) ...[
          const SizedBox(height: 16),
          buildYesNo("Digital Planning Tools", _digitalPlanningTools,
              (v) => setState(() => _digitalPlanningTools = v)),
          buildYesNo("Real-Time Coordination Team", _realTimeCoordinationTeam,
              (v) => setState(() => _realTimeCoordinationTeam = v)),
          buildYesNo("Timeline Planning", _timelinePlanning,
              (v) => setState(() => _timelinePlanning = v)),
          buildYesNo("Checklist Management", _checklistManagement,
              (v) => setState(() => _checklistManagement = v)),
          buildYesNo("On-Ground Execution Team", _onGroundExecutionTeam,
              (v) => setState(() => _onGroundExecutionTeam = v)),
        ],
        dividerLine(),

        // ── Section 9: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 9 — Workflow & booking", _ws9,
            () => setState(() => _ws9 = !_ws9)),
        if (_ws9) ...[
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

        // ── Section 10: Event Suitability ──────────────────────────────────
        sectionHeader("Section 10 — Event suitability", _ws10,
            () => setState(() => _ws10 = !_ws10)),
        if (_ws10) ...[
          const SizedBox(height: 16),
          buildMultiSelectWithOther("Best For",
            ["Budget Weddings", "Luxury Weddings", "Destination Weddings",
             "Intimate Weddings", "Large Weddings"],
            _bestFor,
            (o, c) => setState(() => c ? _bestFor.add(o) : _bestFor.remove(o)),
            _oc('best_for_other')),
          buildMultiSelectWithOther("Ideal Client Type",
            ["Hands-On Clients", "Fully Managed Clients",
             "NRI Clients", "Destination Clients"],
            _idealClientType,
            (o, c) => setState(() => c ? _idealClientType.add(o) : _idealClientType.remove(o)),
            _oc('ideal_client_type_other')),
        ],
      ],
    );
  }
}
