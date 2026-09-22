import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/vendor_subscription_api.dart';
import '../providers/vendor_access_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/common_app_bar.dart';
import 'subscription_history_screen.dart';

/// What each storefront section is for, in a vendor's terms. Shown in the
/// "Know more about what you'll get" sheet on a plan card, so a vendor can see
/// what a plan actually lets them do before paying for it. Ported from
/// `subscription/storefrontTabGuide.js`.
const Map<String, String> _kStorefrontTabGuide = {
  'vendor-basic':
      "Your business name, tagline and About Us - the first thing couples read on your profile.",
  'faq':
      "Answer the questions couples ask most, like travel, booking and what is included, before they need to message you.",
  'vendor-contact': "The contact name, phone number and email couples use to reach you directly.",
  'vendor-location':
      "Your address and the areas you serve, so you appear when couples search in those places.",
  'photos': "Your portfolio - usually the first thing couples look at when comparing vendors.",
  'videos': "Showreels, highlight films and walkthroughs, played right on your profile.",
  'preferred-vendors': "Recommend other HappyWedz vendors you like working with, shown on your profile.",
  'social': "Links to your Instagram, Facebook, Pinterest, X and website, so couples can see more of your work.",
  'vendor-facilities':
      "Practical details such as delivery time, travel coverage, the events you cover and when you started.",
  'vendor-menus': "Your food menus with veg and non-veg prices per plate. Only shown for caterers and venues.",
  'promotions': "Offers and discounts, highlighted on your listing to turn interest into bookings.",
  'vendor-policies': "Your terms and conditions, cancellation and refund policies, set out up front.",
  'vendor-availability': "The dates and slots you are free, so couples only enquire when you can take the booking.",
  'vendor-pricing': "Your starting price and price range, so enquiries come from couples whose budget fits.",
};

class ViewPlansScreen extends ConsumerStatefulWidget {
  const ViewPlansScreen({super.key});

  @override
  ConsumerState<ViewPlansScreen> createState() => _ViewPlansScreenState();
}

