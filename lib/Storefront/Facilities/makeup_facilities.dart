import 'package:flutter/material.dart';
import 'facilities_helpers.dart';

class MakeupFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const MakeupFacilities({super.key, required this.attributes});

  @override
  State<MakeupFacilities> createState() => MakeupFacilitiesState();
}

class MakeupFacilitiesState extends State<MakeupFacilities>
    with FacilitiesHelpersMixin<MakeupFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  final        _brandArtistNameCtrl  = TextEditingController();
  String?      _artistType;
  List<String> _servicesOffered      = [];
  List<String> _categoriesCovered    = [];
  final        _yearsExpCtrl         = TextEditingController();
  List<String> _cities               = [];
  String?      _travelAvailability;

  // ── makeup_style_intelligence ─────────────────────────────────────────────
  List<String> _signatureMakeupStyle = [];
  List<String> _expertiseIn          = [];
  List<String> _bestKnownFor         = [];
  List<String> _idealClientType      = [];

  // ── skin_hair_expertise ───────────────────────────────────────────────────
  List<String> _skinTypesHandled     = [];
  List<String> _skinToneExpertise    = [];
  String?      _skinCareConsultation;
  String?      _hairstylingIncluded;
  String?      _hairExtensions;
  String?      _drapingIncluded;
  String?      _lashesLensesIncluded;
  String?      _outfitStylingGuidance;

  // ── products_brands ───────────────────────────────────────────────────────
  String?      _productCategory;
  List<String> _brandsLuxury         = [];
  List<String> _brandsPremium        = [];
  List<String> _brandsBasic          = [];
  List<String> _hygienePractices     = [];

  // ── bridal_package ────────────────────────────────────────────────────────
  List<String> _packageIncludes      = [];
  String?      _numberOfLooks;
  String?      _trialMakeupAvailable;
  String?      _trialCost;
  String?      _touchUpService;

  // ── pricing_structure ─────────────────────────────────────────────────────
  final        _bridalStartingPriceCtrl = TextEditingController();
  String?      _pricingType;
  String?      _groomMakeupCost;
  String?      _familyMakeupCost;
  final        _familyPriceNoteCtrl  = TextEditingController();
  String?      _travelCharges;
  String?      _stayRequired;

  // ── workflow_process ──────────────────────────────────────────────────────
  String?      _advanceRequired;
  String?      _advancePercentage;
  String?      _bookingTimeline;
  String?      _cancellationPolicy;
  String?      _delayHandling;

  // ── event_suitability ─────────────────────────────────────────────────────
  List<String> _functionsCovered     = [];
  List<String> _bestFor              = [];

  // ── portfolio_intelligence ────────────────────────────────────────────────
  final        _taggingGuidanceCtrl  = TextEditingController();
  final        _portfolioNotesCtrl   = TextEditingController();

  // ── ai_faq (Section 10 — saved to API) ───────────────────────────────────
  String?      _faqHdMakeup;
  String?      _faqAirbrushMakeup;
  String?      _faqHairstylingIncluded;
  String?      _faqDrapingIncluded;
  String?      _faqTrialAvailable;
  String?      _faqTrialCost;
  String?      _faqTravelAvailable;
  String?      _faqTouchupIncluded;
  String?      _faqSkinPrepIncluded;
  List<String> _faqBrandsUsed        = [];
  List<String> _faqSuitableSkinTypes = [];
  List<String> _faqSuitableSkinTones = [];
  String?      _faqGroomMakeupOffered;
  String?      _faqAdvanceRequired;
  String?      _faqCancellationPolicy;

  // ── section expansion ─────────────────────────────────────────────────────
  bool _mks1  = true;
  bool _mks2  = false;
  bool _mks3  = false;
  bool _mks4  = false;
  bool _mks5  = false;
  bool _mks6  = false;
  bool _mks7  = false;
  bool _mks8  = false;
  bool _mks9  = false;
  bool _mks10 = false;

  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _brandArtistNameCtrl.dispose();
    _yearsExpCtrl.dispose();
    _bridalStartingPriceCtrl.dispose();
    _familyPriceNoteCtrl.dispose();
    _taggingGuidanceCtrl.dispose();
    _portfolioNotesCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final mam = asMap(attrs['makeup_artist_master']);

    final id = asMap(mam['identity']);
    _brandArtistNameCtrl.text = id['brand_artist_name']?.toString() ?? '';
    _artistType               = id['artist_type'] as String?;
    _servicesOffered          = toList(id['services_offered']);
    _categoriesCovered        = toList(id['categories_covered']);
    _yearsExpCtrl.text        = id['years_of_experience']?.toString() ?? '';
    _cities                   = toList(id['cities']);
    _travelAvailability       = id['travel_availability'] as String?;

    final style = asMap(mam['makeup_style_intelligence']);
    _signatureMakeupStyle = toList(style['signature_makeup_style']);
    _expertiseIn          = toList(style['expertise_in']);
    _bestKnownFor         = toList(style['best_known_for']);
    _idealClientType      = toList(style['ideal_client_type']);

    final skin = asMap(mam['skin_hair_expertise']);
    _skinTypesHandled      = toList(skin['skin_types_handled']);
    _skinToneExpertise     = toList(skin['skin_tone_expertise']);
    _skinCareConsultation  = skin['skin_care_consultation'] as String?;
    _hairstylingIncluded   = skin['hairstyling_included'] as String?;
    _hairExtensions        = skin['hair_extensions'] as String?;
    _drapingIncluded       = skin['draping_included'] as String?;
    _lashesLensesIncluded  = skin['lashes_lenses_included'] as String?;
    _outfitStylingGuidance = skin['outfit_styling_guidance'] as String?;

    final brands = asMap(mam['products_brands']);
    _productCategory   = brands['product_category'] as String?;
    _brandsLuxury      = toList(brands['brands_luxury']);
    _brandsPremium     = toList(brands['brands_premium']);
    _brandsBasic       = toList(brands['brands_basic']);
    _hygienePractices  = toList(brands['hygiene_practices']);

    final pkg = asMap(mam['bridal_package']);
    _packageIncludes     = toList(pkg['package_includes']);
    _numberOfLooks       = pkg['number_of_looks'] as String?;
    _trialMakeupAvailable = pkg['trial_makeup_available'] as String?;
    _trialCost           = pkg['trial_cost'] as String?;
    _touchUpService      = pkg['touch_up_service'] as String?;

    final pricing = asMap(mam['pricing_structure']);
    _bridalStartingPriceCtrl.text = pricing['bridal_makeup_starting_price']?.toString() ?? '';
    _pricingType       = pricing['pricing_type'] as String?;
    _groomMakeupCost   = pricing['groom_makeup_cost'] as String?;
    _familyMakeupCost  = pricing['family_makeup_cost'] as String?;
    _familyPriceNoteCtrl.text = pricing['family_price_note']?.toString() ?? '';
    _travelCharges     = pricing['travel_charges'] as String?;
    _stayRequired      = pricing['stay_required'] as String?;

    final wf = asMap(mam['workflow_process']);
    _advanceRequired    = wf['advance_required'] as String?;
    _advancePercentage  = wf['advance_percentage'] as String?;
    _bookingTimeline    = wf['booking_timeline'] as String?;
    _cancellationPolicy = wf['cancellation_policy'] as String?;
    _delayHandling      = wf['delay_handling'] as String?;

    final ev = asMap(mam['event_suitability']);
    _functionsCovered = toList(ev['functions_covered']);
    _bestFor          = toList(ev['best_for']);

    final port = asMap(mam['portfolio_intelligence']);
    _taggingGuidanceCtrl.text = port['tagging_guidance']?.toString() ?? '';
    _portfolioNotesCtrl.text  = port['notes']?.toString() ?? '';

    final faq = asMap(mam['ai_faq']);
    _faqHdMakeup            = faq['hd_makeup'] as String?;
    _faqAirbrushMakeup      = faq['airbrush_makeup'] as String?;
    _faqHairstylingIncluded = faq['hairstyling_included'] as String?;
    _faqDrapingIncluded     = faq['draping_included'] as String?;
    _faqTrialAvailable      = faq['trial_available'] as String?;
    _faqTrialCost           = faq['trial_cost'] as String?;
    _faqTravelAvailable     = faq['travel_available'] as String?;
    _faqTouchupIncluded     = faq['touchup_included'] as String?;
    _faqSkinPrepIncluded    = faq['skin_prep_included'] as String?;
    _faqBrandsUsed          = toList(faq['brands_used']);
    _faqSuitableSkinTypes   = toList(faq['suitable_skin_types']);
    _faqSuitableSkinTones   = toList(faq['suitable_skin_tones']);
    _faqGroomMakeupOffered  = faq['groom_makeup_offered'] as String?;
    _faqAdvanceRequired     = faq['advance_required'] as String?;
    _faqCancellationPolicy  = faq['cancellation_policy'] as String?;
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "brand_artist_name":   _brandArtistNameCtrl.text,
        "artist_type":         _artistType,
        "services_offered":    _servicesOffered,
        "categories_covered":  _categoriesCovered,
        "years_of_experience": _yearsExpCtrl.text,
        "cities":              _cities,
        "travel_availability": _travelAvailability,
      },
      "makeup_style_intelligence": {
        ...asMap(ex["makeup_style_intelligence"]),
        "signature_makeup_style": _signatureMakeupStyle,
        "expertise_in":           _expertiseIn,
        "best_known_for":         _bestKnownFor,
        "ideal_client_type":      _idealClientType,
      },
      "skin_hair_expertise": {
        ...asMap(ex["skin_hair_expertise"]),
        "skin_types_handled":      _skinTypesHandled,
        "skin_tone_expertise":     _skinToneExpertise,
        "skin_care_consultation":  _skinCareConsultation,
        "hairstyling_included":    _hairstylingIncluded,
        "hair_extensions":         _hairExtensions,
        "draping_included":        _drapingIncluded,
        "lashes_lenses_included":  _lashesLensesIncluded,
        "outfit_styling_guidance": _outfitStylingGuidance,
      },
      "products_brands": {
        ...asMap(ex["products_brands"]),
        "product_category":  _productCategory,
        "brands_luxury":     _brandsLuxury,
        "brands_premium":    _brandsPremium,
        "brands_basic":      _brandsBasic,
        "hygiene_practices": _hygienePractices,
      },
      "bridal_package": {
        ...asMap(ex["bridal_package"]),
        "package_includes":      _packageIncludes,
        "number_of_looks":       _numberOfLooks,
        "trial_makeup_available":_trialMakeupAvailable,
        "trial_cost":            _trialCost,
        "touch_up_service":      _touchUpService,
      },
      "pricing_structure": {
        ...asMap(ex["pricing_structure"]),
        "bridal_makeup_starting_price": _bridalStartingPriceCtrl.text,
        "pricing_type":      _pricingType,
        "groom_makeup_cost": _groomMakeupCost,
        "family_makeup_cost":_familyMakeupCost,
        "family_price_note": _familyPriceNoteCtrl.text,
        "travel_charges":    _travelCharges,
        "stay_required":     _stayRequired,
      },
      "workflow_process": {
        ...asMap(ex["workflow_process"]),
        "advance_required":    _advanceRequired,
        "advance_percentage":  _advancePercentage,
        "booking_timeline":    _bookingTimeline,
        "cancellation_policy": _cancellationPolicy,
        "delay_handling":      _delayHandling,
      },
      "event_suitability": {
        ...asMap(ex["event_suitability"]),
        "functions_covered": _functionsCovered,
        "best_for":          _bestFor,
      },
      "portfolio_intelligence": {
        ...asMap(ex["portfolio_intelligence"]),
        "tagging_guidance": _taggingGuidanceCtrl.text,
        "notes":            _portfolioNotesCtrl.text,
      },
      "ai_faq": {
        ...asMap(ex["ai_faq"]),
        "hd_makeup":            _faqHdMakeup,
        "airbrush_makeup":      _faqAirbrushMakeup,
        "hairstyling_included": _faqHairstylingIncluded,
        "draping_included":     _faqDrapingIncluded,
        "trial_available":      _faqTrialAvailable,
        "trial_cost":           _faqTrialCost,
        "travel_available":     _faqTravelAvailable,
        "touchup_included":     _faqTouchupIncluded,
        "skin_prep_included":   _faqSkinPrepIncluded,
        "brands_used":          _faqBrandsUsed,
        "suitable_skin_types":  _faqSuitableSkinTypes,
        "suitable_skin_tones":  _faqSuitableSkinTones,
        "groom_makeup_offered": _faqGroomMakeupOffered,
        "advance_required":     _faqAdvanceRequired,
        "cancellation_policy":  _faqCancellationPolicy,
      },
    };
  }

  static const List<String> _kCities = [
    "Mumbai", "Delhi", "Bangalore", "Hyderabad", "Chennai", "Kolkata",
    "Pune", "Ahmedabad", "Jaipur", "Surat", "Lucknow", "Nagpur",
    "Nashik", "Indore", "Bhopal", "Chandigarh", "Coimbatore",
    "Visakhapatnam", "Kochi", "Agra", "Varanasi", "Udaipur",
    "Jodhpur", "Amritsar", "Goa", "Dehradun", "Patna",
  ];

  static const List<String> _kBrandsLuxury = [
    "Dior", "Chanel", "Charlotte Tilbury", "Estée Lauder", "NARS",
    "MAC Cosmetics", "Bobbi Brown", "Pat McGrath Labs", "Tom Ford Beauty",
    "Giorgio Armani Beauty", "YSL Beauty", "Fenty Beauty", "Laura Mercier",
    "Clé de Peau Beauté", "Sisley Paris", "Valentino Beauty", "Hourglass",
  ];

  static const List<String> _kBrandsPremium = [
    "Kryolan", "Make Up For Ever", "Smashbox", "Too Faced",
    "Benefit Cosmetics", "Anastasia Beverly Hills", "Huda Beauty",
    "Kiko Milano", "Inglot", "Sephora Collection", "Kay Beauty",
    "Colorbar", "Rare Beauty", "Tarte Cosmetics", "Forever52",
  ];

  static const List<String> _kBrandsBasic = [
    "Maybelline New York", "L'Oréal Paris", "Lakmé", "Nykaa Cosmetics",
    "SUGAR Cosmetics", "Swiss Beauty", "Insight Cosmetics", "Faces Canada",
    "Wet n Wild", "e.l.f. Cosmetics", "Essence", "NYX Professional Makeup",
    "Revlon",
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Bridal Makeup Artist Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured makeup artist attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _mks1,
            () => setState(() => _mks1 = !_mks1)),
        if (_mks1) ...[
          const SizedBox(height: 16),
          buildTextArea("Brand / Artist Name", _brandArtistNameCtrl, maxLines: 1),
          buildDropdown("Artist Type",
            ["Individual Freelancer", "Studio Owner", "Salon Based", "Celebrity Makeup Artist"],
            _artistType, (v) => setState(() => _artistType = v)),
          buildMultiSelect("Services Offered",
            ["Bridal Makeup", "Groom Makeup", "Family / Siders Makeup",
             "Engagement Makeup", "Reception Makeup", "Party Makeup",
             "Hairstyling", "Draping"],
            _servicesOffered,
            (o, c) => setState(() => c ? _servicesOffered.add(o) : _servicesOffered.remove(o))),
          buildMultiSelect("Categories Covered",
            ["Bridal", "Groom", "Bridesmaids", "Family Members"],
            _categoriesCovered,
            (o, c) => setState(() => c ? _categoriesCovered.add(o) : _categoriesCovered.remove(o))),
          buildNumberField("Years of Experience", _yearsExpCtrl),
          buildMultiSelect("Cities Served", _kCities, _cities,
            (o, c) => setState(() => c ? _cities.add(o) : _cities.remove(o))),
          buildDropdown("Travel Availability",
            ["Local Only", "Pan India", "International"],
            _travelAvailability, (v) => setState(() => _travelAvailability = v)),
        ],
        dividerLine(),

        // ── Section 2: Makeup Style Intelligence ──────────────────────────
        sectionHeader("Section 2 — Makeup style intelligence", _mks2,
            () => setState(() => _mks2 = !_mks2)),
        if (_mks2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Signature Makeup Style",
            ["HD Makeup", "Airbrush Makeup", "Natural Makeup", "Glam Makeup",
             "Minimal Makeup", "Matte Finish", "Dewy Finish"],
            _signatureMakeupStyle,
            (o, c) => setState(() => c ? _signatureMakeupStyle.add(o) : _signatureMakeupStyle.remove(o))),
          buildMultiSelect("Expertise In",
            ["Bridal Looks", "Editorial Looks", "Traditional Looks",
             "Contemporary Looks", "Celebrity Style Looks"],
            _expertiseIn,
            (o, c) => setState(() => c ? _expertiseIn.add(o) : _expertiseIn.remove(o))),
          buildMultiSelect("Best Known For",
            ["Natural Skin Finish", "Long-Lasting Makeup", "Glam Transformations",
             "Subtle Bridal Looks", "Bold Makeup Looks"],
            _bestKnownFor,
            (o, c) => setState(() => c ? _bestKnownFor.add(o) : _bestKnownFor.remove(o))),
          buildMultiSelect("Ideal Client Type",
            ["Budget Brides", "Luxury Brides", "Destination Brides",
             "Minimalist Brides", "Glam Brides"],
            _idealClientType,
            (o, c) => setState(() => c ? _idealClientType.add(o) : _idealClientType.remove(o))),
        ],
        dividerLine(),

        // ── Section 3: Skin & Hair Expertise ──────────────────────────────
        sectionHeader("Section 3 — Skin & hair expertise", _mks3,
            () => setState(() => _mks3 = !_mks3)),
        if (_mks3) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Skin Types Handled",
            ["Dry Skin", "Oily Skin", "Combination Skin",
             "Sensitive Skin", "Acne-Prone Skin"],
            _skinTypesHandled,
            (o, c) => setState(() => c ? _skinTypesHandled.add(o) : _skinTypesHandled.remove(o))),
          buildMultiSelect("Skin Tone Expertise",
            ["Fair", "Medium", "Dusky", "Deep"],
            _skinToneExpertise,
            (o, c) => setState(() => c ? _skinToneExpertise.add(o) : _skinToneExpertise.remove(o))),
          buildDropdown("Skin Care Consultation Included",
            ["Yes", "No", "Extra Charges"],
            _skinCareConsultation, (v) => setState(() => _skinCareConsultation = v)),
          buildDropdown("Hairstyling Included",
            ["Yes", "No", "Extra Charges"],
            _hairstylingIncluded, (v) => setState(() => _hairstylingIncluded = v)),
          buildDropdown("Hair Extensions Provided",
            ["Yes", "No", "Extra Charges"],
            _hairExtensions, (v) => setState(() => _hairExtensions = v)),
          buildDropdown("Draping Included",
            ["Yes", "No", "Extra Charges"],
            _drapingIncluded, (v) => setState(() => _drapingIncluded = v)),
          buildDropdown("Lashes & Lenses Included",
            ["Yes", "No", "Extra Charges"],
            _lashesLensesIncluded, (v) => setState(() => _lashesLensesIncluded = v)),
          buildDropdown("Bridal Outfit Styling Guidance",
            ["Yes", "No", "Extra Charges"],
            _outfitStylingGuidance, (v) => setState(() => _outfitStylingGuidance = v)),
        ],
        dividerLine(),

        // ── Section 4: Products & Brands ──────────────────────────────────
        sectionHeader("Section 4 — Products & brands", _mks4,
            () => setState(() => _mks4 = !_mks4)),
        if (_mks4) ...[
          const SizedBox(height: 16),
          buildDropdown("Product Category",
            ["Luxury Brands", "Premium Brands", "Mixed Brands"],
            _productCategory, (v) => setState(() => _productCategory = v)),
          buildMultiSelect("Luxury / High-End Brands", _kBrandsLuxury, _brandsLuxury,
            (o, c) => setState(() => c ? _brandsLuxury.add(o) : _brandsLuxury.remove(o))),
          buildMultiSelect("Premium / Mid-Range Brands", _kBrandsPremium, _brandsPremium,
            (o, c) => setState(() => c ? _brandsPremium.add(o) : _brandsPremium.remove(o))),
          buildMultiSelect("Basic / Economical Brands", _kBrandsBasic, _brandsBasic,
            (o, c) => setState(() => c ? _brandsBasic.add(o) : _brandsBasic.remove(o))),
          buildMultiSelect("Hygiene Practices",
            ["Disposable Applicators", "Brush Sanitization",
             "Fresh Sponges", "Individual Kits"],
            _hygienePractices,
            (o, c) => setState(() => c ? _hygienePractices.add(o) : _hygienePractices.remove(o))),
        ],
        dividerLine(),

        // ── Section 5: Bridal Package Structure ───────────────────────────
        sectionHeader("Section 5 — Bridal package structure", _mks5,
            () => setState(() => _mks5 = !_mks5)),
        if (_mks5) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Bridal Package Includes",
            ["Makeup", "Hairstyling", "Draping", "Nail Prep", "Touch-Up Kit"],
            _packageIncludes,
            (o, c) => setState(() => c ? _packageIncludes.add(o) : _packageIncludes.remove(o))),
          buildDropdown("Number of Looks Included",
            ["1 Look", "2 Looks", "3 Looks", "4+ Looks"],
            _numberOfLooks, (v) => setState(() => _numberOfLooks = v)),
          buildDropdown("Trial Makeup Available",
            ["Yes", "No"],
            _trialMakeupAvailable, (v) => setState(() => _trialMakeupAvailable = v)),
          buildDropdown("Trial Cost",
            ["Free", "Paid", "Adjustable in final booking"],
            _trialCost, (v) => setState(() => _trialCost = v)),
          buildDropdown("Touch-Up Service",
            ["Included", "Extra Cost", "Not Available"],
            _touchUpService, (v) => setState(() => _touchUpService = v)),
        ],
        dividerLine(),

        // ── Section 6: Pricing Structure ──────────────────────────────────
        sectionHeader("Section 6 — Pricing structure", _mks6,
            () => setState(() => _mks6 = !_mks6)),
        if (_mks6) ...[
          const SizedBox(height: 16),
          buildNumberField("Bridal Makeup Starting Price (₹)", _bridalStartingPriceCtrl),
          buildDropdown("Pricing Type",
            ["Per Function", "Package Based"],
            _pricingType, (v) => setState(() => _pricingType = v)),
          buildDropdown("Groom Makeup Cost",
            ["Included", "Extra Charge", "Not Offered"],
            _groomMakeupCost, (v) => setState(() => _groomMakeupCost = v)),
          buildDropdown("Family Makeup Cost",
            ["Per Person", "Package", "Not Offered"],
            _familyMakeupCost, (v) => setState(() => _familyMakeupCost = v)),
          if (_familyMakeupCost != "Not Offered")
            buildNumberField("Family Makeup Price Starting From (₹)", _familyPriceNoteCtrl),
          buildDropdown("Travel Charges",
            ["Included", "Extra", "Depends on Location"],
            _travelCharges, (v) => setState(() => _travelCharges = v)),
          buildDropdown("Stay Required",
            ["Yes", "No", "Depends on Location"],
            _stayRequired, (v) => setState(() => _stayRequired = v)),
        ],
        dividerLine(),

        // ── Section 7: Workflow & Process ─────────────────────────────────
        sectionHeader("Section 7 — Workflow & process", _mks7,
            () => setState(() => _mks7 = !_mks7)),
        if (_mks7) ...[
          const SizedBox(height: 16),
          buildYesNo("Advance Required", _advanceRequired,
              (v) => setState(() => _advanceRequired = v)),
          buildDropdown("Advance Percentage", ["25%", "50%", "75%"],
            _advancePercentage, (v) => setState(() => _advancePercentage = v)),
          buildDropdown("Booking Timeline",
            ["1 Month Before", "3 Months Before", "6 Months Before"],
            _bookingTimeline, (v) => setState(() => _bookingTimeline = v)),
          buildDropdown("Cancellation Policy",
            ["Non Refundable", "Partial Refund", "Flexible"],
            _cancellationPolicy, (v) => setState(() => _cancellationPolicy = v)),
          buildDropdown("Delay Handling",
            ["Flexible", "Extra Charges Apply"],
            _delayHandling, (v) => setState(() => _delayHandling = v)),
        ],
        dividerLine(),

        // ── Section 8: Event Suitability ──────────────────────────────────
        sectionHeader("Section 8 — Event suitability", _mks8,
            () => setState(() => _mks8 = !_mks8)),
        if (_mks8) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Functions Covered",
            ["Engagement", "Mehendi", "Haldi", "Sangeet", "Wedding", "Reception"],
            _functionsCovered,
            (o, c) => setState(() => c ? _functionsCovered.add(o) : _functionsCovered.remove(o))),
          buildMultiSelect("Best For",
            ["Day Weddings", "Night Weddings", "Destination Weddings",
             "Indoor Events", "Outdoor Events"],
            _bestFor,
            (o, c) => setState(() => c ? _bestFor.add(o) : _bestFor.remove(o))),
        ],
        dividerLine(),

        // ── Section 9: Portfolio Intelligence ─────────────────────────────
        sectionHeader("Section 9 — Portfolio intelligence", _mks9,
            () => setState(() => _mks9 = !_mks9)),
        if (_mks9) ...[
          const SizedBox(height: 8),
          Text(
            "Upload portfolio in the Photos tab. Each image should be tagged by Skin Tone, Makeup Style, Function Type, Lighting Condition, Outfit Color.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          buildTextArea("Default Tagging Guidance", _taggingGuidanceCtrl, maxLines: 2),
          buildTextArea("Portfolio Notes", _portfolioNotesCtrl),
        ],
        dividerLine(),

        // ── Section 10: AI FAQ ────────────────────────────────────────────
        sectionHeader("Section 10 — AI FAQ", _mks10,
            () => setState(() => _mks10 = !_mks10)),
        if (_mks10) ...[
          const SizedBox(height: 16),
          buildYesNo("Do you offer HD makeup?", _faqHdMakeup,
              (v) => setState(() => _faqHdMakeup = v)),
          buildYesNo("Do you offer airbrush makeup?", _faqAirbrushMakeup,
              (v) => setState(() => _faqAirbrushMakeup = v)),
          buildYesNo("Is hairstyling included?", _faqHairstylingIncluded,
              (v) => setState(() => _faqHairstylingIncluded = v)),
          buildYesNo("Is draping included?", _faqDrapingIncluded,
              (v) => setState(() => _faqDrapingIncluded = v)),
          buildYesNo("Trial available?", _faqTrialAvailable,
              (v) => setState(() => _faqTrialAvailable = v)),
          buildDropdown("Trial cost?",
            ["Free", "Paid", "Adjustable in final booking"],
            _faqTrialCost, (v) => setState(() => _faqTrialCost = v)),
          buildYesNo("Travel available?", _faqTravelAvailable,
              (v) => setState(() => _faqTravelAvailable = v)),
          buildYesNo("Touch-up included?", _faqTouchupIncluded,
              (v) => setState(() => _faqTouchupIncluded = v)),
          buildYesNo("Skin prep included?", _faqSkinPrepIncluded,
              (v) => setState(() => _faqSkinPrepIncluded = v)),
          buildMultiSelect("Brands used? (multi)",
            [..._kBrandsLuxury, ..._kBrandsPremium, ..._kBrandsBasic],
            _faqBrandsUsed,
            (o, c) => setState(() => c ? _faqBrandsUsed.add(o) : _faqBrandsUsed.remove(o))),
          buildMultiSelect("Suitable for skin type? (multi)",
            ["Dry Skin", "Oily Skin", "Combination Skin",
             "Sensitive Skin", "Acne-Prone Skin"],
            _faqSuitableSkinTypes,
            (o, c) => setState(() => c ? _faqSuitableSkinTypes.add(o) : _faqSuitableSkinTypes.remove(o))),
          buildMultiSelect("Suitable for skin tone? (multi)",
            ["Fair", "Medium", "Dusky", "Deep"],
            _faqSuitableSkinTones,
            (o, c) => setState(() => c ? _faqSuitableSkinTones.add(o) : _faqSuitableSkinTones.remove(o))),
          buildYesNo("Groom makeup offered?", _faqGroomMakeupOffered,
              (v) => setState(() => _faqGroomMakeupOffered = v)),
          buildYesNo("Advance required?", _faqAdvanceRequired,
              (v) => setState(() => _faqAdvanceRequired = v)),
          buildDropdown("Cancellation policy?",
            ["Cancellable", "Non-Cancellable"],
            _faqCancellationPolicy,
            (v) => setState(() => _faqCancellationPolicy = v)),
        ],
      ],
    );
  }
}
