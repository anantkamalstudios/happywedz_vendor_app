// "Improve with AI" step 1 (website dashboard/ImproveStorefront.jsx): what the
// vendor's HappyWedz storefront can give (About us, FAQs, social links) and
// "Use my storefront", which copies them to GrowthOS (only when pressed).
// API: storefront → { description, faqs, photos, service_text, social_links };
// useStorefront → the GrowthOS facts { description, faqs, logo_url, cover_url, social_links }.
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'improve_utils.dart';

String _faqWord(int n) => '$n ${n == 1 ? 'FAQ' : 'FAQs'}';

const Map<String, String> _socialNames = {
  'facebook': 'Facebook',
  'instagram': 'Instagram',
  'linkedin': 'LinkedIn',
  'youtube': 'YouTube',
  'x': 'X',
};

/// The site names of a { facebook?, instagram?, … } links object, in a fixed order.
List<String> _linkNames(Object? links) {
  if (links is! Map) return const [];
  return _socialNames.keys
      .where((k) => links[k] is String && str(links[k]).isNotEmpty)
      .map((k) => _socialNames[k]!)
      .toList();
}

class ImproveStorefront extends StatefulWidget {
  final ImproveLoader storefront;

  /// The GrowthOS facts (saved, or the answer of "Use my storefront").
  final Map<String, dynamic>? facts;
  final ValueChanged<Map<String, dynamic>?> onUsed;

  const ImproveStorefront(
      {super.key,
      required this.storefront,
      required this.facts,
      required this.onUsed});

  @override
  State<ImproveStorefront> createState() => _ImproveStorefrontState();
}

class _ImproveStorefrontState extends State<ImproveStorefront> {
  bool _busy = false;
  Object? _error;
  String _message = '';

  Future<void> _use() async {
    setState(() {
      _busy = true;
      _error = null;
      _message = '';
    });
    try {
      final raw = await GoogleProfileApi.instance.useStorefront();
      if (!mounted) return;
      final answer = raw is Map ? mapOf(raw) : null;
      widget.onUsed(answer);
      final saved = answer?['faqs'] is List ? listOf(answer!['faqs']).length : 0;
      final savedLinks = _linkNames(answer?['social_links']);
      final linkNote = savedLinks.isNotEmpty
          ? ' Your ${savedLinks.join(', ')} ${savedLinks.length == 1 ? 'link is' : 'links are'} saved too; the AI offers to add them on Google under AI fixes when Google allows it for your business type.'
          : '';
      setState(() {
        _message = (str(answer?['description']).isNotEmpty
                ? 'Done. GrowthOS now has your description${saved > 0 ? ' and ${_faqWord(saved)}' : ''}. The AI uses them for your Google profile.'
                : "Sent. GrowthOS has no description from it yet; check your storefront's About us text.") +
            linkNote;
      });
    } catch (e) {
      if (!mounted || gpHandleLocked(context, e)) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sf = widget.storefront;
    if (sf.isLoading) return const GpLoadingLine('Loading your storefront…');
    if (sf.isError) {
      return ImproveLoadFailed(
        error: sf.error,
        fallback: "We couldn't load your storefront. Please try again.",
        onRetry: () => sf.reload(),
      );
    }
    final data = mapOf(sf.data);
    final description =
        data['description'] is String ? str(data['description']).trim() : '';
    final faqs = listOf(data['faqs']);
    final links = _linkNames(data['social_links']);
    final used = str(widget.facts?['description']).isNotEmpty;

    if (description.isEmpty && faqs.isEmpty && links.isEmpty) {
      return GpStack(gap: 10, children: [
        const GpCallout(
          tone: GpTone.warn,
          text:
              'Your storefront has no About us text, FAQs or social links yet. Add them to your storefront first, then come back here.',
        ),
        GpButton.ghost(
          label: 'Open my storefront',
          icon: Icons.open_in_new,
          onPressed: () => gpOpenStorefront(context),
        ),
      ]);
    }

    return GpStack(gap: 14, children: [
      const Text(
          "The AI writes a better Google description when it knows your business. This copies your storefront's About us text, FAQs and social links to GrowthOS. Nothing is copied until you press the button.",
          style: GpText.note),
      ImproveAiBox(label: 'What will be sent', children: [
        GpStack(gap: 4, children: [
          const Text('About us', style: GpText.note),
          description.isNotEmpty
              ? Text(description,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13.5, height: 1.4, color: AppColors.textPrimary))
              : const Text('No About us text', style: GpText.muted),
        ]),
        Text(
            faqs.isNotEmpty
                ? '${_faqWord(faqs.length)} from your storefront'
                : 'No FAQs on your storefront',
            style: GpText.note),
        if (links.isNotEmpty)
          Text('Social links: ${links.join(', ')}', style: GpText.note)
        else
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
            const Text('No Facebook, Instagram or X links on your storefront. ',
                style: GpText.note),
            GpLink('Add them', onTap: () => gpOpenStorefront(context)),
          ]),
      ]),
      ImproveError(_error),
      if (_message.isNotEmpty) GpCallout(tone: GpTone.ok, text: _message),
      GpButtons(children: [
        GpButton(
          label: _busy
              ? 'Sending…'
              : used
                  ? 'Update from my storefront'
                  : 'Use my storefront',
          icon: Icons.cloud_upload_outlined,
          busy: _busy,
          onPressed: _busy ? null : _use,
        ),
        GpLink('Edit my storefront', onTap: () => gpOpenStorefront(context)),
      ]),
    ]);
  }
}
