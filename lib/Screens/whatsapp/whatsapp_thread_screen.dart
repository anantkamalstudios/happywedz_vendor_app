import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/whatsapp_icon.dart';
import '../crm/crm_widgets.dart';
import 'whatsapp_common.dart';

/// One conversation, with the composer pinned above the keyboard.
///
/// Which box the vendor gets is not a preference: inside the 24-hour window
/// WhatsApp allows free text, outside it only an approved template. So the
/// screen offers whichever is actually possible, and says which, instead of
/// letting a message be typed and refused.
class WhatsAppThreadScreen extends ConsumerStatefulWidget {
  final String conversationKey;
  final String title;

  const WhatsAppThreadScreen({
    super.key,
    required this.conversationKey,
    this.title = '',
  });

  @override
  ConsumerState<WhatsAppThreadScreen> createState() =>
      _WhatsAppThreadScreenState();
}

class _WhatsAppThreadScreenState extends ConsumerState<WhatsAppThreadScreen> {
  final _api = CrmApi();
  final _text = TextEditingController();
  Map? _thread;
  String _error = '';
  String _sendError = '';
  bool _sending = false;
  Timer? _poll;

  /// Approved templates, one per name — the only way to write outside the
  /// window, so they are needed here rather than on another screen.
  List<Map> _templates = const [];

  @override
  void initState() {
    super.initState();
    _text.addListener(() {
      if (_sendError.isNotEmpty) _sendError = '';
      setState(() {});
    });
    _scroll.addListener(_onScroll);
    _open();
    // Keep the conversation moving, or a reply arriving mid-read would not
    // show until it was closed and opened again.
    _poll = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _load(quiet: true),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    await _load();
    if (!mounted || _thread == null) return;
    // Only what was in it when it was opened. Anything arriving while it is
    // open stays unread until it has actually been looked at.
    _api
        .whatsappConversationSeen(widget.conversationKey)
        .catchError((_) => <String, dynamic>{});
    try {
      final temps = await _api.whatsappTemplates();
      if (!mounted) return;
      setState(
        () => _templates = waUniqueByName(
          waApproved(List.from(temps['templates'] ?? const [])),
        ),
      );
    } catch (_) {}
  }

  Future<void> _load({bool quiet = false}) async {
    try {
      final data = await _api.whatsappConversation(widget.conversationKey);
      if (!mounted) return;
      setState(() {
        _thread = data['conversation'] as Map?;
        _error = '';
      });
    } catch (e) {
      if (!mounted || quiet) return;
      final msg = waHandleError(
        context,
        ref,
        e,
        'Could not open this conversation.',
      );
      if (msg != null) setState(() => _error = msg);
    }
  }

