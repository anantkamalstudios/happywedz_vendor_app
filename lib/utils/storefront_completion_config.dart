class StorefrontSections {
  static const Map<String, int> weights = {
    "basic_info": 10,
    "faq": 10,
    "contact_details": 10,
    "location": 10,
    "photos": 5,
    "videos": 10,
    "facilities_and_features": 10,
    "promotion": 10,
    "policies_and_terms": 10,
    "availability": 10,
    "pricing_and_packages" :5
  };

  static int get total =>
      weights.values.reduce((a, b) => a + b);
}
