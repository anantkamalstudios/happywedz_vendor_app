import 'package:flutter/material.dart';
import 'facilities_helpers.dart';

class PhotographerFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const PhotographerFacilities({super.key, required this.attributes});

  @override
  State<PhotographerFacilities> createState() => PhotographerFacilitiesState();
}

class PhotographerFacilitiesState extends State<PhotographerFacilities>
    with FacilitiesHelpersMixin<PhotographerFacilities> {

  List<String> _servicesOffered   = [];
  String?      _photographerType;
  String?      _alsoAvailableFor;
  final        _yearsExpCtrl      = TextEditingController();
  String?      _travelAvailability;
  List<String> _photographyStyle  = [];
  String?      _editingStyle;
  List<String> _bestKnownFor      = [];
  List<String> _idealWeddingType  = [];
  String?      _teamSize;
  final        _maxEventsCtrl     = TextEditingController();
  String?      _backupTeam;
  String?      _femalePhotographer;
  String?      _photosDelivered;
  List<String> _videosDelivered   = [];
  String?      _rawDataProvided;
  String?      _albumIncluded;
  String?      _albumType;
  String?      _deliveryTime;
  String?      _expressDelivery;
  final        _startingPriceCtrl = TextEditingController();
  String?      _pricingType;
  String?      _preWeddingShootCost;
  String?      _travelCharges;
  String?      _accommodationRequired;
  String?      _cameraType;
  String?      _droneAvailable;
  String?      _lightingSetup;
  String?      _liveStreamingSetup;
  String?      _locationsSupported;
  String?      _conceptShootAvailable;
  String?      _propsProvided;
  String?      _locationScoutingSupport;
  String?      _bookingAdvanceRequired;
  String?      _advancePercentage;
  String?      _cancellationPolicy;
  String?      _revisionAllowed;
  String?      _numberOfRevisions;
  List<String> _functionsCovered  = [];
  List<String> _bestFor           = [];
  final        _defaultTagsCtrl   = TextEditingController();
  final        _notesCtrl         = TextEditingController();

  bool _s1  = true;
  bool _s2  = false;
  bool _s39 = false;
  bool _s10 = false;

  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
    if (_defaultTagsCtrl.text.isEmpty) {
      _defaultTagsCtrl.text =
          'Function Type, Shot Type, Lighting Type, Mood, Location Type';
    }
  }

  @override
  void dispose() {
    _yearsExpCtrl.dispose();
    _maxEventsCtrl.dispose();
    _startingPriceCtrl.dispose();
    _defaultTagsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> data) {
    final pm = asMap(data['photographer_master']);

    final identity = asMap(pm['identity']);
    _servicesOffered    = toList(identity['services_offered']);
    _photographerType   = identity['photographer_type'] as String?;
    _alsoAvailableFor   = identity['also_available_for'] as String?;
    _yearsExpCtrl.text  = identity['years_of_experience']?.toString() ?? '';
    _travelAvailability = identity['travel_availability'] as String?;

    final style = asMap(pm['style_intelligence']);
    _photographyStyle = toList(style['photography_style']);
    _editingStyle     = style['editing_style'] as String?;
    _bestKnownFor     = toList(style['best_known_for']);
    _idealWeddingType = toList(style['ideal_wedding_type']);

    final team = asMap(pm['team_coverage']);
    _teamSize           = team['team_size'] as String?;
    _maxEventsCtrl.text = team['max_events_per_day']?.toString() ?? '';
    _backupTeam         = team['backup_team_available'] as String?;
    _femalePhotographer = team['female_photographer_available'] as String?;

    final del = asMap(pm['deliverables']);
    _photosDelivered = del['photos_delivered'] as String?;
    _videosDelivered = toList(del['videos_delivered']);
    _rawDataProvided = del['raw_data_provided'] as String?;
    _albumIncluded   = del['album_included'] as String?;
    _albumType       = del['album_type'] as String?;
    _deliveryTime    = del['delivery_time'] as String?;
    _expressDelivery = del['express_delivery_available'] as String?;

    final pricing = asMap(pm['pricing']);
    _startingPriceCtrl.text = pricing['starting_price']?.toString() ?? '';
    _pricingType            = pricing['pricing_type'] as String?;
    _preWeddingShootCost    = pricing['pre_wedding_shoot_cost'] as String?;
    _travelCharges          = pricing['travel_charges'] as String?;
    _accommodationRequired  = pricing['accommodation_required'] as String?;

    final equip = asMap(pm['equipment']);
    _cameraType         = equip['camera_type'] as String?;
    _droneAvailable     = equip['drone_available'] as String?;
    _lightingSetup      = equip['lighting_setup'] as String?;
    _liveStreamingSetup = equip['live_streaming_setup'] as String?;

    final prewed = asMap(pm['prewedding_specialization']);
    _locationsSupported      = prewed['locations_supported'] as String?;
    _conceptShootAvailable   = prewed['concept_shoot_available'] as String?;
    _propsProvided           = prewed['props_provided'] as String?;
    _locationScoutingSupport = prewed['location_scouting_support'] as String?;

    final wf = asMap(pm['workflow']);
    _bookingAdvanceRequired = wf['booking_advance_required'] as String?;
    _advancePercentage      = wf['advance_percentage'] as String?;
    _cancellationPolicy     = wf['cancellation_policy'] as String?;
    _revisionAllowed        = wf['revision_allowed'] as String?;
    _numberOfRevisions      = wf['number_of_revisions'] as String?;

    final ev = asMap(pm['event_suitability']);
    _functionsCovered = toList(ev['functions_covered']);
    _bestFor          = toList(ev['best_for']);

    final tag = asMap(pm['tagging']);
    _defaultTagsCtrl.text =
        tag['default_tags']?.toString().isNotEmpty == true
            ? tag['default_tags'].toString()
            : 'Function Type, Shot Type, Lighting Type, Mood, Location Type';
    _notesCtrl.text = tag['notes']?.toString() ?? '';
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "services_offered":    _servicesOffered,
        "photographer_type":   _photographerType,
        "also_available_for":  _alsoAvailableFor,
        "years_of_experience": _yearsExpCtrl.text,
        "travel_availability": _travelAvailability,
      },
      "style_intelligence": {
        ...asMap(ex["style_intelligence"]),
        "photography_style":  _photographyStyle,
        "editing_style":      _editingStyle,
        "best_known_for":     _bestKnownFor,
        "ideal_wedding_type": _idealWeddingType,
      },
      "team_coverage": {
        ...asMap(ex["team_coverage"]),
        "team_size":                     _teamSize,
        "max_events_per_day":            _maxEventsCtrl.text,
        "backup_team_available":         _backupTeam,
        "female_photographer_available": _femalePhotographer,
      },
      "deliverables": {
        ...asMap(ex["deliverables"]),
        "photos_delivered":           _photosDelivered,
        "videos_delivered":           _videosDelivered,
        "raw_data_provided":          _rawDataProvided,
        "album_included":             _albumIncluded,
        "album_type":                 _albumType,
        "delivery_time":              _deliveryTime,
        "express_delivery_available": _expressDelivery,
      },
      "pricing": {
        ...asMap(ex["pricing"]),
        "starting_price":         _startingPriceCtrl.text,
        "pricing_type":           _pricingType,
        "pre_wedding_shoot_cost": _preWeddingShootCost,
        "travel_charges":         _travelCharges,
        "accommodation_required": _accommodationRequired,
      },
      "equipment": {
        ...asMap(ex["equipment"]),
        "camera_type":          _cameraType,
        "drone_available":      _droneAvailable,
        "lighting_setup":       _lightingSetup,
        "live_streaming_setup": _liveStreamingSetup,
      },
      "prewedding_specialization": {
        ...asMap(ex["prewedding_specialization"]),
        "locations_supported":       _locationsSupported,
        "concept_shoot_available":   _conceptShootAvailable,
        "props_provided":            _propsProvided,
        "location_scouting_support": _locationScoutingSupport,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "booking_advance_required": _bookingAdvanceRequired,
        "advance_percentage":       _advancePercentage,
        "cancellation_policy":      _cancellationPolicy,
        "revision_allowed":         _revisionAllowed,
        "number_of_revisions":      _numberOfRevisions,
      },
      "event_suitability": {
        ...asMap(ex["event_suitability"]),
        "functions_covered": _functionsCovered,
        "best_for":          _bestFor,
      },
      "tagging": {
        ...asMap(ex["tagging"]),
        "default_tags": _defaultTagsCtrl.text,
        "notes":        _notesCtrl.text,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Wedding photographer master profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured photographer attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic identity ─────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _s1,
            () => setState(() => _s1 = !_s1)),
        if (_s1) ...[
          const SizedBox(height: 16),
          buildMultiSelect(
            "Services offered",
            ["Wedding Photography", "Pre-Wedding Shoot", "Candid Photography",
             "Traditional Photography", "Cinematic Videography", "Drone Shoot",
             "Reel", "Short Content", "Live Streaming"],
            _servicesOffered,
            (o, c) => setState(
                () => c ? _servicesOffered.add(o) : _servicesOffered.remove(o))),
          buildDropdown("Also available for",
            ["Pre-Wedding Only", "Wedding Only", "Both"],
            _alsoAvailableFor, (v) => setState(() => _alsoAvailableFor = v)),
          buildNumberField("Years of experience", _yearsExpCtrl),
          buildDropdown("Travel availability",
            ["Local Only", "Pan India", "International"],
            _travelAvailability, (v) => setState(() => _travelAvailability = v)),
        ],
        dividerLine(),

        // ── Section 2: Style intelligence ────────────────────────────────
        sectionHeader("Section 2 — Style intelligence", _s2,
            () => setState(() => _s2 = !_s2)),
        if (_s2) ...[
          const SizedBox(height: 16),
          buildMultiSelect(
            "Photography style",
            ["Candid", "Traditional", "Documentary", "Editorial", "Fine Art",
             "Cinematic", "Luxury", "Minimal", "Dramatic"],
            _photographyStyle,
            (o, c) => setState(
                () => c ? _photographyStyle.add(o) : _photographyStyle.remove(o))),
          buildDropdown("Editing style",
            ["Light & Airy", "Dark & Moody", "Vibrant", "Natural Tone", "Matte Finish"],
            _editingStyle, (v) => setState(() => _editingStyle = v)),
          buildMultiSelect(
            "Best known for",
            ["Candid Moments", "Couple Portraits", "Bridal Shots",
             "Family Coverage", "Cinematic Films", "Creative Concepts"],
            _bestKnownFor,
            (o, c) => setState(
                () => c ? _bestKnownFor.add(o) : _bestKnownFor.remove(o))),
          buildMultiSelect(
            "Ideal wedding type",
            ["Budget Weddings", "Luxury Weddings", "Destination Weddings",
             "Intimate Weddings", "Big Fat Weddings"],
            _idealWeddingType,
            (o, c) => setState(
                () => c ? _idealWeddingType.add(o) : _idealWeddingType.remove(o))),
        ],
        dividerLine(),

        // ── Section 3–9: Team, deliverables, pricing, equipment, workflow ─
        sectionHeader(
          "Section 3–9 — Team, deliverables, pricing, equipment, workflow & suitability",
          _s39, () => setState(() => _s39 = !_s39)),
        if (_s39) ...[
          const SizedBox(height: 16),
          buildDropdown("Team size",
            ["Solo", "2-3 Members", "4-6 Members", "6+ Members"],
            _teamSize, (v) => setState(() => _teamSize = v)),
          buildNumberField("Max events covered per day", _maxEventsCtrl),
          buildYesNo("Backup team available", _backupTeam,
              (v) => setState(() => _backupTeam = v)),
          buildYesNo("Female photographer available", _femalePhotographer,
              (v) => setState(() => _femalePhotographer = v)),
          buildDropdown("Photos delivered",
            ["100-300", "300-500", "500-1000", "1000+"],
            _photosDelivered, (v) => setState(() => _photosDelivered = v)),
          buildMultiSelect(
            "Videos delivered",
            ["Highlight Video", "Full Wedding Film", "Instagram Reel", "Teaser"],
            _videosDelivered,
            (o, c) => setState(
                () => c ? _videosDelivered.add(o) : _videosDelivered.remove(o))),
          buildYesNo("Raw data provided", _rawDataProvided,
              (v) => setState(() => _rawDataProvided = v)),
          buildYesNo("Album included", _albumIncluded,
              (v) => setState(() => _albumIncluded = v)),
          buildDropdown("Album type",
            ["Premium Album", "Coffee Table Book", "Magazine Style"],
            _albumType, (v) => setState(() => _albumType = v)),
          buildDropdown("Delivery time",
            ["7 Days", "15 Days", "30 Days", "45+ Days"],
            _deliveryTime, (v) => setState(() => _deliveryTime = v)),
          buildYesNo("Express delivery available", _expressDelivery,
              (v) => setState(() => _expressDelivery = v)),
          buildNumberField("Starting price", _startingPriceCtrl),
          buildDropdown("Pricing type",
            ["Per Day", "Per Event", "Package Based"],
            _pricingType, (v) => setState(() => _pricingType = v)),
          buildDropdown("Pre-wedding shoot cost",
            ["Included", "Extra Charge", "Not Offered"],
            _preWeddingShootCost,
            (v) => setState(() => _preWeddingShootCost = v)),
          buildDropdown("Travel charges",
            ["Included", "Extra", "Depends on Location"],
            _travelCharges, (v) => setState(() => _travelCharges = v)),
          buildYesNo("Accommodation required", _accommodationRequired,
              (v) => setState(() => _accommodationRequired = v)),
          buildDropdown("Camera type",
            ["DSLR", "Mirrorless", "Cinema Camera"],
            _cameraType, (v) => setState(() => _cameraType = v)),
          buildYesNo("Drone available", _droneAvailable,
              (v) => setState(() => _droneAvailable = v)),
          buildDropdown("Lighting setup",
            ["Basic", "Advanced", "Cinematic"],
            _lightingSetup, (v) => setState(() => _lightingSetup = v)),
          buildYesNo("Live streaming setup", _liveStreamingSetup,
              (v) => setState(() => _liveStreamingSetup = v)),
          buildDropdown("Pre-wedding shoot locations supported",
            ["Local", "Outstation", "International"],
            _locationsSupported, (v) => setState(() => _locationsSupported = v)),
          buildYesNo("Concept shoot available", _conceptShootAvailable,
              (v) => setState(() => _conceptShootAvailable = v)),
          buildYesNo("Props provided", _propsProvided,
              (v) => setState(() => _propsProvided = v)),
          buildYesNo("Location scouting support", _locationScoutingSupport,
              (v) => setState(() => _locationScoutingSupport = v)),
          buildYesNo("Booking advance required", _bookingAdvanceRequired,
              (v) => setState(() => _bookingAdvanceRequired = v)),
          buildDropdown("Advance percentage", ["25%", "50%", "75%"],
            _advancePercentage, (v) => setState(() => _advancePercentage = v)),
          buildDropdown("Cancellation policy",
            ["Non Refundable", "Partial Refund", "Flexible"],
            _cancellationPolicy, (v) => setState(() => _cancellationPolicy = v)),
          buildYesNo("Revision allowed", _revisionAllowed,
              (v) => setState(() => _revisionAllowed = v)),
          buildDropdown("Number of revisions", ["1", "2", "Unlimited"],
            _numberOfRevisions, (v) => setState(() => _numberOfRevisions = v)),
          buildMultiSelect(
            "Functions covered",
            ["Haldi", "Mehendi", "Sangeet", "Wedding", "Reception",
             "Engagement", "Cocktail"],
            _functionsCovered,
            (o, c) => setState(
                () => c ? _functionsCovered.add(o) : _functionsCovered.remove(o))),
          buildMultiSelect(
            "Best for",
            ["Couple Shoots", "Big Weddings", "Intimate Weddings",
             "Destination Weddings"],
            _bestFor,
            (o, c) =>
                setState(() => c ? _bestFor.add(o) : _bestFor.remove(o))),
        ],
        dividerLine(),

        // ── Section 10: Portfolio tagging ─────────────────────────────────
        sectionHeader("Section 10 — Image & video intelligence tagging", _s10,
            () => setState(() => _s10 = !_s10)),
        if (_s10) ...[
          const SizedBox(height: 8),
          Text(
            "Upload portfolio in Photos/Videos tabs. Use this block for default tagging metadata.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          buildTextArea("Default tags", _defaultTagsCtrl, maxLines: 2),
          buildTextArea("Notes", _notesCtrl),
        ],
      ],
    );
  }
}
