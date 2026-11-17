// Screen 1 of the Google Profile setup (website StartScreen.jsx): what will be
// sent, the working hours (HappyWedz does not keep them), the vendor's answer
// about an existing Google profile, and consent.
//
// RD-23 "Use a different email for this business": with [askOwnerEmail] the
// form also asks for the email of the new GrowthOS account (sent as
// owner_email). It must differ from every email in [blockedEmails].
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'gp_format.dart';
import 'gp_parts.dart';
import '../../widgets/google_glyph.dart';

class _Answer {
  final String id;
  final String label;
  final String help;
  const _Answer(this.id, this.label, this.help);
}

const _answers = [
  _Answer('yes', 'Yes, I have one',
      "You'll sign in with Google and pick it. Nothing new is created."),
  _Answer('no', 'No, create one for me',
      'GrowthOS creates it on your own Google account from the details above.'),
  _Answer('unsure', "I'm not sure",
      'GrowthOS checks Google for a matching profile before creating a new one.'),
];

class _Benefit {
  final IconData icon;
  final String title;
  final String text;
  const _Benefit(this.icon, this.title, this.text);
}

const _benefits = [
  _Benefit(Icons.search, 'Found on Google Search and Maps',
      'Your business with photos, hours, phone and directions.'),
  _Benefit(Icons.star_border, 'Google reviews in one place',
      'Read reviews and reply to them from GrowthOS.'),
  _Benefit(Icons.trending_up, 'Posts and profile help',
      'GrowthOS suggests posts and fixes for your profile. You approve each one.'),
  _Benefit(Icons.lock_outline, 'Your profile, your account',
      'The profile is created in your own Google account. GrowthOS never owns it.'),
];

class GpStartScreen extends StatefulWidget {
  final Map<String, dynamic> view;
  final bool busy;
  final Map<String, dynamic>? problem;
  final ValueChanged<Map<String, dynamic>> onSubmit;
  final bool askOwnerEmail;
  final List<String> blockedEmails;
  final VoidCallback? onBack;

  const GpStartScreen({
    super.key,
    required this.view,
    required this.busy,
    required this.problem,
    required this.onSubmit,
    this.askOwnerEmail = false,
    this.blockedEmails = const [],
    this.onBack,
  });

  @override
  State<GpStartScreen> createState() => _GpStartScreenState();
}

class _GpStartScreenState extends State<GpStartScreen> {
  late String _opening;
  late String _closing;
  late List<String> _closedDays;
  late String _answer;
  bool _consent = false;
  final _email = TextEditingController();
  bool _emailTouched = false;

  Map<String, dynamic> get _storefront => mapOf(widget.view['storefront']);

