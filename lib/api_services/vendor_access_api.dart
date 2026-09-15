import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:happy_weds_vendors/utils/api_config.dart';

class VendorAccess {
  final String? stage;
  final String? verificationStatus;
  final bool canEditBusinessDetails;
  final bool canSubmitVerification;
  final bool canPurchase;
  final List<String> editableTabs;
  final List<String> lockedTabs;
  final Map<String, String> tabLabels;
  final Map<String, dynamic>? subscription;
  final String? headline;
  final String? message;
  final Map<String, dynamic>? nextAction;
  final String? reviewedAt;
  final String? submittedAt;

  const VendorAccess({
    this.stage,
    this.verificationStatus,
    this.canEditBusinessDetails = true,
    this.canSubmitVerification = false,
    this.canPurchase = false,
    this.editableTabs = const [],
    this.lockedTabs = const [],
    this.tabLabels = const {},
    this.subscription,
    this.headline,
    this.message,
    this.nextAction,
    this.reviewedAt,
    this.submittedAt,
  });

  factory VendorAccess.fromJson(Map<String, dynamic> json) {
    return VendorAccess(
      stage: json['stage'] as String?,
      verificationStatus: json['verificationStatus'] as String?,
      canEditBusinessDetails: json['canEditBusinessDetails'] ?? true,
      canSubmitVerification: json['canSubmitVerification'] ?? false,
      canPurchase: json['canPurchase'] ?? false,
      editableTabs: List<String>.from(json['editableTabs'] ?? const []),
      lockedTabs: List<String>.from(json['lockedTabs'] ?? const []),
      tabLabels: Map<String, String>.from(json['tabLabels'] ?? const {}),
      subscription: json['subscription'] as Map<String, dynamic>?,
      headline: json['headline'] as String?,
      message: json['message'] as String?,
      nextAction: json['nextAction'] as Map<String, dynamic>?,
      reviewedAt: json['reviewedAt'] as String?,
      submittedAt: json['submittedAt'] as String?,
    );
  }

  /// True while the plan is live but simply does not include [tabId] —
  /// distinct from onboarding being incomplete, because the fix is different.
  bool tabNotInPlan(String tabId) =>
      (stage == 'active' || stage == 'legacy_grace') &&
      !editableTabs.contains(tabId);

  bool canEditTab(String tabId) {
    if (tabId == 'business') return canEditBusinessDetails;
    return editableTabs.contains(tabId);
  }
}

class VendorAccessApi {
  final String baseUrl = ApiConfig.baseUrl;

  Future<VendorAccess> getAccess(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/vendor/me/access'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final access = data['access'] as Map<String, dynamic>?;
      if (access != null) return VendorAccess.fromJson(access);
    }
    return const VendorAccess();
  }
}
