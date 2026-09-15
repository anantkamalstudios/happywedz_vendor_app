import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:happy_weds_vendors/utils/api_config.dart';

/// Mirrors the review-collection calls made directly in the website's
/// `ReviewsCollector.jsx` (there is no dedicated services/api wrapper there).
class ReviewRequestApi {
  final String baseUrl = ApiConfig.baseUrl;

  /// GET /inbox?filter=booked -> booked leads a review request can be sent to.
  Future<List<dynamic>> getBookedLeads(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/inbox?filter=booked'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<dynamic>.from(data['inbox'] ?? const []);
    }
    return const [];
  }

  Future<bool> sendReviewRequest({
    required String token,
    required dynamic requestId,
    required String message,
    required String reviewLink,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/reviews/send-review-request/$requestId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'message': message, 'reviewLink': reviewLink}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) return true;

    String msg = 'Failed to send review request.';
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['message'] is String) msg = data['message'];
    } catch (_) {}
    throw Exception(msg);
  }
}
