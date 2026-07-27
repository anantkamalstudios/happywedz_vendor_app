import 'package:flutter/material.dart';
import 'facilities_helpers.dart';

class PanditFacilities extends StatefulWidget {
  final Map<String, dynamic> attributes;
  const PanditFacilities({super.key, required this.attributes});

  @override
  State<PanditFacilities> createState() => PanditFacilitiesState();
}

class PanditFacilitiesState extends State<PanditFacilities>
    with FacilitiesHelpersMixin<PanditFacilities> {

  // ── identity ──────────────────────────────────────────────────────────────
  final        _brandNameCtrl      = TextEditingController();
  String?      _vendorType;
  final        _cityBaseCtrl       = TextEditingController();
  List<String> _languagesSpoken    = [];
  String?      _yearsOfExperience;
  List<String> _servicePresence    = [];
  List<String> _religiousTradition = [];

  // ── services_offered ──────────────────────────────────────────────────────
  List<String> _ceremonyTypes              = [];
  String?      _destinationWeddingServices;
  String?      _virtualCeremonySupport;
  String?      _ritualExplanationProvided;
  String?      _customizedRituals;
  String?      _samagriProvided;
  String?      _assistantPanditsIncluded;

  // ── core_intelligence ─────────────────────────────────────────────────────
  String?      _ritualDurationOptions;
  String?      _ritualComplexityLevel;
  String?      _muhuratGuidanceProvided;
  String?      _horoscopeMatching;
  List<String> _ritualLanguagePreference   = [];
  String?      _fireRitualHavanIncluded;
  String?      _interfaithCustomCeremonies;

  // ── technical ─────────────────────────────────────────────────────────────
  String?      _audioSetupRequirement;
  String?      _microphoneUsage;
  String?      _samagriListProvidedInAdvance;
  String?      _setupTimeRequired;
  String?      _dressCodeProvided;
  String?      _documentationRitualBooklet;

  // ── pricing ───────────────────────────────────────────────────────────────
  String?      _priceRange;
  String?      _pricingModel;
  String?      _travelCharges;
  String?      _samagriCharges;
  String?      _dakshinaFlexibility;

  // ── scale_capacity ────────────────────────────────────────────────────────
  String?      _eventsPerDay;
  String?      _teamSize;
  String?      _multiLocationHandling;

  // ── workflow ──────────────────────────────────────────────────────────────
  String?      _advanceBookingRequired;
  String?      _bookingWindow;
  String?      _preCeremonyConsultation;
  String?      _ritualCustomizationDiscussion;
  String?      _arrivalTiming;
  List<String> _paymentModes                = [];
  String?      _advancePaymentPercentage;

  // ── portfolio_tagging ─────────────────────────────────────────────────────
  List<String> _styleTags       = [];
  List<String> _audienceTags    = [];
  List<String> _usageTags       = [];
  String?      _priceSegmentTags;

  // ── ai_faq (Section 9 — saved to API) ────────────────────────────────────
  String?      _faqPerformsFullWeddingRituals;
  String?      _faqProvidesPoojaSamagri;
  String?      _faqConductsDestinationWeddings;
  String?      _faqExplainsRitualsDuringCeremony;
  String?      _faqKundliMatchingAvailable;
  String?      _faqRitualsCustomizedByFamilyTradition;
  String?      _faqPerformsInterfaithWeddings;
  String?      _faqHavanIncluded;
  String?      _faqProvidesAssistantPandits;
  String?      _faqAdvanceBookingRequired;
  String?      _faqCeremonyInRegionalLanguage;
  String?      _faqTravelsOutstation;
  String?      _faqSameDayBookingPossible;
  String?      _faqProvidesMuhuratGuidance;
  String?      _faqMicrophoneAudioSetupRequired;

  // ── section expansion ─────────────────────────────────────────────────────
  bool _ps1 = true;
  bool _ps2 = false;
  bool _ps3 = false;
  bool _ps4 = false;
  bool _ps5 = false;
  bool _ps6 = false;
  bool _ps7 = false;
  bool _ps8 = false;


  @override
  void initState() {
    super.initState();
    _setFields(widget.attributes);
  }

  @override
  void dispose() {
    _brandNameCtrl.dispose();

    _cityBaseCtrl.dispose();
    super.dispose();
  }

  void _setFields(Map<String, dynamic> attrs) {
    final pm = asMap(attrs['pandit_master']);

    final id = asMap(pm['identity']);
    _brandNameCtrl.text    = id['brand_name']?.toString() ?? '';

    _vendorType            = id['vendor_type'] as String?;
    _cityBaseCtrl.text     = id['city_base']?.toString() ?? '';
    _languagesSpoken       = toList(id['languages_spoken']);
    _yearsOfExperience     = id['years_of_experience'] as String?;
    _servicePresence       = toList(id['service_presence']);
    _religiousTradition    = toList(id['religious_tradition']);

    final so = asMap(pm['services_offered']);
    _ceremonyTypes               = toList(so['ceremony_types']);
    _destinationWeddingServices  = so['destination_wedding_services'] as String?;
    _virtualCeremonySupport      = so['virtual_ceremony_support'] as String?;
    _ritualExplanationProvided   = so['ritual_explanation_provided'] as String?;
    _customizedRituals           = so['customized_rituals'] as String?;
    _samagriProvided             = so['samagri_provided'] as String?;
    _assistantPanditsIncluded    = so['assistant_pandits_included'] as String?;

    final ci = asMap(pm['core_intelligence']);
    _ritualDurationOptions    = ci['ritual_duration_options'] as String?;
    _ritualComplexityLevel    = ci['ritual_complexity_level'] as String?;
    _muhuratGuidanceProvided  = ci['muhurat_guidance_provided'] as String?;
    _horoscopeMatching        = ci['horoscope_matching'] as String?;
    _ritualLanguagePreference = toList(ci['ritual_language_preference']);
    _fireRitualHavanIncluded  = ci['fire_ritual_havan_included'] as String?;
    _interfaithCustomCeremonies = ci['interfaith_custom_ceremonies'] as String?;

    final te = asMap(pm['technical']);
    _audioSetupRequirement        = te['audio_setup_requirement'] as String?;
    _microphoneUsage              = te['microphone_usage'] as String?;
    _samagriListProvidedInAdvance = te['samagri_list_provided_in_advance'] as String?;
    _setupTimeRequired            = te['setup_time_required'] as String?;
    _dressCodeProvided            = te['dress_code_provided'] as String?;
    _documentationRitualBooklet   = te['documentation_ritual_booklet'] as String?;

    final pr = asMap(pm['pricing']);
    _priceRange          = pr['price_range'] as String?;
    _pricingModel        = pr['pricing_model'] as String?;
    _travelCharges       = pr['travel_charges'] as String?;
    _samagriCharges      = pr['samagri_charges'] as String?;
    _dakshinaFlexibility = pr['dakshina_flexibility'] as String?;

    final sc = asMap(pm['scale_capacity']);
    _eventsPerDay          = sc['events_per_day'] as String?;
    _teamSize              = sc['team_size'] as String?;
    _multiLocationHandling = sc['multi_location_handling'] as String?;

    final wf = asMap(pm['workflow']);
    _advanceBookingRequired        = wf['advance_booking_required'] as String?;
    _bookingWindow                 = wf['booking_window'] as String?;
    _preCeremonyConsultation       = wf['pre_ceremony_consultation'] as String?;
    _ritualCustomizationDiscussion = wf['ritual_customization_discussion'] as String?;
    _arrivalTiming                 = wf['arrival_timing'] as String?;
    _paymentModes                  = toList(wf['payment_modes']);
    _advancePaymentPercentage      = wf['advance_payment_percentage'] as String?;

    final pt = asMap(pm['portfolio_tagging']);
    _styleTags        = toList(pt['style_tags']);
    _audienceTags     = toList(pt['audience_tags']);
    _usageTags        = toList(pt['usage_tags']);
    _priceSegmentTags = pt['price_segment_tags'] as String?;

    final faq = asMap(pm['ai_faq']);
    _faqPerformsFullWeddingRituals          = faq['performs_full_wedding_rituals'] as String?;
    _faqProvidesPoojaSamagri                = faq['provides_pooja_samagri'] as String?;
    _faqConductsDestinationWeddings         = faq['conducts_destination_weddings'] as String?;
    _faqExplainsRitualsDuringCeremony       = faq['explains_rituals_during_ceremony'] as String?;
    _faqKundliMatchingAvailable             = faq['kundli_matching_available'] as String?;
    _faqRitualsCustomizedByFamilyTradition  = faq['rituals_customized_by_family_tradition'] as String?;
    _faqPerformsInterfaithWeddings          = faq['performs_interfaith_weddings'] as String?;
    _faqHavanIncluded                       = faq['havan_included'] as String?;
    _faqProvidesAssistantPandits            = faq['provides_assistant_pandits'] as String?;
    _faqAdvanceBookingRequired              = faq['advance_booking_required'] as String?;
    _faqCeremonyInRegionalLanguage          = faq['ceremony_in_regional_language'] as String?;
    _faqTravelsOutstation                   = faq['travels_outstation'] as String?;
    _faqSameDayBookingPossible              = faq['same_day_booking_possible'] as String?;
    _faqProvidesMuhuratGuidance             = faq['provides_muhurat_guidance'] as String?;
    _faqMicrophoneAudioSetupRequired        = faq['microphone_audio_setup_required'] as String?;
  }

  Map<String, dynamic> buildMaster(Map<String, dynamic> ex) {
    return {
      ...ex,
      "identity": {
        ...asMap(ex["identity"]),
        "brand_name":          _brandNameCtrl.text,

        "vendor_type":         _vendorType,
        "city_base":           _cityBaseCtrl.text,
        "languages_spoken":    _languagesSpoken,
        "years_of_experience": _yearsOfExperience,
        "service_presence":    _servicePresence,
        "religious_tradition": _religiousTradition,
      },
      "services_offered": {
        ...asMap(ex["services_offered"]),
        "ceremony_types":               _ceremonyTypes,
        "destination_wedding_services": _destinationWeddingServices,
        "virtual_ceremony_support":     _virtualCeremonySupport,
        "ritual_explanation_provided":  _ritualExplanationProvided,
        "customized_rituals":           _customizedRituals,
        "samagri_provided":             _samagriProvided,
        "assistant_pandits_included":   _assistantPanditsIncluded,
      },
      "core_intelligence": {
        ...asMap(ex["core_intelligence"]),
        "ritual_duration_options":     _ritualDurationOptions,
        "ritual_complexity_level":     _ritualComplexityLevel,
        "muhurat_guidance_provided":   _muhuratGuidanceProvided,
        "horoscope_matching":          _horoscopeMatching,
        "ritual_language_preference":  _ritualLanguagePreference,
        "fire_ritual_havan_included":  _fireRitualHavanIncluded,
        "interfaith_custom_ceremonies":_interfaithCustomCeremonies,
      },
      "technical": {
        ...asMap(ex["technical"]),
        "audio_setup_requirement":          _audioSetupRequirement,
        "microphone_usage":                 _microphoneUsage,
        "samagri_list_provided_in_advance": _samagriListProvidedInAdvance,
        "setup_time_required":              _setupTimeRequired,
        "dress_code_provided":              _dressCodeProvided,
        "documentation_ritual_booklet":     _documentationRitualBooklet,
      },
      "pricing": {
        ...asMap(ex["pricing"]),
        "price_range":          _priceRange,
        "pricing_model":        _pricingModel,
        "travel_charges":       _travelCharges,
        "samagri_charges":      _samagriCharges,
        "dakshina_flexibility": _dakshinaFlexibility,
      },
      "scale_capacity": {
        ...asMap(ex["scale_capacity"]),
        "events_per_day":          _eventsPerDay,
        "team_size":               _teamSize,
        "multi_location_handling": _multiLocationHandling,
      },
      "workflow": {
        ...asMap(ex["workflow"]),
        "advance_booking_required":        _advanceBookingRequired,
        "booking_window":                  _bookingWindow,
        "pre_ceremony_consultation":       _preCeremonyConsultation,
        "ritual_customization_discussion": _ritualCustomizationDiscussion,
        "arrival_timing":                  _arrivalTiming,
        "payment_modes":                   _paymentModes,
        "advance_payment_percentage":      _advancePaymentPercentage,
      },
      "portfolio_tagging": {
        ...asMap(ex["portfolio_tagging"]),
        "style_tags":         _styleTags,
        "audience_tags":      _audienceTags,
        "usage_tags":         _usageTags,
        "price_segment_tags": _priceSegmentTags,
      },
      "ai_faq": {
        ...asMap(ex["ai_faq"]),
        "performs_full_wedding_rituals":          _faqPerformsFullWeddingRituals,
        "provides_pooja_samagri":                 _faqProvidesPoojaSamagri,
        "conducts_destination_weddings":          _faqConductsDestinationWeddings,
        "explains_rituals_during_ceremony":       _faqExplainsRitualsDuringCeremony,
        "kundli_matching_available":              _faqKundliMatchingAvailable,
        "rituals_customized_by_family_tradition": _faqRitualsCustomizedByFamilyTradition,
        "performs_interfaith_weddings":           _faqPerformsInterfaithWeddings,
        "havan_included":                         _faqHavanIncluded,
        "provides_assistant_pandits":             _faqProvidesAssistantPandits,
        "advance_booking_required":               _faqAdvanceBookingRequired,
        "ceremony_in_regional_language":          _faqCeremonyInRegionalLanguage,
        "travels_outstation":                     _faqTravelsOutstation,
        "same_day_booking_possible":              _faqSameDayBookingPossible,
        "provides_muhurat_guidance":              _faqProvidesMuhuratGuidance,
        "microphone_audio_setup_required":        _faqMicrophoneAudioSetupRequired,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Wedding Pandit Master Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Structured pandit attributes for storefront and AI FAQ matching.",
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
        const SizedBox(height: 20),

        // ── Section 1: Basic Identity ──────────────────────────────────────
        sectionHeader("Section 1 — Basic identity", _ps1,
            () => setState(() => _ps1 = !_ps1)),
        if (_ps1) ...[
          const SizedBox(height: 16),
          buildDropdown("Vendor Type",
            ["Independent Pandit", "Pandit Agency / Group",
             "Temple-Associated Pandit", "Online Ritual Service Provider"],
            _vendorType, (v) => setState(() => _vendorType = v)),

          buildTextArea("Brand / Organization Name", _brandNameCtrl, maxLines: 1),
          buildMultiSelect("Service Presence",
            ["Local", "Outstation", "Pan-India", "International"],
            _servicePresence,
            (o, c) => setState(() => c ? _servicePresence.add(o) : _servicePresence.remove(o))),
          buildTextArea("City Base", _cityBaseCtrl, maxLines: 1),
          buildMultiSelect("Languages Spoken",
            ["Sanskrit", "Hindi", "Marathi", "Gujarati",
             "Tamil", "Telugu", "Kannada", "English"],
            _languagesSpoken,
            (o, c) => setState(() => c ? _languagesSpoken.add(o) : _languagesSpoken.remove(o))),
          buildDropdown("Years of Experience",
            ["0–2", "3–5", "6–10", "10+"],
            _yearsOfExperience, (v) => setState(() => _yearsOfExperience = v)),
          buildMultiSelect("Religious Tradition",
            ["North Indian (Hindi Rituals)", "South Indian (Tamil/Telugu/Kannada)",
             "Maharashtrian", "Gujarati", "Bengali", "Jain Rituals"],
            _religiousTradition,
            (o, c) => setState(() => c ? _religiousTradition.add(o) : _religiousTradition.remove(o))),
        ],
        dividerLine(),

        // ── Section 2: Services Offered ────────────────────────────────────
        sectionHeader("Section 2 — Services offered", _ps2,
            () => setState(() => _ps2 = !_ps2)),
        if (_ps2) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Ceremony Types",
            ["Wedding Ceremony (Vivah)", "Engagement (Sakharpuda / Ring Ceremony)",
             "Haldi", "Mehendi Rituals", "Griha Pravesh", "Satyanarayan Pooja"],
            _ceremonyTypes,
            (o, c) => setState(() => c ? _ceremonyTypes.add(o) : _ceremonyTypes.remove(o))),
          buildYesNo("Destination Wedding Services", _destinationWeddingServices,
              (v) => setState(() => _destinationWeddingServices = v)),
          buildYesNo("Virtual Ceremony Support", _virtualCeremonySupport,
              (v) => setState(() => _virtualCeremonySupport = v)),
          buildYesNo("Ritual Explanation Provided", _ritualExplanationProvided,
              (v) => setState(() => _ritualExplanationProvided = v)),
          buildYesNo("Customized Rituals Based on Culture", _customizedRituals,
              (v) => setState(() => _customizedRituals = v)),
          buildDropdown("Samagri (Pooja Items) Provided",
            ["Full Kit", "Partial", "Not Provided"],
            _samagriProvided, (v) => setState(() => _samagriProvided = v)),
          buildYesNo("Assistant Pandits Included", _assistantPanditsIncluded,
              (v) => setState(() => _assistantPanditsIncluded = v)),
        ],
        dividerLine(),

        // ── Section 3: Core Intelligence ───────────────────────────────────
        sectionHeader("Section 3 — Core intelligence", _ps3,
            () => setState(() => _ps3 = !_ps3)),
        if (_ps3) ...[
          const SizedBox(height: 16),
          buildDropdown("Ritual Duration Options",
            ["30–60 mins", "1–2 hours", "2–4 hours", "4+ hours"],
            _ritualDurationOptions, (v) => setState(() => _ritualDurationOptions = v)),
          buildDropdown("Ritual Complexity Level",
            ["Basic", "Standard", "Detailed Traditional"],
            _ritualComplexityLevel, (v) => setState(() => _ritualComplexityLevel = v)),
          buildYesNo("Muhurat Guidance Provided", _muhuratGuidanceProvided,
              (v) => setState(() => _muhuratGuidanceProvided = v)),
          buildYesNo("Horoscope Matching (Kundli Milan)", _horoscopeMatching,
              (v) => setState(() => _horoscopeMatching = v)),
          buildMultiSelect("Ritual Language Preference",
            ["Sanskrit Only", "Sanskrit + Regional Language",
             "Fully Explained in Local Language"],
            _ritualLanguagePreference,
            (o, c) => setState(() => c ? _ritualLanguagePreference.add(o) : _ritualLanguagePreference.remove(o))),
          buildYesNo("Fire Ritual (Havan) Included", _fireRitualHavanIncluded,
              (v) => setState(() => _fireRitualHavanIncluded = v)),
          buildYesNo("Interfaith / Custom Ceremonies", _interfaithCustomCeremonies,
              (v) => setState(() => _interfaithCustomCeremonies = v)),
        ],
        dividerLine(),

        // ── Section 4: Technical / Skill Layer ─────────────────────────────
        sectionHeader("Section 4 — Technical & skill", _ps4,
            () => setState(() => _ps4 = !_ps4)),
        if (_ps4) ...[
          const SizedBox(height: 16),
          buildYesNo("Audio Setup Requirement", _audioSetupRequirement,
              (v) => setState(() => _audioSetupRequirement = v)),
          buildYesNo("Microphone Usage", _microphoneUsage,
              (v) => setState(() => _microphoneUsage = v)),
          buildYesNo("Samagri List Provided in Advance", _samagriListProvidedInAdvance,
              (v) => setState(() => _samagriListProvidedInAdvance = v)),
          buildDropdown("Setup Time Required Before Ceremony",
            ["<30 mins", "30–60 mins", "60+ mins"],
            _setupTimeRequired, (v) => setState(() => _setupTimeRequired = v)),
          buildYesNo("Dress Code Provided", _dressCodeProvided,
              (v) => setState(() => _dressCodeProvided = v)),
          buildYesNo("Documentation / Ritual Booklet Provided",
            _documentationRitualBooklet,
              (v) => setState(() => _documentationRitualBooklet = v)),
        ],
        dividerLine(),

        // ── Section 5: Pricing Logic ────────────────────────────────────────
        sectionHeader("Section 5 — Pricing logic", _ps5,
            () => setState(() => _ps5 = !_ps5)),
        if (_ps5) ...[
          const SizedBox(height: 16),
          buildDropdown("Price Range (INR)",
            ["2K–5K", "5K–10K", "10K–25K", "25K–50K", "50K+"],
            _priceRange, (v) => setState(() => _priceRange = v)),
          buildDropdown("Pricing Model",
            ["Per Ceremony", "Per Day", "Package Based"],
            _pricingModel, (v) => setState(() => _pricingModel = v)),
          buildDropdown("Travel Charges",
            ["Included", "Extra"],
            _travelCharges, (v) => setState(() => _travelCharges = v)),
          buildDropdown("Samagri Charges",
            ["Included", "Extra", "Not Applicable"],
            _samagriCharges, (v) => setState(() => _samagriCharges = v)),
          buildDropdown("Dakshina Flexibility",
            ["Fixed", "Flexible"],
            _dakshinaFlexibility, (v) => setState(() => _dakshinaFlexibility = v)),
        ],
        dividerLine(),

        // ── Section 6: Scale & Capacity ────────────────────────────────────
        sectionHeader("Section 6 — Scale & capacity", _ps6,
            () => setState(() => _ps6 = !_ps6)),
        if (_ps6) ...[
          const SizedBox(height: 16),
          buildDropdown("Events Per Day Capacity",
            ["1", "2–3", "3–5", "5+"],
            _eventsPerDay, (v) => setState(() => _eventsPerDay = v)),
          buildDropdown("Team Size (Assistants)",
            ["Solo", "1–2", "3–5", "5+"],
            _teamSize, (v) => setState(() => _teamSize = v)),
          buildYesNo("Multi-Location Handling", _multiLocationHandling,
              (v) => setState(() => _multiLocationHandling = v)),
        ],
        dividerLine(),

        // ── Section 7: Workflow & Booking ──────────────────────────────────
        sectionHeader("Section 7 — Workflow & booking", _ps7,
            () => setState(() => _ps7 = !_ps7)),
        if (_ps7) ...[
          const SizedBox(height: 16),
          buildYesNo("Advance Booking Required", _advanceBookingRequired,
              (v) => setState(() => _advanceBookingRequired = v)),
          buildDropdown("Booking Window",
            ["Same Day", "1–7 days", "7–30 days", "1+ month"],
            _bookingWindow, (v) => setState(() => _bookingWindow = v)),
          buildYesNo("Pre-Ceremony Consultation", _preCeremonyConsultation,
              (v) => setState(() => _preCeremonyConsultation = v)),
          buildYesNo("Ritual Customization Discussion", _ritualCustomizationDiscussion,
              (v) => setState(() => _ritualCustomizationDiscussion = v)),
          buildDropdown("Arrival Timing Before Ceremony",
            ["On Time", "30 mins Early", "1 hour Early"],
            _arrivalTiming, (v) => setState(() => _arrivalTiming = v)),
          buildMultiSelect("Payment Modes",
            ["UPI", "Cash", "Bank Transfer"],
            _paymentModes,
            (o, c) => setState(() => c ? _paymentModes.add(o) : _paymentModes.remove(o))),
          buildDropdown("Advance Payment Percentage",
            ["0%", "25%", "50%", "100%"],
            _advancePaymentPercentage,
            (v) => setState(() => _advancePaymentPercentage = v)),
        ],
        dividerLine(),

        // ── Section 8: Portfolio Tagging ────────────────────────────────────
        sectionHeader("Section 8 — Portfolio tagging (AI layer)", _ps8,
            () => setState(() => _ps8 = !_ps8)),
        if (_ps8) ...[
          const SizedBox(height: 16),
          buildMultiSelect("Style Tags",
            ["Traditional", "Modern Simplified", "Ritual Explainer", "Premium Ceremony"],
            _styleTags,
            (o, c) => setState(() => c ? _styleTags.add(o) : _styleTags.remove(o))),
          buildMultiSelect("Audience Tags",
            ["Bride & Groom", "Family", "Destination Weddings"],
            _audienceTags,
            (o, c) => setState(() => c ? _audienceTags.add(o) : _audienceTags.remove(o))),
          buildMultiSelect("Usage Tags",
            ["Wedding Ceremony", "Engagement", "House Rituals"],
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