  Future<void> _sendText() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
      _sendError = '';
    });
    try {
      await _api.whatsappConversationReply(widget.conversationKey, {
        'text': text,
      });
      if (!mounted) return;
      _text.clear();
      await _load(quiet: true);
    } catch (e) {
      if (!mounted) return;
      final msg = waHandleError(context, ref, e, 'Could not send that.');
      if (msg != null) setState(() => _sendError = msg);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendTemplate() async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _TemplateSheet(
        templates: _templates,
        notAClient: _thread?['clientId'] == null,
        send: (name, values) => _api.whatsappConversationTemplate(
          widget.conversationKey,
          {'templateName': name, 'variables': values},
        ),
      ),
    );
    if (!mounted || sent != true) return;
    waToast(context, 'Template sent.');
    _load(quiet: true);
  }

  Future<void> _openMedia(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      waToast(context, 'Could not open the attachment.');
    }
  }

  // ---------------------------------------------------------------- look
  //
  // Laid out like WhatsApp — patterned wallpaper, tailed bubbles with the
  // time and ticks inside them, a pill composer with a round send button —
  // but coloured from the app's own palette: every shade below is the app's
  // primary blue mixed into white, so the screen still reads as HappyWedz.

  static final Color _wallpaper =
      Color.alphaBlend(AppColors.primary.withValues(alpha: 0.06), Colors.white);
  static final Color _outgoing =
      Color.alphaBlend(AppColors.primary.withValues(alpha: 0.15), Colors.white);
  static const Color _incoming = Colors.white;

  final ScrollController _scroll = ScrollController();
  bool _showJump = false;

  void _onScroll() {
    // The list is reversed, so 0 is the newest message.
    final away = _scroll.hasClients && _scroll.offset > 400;
    if (away != _showJump) setState(() => _showJump = away);
  }

  void _jumpToLatest() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  /// "Today", "Yesterday", or the date — the chip between days.
  String _dayLabel(dynamic at) {
    final d = waParse(at);
    if (d == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return waDayOf(d);
  }

  @override
  Widget build(BuildContext context) {
    final t = _thread;
    final name = '${t?['name'] ?? ''}'.isNotEmpty
        ? '${t!['name']}'
        : '${t?['number'] ?? widget.title}';
    return Scaffold(
      backgroundColor: _wallpaper,
      appBar: _appBar(t, name.isEmpty ? 'Conversation' : name),
      body: t == null
          ? (_error.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: WaErrorBox(_error, onRetry: _open),
                    ),
                  )
                : const ListShimmer(showAvatar: false, itemHeight: 56))
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: CustomPaint(painter: _WallpaperPainter()),
                      ),
                      _messages(t),
                      if (_showJump)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 3,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _jumpToLatest,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.keyboard_double_arrow_down,
                                    color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SafeArea(top: false, child: _composer(t)),
              ],
            ),
    );
  }

  /// WhatsApp's header: back, photo, name with the number underneath.
  PreferredSizeWidget _appBar(Map? t, String name) {
    final number = '${t?['number'] ?? ''}';
    final subtitle = [
      if (number.isNotEmpty && number != name) number,
      if (t != null && t['clientId'] == null) 'not a client yet',
    ].join(' · ');
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 1,
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.white,
            child: Text(
              name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messages(Map t) {
    final messages = List.from(
      t['messages'] ?? const [],
    ).whereType<Map>().toList();
    final failed = messages.where((m) => m['status'] == 'failed').toList();
    final lastError = messages
        .where((m) => '${m['error'] ?? ''}'.isNotEmpty)
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: messages.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 40),
                Center(child: _systemChip('No messages yet')),
              ],
            )
          : ListView.builder(
              controller: _scroll,
              // Newest at the bottom, and the list opens there.
              reverse: true,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              itemCount: messages.length + (failed.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                if (failed.isNotEmpty) {
                  if (index == 0) {
                    // Once, where it is acted on.
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Center(
                        child: _systemChip(
                          lastError.isNotEmpty
                              ? '${lastError.last['error']}'
                              : 'Some of these did not send.',
                          error: true,
                        ),
                      ),
                    );
                  }
                  index -= 1;
                }
                final i = messages.length - 1 - index;
                final m = messages[i];
                final prev = i > 0 ? messages[i - 1] : null;
                final newDay =
                    prev == null || waDayOf(m['at']) != waDayOf(prev['at']);
                // A run of messages from the same side gets one tail, on the
                // first of them, as in WhatsApp.
                final firstOfRun = newDay ||
                    (prev['direction'] == 'in') != (m['direction'] == 'in');
                return Column(
                  children: [
                    if (newDay)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: _systemChip(_dayLabel(m['at'])),
                      ),
                    _bubble(m, tail: firstOfRun),
                  ],
                );
              },
            ),
    );
  }

  /// The centred pill for dates and notices.
  Widget _systemChip(String text, {bool error = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: error ? AppColors.errorTint : Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1)),
      ],
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12.5,
        color: error ? AppColors.error : AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  /// WhatsApp's ticks: one grey for sent, two grey for delivered, two blue
  /// for read; a clock while queued and a red mark when it failed.
  Widget _tick(dynamic status) {
    switch (status) {
      case 'queued':
        return const Icon(Icons.schedule, size: 14, color: AppColors.textTertiary);
      case 'sent':
        return const Icon(Icons.done, size: 15, color: AppColors.textTertiary);
      case 'delivered':
        return const Icon(Icons.done_all, size: 15, color: AppColors.textTertiary);
      case 'read':
        return const Icon(Icons.done_all, size: 15, color: AppColors.primaryLight);
      case 'failed':
        return const Icon(Icons.error_outline, size: 14, color: AppColors.error);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _bubble(Map m, {required bool tail}) {
    final ours = m['direction'] != 'in';
    final body = '${m['body'] ?? ''}';
    final media = '${m['mediaUrl'] ?? ''}';
    final actor = ours ? '${m['actorName'] ?? ''}' : '';
    final template = '${m['template'] ?? ''}';
    final color = ours ? _outgoing : _incoming;

    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          waTimeOf(m['at']),
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        if (ours) ...[const SizedBox(width: 3), _tick(m['status'])],
      ],
    );

    // Room reserved at the end of the text so the time sits inline on the
    // last line, the way WhatsApp places it.
    final reserve = ours ? 74.0 : 56.0;

    final content = <Widget>[
      if (actor.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            actor,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      if (template.isNotEmpty && body.isEmpty)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined,
                size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Template · $template',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      if (media.isNotEmpty)
        InkWell(
          onTap: () => _openMedia(media),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insert_drive_file_outlined,
                    size: 22, color: AppColors.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${m['mediaType'] ?? ''}'.isNotEmpty
                        ? '${m['mediaType']}'
                        : 'Attachment',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.open_in_new,
                    size: 15, color: AppColors.primary),
              ],
            ),
          ),
        ),
      if (body.isNotEmpty)
        SelectableText.rich(
          TextSpan(
            text: body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.3,
              color: AppColors.textPrimary,
            ),
            children: [WidgetSpan(child: SizedBox(width: reserve, height: 1))],
          ),
        ),
      if (body.isEmpty && media.isEmpty && template.isEmpty)
        Text(
          '${m['kind'] ?? ''}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      // Anything without free text still needs a line for the time.
      if (body.isEmpty) const SizedBox(height: 14),
    ];

    final radius = BorderRadius.only(
      topLeft: Radius.circular(!ours && tail ? 0 : 10),
      topRight: Radius.circular(ours && tail ? 0 : 10),
      bottomLeft: const Radius.circular(10),
      bottomRight: const Radius.circular(10),
    );

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
        minWidth: reserve + 16,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 1.5, offset: Offset(0, 1)),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 6, 9, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: content,
            ),
          ),
          Positioned(right: 8, bottom: 5, child: meta),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        top: tail ? 6 : 1.5,
        left: ours ? 48 : 0,
        right: ours ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            ours ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The tail, or the same width of nothing so a run stays aligned.
          if (!ours)
            SizedBox(
              width: 8,
              height: 12,
              child: tail
                  ? CustomPaint(painter: _TailPainter(color, left: true))
                  : null,
            ),
          Flexible(child: bubble),
          if (ours)
            SizedBox(
              width: 8,
              height: 12,
              child: tail
                  ? CustomPaint(painter: _TailPainter(color, left: false))
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _composer(Map t) {
    final replyable = '${t['key'] ?? widget.conversationKey}'.startsWith('p-');
    final window = t['window'] as Map?;
    final canWrite = window?['open'] == true;
    final line = waWindowLine(window);
    final hasText = _text.text.trim().isNotEmpty;

    if (!replyable) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Center(
          child: _systemChip(
            'This conversation has no phone number we can reply to — Wapzio '
            'sent an id rather than a number.',
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_sendError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _systemChip(_sendError, error: true),
            ),
          // Inside the window the line says when it closes; outside it says
          // why only a template is possible.
          if (line != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _systemChip(line),
            ),
          if (canWrite)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Send a template',
                          onPressed: _templates.isEmpty ? null : _sendTemplate,
                          icon: const Icon(Icons.description_outlined,
                              color: AppColors.textSecondary),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _text,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(fontSize: 15.5),
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _roundButton(
                  onTap: _sending || !hasText ? null : _sendText,
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_clock_outlined,
                            size: 18, color: AppColors.textTertiary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Send a template to start',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _roundButton(
                  onTap: _sendTemplate,
                  child: const WhatsAppIcon(size: 22, color: Colors.white),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// WhatsApp's round send button, in the app's primary colour.
  Widget _roundButton({required VoidCallback? onTap, required Widget child}) {
    return Material(
      color: onTap == null
          ? AppColors.primary.withValues(alpha: 0.45)
          : AppColors.primary,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 48, height: 48, child: Center(child: child)),
      ),
    );
  }
}

/// The small curved point on the first bubble of a run.
class _TailPainter extends CustomPainter {
  final Color color;
  final bool left;
  const _TailPainter(this.color, {required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path();
    if (left) {
      path
        ..moveTo(w, 0)
        ..lineTo(0, 0)
        ..quadraticBezierTo(w * 0.55, h * 0.35, w, h)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..quadraticBezierTo(w * 0.45, h * 0.35, 0, h)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) =>
      old.color != color || old.left != left;
}

/// A faint repeating doodle behind the chat, like WhatsApp's wallpaper, in
/// the app's primary blue at a few percent.
class _WallpaperPainter extends CustomPainter {
  const _WallpaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const step = 64.0;
    var row = 0;
    for (double y = 12; y < size.height + step; y += step, row++) {
      final shift = row.isOdd ? step / 2 : 0.0;
      var col = 0;
      for (double x = 12 + shift; x < size.width + step; x += step, col++) {
        final o = Offset(x, y);
        switch ((row + col) % 3) {
          case 0: // heart
            final p = Path()
              ..moveTo(o.dx, o.dy + 5)
              ..cubicTo(o.dx - 9, o.dy - 2, o.dx - 3, o.dy - 9, o.dx, o.dy - 3)
              ..cubicTo(o.dx + 3, o.dy - 9, o.dx + 9, o.dy - 2, o.dx, o.dy + 5);
            canvas.drawPath(p, paint);
          case 1: // ring
            canvas.drawCircle(o, 5, paint);
            canvas.drawCircle(o.translate(4, -4), 2, paint);
          default: // sparkle
            canvas.drawLine(o.translate(-5, 0), o.translate(5, 0), paint);
            canvas.drawLine(o.translate(0, -5), o.translate(0, 5), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Choosing an approved template and its values, then sending it.
class _TemplateSheet extends ConsumerStatefulWidget {
  final List<Map> templates;
  final bool notAClient;
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, String> values,
  )
  send;

  const _TemplateSheet({
    required this.templates,
    required this.notAClient,
    required this.send,
  });

  @override
  ConsumerState<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends ConsumerState<_TemplateSheet> {
  final _draft = WaTemplateDraft();
  bool _sending = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _draft.addListener(() {
      if (_error.isNotEmpty) _error = '';
      setState(() {});
    });
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_draft.name.isEmpty) return;
    setState(() {
      _sending = true;
      _error = '';
    });
    try {
      await widget.send(_draft.name, _draft.values);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = waHandleError(context, ref, e, 'Could not send that.');
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Send a template', style: AppTextStyles.h3),
              const SizedBox(height: 10),
              if (_error.isNotEmpty) WaErrorBox(_error),
              WaTemplateFields(templates: widget.templates, draft: _draft),
              if (widget.notAClient)
                const WaHint('This number is not one of your clients yet.'),
              const SizedBox(height: 6),
              CrmFormButtons(
                primaryLabel: 'Send template',
                onPrimary: _draft.name.isEmpty ? null : _send,
                busy: _sending,
                busyLabel: 'Sending…',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
