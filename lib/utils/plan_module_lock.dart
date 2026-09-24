import 'dart:convert';
import 'package:http/http.dart' as http;

/// Server answer when the vendor's plan does not include a gated feature:
/// HTTP 403 `{success:false, code:"PLAN_MODULE_LOCKED", module, message}`.
///
/// This is an answer, not a failure — callers must not sign the vendor out
/// or show a generic error. Show [PlanFeatureNotice] instead.
class PlanModuleLockedException implements Exception {
  final String module;
  final String? message;

  const PlanModuleLockedException(this.module, [this.message]);

  @override
  String toString() => 'PlanModuleLockedException($module): $message';
}

/// The one place gated responses are recognised. Call it on every response
/// from a plan-gated endpoint (`/vendor/crm/*`, `/instagram/*`); it throws
/// [PlanModuleLockedException] when the server says the feature is locked.
/// Matches on `code`, never on the message text.
void throwIfPlanModuleLocked(http.Response res) {
  if (res.statusCode != 403) return;
  try {
    final data = jsonDecode(res.body);
    if (data is Map && data['code'] == 'PLAN_MODULE_LOCKED') {
      throw PlanModuleLockedException(
        '${data['module'] ?? ''}',
        data['message']?.toString(),
      );
    }
  } on FormatException {
    // Not JSON — an ordinary 403, left to the caller.
  }
}
