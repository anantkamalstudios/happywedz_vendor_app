import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/vendor_subscription_api.dart';
import '../providers/vendor_access_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/common_app_bar.dart';
import 'ViewPlanScreen.dart';

/// The vendor's billing view: the plan they are on, and every payment attempt.
///
/// Failed and abandoned attempts are shown rather than hidden. A vendor whose
/// card was declined and then sees an empty history assumes the money vanished;
/// the row with its reason is what prevents that support ticket.
///
/// Ported from the website's `subscription/SubscriptionSettings.jsx`, in the
/// app's own palette.
class SubscriptionHistoryScreen extends ConsumerStatefulWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  ConsumerState<SubscriptionHistoryScreen> createState() =>
      _SubscriptionHistoryScreenState();
}

class _SubscriptionHistoryScreenState
    extends ConsumerState<SubscriptionHistoryScreen> {
  final VendorSubscriptionApi _api = VendorSubscriptionApi();
  String? _token;

  bool _loading = true;
  bool _refreshing = false;
  bool _cancelling = false;
  String? _error;

  Map<String, dynamic> _access = {};
  Map<String, dynamic>? _sub;
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool quiet = false}) async {
    setState(() {
      if (quiet) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) {
        _error = 'Please sign in again.';
      } else {
        final data = await _api.getHistory(_token!);
        final access = Map<String, dynamic>.from(data['access'] ?? const {});
        _access = access;
        _sub = access['subscription'] as Map<String, dynamic>?;
        _payments = List<dynamic>.from(data['payments'] ?? const []);
      }
    } catch (e) {
      _error = 'Could not load your billing details.';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  String _date(dynamic value) {
    if (value == null) return '—';
    final parsed = DateTime.tryParse('$value');
    if (parsed == null) return '$value';
    return DateFormat('d MMM yyyy').format(parsed.toLocal());
  }

  String _money(dynamic amount, [String currency = 'INR']) {
    final n = num.tryParse('$amount');
    if (n == null) return '—';
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: currency == 'INR' ? '₹' : '$currency ',
      decimalDigits: n % 1 == 0 ? 0 : 2,
    ).format(n);
  }

  int? _daysUntil(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse('$value');
    if (parsed == null) return null;
    return parsed.difference(DateTime.now()).inHours ~/ 24;
  }

  Future<void> _cancelAutopay() async {
    if (_token == null) return;
    final isTrial = _sub?['isTrial'] == true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isTrial ? 'Cancel your free trial?' : 'Turn off auto-pay?'),
        content: Text(
          isTrial
              ? 'You have not been charged anything, and you will not be. Your storefront '
                  'stays live, but you will not be able to edit it.'
              : 'No further payments will be taken. You keep your plan until '
                  '${_date(_sub?['endsAt'])}.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep it')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(isTrial ? 'Yes, cancel it' : 'Yes, turn it off'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    final ok = await _api.cancelAutopay(_token!);
    if (!mounted) return;
    setState(() => _cancelling = false);

    if (ok) {
      ref.invalidate(vendorAccessProvider);
      await _load(quiet: true);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Done.'
            : 'Something went wrong. Please try again, or contact support.'),
      ),
    );
  }

  Future<void> _viewInvoice(Map payment) async {
    if (_token == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Loading invoice…')));
    final invoice = await _api.getInvoiceBytes(_token!, payment['id']);
    if (!mounted) return;
    if (invoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load the invoice.')));
      return;
    }
    await Printing.layoutPdf(
      onLayout: (_) async => invoice.bytes,
      name: invoice.fileName,
    );
  }

  void _openPlans() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ViewPlansScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = _sub;
    final left = _daysUntil(sub?['endsAt']);
    final soon = left != null && left <= 14;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(title: 'Payments & Subscription'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(quiet: true),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) ...[
                    _ErrorBar(message: _error!, onRetry: _load),
                    const SizedBox(height: 16),
                  ],
                  _PlanPanel(
                    sub: sub,
                    access: _access,
                    soon: soon,
                    daysLeft: left,
                    cancelling: _cancelling,
                    date: _date,
                    onChangePlan: _openPlans,
                    onCancelAutopay: _cancelAutopay,
                  ),
                  const SizedBox(height: 18),
                  _HistoryPanel(
                    payments: _payments,
                    refreshing: _refreshing,
                    date: _date,
                    money: _money,
                    onRefresh: () => _load(quiet: true),
                    onViewInvoice: _viewInvoice,
                  ),
                ],
              ),
            ),
    );
  }
}