  @override
  void initState() {
    super.initState();
    final hours = mapOf(_storefront['hours']);
    _opening = toTimeInput(hours['opening_time']);
    _closing = toTimeInput(hours['closing_time']);
    _closedDays = listOf(hours['weekly_off'])
        .map((e) => '$e')
        .where(gpWeekdayIds.contains)
        .toList();
    final a = str(mapOf(widget.view['answer'])['has_google_profile']);
    _answer = a.isNotEmpty ? a : 'no';
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _toggleDay(String day) => setState(() => _closedDays.contains(day)
      ? _closedDays.remove(day)
      : _closedDays.add(day));

  Widget _fact(String label, Object? value, {String? note}) {
    final v = str(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label, style: GpText.note)),
        Expanded(
          child: GpStack(gap: 2, children: [
            v.isNotEmpty
                ? Text(v, style: GpText.lead)
                : const Text('Not added', style: GpText.muted),
            if (note != null) Text(note, style: GpText.note),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storefront = _storefront;
    final missing = listOf(storefront['missing']);
    final hoursMissing = _opening.isEmpty || _closing.isEmpty;
    final allClosed = _closedDays.length == gpWeekdays.length;

    final cleanEmail = _email.text.trim();
    var emailError = '';
    if (widget.askOwnerEmail) {
      final blocked = widget.blockedEmails
          .where((e) => sameEmail(e, cleanEmail))
          .cast<String?>()
          .firstWhere((_) => true, orElse: () => null);
      if (cleanEmail.isEmpty) {
        emailError = 'Enter the email for GrowthOS.';
      } else if (!isEmail(cleanEmail)) {
        emailError = 'Enter a valid email, like name@example.com.';
      } else if (blocked != null) {
        emailError = 'Use a different email from $blocked.';
      }
    }
    final showEmailError = emailError.isNotEmpty && _emailTouched;

    var hint = '';
    if (missing.isNotEmpty) {
      hint = 'Add the missing details in Storefront first.';
    } else if (emailError.isNotEmpty) {
      hint = emailError;
    } else if (hoursMissing) {
      hint = 'Add your opening and closing time.';
    } else if (allClosed) {
      hint = 'Leave at least one day open.';
    } else if (!_consent) {
      hint = 'Tick the box above to continue.';
    }
    final canSubmit = hint.isEmpty && !widget.busy;

    final category = str(storefront['category']);
    final searchExample = category.isNotEmpty
        ? '"${category.toLowerCase()} near me"'
        : '"wedding vendors near me"';
    final sfEmail = str(storefront['email']);

    return Column(children: [
      GpCard(
        tint: true,
        child: GpStack(gap: 16, children: [
          if (widget.view['disconnected'] == true)
            const GpCallout(
                tone: GpTone.alert,
                text: 'Your GrowthOS connection was removed. Set it up again below.'),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12)),
              child: const GoogleGlyph(size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GpStack(gap: 6, children: [
                Text(
                    widget.askOwnerEmail
                        ? 'USE A DIFFERENT EMAIL'
                        : 'NEW ON HAPPYWEDZ',
                    style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPink)),
                const Text('Show up when couples search on Google and Maps',
                    style: GpText.h2),
              ]),
            ),
          ]),
          Text(
              'Couples search $searchExample on Google. Set up your Google Business Profile from your HappyWedz storefront. GrowthOS does the setup, and the profile stays in your own Google account.',
              style: GpText.lead),
          GpStack(gap: 8, children: [
            const Text("We'll use these details from your storefront",
                style: GpText.h3),
            _fact('Business name', storefront['business_name']),
            _fact('Category', storefront['category']),
            _fact('Owner', storefront['owner_name']),
            _fact('Email', storefront['email'],
                note: sfEmail.isEmpty
                    ? null
                    : widget.askOwnerEmail
                        ? 'Your HappyWedz login. It does not change.'
                        : 'Your GrowthOS account uses this email'),
            _fact('Mobile', storefront['mobile']),
            _fact('Address', storefront['address']),
            _fact('Website', storefront['website']),
            GpLink('Something wrong? Edit it in Storefront first.',
                onTap: () => gpOpenStorefront(context)),
          ]),
          if (widget.askOwnerEmail)
            Focus(
              onFocusChange: (has) {
                if (!has) setState(() => _emailTouched = true);
              },
              child: GpTextField(
                label: 'Email for GrowthOS',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                maxLength: emailMax,
                helper:
                    'GrowthOS creates a new account for this business with this email and sends the set-password link there.',
                error: showEmailError ? emailError : null,
                onChanged: (_) => setState(() {}),
              ),
            ),
          if (missing.isNotEmpty)
            GpCallout(
              tone: GpTone.alert,
              title: 'Add these to your storefront first:',
              child: GpStack(gap: 2, children: [
                for (final item in missing)
                  GpLink(
                    str(mapOf(item)['label']).isNotEmpty
                        ? str(mapOf(item)['label'])
                        : str(mapOf(item)['field']),
                    onTap: () => gpOpenStorefront(context),
                  ),
              ]),
            ),
          GpStack(gap: 10, children: [
            const Text('Working hours', style: GpText.h3),
            Row(children: [
              Expanded(
                child: GpTimeField(
                    label: 'Opening time',
                    value: _opening,
                    onChanged: (v) => setState(() => _opening = v)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GpTimeField(
                    label: 'Closing time',
                    value: _closing,
                    onChanged: (v) => setState(() => _closing = v)),
              ),
            ]),
            const Text('Closed days', style: GpText.label),
            GpDayPicker(
                selected: _closedDays, onToggle: _toggleDay, closedStyle: true),
            const Text(
                'Tap the days you are closed. Leave them all open if you work every day.',
                style: GpText.note),
          ]),
          GpStack(gap: 8, children: [
            const Text('Do you already have a Google Business Profile?',
                style: GpText.h3),
            Column(children: [
              for (final o in _answers)
                GpChoice(
                  selected: _answer == o.id,
                  title: o.label,
                  subtitle: o.help,
                  onTap: () => setState(() => _answer = o.id),
                ),
            ]),
          ]),
          GpCheck(
            value: _consent,
            onChanged: (v) => setState(() => _consent = v),
            label: GpStack(gap: 4, children: [
              Text(str(widget.view['consent_text']), style: GpText.lead),
              Wrap(spacing: 12, children: [
                GpLink('GrowthOS Terms of Service',
                    onTap: () => gpOpenUrl(context, growthosTermsUrl)),
                GpLink('Privacy Policy',
                    onTap: () => gpOpenUrl(context, growthosPrivacyUrl)),
              ]),
            ]),
          ),
          if (widget.problem != null) _SetupProblem(problem: widget.problem!),
          GpStack(gap: 8, children: [
            GpButton(
              label: 'Set up my Google profile',
              icon: Icons.arrow_forward,
              busy: widget.busy,
              expand: true,
              onPressed: canSubmit
                  ? () => widget.onSubmit({
                        'has_google_profile': _answer,
                        'opening_time': _opening,
                        'closing_time': _closing,
                        'weekly_off':
                            gpWeekdayIds.where(_closedDays.contains).toList(),
                        'consent': true,
                        if (widget.askOwnerEmail) 'owner_email': cleanEmail,
                      })
                  : null,
            ),
            if (widget.onBack != null)
              GpButton.ghost(
                  label: 'Back to the choices',
                  expand: true,
                  onPressed: widget.busy ? null : widget.onBack),
            if (hint.isNotEmpty && !widget.busy) Text(hint, style: GpText.note),
          ]),
        ]),
      ),
      GpCard(
        child: GpStack(children: [
          const Text('What you get', style: GpText.h3),
          for (final b in _benefits)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(b.icon, size: 22, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: GpStack(gap: 2, children: [
                  Text(b.title, style: GpText.label),
                  Text(b.text, style: GpText.note),
                ]),
              ),
            ]),
          const Divider(color: AppColors.divider),
          const Row(children: [
            Icon(Icons.trending_up, size: 18, color: AppColors.accentPink),
            SizedBox(width: 8),
            Expanded(
              child: Text.rich(TextSpan(style: GpText.note, children: [
                TextSpan(text: 'Set up by '),
                TextSpan(
                    text: 'GrowthOS AI',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: ', a HappyWedz partner'),
              ])),
            ),
          ]),
        ]),
      ),
    ]);
  }
}

/// Why the last "Set up" press did not go through.
class _SetupProblem extends StatelessWidget {
  final Map<String, dynamic> problem;
  const _SetupProblem({required this.problem});

  @override
  Widget build(BuildContext context) {
    final fields = listOf(problem['fields']);
    return GpCallout(
      tone: GpTone.bad,
      title: str(problem['message']),
      child: fields.isEmpty
          ? null
          : GpStack(gap: 4, children: [
              for (final raw in fields)
                Builder(builder: (context) {
                  final f = mapOf(raw);
                  final label =
                      str(f['label']).isNotEmpty ? str(f['label']) : str(f['path']);
                  final message = str(f['message']);
                  return GpStack(gap: 0, children: [
                    Text.rich(TextSpan(style: GpText.lead, children: [
                      TextSpan(
                          text: label,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (message.isNotEmpty) TextSpan(text: ': $message'),
                    ])),
                    if (str(f['fix_url']).isNotEmpty)
                      GpLink('Fix it in Storefront',
                          onTap: () => gpOpenStorefront(context)),
                  ]);
                }),
            ]),
    );
  }
}
