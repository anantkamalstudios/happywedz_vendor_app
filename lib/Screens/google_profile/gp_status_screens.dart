// Screens 2 to 5 of the Google Profile setup, the "email already in GrowthOS"
// choices and the Owner's approval (website StatusScreens.jsx).
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'gp_format.dart';
import 'gp_parts.dart';
import 'gp_setup_verify.dart';

String _ownerEmail(Map<String, dynamic> view) {
  final g = str(mapOf(view['growthos'])['owner_email']);
  if (g.isNotEmpty) return g;
  final s = str(mapOf(view['storefront'])['email']);
  return s.isNotEmpty ? s : 'your email';
}

String gpBusinessName(Map<String, dynamic> view) {
  final g = str(mapOf(view['growthos'])['profile_title']);
  if (g.isNotEmpty) return g;
  final s = str(mapOf(view['storefront'])['business_name']);
  return s.isNotEmpty ? s : 'Your business';
}

String gpProfileLine(Map<String, dynamic> view) =>
    mapOf(view['growthos'])['created_by_growthos'] == true
        ? 'Created by GrowthOS in your Google account'
        : 'Your Google Business Profile, connected to GrowthOS';

/// "I've set my password" / "I've connected it" / "Check again".
class GpRefreshButton extends StatelessWidget {
  final String label;
  final bool busy;
  final bool disabled;
  final bool primary;
  final VoidCallback onPressed;
  const GpRefreshButton(
      {super.key,
      required this.label,
      required this.busy,
      required this.disabled,
      required this.onPressed,
      this.primary = false});

  @override
  Widget build(BuildContext context) => GpButton(
        label: label,
        icon: Icons.refresh,
        primary: primary,
        busy: busy,
        onPressed: (busy || disabled) ? null : onPressed,
      );
}

/// "Send the email again" / "Send a new link", held back until resend_available_at.
class _ResendButton extends StatelessWidget {
  final String label;
  final String? waitUntil;
  final bool busy;
  final bool primary;
  final VoidCallback onResend;
  const _ResendButton(
      {required this.label,
      required this.waitUntil,
      required this.busy,
      required this.onResend,
      this.primary = false});

  @override
  Widget build(BuildContext context) {
    final waiting = waitUntil != null;
    return GpButton(
      label: waiting ? 'You can send it again at ${formatClock(waitUntil)}' : label,
      icon: Icons.mail_outline,
      primary: primary,
      busy: busy,
      onPressed: (busy || waiting) ? null : onResend,
    );
  }
}

class GpInvitedScreen extends StatelessWidget {
  final Map<String, dynamic> view;
  final String? busy;
  final String? resendWait;
  final VoidCallback onRefresh;
  final VoidCallback onResend;
  const GpInvitedScreen(
      {super.key,
      required this.view,
      required this.busy,
      required this.resendWait,
      required this.onRefresh,
      required this.onResend});

  @override
  Widget build(BuildContext context) {
    final email = _ownerEmail(view);
    final sfName = str(mapOf(view['storefront'])['business_name']);
    final name = sfName.isNotEmpty ? sfName : 'your business';
    return Column(children: [
      GpCard(
        child: GpStack(children: [
          const GpCallout(text: 'Your details were sent to GrowthOS.'),
          const Text('Check your email to set your password', style: GpText.h2),
          Text.rich(TextSpan(style: GpText.lead, children: [
            const TextSpan(text: 'GrowthOS emailed '),
            TextSpan(text: email, style: const TextStyle(fontWeight: FontWeight.w600)),
            const TextSpan(
                text:
                    ". Open the email, set a password, and you'll go straight to connecting Google. The link works for 7 days."),
          ])),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: GpStack(gap: 4, children: [
              const Text('From: GrowthOS AI · no-reply@gmb.aslai.cloud',
                  style: GpText.muted),
              Text('Your GrowthOS account for $name is ready',
                  style: GpText.label),
              Text(
                  'HappyWedz set up a GrowthOS account for $name, with you as the Owner. [Set your password]',
                  style: GpText.note),
            ]),
          ),
          GpButtons(children: [
            GpRefreshButton(
                label: "I've set my password",
                primary: true,
                busy: busy == 'refresh',
                disabled: busy != null,
                onPressed: onRefresh),
            _ResendButton(
                label: 'Send the email again',
                waitUntil: resendWait,
                busy: busy == 'resend',
                onResend: onResend),
          ]),
          const Text(
              "Can't find it? Check spam or promotions. Wrong email? Contact HappyWedz support.",
              style: GpText.note),
        ]),
      ),
      const GpAsideCard(title: 'What happens next', children: [
        GpNumbered([
          'Set your GrowthOS password.',
          'Sign in with Google.',
          'Pick your profile, or let GrowthOS create it.',
          'Google verifies the new profile.',
        ]),
      ]),
    ]);
  }
}

