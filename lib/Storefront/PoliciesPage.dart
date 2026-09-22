import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/api_service_vendor.dart';
import '../api_services/storefront_completion_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/common_app_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_shimmer.dart';
import '../utils/subcategory_selection.dart';

class PoliciesPage extends StatefulWidget {
  const PoliciesPage({super.key});

  @override
  State<PoliciesPage> createState() => _PoliciesPageState();
}

class _PoliciesPageState extends State<PoliciesPage> {
  final TextEditingController _cancellationController = TextEditingController();
  final TextEditingController _refundController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _tncController = TextEditingController();

  bool loading = true;
  bool saving = false;

  int? vendorId;
  int? serviceId;
  int? vendorSubcategoryId;
  String? token;
  final VendorServiceApi _vendorApi = VendorServiceApi();


  @override
  void initState() {
    super.initState();
    debugPrint("🔔 PoliciesPage.initState()");
    _attachListeners();
    _loadCredentialsAndData();
  }

  void _attachListeners() {
    _cancellationController.addListener(_autosaveLocally);
    _refundController.addListener(_autosaveLocally);
    _paymentController.addListener(_autosaveLocally);
    _tncController.addListener(_autosaveLocally);
  }

  void _removeListeners() {
    _cancellationController.removeListener(_autosaveLocally);
    _refundController.removeListener(_autosaveLocally);
    _paymentController.removeListener(_autosaveLocally);
    _tncController.removeListener(_autosaveLocally);
  }

  @override
  void dispose() {
    _removeListeners();
    _cancellationController.dispose();
    _refundController.dispose();
    _paymentController.dispose();
    _tncController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentialsAndData() async {
    setState(() => loading = true);
    debugPrint("📥 Loading SharedPreferences credentials & local data...");
    final prefs = await SharedPreferences.getInstance();

    vendorId = prefs.getInt('vendorId');
    token = prefs.getString('token');
    serviceId = prefs.getInt('serviceId');
    vendorSubcategoryId = prefs.getInt('vendor_subcategory_id');

    debugPrint("🔑 Loaded: vendorId=$vendorId, serviceId=$serviceId, vendor_subcategory_id=$vendorSubcategoryId, token=${token != null ? 'present' : 'null'}");

    // Load locally saved copy first (so UI is instant)
    final local = prefs.getString('policiesData');
    if (local != null) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(local);
        debugPrint("📦 Found local policiesData: $parsed");
        _setFieldsFromMap(parsed);
      } catch (e) {
        debugPrint("⚠️ Failed to parse local policiesData: $e");
      }
    } else {
      debugPrint("📭 No local policiesData found.");
    }

    // If vendorId and token present, fetch server data (this may update serviceId & attributes)
    if (vendorId != null && token != null) {
      await _fetchVendorServiceAndPopulate();
    } else {
      debugPrint("⚠ Skipping server fetch (vendorId or token missing).");
    }

