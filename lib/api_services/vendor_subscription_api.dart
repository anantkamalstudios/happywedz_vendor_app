import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:happy_weds_vendors/utils/api_config.dart';

class VendorInvoice {
  final Uint8List bytes;
  final String fileName;
  const VendorInvoice({required this.bytes, required this.fileName});
}

/// Mirrors `backen/src/services/api/vendorSubscriptionApi.js` — same backend,
/// same endpoints, same request/response shapes as the website.
class VendorSubscriptionApi {
  final String baseUrl = ApiConfig.baseUrl;
  static const String _base = '/vendor/subscription';

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>> getPlans(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl$_base/plans'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Could not load plans. Please try again.');
  }

  Future<Map<String, dynamic>> createOrder(String token, int planId) async {
    final res = await http.post(
      Uri.parse('$baseUrl$_base/order'),
      headers: _headers(token),
      body: jsonEncode({'planId': planId}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_errorMessage(res, 'Could not start the payment.'));
  }

  Future<Map<String, dynamic>> verify(
    String token, {
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl$_base/verify'),
      headers: _headers(token),
      body: jsonEncode({
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_errorMessage(
      res,
      'Your payment went through but we could not confirm it here. '
      'It will be activated automatically — please refresh in a minute.',
    ));
  }

  Future<Map<String, dynamic>> startTrial(String token, int planId) async {
    final res = await http.post(
      Uri.parse('$baseUrl$_base/trial'),
      headers: _headers(token),
      body: jsonEncode({'planId': planId}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_errorMessage(res, 'Could not start your free trial.'));
  }

  Future<Map<String, dynamic>> confirmTrial(
    String token,
    String razorpaySubscriptionId,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl$_base/trial/confirm'),
      headers: _headers(token),
      body: jsonEncode({'razorpaySubscriptionId': razorpaySubscriptionId}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_errorMessage(
      res,
      'Your trial was authorised but we could not confirm it here. '
      'It will start automatically — please refresh in a minute.',
    ));
  }

  Future<bool> cancelAutopay(String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl$_base/cancel'),
      headers: _headers(token),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  /// Returns the whole billing payload — `{ access: {...}, payments: [...] }`.
  /// The plan shown on the billing screen comes from THIS response, not from
  /// `/vendor/me/access`: that is what the website reads, and it is the only
  /// place `subscription.startsAt/endsAt/onAutopay/paymentFailing` appear.
  Future<Map<String, dynamic>> getHistory(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl$_base/history'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) return data;
    }
    return const {};
  }

  Future<VendorInvoice?> getInvoiceBytes(String token, dynamic paymentId) async {
    final res = await http.get(
      Uri.parse('$baseUrl$_base/invoice/$paymentId?disposition=inline'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return null;

    final disposition = res.headers['content-disposition'] ?? '';
    final match = RegExp(r'filename="?([^"]+)"?').firstMatch(disposition);
    final fileName = match?.group(1) ?? 'HappyWedz_Invoice_$paymentId.pdf';

    return VendorInvoice(bytes: res.bodyBytes, fileName: fileName);
  }

  String _errorMessage(http.Response res, String fallback) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['message'] is String) return data['message'];
    } catch (_) {}
    return fallback;
  }
}