class GpExpiredScreen extends StatelessWidget {
  final Map<String, dynamic> view;
  final String? busy;
  final String? resendWait;
  final VoidCallback onResend;
  const GpExpiredScreen(
      {super.key,
      required this.view,
      required this.busy,
      required this.resendWait,
      required this.onResend});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GpCard(
        child: GpStack(children: [
          const GpCallout(
              tone: GpTone.warn,
              text: 'The set-password link expired. Links work for 7 days.'),
          const Text('Get a new link', style: GpText.h2),
          Text.rich(TextSpan(style: GpText.lead, children: [
            const TextSpan(text: "We'll ask GrowthOS to email "),
            TextSpan(
                text: _ownerEmail(view),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const TextSpan(text: ' again. The old link stops working.'),
          ])),
          _ResendButton(
              label: 'Send a new link',
              primary: true,
              waitUntil: resendWait,
              busy: busy == 'resend',
              onResend: onResend),
        ]),
      ),
      const GpAsideCard(title: 'Your details are saved', children: [
        Text("You don't need to fill anything in again. Only the email link is new.",
            style: GpText.lead),
      ]),
    ]);
  }
}

class _ConnectWords {
  final String lead;
  final String asideTitle;
  final String aside;
  const _ConnectWords(this.lead, this.asideTitle, this.aside);
}

const _connectWords = {
  'yes': _ConnectWords(
    'You told us you already have a Google Business Profile. Connect the Google account that owns it, then pick it here. Nothing new is created.',
    'Picking your profile',
    'After you connect Google, we list the profiles in that Google account. Pick yours and nothing new is created.',
  ),
  'no': _ConnectWords(
    "You told us you don't have a Google Business Profile yet. Connect the Google account you want to own it. We fill in a new profile from your HappyWedz details. You check it, and it's created in your own Google account.",
    'Already have a profile?',
    'No problem. After you connect Google, we list the profiles in that Google account. Pick yours and nothing new is created.',
  ),
  'unsure': _ConnectWords(
    "You weren't sure if you have a Google Business Profile. Connect your Google account. We list the profiles in it, and check Google for a matching profile before creating a new one in your own Google account.",
    'Already have a profile?',
    'No problem. After you connect Google, we list the profiles in that Google account. Pick yours and nothing new is created.',
  ),
};

/// "Connect Google": gets the one-time link, then the browser goes to Google.
class GpConnectButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onConnect;
  final bool primary;
  final String label;
  const GpConnectButton(
      {super.key,
      required this.busy,
      required this.onConnect,
      this.primary = true,
      this.label = 'Connect Google'});

  @override
  Widget build(BuildContext context) => GpButton(
      label: label,
      icon: Icons.g_mobiledata_rounded,
      primary: primary,
      busy: busy,
      onPressed: busy ? null : onConnect);
}

class GpConnectScreen extends StatelessWidget {
  final Map<String, dynamic> view;
  final String? busy;
  final String? connectProblem;
  final VoidCallback onConnect;
  final VoidCallback onRefresh;
  const GpConnectScreen(
      {super.key,
      required this.view,
      required this.busy,
      required this.connectProblem,
      required this.onConnect,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final words = _connectWords[str(mapOf(view['answer'])['has_google_profile'])] ??
        _connectWords['no']!;
    return Column(children: [
      GpCard(
        tint: true,
        child: GpStack(children: [
          connectProblem != null
              ? GpCallout(tone: GpTone.bad, text: connectProblem)
              : const GpCallout(text: 'Your details were sent to GrowthOS.'),
          const Text('Connect your Google account', style: GpText.h2),
          Text(words.lead, style: GpText.lead),
          GpButtons(children: [
            GpConnectButton(busy: busy == 'connect', onConnect: onConnect),
            GpRefreshButton(
                label: "I've connected it",
                busy: busy == 'refresh',
                disabled: busy != null,
                onPressed: onRefresh),
          ]),
          const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.shield_outlined, size: 16, color: AppColors.textSecondary),
            SizedBox(width: 6),
            Expanded(
              child: Text.rich(TextSpan(style: GpText.note, children: [
                TextSpan(
                    text: 'GrowthOS AI',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(
                    text:
                        " is HappyWedz's Google partner. Google will ask you to allow it."),
              ])),
            ),
          ]),
          const Text(
              'Use the Google account you want to own the profile. A personal Gmail works.',
              style: GpText.note),
          const Text(
              'Google opens in your browser. Come back to the app when you are done and this page will update.',
              style: GpText.note),
        ]),
      ),
      GpAsideCard(title: words.asideTitle, children: [
        Text(words.aside, style: GpText.lead),
        const GpNumbered([
          'Press Connect Google and choose your Google account.',
          'Allow GrowthOS AI on Google\'s screen.',
          'Pick your profile, or create a new one here.',
          'Google verifies the profile.',
        ]),
      ]),
    ]);
  }
}

