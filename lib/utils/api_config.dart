class ApiConfig {
  ApiConfig._();

  static const String baseUrl = "https://api.happywedz.com";
  static const String websiteUrl = "https://happywedz.com";//sharing and redirecting the url to the website

  /// The HappyWedz Store subdomain. The website's header links "Shop" straight
  /// here with target="_blank", so the app opens it in the browser too — there
  /// is no in-app store to route to.
  static const String storeUrl = "https://store.happywedz.com";
}