class _ViewPlansScreenState extends ConsumerState<ViewPlansScreen>
    with SingleTickerProviderStateMixin {
  final VendorSubscriptionApi _api = VendorSubscriptionApi();
  late final Razorpay _razorpay;
  String? _token;

  /// Drives the staggered fade-and-rise of the plan cards.
  late final AnimationController _entry;

  /// Also read during paint so the card nearest the middle can sit slightly
  /// larger than its neighbours as the carousel moves.
  final ScrollController _carousel = ScrollController();

  bool _loading = true;
  String? _error;
  List<dynamic> _plans = [];
  List<dynamic> _storefrontTabs = [];
  bool _trialAvailable = false;
  Map<String, dynamic> _access = {};

  String _cycle = 'monthly';
  bool _showCycleTabs = false;

  bool _processing = false;
  String _status = '';
  dynamic _activePlanId;
  // Which flow the pending Razorpay callback belongs to.
  String? _pendingAction; // 'checkout' | 'trial'
  Map<String, dynamic>? _pendingTrial;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _load();
  }

  @override
  void dispose() {
    _entry.dispose();
    _carousel.dispose();
    _razorpay.clear();
    super.dispose();
  }

  /// Replays the card entrance and returns the carousel to the first plan —
  /// used on first load and whenever the billing cycle swaps the card set out.
  void _replayEntrance() {
    _entry.forward(from: 0);
    // After the frame, not during it: on first load the carousel has no
    // scroll clients yet, so jumping here would silently do nothing and the
    // list could settle anywhere but the first plan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_carousel.hasClients) _carousel.jumpTo(0);
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token == null) {
      setState(() {
        _loading = false;
        _error = 'Please sign in again.';
      });
      return;
    }

    try {
      final data = await _api.getPlans(_token!);
      final plans = List<dynamic>.from(data['plans'] ?? const []);
      final hasMonthly = plans.any((p) => p['billing_cycle'] == 'monthly');
      final hasYearly = plans.any((p) => p['billing_cycle'] == 'yearly');

      setState(() {
        _plans = plans;
        _access = Map<String, dynamic>.from(data['access'] ?? const {});
        _storefrontTabs = List<dynamic>.from(data['storefrontTabs'] ?? const []);
        _trialAvailable = data['trialAvailable'] == true;
        _showCycleTabs = hasMonthly && hasYearly;
        _cycle = hasMonthly ? 'monthly' : 'yearly';
        _loading = false;
      });
      _replayEntrance();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not load plans. Please try again.';
      });
    }
  }

  List<dynamic> get _visiblePlans {
    if (!_showCycleTabs) return _plans;
    return _plans.where((p) => p['billing_cycle'] == _cycle).toList();
  }

  void _fail(String message) {
    setState(() {
      _processing = false;
      _status = '';
      _activePlanId = null;
      _pendingAction = null;
      _pendingTrial = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startCheckout(Map plan) async {
    if (_processing || _token == null) return;
    setState(() {
      _processing = true;
      _activePlanId = plan['id'];
      _status = 'Preparing your payment…';
      _pendingAction = 'checkout';
    });

    try {
      final order = await _api.createOrder(_token!, plan['id'] as int);
      setState(() => _status = 'Opening payment window…');

      final orderData = order['order'] as Map<String, dynamic>;
      final prefill = order['prefill'] as Map<String, dynamic>?;

      _razorpay.open({
        'key': order['razorpayKeyId'],
        'amount': orderData['amount'],
        'currency': orderData['currency'],
        'order_id': orderData['id'],
        'name': 'HappyWedz',
        'description': '${order['plan']?['name'] ?? plan['name']} plan',
        if (prefill != null) 'prefill': prefill,
        'theme': {'color': '#00509D'},
      });
    } catch (e) {
      _fail(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _startTrial(Map plan) async {
    if (_processing || _token == null) return;
    setState(() {
      _processing = true;
      _activePlanId = plan['id'];
      _status = 'Preparing your trial…';
      _pendingAction = 'trial';
    });

    try {
      final trial = await _api.startTrial(_token!, plan['id'] as int);
      setState(() {
        _status = 'Opening the authorisation window…';
        _pendingTrial = trial;
      });

      _razorpay.open({
        'key': trial['razorpayKeyId'],
        'subscription_id': trial['razorpaySubscriptionId'],
        'name': 'HappyWedz',
        'description': '${trial['plan']?['name'] ?? plan['name']} — ${trial['trialDays'] ?? 14}-day free trial',
        'theme': {'color': '#00509D'},
      });
    } catch (e) {
      _fail(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (_token == null) return;

    try {
      if (_pendingAction == 'trial') {
        setState(() => _status = 'Starting your trial…');
        final subscriptionId = _pendingTrial?['razorpaySubscriptionId'] as String?;
        await _api.confirmTrial(_token!, subscriptionId ?? '');
      } else {
        setState(() => _status = 'Confirming your payment…');
        await _api.verify(
          _token!,
          razorpayOrderId: response.orderId ?? '',
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
        );
      }

      ref.invalidate(vendorAccessProvider);

      if (!mounted) return;
      setState(() {
        _processing = false;
        _status = '';
        _activePlanId = null;
        _pendingAction = null;
        _pendingTrial = null;
      });

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Your storefront is unlocked. A receipt is on its way to your email.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go to my storefront')),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _fail(e.toString().replaceFirst('Exception: ', ''));
      _load();
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    _fail(response.message ?? 'The payment did not go through. No money has been taken.');
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _fail('Payment not completed via external wallet.');
  }

  void _showPlanGuide(Map plan) {
    final allowedTabs = List<String>.from(plan['allowed_tabs'] ?? const []);
    final unlockedTabs = _storefrontTabs
        .where((t) => t['id'] != 'business' && allowedTabs.contains(t['id']))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan['name'] ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text("What you'll get", style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text('The storefront sections this plan lets you edit, and what each one is for.', style: AppTextStyles.bodySecondary),
              const Divider(height: 24),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: unlockedTabs.length,
                  separatorBuilder: (_, __) => const Divider(height: 20),
                  itemBuilder: (context, i) {
                    final tab = unlockedTabs[i];
                    final desc = _kStorefrontTabGuide[tab['id']];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tab['label'] ?? '', style: AppTextStyles.bodyMedium),
                              if (desc != null) ...[
                                const SizedBox(height: 2),
                                Text(desc, style: AppTextStyles.caption),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 12),
              Text(
                'Business details comes with every plan — it is where your verification documents are kept.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(dynamic value) {
    final n = num.tryParse('$value');
    if (n == null) return '';
    return '₹${n.toStringAsFixed(0)}';
  }

  /// Slightly narrower than the screen so the next card peeks in and the
  /// sideways scroll is discoverable without a hint.
  double _cardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 32;
    return width * 0.86;
  }

  /// Two animations on one card:
  ///  • entrance — cards fade and rise in, each one a beat after the last;
  ///  • focus — whichever card the carousel is resting on sits at full size
  ///    while its neighbours sit slightly back, so the current plan reads as
  ///    the one being considered.
  Widget _animatedCard({
    required int index,
    required int total,
    required Widget child,
  }) {
    final start = total <= 1 ? 0.0 : (index / total * 0.45).clamp(0.0, 0.45);
    final entrance = CurvedAnimation(
      parent: _entry,
      curve: Interval(start, (start + 0.55).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    final itemExtent = _cardWidth(context) + 12;

    return AnimatedBuilder(
      animation: Listenable.merge([entrance, _carousel]),
      child: child,
      builder: (context, built) {
        final t = entrance.value;
        // Distance of this card from the one the carousel is resting on.
        final delta = _carousel.hasClients
            ? (_carousel.offset / itemExtent) - index
            : -index.toDouble();
        final focus = 1 - delta.abs().clamp(0.0, 1.0);

        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 28),
            child: Transform.scale(
              scale: (0.94 + 0.06 * focus) * (0.96 + 0.04 * t),
              alignment: Alignment.topCenter,
              child: built,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabLabels = <String, String>{
      for (final t in _storefrontTabs) t['id'] as String: t['label'] as String,
    };
    final sellableTabCount = _storefrontTabs.where((t) => t['id'] != 'business').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: 'Membership Plans',
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Billing & Invoices',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionHistoryScreen()));
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : _plans.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        // Edge to edge (targetSdk 36): keeps the last item clear of the
                        // 3-button navigation bar.
                        padding: EdgeInsets.fromLTRB(16, 16, 16,
                            16 + MediaQuery.of(context).padding.bottom),
                        children: [
                          Text(
                            'Choose your plan',
                            style: AppTextStyles.h2,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            sellableTabCount > 0
                                ? 'Each plan unlocks a different set of storefront sections. Your listing stays live either way.'
                                : 'Your listing stays live either way.',
                            style: AppTextStyles.bodySecondary,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          if (_showCycleTabs) _CycleToggle(
                            cycle: _cycle,
                            onChanged: (c) {
                              if (c == _cycle) return;
                              setState(() => _cycle = c);
                              _replayEntrance();
                            },
                          ),
                          const SizedBox(height: 18),
                          // Plans scroll sideways, one card at a time, with the
                          // next one peeking so it is obvious there is more.
                          // IntrinsicHeight keeps every card the same height,
                          // and each card pushes its buttons to the bottom so
                          // they line up across the row.
                          //
                          // Deliberately NOT wrapped in an AnimatedSwitcher: it
                          // keeps the outgoing and incoming lists alive at the
                          // same time, so both would attach to `_carousel` and
                          // Flutter throws "ScrollController attached to
                          // multiple scroll views". Swapping the cycle already
                          // animates, because `_replayEntrance` fades and
                          // raises the new cards in.
                          SingleChildScrollView(
                              controller: _carousel,
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              physics: _CardSnapPhysics(
                                itemExtent: _cardWidth(context) + 12,
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    for (int i = 0; i < _visiblePlans.length; i++)
                                      _animatedCard(
                                        index: i,
                                        total: _visiblePlans.length,
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 12),
                                          child: SizedBox(
                                            width: _cardWidth(context),
                                            child: _PlanCard(
                                              plan: _visiblePlans[i],
                                              tabLabels: tabLabels,
                                              sellableTabCount: sellableTabCount,
                                              isCurrent: _access['subscription']?['planId'] == _visiblePlans[i]['id'],
                                              processing: _processing && _activePlanId == _visiblePlans[i]['id'],
                                              disabled: (_access['canPurchase'] == false) || (_processing && _activePlanId != _visiblePlans[i]['id']),
                                              disabledReason: 'Complete your business verification first',
                                              statusLabel: _status,
                                              trialAvailable: _trialAvailable,
                                              formatPrice: _formatPrice,
                                              onKnowMore: () => _showPlanGuide(_visiblePlans[i]),
                                              onChoose: () => _startCheckout(_visiblePlans[i]),
                                              onStartTrial: () => _startTrial(_visiblePlans[i]),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          if (_visiblePlans.length > 1) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.swipe_left_alt_outlined,
                                    size: 16, color: AppColors.textTertiary),
                                const SizedBox(width: 6),
                                Text('Swipe to compare plans', style: AppTextStyles.caption),
                              ],
                            ),
                          ],
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Payments are processed securely by Razorpay. You will receive an invoice by '
                                    'email, and your full payment history is available above.',
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

/// How many unlocked sections a plan card lists before collapsing the rest
/// into a "+N more sections" line.
const int _maxVisibleSections = 6;

/// Snaps the plan carousel so a swipe always settles on a whole card instead
/// of leaving one cut in half.
class _CardSnapPhysics extends ScrollPhysics {
  final double itemExtent;

  const _CardSnapPhysics({required this.itemExtent, super.parent});

  @override
  _CardSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _CardSnapPhysics(itemExtent: itemExtent, parent: buildParent(ancestor));

  double _targetPixels(ScrollMetrics position, Tolerance tolerance, double velocity) {
    double page = position.pixels / itemExtent;
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    return (page.roundToDouble() * itemExtent)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final target = _targetPixels(position, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }

  @override
  bool get allowImplicitScrolling => false;
}

class _CycleToggle extends StatelessWidget {
  final String cycle;
  final ValueChanged<String> onChanged;
  const _CycleToggle({required this.cycle, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ['monthly', 'yearly'].map((c) {
            final selected = cycle == c;
            return GestureDetector(
              onTap: () => onChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: selected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Text(c == 'monthly' ? 'Monthly' : 'Yearly'),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map plan;
  final Map<String, String> tabLabels;
  final int sellableTabCount;
  final bool isCurrent;
  final bool processing;
  final bool disabled;
  final String disabledReason;
  final String statusLabel;
  final bool trialAvailable;
  final String Function(dynamic) formatPrice;
  final VoidCallback onKnowMore;
  final VoidCallback onChoose;
  final VoidCallback onStartTrial;

  const _PlanCard({
    required this.plan,
    required this.tabLabels,
    required this.sellableTabCount,
    required this.isCurrent,
    required this.processing,
    required this.disabled,
    required this.disabledReason,
    required this.statusLabel,
    required this.trialAvailable,
    required this.formatPrice,
    required this.onKnowMore,
    required this.onChoose,
    required this.onStartTrial,
  });

  @override
  Widget build(BuildContext context) {
    final isPopular = plan['is_popular'] == true;
    final allowedTabs = List<String>.from(plan['allowed_tabs'] ?? const []);
    final unlockedLabels = allowedTabs.where((id) => id != 'business' && tabLabels[id] != null).map((id) => tabLabels[id]!).toList();
    final billingCycle = plan['billing_cycle'] ?? 'monthly';
    final canTrial = !isCurrent && trialAvailable && plan['trial_enabled'] == true;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? AppColors.success : (isPopular ? AppColors.primary : AppColors.border),
          width: isPopular || isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular && !isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
              child: const Text('RECOMMENDED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          const SizedBox(height: 8),
          Text(plan['name'] ?? '', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(formatPrice(plan['price_inr']), style: AppTextStyles.h1.copyWith(fontSize: 28)),
              const SizedBox(width: 6),
              Text('/ ${billingCycle == 'monthly' ? 'month' : 'year'}', style: AppTextStyles.bodySecondary),
            ],
          ),
          if (plan['description'] != null) ...[
            const SizedBox(height: 8),
            Text(plan['description'], style: AppTextStyles.bodySecondary),
          ],
          const Divider(height: 24),
          if (sellableTabCount > 0) ...[
            Text('What you can edit', style: AppTextStyles.captionMedium),
            const SizedBox(height: 8),
            if (unlockedLabels.length >= sellableTabCount)
              _Bullet(text: 'Every storefront section — photos, videos, pricing, availability, promotions and more')
            else ...[
              // Capped so one plan with many sections cannot stretch every
              // card in the row; the full list lives in the "Know more" sheet.
              ...unlockedLabels.take(_maxVisibleSections).map((l) => _Bullet(text: l)),
              if (unlockedLabels.length > _maxVisibleSections)
                _Bullet(text: '+${unlockedLabels.length - _maxVisibleSections} more sections'),
            ],
            TextButton(
              onPressed: onKnowMore,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Flexible(child: Text("Know more about what you'll get")),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14),
                ],
              ),
            ),
          ],
          // Every card is the same height, so this pushes the buttons to the
          // bottom edge and keeps them aligned across the whole row.
          const Spacer(),
          const SizedBox(height: 8),
          if (canTrial) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: disabled ? null : onStartTrial,
                child: Text(processing ? (statusLabel.isNotEmpty ? statusLabel : 'Starting…') : 'Start ${plan['trial_days'] ?? 14}-day free trial'),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No charge today. We save a payment method and bill ${formatPrice(plan['price_inr'])} after '
              '${plan['trial_days'] ?? 14} days unless you cancel.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? OutlinedButton(onPressed: null, child: const Text('Your current plan'))
                : isPopular
                    ? ElevatedButton(
                        onPressed: disabled ? null : onChoose,
                        child: Text(processing ? (statusLabel.isNotEmpty ? statusLabel : 'Please wait…') : 'Choose plan'),
                      )
                    : OutlinedButton(
                        onPressed: disabled ? null : onChoose,
                        child: Text(processing ? (statusLabel.isNotEmpty ? statusLabel : 'Please wait…') : 'Choose plan'),
                      ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_membership_outlined, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('No plans available right now', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 6),
            Text('Please check back shortly, or contact us and we will help you get set up.',
                style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