// ===========================================================================
// YOUR PLAN
// ===========================================================================

class _PlanPanel extends StatelessWidget {
  final Map<String, dynamic>? sub;
  final Map<String, dynamic> access;
  final bool soon;
  final int? daysLeft;
  final bool cancelling;
  final String Function(dynamic) date;
  final VoidCallback onChangePlan;
  final VoidCallback onCancelAutopay;

  const _PlanPanel({
    required this.sub,
    required this.access,
    required this.soon,
    required this.daysLeft,
    required this.cancelling,
    required this.date,
    required this.onChangePlan,
    required this.onCancelAutopay,
  });

  @override
  Widget build(BuildContext context) {
    final s = sub;
    final isTrial = s?['isTrial'] == true;
    final paymentFailing = s?['paymentFailing'] == true;

    return _Panel(
      title: 'Your plan',
      icon: Icons.credit_card_outlined,
      trailing: s == null
          ? null
          : _Chip(
              label: soon ? 'Renews soon' : 'Active',
              color: soon ? AppColors.warning : AppColors.success,
              background: soon ? AppColors.warningTint : AppColors.successTint,
            ),
      children: [
        // A trial is not a normal plan and must not read like one: the vendor
        // needs the date and the amount, or the first debit is a chargeback.
        if (isTrial && !paymentFailing)
          _Notice(
            icon: Icons.schedule_outlined,
            background: AppColors.infoTint,
            accent: AppColors.info,
            title: '${s!['trialDaysLeft']} '
                '${s['trialDaysLeft'] == 1 ? 'day' : 'days'} left in your free trial',
            body: 'Nothing has been charged. On ${date(s['trialEndsAt'])} we will '
                'bill the payment method you saved, unless you cancel before then.',
          ),

        if (paymentFailing)
          _Notice(
            icon: Icons.warning_amber_rounded,
            background: AppColors.warningTint,
            accent: AppColors.warning,
            title: 'We could not take your payment',
            body: 'Your storefront is still live and nothing has been removed. '
                'Please update your payment method'
                '${s?['graceUntil'] != null ? ' before ${date(s!['graceUntil'])}' : ' soon'}'
                ' to keep editing.',
          ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: s != null ? _activePlan(context, s) : _noPlan(context),
        ),
      ],
    );
  }

  Widget _activePlan(BuildContext context, Map<String, dynamic> s) {
    final isTrial = s['isTrial'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CURRENT PLAN',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            )),
        const SizedBox(height: 4),
        Text('${s['planName'] ?? '—'}',
            style: AppTextStyles.h1.copyWith(fontSize: 24)),
        const SizedBox(height: 6),
        Text(
          '${date(s['startsAt'])} — ${date(s['endsAt'])}'
          '${daysLeft != null && daysLeft! >= 0 ? ' · $daysLeft ${daysLeft == 1 ? 'day' : 'days'} remaining' : ''}',
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: soon && !isTrial
              ? ElevatedButton(
                  onPressed: onChangePlan, child: const Text('Renew now'))
              : OutlinedButton(
                  onPressed: onChangePlan, child: const Text('Change plan')),
        ),
        // Only offered when there is a mandate to stop — otherwise this is a
        // button that cancels nothing.
        if (s['onAutopay'] == true) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: cancelling ? null : onCancelAutopay,
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              child: cancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isTrial ? 'Cancel trial' : 'Turn off auto-pay'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _noPlan(BuildContext context) {
    final expired = access['stage'] == 'expired';
    final canPurchase = access['canPurchase'] != false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(expired ? 'Your plan has ended' : 'You are not on a plan yet',
            style: AppTextStyles.h3),
        const SizedBox(height: 6),
        Text(
          access['message'] ??
              'Pick a plan to unlock your storefront and start editing.',
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canPurchase ? onChangePlan : null,
            child: Text(expired ? 'Renew plan' : 'View plans'),
          ),
        ),
        if (!canPurchase) ...[
          const SizedBox(height: 8),
          Text('Complete your business verification first',
              style: AppTextStyles.caption),
        ],
      ],
    );
  }
}