class GpVerifyScreen extends StatelessWidget {
  final Map<String, dynamic> view;
  final String? busy;
  final VoidCallback onRefresh;
  final Future<bool> Function([String? message]) onVerified;
  const GpVerifyScreen(
      {super.key,
      required this.view,
      required this.busy,
      required this.onRefresh,
      required this.onVerified});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GpCard(
        child: GpStack(children: [
          GpProfileHead(
            name: gpBusinessName(view),
            line: gpProfileLine(view),
            chips: const [GpChip('Google is verifying', tone: GpTone.warn)],
          ),
          const Text(
              'Google needs to confirm your business before the profile shows on Search and Maps. Google chooses which ways it offers: a code by postcard, phone call, text message or email, or sometimes no code at all.',
              style: GpText.lead),
          GpSetupVerify(
              onVerified: onVerified,
              onRefresh: onRefresh,
              refreshing: busy == 'refresh'),
        ]),
      ),
      const GpAsideCard(title: 'How long does it take?', children: [
        Text(
            'A postcard can take a few days to arrive. Phone, text message and email codes are usually quicker. Some businesses are verified automatically.',
            style: GpText.lead),
      ]),
    ]);
  }
}

/// The slim line above the dashboard once the profile is live (website LiveScreen).
class GpLiveBar extends StatelessWidget {
  final Map<String, dynamic> view;
  const GpLiveBar({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final name = gpBusinessName(view);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
          child: Text(initials(name),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GpStack(gap: 4, children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const Wrap(spacing: 6, runSpacing: 4, children: [
              GpChip('Verified by Google', tone: GpTone.ok),
              GpChip('Managed with GrowthOS', color: AppColors.accentPink),
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// The email already has a GrowthOS account (RD-23).
class GpTakenScreen extends StatelessWidget {
  final Map<String, dynamic> view;
  final String loginUrl;
  final String? busy;
  final String? takenEmail;
  final String? problem;
  final VoidCallback onLinkExisting;
  final VoidCallback onUseOtherEmail;
  const GpTakenScreen(
      {super.key,
      required this.view,
      required this.loginUrl,
      required this.busy,
      required this.takenEmail,
      required this.problem,
      required this.onLinkExisting,
      required this.onUseOtherEmail});

  Widget _pick({
    required IconData icon,
    required String title,
    required String text,
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: AppColors.primaryTint, shape: BoxShape.circle),
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GpStack(gap: 3, children: [
                  Text(title, style: GpText.label),
                  Text(text, style: GpText.note),
                ]),
              ),
              const Icon(Icons.arrow_forward, size: 18, color: AppColors.textSecondary),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sfEmail = str(mapOf(view['storefront'])['email']);
    final loginEmail = sfEmail.isNotEmpty ? sfEmail : 'your login email';
    final shownEmail = takenEmail ?? _ownerEmail(view);
    final declined = view['link_declined'] == true;
    return Column(children: [
      GpCard(
        child: GpStack(children: [
          if (declined)
            const GpCallout(
                tone: GpTone.bad,
                title: 'The GrowthOS Owner declined the connection.'),
          GpCallout(
            tone: GpTone.bad,
            title: '$shownEmail already has a GrowthOS account.',
            text: "HappyWedz can't create a second one with the same email.",
          ),
          if (problem != null) GpCallout(tone: GpTone.bad, text: problem),
          const Text('Choose how to continue', style: GpText.h2),
          Column(children: [
            _pick(
              icon: Icons.link,
              title: 'Connect my existing GrowthOS account',
              text:
                  "If GrowthOS already has this business. We'll email $loginEmail to approve.",
              loading: busy == 'link',
              onTap: busy != null ? null : onLinkExisting,
            ),
            _pick(
              icon: Icons.alternate_email,
              title: 'Use a different email for this business',
              text:
                  'GrowthOS creates a new account with that email. Your HappyWedz login does not change.',
              loading: false,
              onTap: busy != null ? null : onUseOtherEmail,
            ),
          ]),
        ]),
      ),
      GpAsideCard(title: 'Why this happens', children: [
        const Text(
            'Each GrowthOS account needs its own email. This email was used for GrowthOS before, either directly or through another partner.',
            style: GpText.lead),
        const Text(
            'Not sure which business that account has? Sign in to GrowthOS with this email to check.',
            style: GpText.lead),
        GpButton.ghost(
          label: 'Sign in to GrowthOS',
          icon: Icons.open_in_new,
          onPressed: () => gpOpenUrl(context, loginUrl),
        ),
      ]),
    ]);
  }
}

/// RD-23: GrowthOS emailed the Owner of the existing account to approve.
class GpApproveScreen extends StatelessWidget {
  final Map<String, dynamic> view;
  final String? busy;
  final String? resendWait;
  final VoidCallback onRefresh;
  final VoidCallback onResend;
  const GpApproveScreen(
      {super.key,
      required this.view,
      required this.busy,
      required this.resendWait,
      required this.onRefresh,
      required this.onResend});

  @override
  Widget build(BuildContext context) {
    final request = mapOf(view['link_request']);
    final reqEmail = str(request['email']);
    final sfEmail = str(mapOf(view['storefront'])['email']);
    final email = reqEmail.isNotEmpty
        ? reqEmail
        : (sfEmail.isNotEmpty ? sfEmail : 'your email');
    final until = formatWhen(request['expires_at']);
    final expired = view['expired'] == true ||
        request['status'] == 'expired' ||
        (until.isNotEmpty && msUntil(request['expires_at']) == 0);

    if (expired) {
      return Column(children: [
        GpCard(
          child: GpStack(children: [
            const GpCallout(
                tone: GpTone.warn, text: 'The link expired. Send a new one.'),
            const Text('Get a new approval link', style: GpText.h2),
            Text.rich(TextSpan(style: GpText.lead, children: [
              const TextSpan(text: "We'll ask GrowthOS to email "),
              TextSpan(text: email, style: const TextStyle(fontWeight: FontWeight.w600)),
              const TextSpan(
                  text:
                      ' again. The link works for 7 days, and the old one stops working.'),
            ])),
            _ResendButton(
                label: 'Send a new link',
                primary: true,
                waitUntil: resendWait,
                busy: busy == 'resend',
                onResend: onResend),
          ]),
        ),
        const GpAsideCard(title: 'Your details are saved', children: [
          Text("You don't need to fill anything in again. Only the email link is new.",
              style: GpText.lead),
        ]),
      ]);
    }

    return Column(children: [
      GpCard(
        child: GpStack(children: [
          const GpCallout(text: 'We asked GrowthOS to connect your account.'),
          const Text('Check your email to approve', style: GpText.h2),
          Text.rich(TextSpan(style: GpText.lead, children: [
            const TextSpan(text: 'GrowthOS emailed '),
            TextSpan(text: email, style: const TextStyle(fontWeight: FontWeight.w600)),
            const TextSpan(text: '. Open the email and press '),
            const TextSpan(
                text: 'Review and approve',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const TextSpan(
                text: '. Only the Owner of the business in GrowthOS can approve.'),
          ])),
          Text(
              until.isNotEmpty
                  ? 'The link works until $until.'
                  : 'The link works for 7 days.',
              style: GpText.note),
          GpButtons(children: [
            GpRefreshButton(
                label: "I've approved it",
                primary: true,
                busy: busy == 'refresh',
                disabled: busy != null,
                onPressed: onRefresh),
            _ResendButton(
                label: 'Send the email again',
                waitUntil: resendWait,
                busy: busy == 'resend',
                onResend: onResend),
          ]),
          const Text("Can't find it? Check spam or promotions.", style: GpText.note),
        ]),
      ),
      const GpAsideCard(title: 'What happens next', children: [
        GpNumbered([
          'Open the email from GrowthOS.',
          'Sign in and approve HappyWedz.',
          'Come back here and press "I\'ve approved it".',
        ]),
        Text(
            'Nothing in your GrowthOS account is changed. You can disconnect HappyWedz at any time in GrowthOS Settings, under Connected partners.',
            style: GpText.note),
      ]),
    ]);
  }
}