    setState(() => loading = false);
  }

  void _setFieldsFromMap(Map<String, dynamic> data) {
    // Accept either an 'attributes' map or direct keys map
    final attributes = data.containsKey('attributes') ? data['attributes'] as Map<String, dynamic> : data;
    debugPrint("🔧 _setFieldsFromMap attributes: $attributes");

    _cancellationController.text = attributes['cancellation_policy']?.toString() ?? '';
    _refundController.text = attributes['refund_policy']?.toString() ?? '';
    _paymentController.text = attributes['payment_terms']?.toString() ?? '';
    _tncController.text = attributes['tnc']?.toString() ?? '';
  }

  Future<void> _fetchVendorServiceAndPopulate() async {
    try {
      final data = await _vendorApi.getByVendorId(
        vendorId: vendorId!,
        token: token!,
      );

      if (data == null) return;

      // save serviceId
      serviceId = data["id"];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt("serviceId", serviceId!);

      final attributes = Map<String, dynamic>.from(data["attributes"] ?? {});
      _setFieldsFromMap({"attributes": attributes});
      await _saveLocallyFromControllers();
    } catch (e) {
      debugPrint("❌ fetch policies error: $e");
    }
  }


  Future<void> _autosaveLocally() async {
    // Called on every change; keep lightweight and quick
    await _saveLocallyFromControllers();
  }

  Future<void> _saveLocallyFromControllers() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {
      "cancellation_policy": _cancellationController.text.trim(),
      "refund_policy": _refundController.text.trim(),
      "payment_terms": _paymentController.text.trim(),
      "tnc": _tncController.text.trim(),
    };
    await prefs.setString('policiesData', jsonEncode(data));
    debugPrint("💾 Autosaved policies locally: $data");
  }

  Future<void> _savePoliciesToServer() async {
    if (vendorId == null || token == null || serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete Basic Info first.")),
      );
      return;
    }

    setState(() => saving = true);

    // 🔥 Fetch latest attributes first
    final latest = await _vendorApi.getByServiceId(
      serviceId: serviceId!,
      token: token!,
    );

    Map<String, dynamic> attributes =
    Map<String, dynamic>.from(latest?["attributes"] ?? {});

    // ✅ Update ONLY policy-related keys
    attributes.addAll({
      "cancellation_policy": _cancellationController.text.trim(),
      "refund_policy": _refundController.text.trim(),
      "payment_terms": _paymentController.text.trim(),
      "tnc": _tncController.text.trim(),
    });

    final body = {
      "vendor_id": vendorId,
      "vendor_subcategory_id": await SubcategorySelection.payloadForPrimary(vendorSubcategoryId),
      "attributes": attributes,
    };

    final success = await _vendorApi.updateService(
      serviceId: serviceId!,
      token: token!,
      body: body,
    );

    if (success) {
      await StorefrontCompletionService.refreshCompletion(
        serviceId: serviceId!,
      );
      await _saveLocallyFromControllers();
      // AUDIT FIX: context used after an await — guard added.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Policies saved successfully")),
      );
    } else {
      // AUDIT FIX: context used after an await — guard added.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save policies")),
      );
    }

    setState(() => saving = false);
  }


  void _resetForm() async {
    debugPrint("♻️ Reset: clearing controllers and removing local storage");
    _cancellationController.clear();
    _refundController.clear();
    _paymentController.clear();
    _tncController.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('policiesData');
    debugPrint("🗑 Removed policiesData from SharedPreferences");
    setState(() {}); // refresh
  }

  /// Why these fields are worth filling in. The screen opened on four unlabelled
  /// boxes with no indication of what belongs in them.
  Widget _intro() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined,
              size: 20, color: AppColors.primary),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Text(
              "Couples read these on your profile before they book. "
              "Clear policies mean fewer back-and-forth enquiries.",
              style: AppTextStyles.bodySecondary
                  .copyWith(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  /// Tinted square icon, matching the leading icons on the Storefront list.
  Widget _fieldIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Icon(icon, size: 19, color: AppColors.primary),
    );
  }

  /// One policy block — icon, what the field is for, then the input.
  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    required IconData icon,
    required String helper,
    required String hint,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _fieldIcon(icon),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.label),
                    const SizedBox(height: 2),
                    Text(helper, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: AppTextStyles.input,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.hint,
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: border(AppColors.border),
              enabledBorder: border(AppColors.border),
              focusedBorder: border(AppColors.primary, 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Save and Reset pinned to the bottom, the way Basic Information and Upload
  /// Gallery already place their primary action.
  Widget _actions() {
    return Container(
      // targetSdk 36 means Android draws this app edge to edge, so a bar
      // pinned to the bottom of the body sits UNDER the 3-button navigation
      // bar. The SafeArea is inside the Container so the bar's own background
      // still fills that strip instead of leaving a gap.
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: "Reset",
                  variant: AppButtonVariant.outline,
                  onPressed: _resetForm,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: "Save Policies",
                  isLoading: saving,
                  onPressed: saving ? null : _savePoliciesToServer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A white card on a white page read as nothing at all. The tinted page
      // background is what gives the cards an edge.
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: 'Policies & Terms'),
      body: loading
          ? const FormShimmer(fields: 4)
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _intro(),
                        const SizedBox(height: AppTheme.spaceLg),

                        _field(
                          "Cancellation Policy",
                          _cancellationController,
                          maxLines: 3,
                          icon: Icons.event_busy_outlined,
                          helper: "How late can a booking be called off?",
                          hint:
                              "e.g. Free cancellation up to 30 days before the "
                              "event date.",
                        ),
                        _field(
                          "Refund Policy",
                          _refundController,
                          maxLines: 3,
                          icon: Icons.replay_outlined,
                          helper: "What comes back, and when?",
                          hint:
                              "e.g. 50% of the advance is refunded if cancelled "
                              "15 days before the event.",
                        ),
                        _field(
                          "Payment Terms",
                          _paymentController,
                          icon: Icons.payments_outlined,
                          helper: "Advance, instalments and accepted methods.",
                          hint:
                              "e.g. 30% advance to confirm, balance on the "
                              "event day.",
                        ),
                        _field(
                          "Terms & Conditions",
                          _tncController,
                          maxLines: 5,
                          icon: Icons.assignment_outlined,
                          helper:
                              "Anything else a couple agrees to on booking.",
                          hint:
                              "e.g. Travel and stay for outstation events are "
                              "borne by the client. Overtime billed hourly.",
                        ),
                      ],
                    ),
                  ),
                ),
                _actions(),
              ],
            ),
    );
  }
}