// ===========================================================================
// PAYMENT HISTORY
// ===========================================================================

/// Status wording and colour per payment state, matching the website's table.
({String label, Color color, Color background}) _statusStyle(String status) {
  switch (status) {
    case 'paid':
      return (label: 'Paid', color: AppColors.success, background: AppColors.successTint);
    case 'failed':
      return (label: 'Failed', color: AppColors.error, background: AppColors.errorTint);
    case 'refunded':
      return (label: 'Refunded', color: AppColors.warning, background: AppColors.warningTint);
    default:
      return (
        label: 'Incomplete',
        color: AppColors.textSecondary,
        background: AppColors.inputFill
      );
  }
}

class _HistoryPanel extends StatelessWidget {
  final List<dynamic> payments;
  final bool refreshing;
  final String Function(dynamic) date;
  final String Function(dynamic, [String]) money;
  final VoidCallback onRefresh;
  final void Function(Map) onViewInvoice;

  const _HistoryPanel({
    required this.payments,
    required this.refreshing,
    required this.date,
    required this.money,
    required this.onRefresh,
    required this.onViewInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Payment history',
      trailing: IconButton(
        onPressed: refreshing ? null : onRefresh,
        tooltip: 'Refresh',
        icon: refreshing
            ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.refresh, size: 20),
      ),
      children: [
        if (payments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            child: Column(
              children: [
                Text('No payments yet',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Your invoices will appear here once you buy a plan.',
                    style: AppTextStyles.bodySecondary,
                    textAlign: TextAlign.center),
              ],
            ),
          )
        else ...[
          for (final p in payments)
            _PaymentRow(
              payment: p,
              date: date,
              money: money,
              onViewInvoice: () => onViewInvoice(p),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Text(
              'Payments that were started but never completed are not listed. If money '
              'was deducted for one of them, reply to your receipt email and we will '
              'check it.',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final Map payment;
  final String Function(dynamic) date;
  final String Function(dynamic, [String]) money;
  final VoidCallback onViewInvoice;

  const _PaymentRow({
    required this.payment,
    required this.date,
    required this.money,
    required this.onViewInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final status = (payment['status'] ?? 'created').toString();
    final style = _statusStyle(status);
    final planName = payment['plan']?['name'] ?? '—';
    final invoiceNo = payment['invoice_no'];
    final razorpayId = payment['razorpay_payment_id'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date(payment['paid_at'] ?? payment['created_at']),
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 2),
                    Text('$planName', style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
              Text(money(payment['amount'], payment['currency'] ?? 'INR'),
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(
                  label: style.label,
                  color: style.color,
                  background: style.background),
              const Spacer(),
              // Only paid rows have an invoice — a document for a payment that
              // never completed would claim money changed hands.
              if (status == 'paid')
                OutlinedButton(
                  onPressed: onViewInvoice,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('View'),
                ),
            ],
          ),
          if (status == 'failed' && payment['failure_reason'] != null) ...[
            const SizedBox(height: 8),
            Text('${payment['failure_reason']}', style: AppTextStyles.caption),
          ],
          if (invoiceNo != null || razorpayId != null) ...[
            const SizedBox(height: 8),
            if (invoiceNo != null)
              Text('$invoiceNo',
                  style: AppTextStyles.caption
                      .copyWith(fontFamily: 'monospace')),
            if (razorpayId != null)
              Text('$razorpayId',
                  style: AppTextStyles.caption.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.textTertiary,
                  )),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// SHARED BITS
// ===========================================================================

class _Panel extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;

  const _Panel({
    required this.title,
    this.icon,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16, trailing != null ? 6 : 14, 8, trailing != null ? 6 : 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(title,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                if (trailing != null) trailing!,
                if (trailing == null) const SizedBox(width: 8),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _Chip({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color accent;
  final String title;
  final String body;

  const _Notice({
    required this.icon,
    required this.background,
    required this.accent,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      color: background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBar({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(message,
                style: AppTextStyles.body.copyWith(color: AppColors.error)),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
