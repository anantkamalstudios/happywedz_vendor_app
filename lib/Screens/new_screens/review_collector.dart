import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_services/api_service_vendor.dart';
import '../../api_services/review_request_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/api_config.dart';
import '../../utils/common_app_bar.dart';

/// Lets a vendor send a review-request link to a past booked customer.
/// Ported from the website's `subVendors/ReviewsCollector.jsx`.
class ReviewCollectorScreen extends StatefulWidget {
  const ReviewCollectorScreen({super.key});

  @override
  State<ReviewCollectorScreen> createState() => _ReviewCollectorScreenState();
}

class _ReviewCollectorScreenState extends State<ReviewCollectorScreen> {
  final ReviewRequestApi _reviewApi = ReviewRequestApi();
  final VendorServiceApi _vendorApi = VendorServiceApi();
  final TextEditingController _messageController = TextEditingController();

  String? _token;
  int? _vendorId;
  dynamic _serviceId;
  String? _serviceSlug;

  bool _loading = true;
  bool _sending = false;
  bool _copied = false;

  List<dynamic> _bookedLeads = [];
  Map<String, dynamic>? _selectedLead;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String get _reviewUrl {
    final base = '${ApiConfig.websiteUrl}/write-review/$_serviceId';
    return _serviceSlug != null ? '$base/$_serviceSlug' : base;
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _vendorId = prefs.getInt('vendorId');

    if (_token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final results = await Future.wait([
        _reviewApi.getBookedLeads(_token!),
        if (_vendorId != null)
          _vendorApi.getByVendorId(vendorId: _vendorId!, token: _token!)
        else
          Future.value(null),
      ]);

      _bookedLeads = List<dynamic>.from(results[0] as List<dynamic>);
      final service = results[1] as Map<String, dynamic>?;
      _serviceId = service?['id'];
      _serviceSlug = service?['slug'];
    } catch (e) {
      debugPrint('ReviewCollector init error: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  void _onLeadSelected(dynamic lead) {
    final request = lead['request'] ?? {};
    final user = request['user'] ?? {};
    final name = (user['name'] ?? '').toString();
    final eventDate = (request['eventDate'] ?? '').toString();

    setState(() {
      _selectedLead = Map<String, dynamic>.from(lead);
      _messageController.text = 'Hi $name,\n\n'
          'Thank you for choosing us for your event on $eventDate.\n'
          'We would love to hear your feedback on our services!\n\n'
          'Please review us on HappyWedz.\n\n'
          'Thanks & Regards';
    });
  }

  Future<void> _send() async {
    final lead = _selectedLead;
    if (lead == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a booked customer')));
      return;
    }

    final request = lead['request'] ?? {};
    final user = request['user'] ?? {};
    final requestId = request['id'];
    final email = user['email'];

    if (requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found for this booking')));
      return;
    }
    if (email == null || email.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email found for this customer')));
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message cannot be empty')));
      return;
    }
    if (_token == null || _serviceId == null) return;

    setState(() => _sending = true);
    try {
      await _reviewApi.sendReviewRequest(
        token: _token!,
        requestId: requestId,
        message: _messageController.text.trim(),
        reviewLink: _reviewUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review request sent successfully!')));
      setState(() {
        _selectedLead = null;
        _messageController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _reviewUrl));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(title: 'Review Collector'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Send Review Request', style: AppTextStyles.h3),
                      const SizedBox(height: 4),
                      Text('Send review requests to your happy clients and grow your reputation.', style: AppTextStyles.bodySecondary),
                      const SizedBox(height: 16),

                      Text('Select customer', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        value: _selectedLead != null
                            ? _bookedLeads.indexWhere((l) => l['id'] == _selectedLead!['id'])
                            : null,
                        hint: const Text('Choose a booked customer...'),
                        items: List.generate(_bookedLeads.length, (i) {
                          final lead = _bookedLeads[i];
                          final request = lead['request'] ?? {};
                          final name = '${request['firstName'] ?? ''} ${request['lastName'] ?? ''}'.trim();
                          final eventDate = request['eventDate'] ?? '';
                          return DropdownMenuItem(
                            value: i,
                            child: Text(
                              '${name.isEmpty ? 'No Name' : name} - $eventDate',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        onChanged: (i) {
                          if (i != null) _onLeadSelected(_bookedLeads[i]);
                        },
                      ),

                      if (_selectedLead != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoChip(
                                label: 'Customer name',
                                value: (_selectedLead!['request']?['user']?['name'] ?? '').toString(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _InfoChip(
                                label: 'Email',
                                value: (_selectedLead!['request']?['user']?['email'] ?? '').toString(),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                      Text('Personalized message', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _messageController,
                        maxLines: 8,
                        decoration: const InputDecoration(hintText: 'Write a personalized message to your client...'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send),
                          label: Text(_sending ? 'Sending…' : 'Send Review Request'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Share Your Review Link', style: AppTextStyles.h3),
                      const SizedBox(height: 4),
                      Text(
                        'Share this personalized URL with your past clients via WhatsApp, SMS or social media.',
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)),
                              child: Text(_reviewUrl, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _copyLink,
                            icon: Icon(_copied ? Icons.check : Icons.copy, size: 18),
                          ),
                        ],
                      ),
                      if (_copied) ...[
                        const SizedBox(height: 8),
                        Text('Link copied to clipboard!', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '—' : value, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
