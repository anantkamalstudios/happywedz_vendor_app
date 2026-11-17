// Posts tab (website dashboard/PostsTab.jsx). Drafts, scheduled and published
// Google posts with a status filter; Write a post (with AI help, an image,
// publish now or schedule); edit a draft or a post on Google; cancel a
// schedule; delete with a check; refresh from Google.
// API: posts / deletePost / unschedulePost / syncGoogle (the editor is post_editor.dart).
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'post_editor.dart';
import 'posts_utils.dart';

const List<(String, String)> _filters = [
  ('', 'All'),
  ('draft', 'Drafts'),
  ('scheduled', 'Scheduled'),
  ('published', 'Published'),
];

class _Status {
  final String label;
  final GpTone? tone;
  const _Status(this.label, this.tone);
}

const Map<String, _Status> _statuses = {
  'draft': _Status('Draft', null),
  'scheduled': _Status('Scheduled', GpTone.warn),
  'publishing': _Status('Publishing', GpTone.warn),
  'published': _Status('Published', GpTone.ok),
};

const Map<String, String> _doneText = {
  'draft': 'Draft saved. It stays here until you publish or schedule it.',
  'published': 'Published on Google. Google may take a few minutes to show it.',
  'scheduled': 'Post scheduled. It goes on Google at the time you chose.',
  'updated':
      'Post updated on Google. Google may take a few minutes to show the change.',
  'unscheduled': 'Schedule cancelled. The post is a draft again.',
  'synced': 'Read from Google. Posts made on Google now show here too.',
  'deleted': 'Post deleted.',
};

class GpPostsTab extends StatefulWidget {
  final Map<String, dynamic> view;
  final void Function(String tabId) onOpenTab;
  final VoidCallback onChanged;

  const GpPostsTab(
      {super.key,
      required this.view,
      required this.onOpenTab,
      required this.onChanged});

  @override
  State<GpPostsTab> createState() => _GpPostsTabState();
}

class _GpPostsTabState extends State<GpPostsTab> {
  String _filter = '';
  String _status = 'loading'; // loading | ready | error
  List<Map<String, dynamic>> _posts = [];
  Object? _loadError;
  bool _reloading = false;
  String? _deletingId;
  String? _rowBusy;
  Object? _rowError;
  String _done = '';
  bool _syncing = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool quiet = false}) async {
    final mine = ++_request;
    setState(() {
      if (quiet) {
        _reloading = true;
      } else {
        _status = 'loading';
        _loadError = null;
      }
    });
    try {
      final page = await GoogleProfileApi.instance.posts(_filter);
      if (!mounted || mine != _request) return;
      setState(() {
        _status = 'ready';
        _posts = page.list.map(mapOf).toList();
        _loadError = null;
      });
    } catch (error) {
      if (!mounted || mine != _request) return;
      if (gpHandleLocked(context, error)) return;
      setState(() {
        if (quiet) _rowError = error;
        _status = quiet && _status == 'ready' ? 'ready' : 'error';
        _loadError = error;
      });
    } finally {
      if (mounted && mine == _request) setState(() => _reloading = false);
    }
  }

  void _setFilter(String id) {
    setState(() {
      _done = '';
      _rowError = null;
      _deletingId = null;
      _filter = id;
    });
    _load();
  }

  Future<void> _openEditor(Map<String, dynamic>? post) async {
    setState(() {
      _done = '';
      _rowError = null;
      _deletingId = null;
    });
    final kind = await openPostEditor(context, post: post);
    if (!mounted) return;
    if (kind != null && _doneText.containsKey(kind)) {
      setState(() => _done = _doneText[kind]!);
    }
    _load(quiet: true);
  }

  // "Refresh from Google": GrowthOS reads the profile and its posts now (once every 5 minutes).
  Future<void> _syncGoogle() async {
    setState(() {
      _syncing = true;
      _rowError = null;
      _done = '';
    });
    try {
      await GoogleProfileApi.instance.syncGoogle();
      if (!mounted) return;
      setState(() => _done = _doneText['synced']!);
      await _load(quiet: true);
    } catch (error) {
      if (!mounted) return;
      if (gpHandleLocked(context, error)) return;
      setState(() => _rowError = error);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _unschedule(Map<String, dynamic> post) async {
    setState(() {
      _rowBusy = str(post['id']);
      _rowError = null;
      _done = '';
    });
    try {
      await GoogleProfileApi.instance.unschedulePost(str(post['id']));
      if (!mounted) return;
      setState(() => _done = _doneText['unscheduled']!);
      await _load(quiet: true);
    } catch (error) {
      if (!mounted) return;
      if (gpHandleLocked(context, error)) return;
      setState(() => _rowError = error);
    } finally {
      if (mounted) setState(() => _rowBusy = null);
    }
  }

  Future<void> _remove() async {
    final id = _deletingId;
    if (id == null) return;
    setState(() {
      _rowBusy = id;
      _rowError = null;
    });
    try {
      await GoogleProfileApi.instance.deletePost(id);
      if (!mounted) return;
      setState(() {
        _deletingId = null;
        _done = _doneText['deleted']!;
      });
      await _load(quiet: true);
    } catch (error) {
      if (!mounted) return;
      if (gpHandleLocked(context, error)) return;
      setState(() => _rowError = error);
    } finally {
      if (mounted) setState(() => _rowBusy = null);
    }
  }

  Widget _writeButton() => GpButton(
        label: 'Write a post',
        icon: Icons.add,
        onPressed: () => _openEditor(null),
      );

  Widget _filterChip(String label,
      {required bool active, VoidCallback? onTap, Widget? leading}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: active ? AppColors.primary : AppColors.borderStrong),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (leading != null) ...[leading, const SizedBox(width: 6)],
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.textPrimary)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _filtersRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final f in _filters)
          _filterChip(f.$2,
              active: _filter == f.$1, onTap: () => _setFilter(f.$1)),
        _filterChip(
          _syncing ? 'Reading Google…' : 'Refresh from Google',
          active: false,
          onTap: _syncing ? null : _syncGoogle,
          leading: _syncing
              ? const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh, size: 15, color: AppColors.primary),
        ),
      ]),
    );
  }

  Widget _postCard(Map<String, dynamic> post) {
    final id = str(post['id']);
    final status = str(post['status']);
    final st = _statuses[status] ?? _statuses['draft']!;
    final googleState = str(post['google_state']);
    final rejected = status == 'published' && googleState == 'REJECTED';
    final reviewing = status == 'published' && googleState == 'PROCESSING';
    // A post made on Google (not in GrowthOS) can be seen and deleted, not changed.
    final fromGoogle = post['imported_from_google'] == true;
    final canEdit =
        !fromGoogle && (status == 'draft' || status == 'published');
    final canDelete = canEdit || fromGoogle;
    final busy = _rowBusy == id;
    final topic = str(post['topic']);
    final type = str(post['post_type']);
    final cta = str(post['cta']);
    final imageUrl = str(post['image_url']);
    final description = str(post['description']);
    final publishError = str(post['publish_error']);
    final searchUrl = str(post['search_url']);

    final meta = [
      if (cta.isNotEmpty) 'Button: ${postsCtaLabels[cta] ?? cta}',
      if (status == 'published' && str(post['published_at']).isNotEmpty)
        'Published ${formatWhen(post['published_at'])}',
      if ((status == 'scheduled' || status == 'publishing') &&
          str(post['schedule_at']).isNotEmpty)
        'Goes live ${formatWhen(post['schedule_at'])}',
      if (str(post['updated_at']).isNotEmpty)
        'Updated ${formatWhen(post['updated_at'])}',
    ].join(' · ');

    return GpCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          imageUrl.isNotEmpty
              ? GpImage(
                  url: imageUrl,
                  width: 64,
                  height: 64,
                  borderRadius: BorderRadius.circular(10))
              : Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.article_outlined,
                      color: AppColors.primary, size: 22),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: GpStack(gap: 6, children: [
              Text(topic,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Wrap(spacing: 6, runSpacing: 6, children: [
                GpChip(st.label,
                    tone: st.tone,
                    color: st.tone == null ? AppColors.textSecondary : null),
                GpChip(postsTypeLabels[type] ?? type,
                    color: AppColors.accentPink),
                if (fromGoogle)
                  const GpChip('Made on Google', color: AppColors.textSecondary),
                if (post['ai_generated'] == true)
                  const GpChip('AI text', color: AppColors.textSecondary),
                if (rejected) const GpChip('Rejected by Google', tone: GpTone.bad),
                if (reviewing)
                  const GpChip('Google is reviewing it', tone: GpTone.warn),
              ]),
              if (meta.isNotEmpty) Text(meta, style: GpText.note),
            ]),
          ),
        ]),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GpText.lead),
        ],
        if (rejected) ...[
          const SizedBox(height: 8),
          const Text(
              'Google did not accept this post. A phone number in the text is a common reason (use the Call now button instead). Delete it and publish a corrected post.',
              style: GpText.error),
        ],
        if (status == 'draft' && publishError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(top: 1, right: 4),
              child: Icon(Icons.warning_amber_rounded,
                  size: 14, color: AppColors.error),
            ),
            Expanded(
                child: Text('Not published: $publishError',
                    style: GpText.error)),
          ]),
        ],
        const SizedBox(height: 12),
        if (_deletingId == id)
          PostsConfirmBox(
            danger: true,
            title: 'Delete “$topic”?',
            message: status == 'published'
                ? "It is also removed from your Google profile. This can't be undone."
                : "This can't be undone.",
            confirmLabel: 'Delete post',
            busy: busy,
            error: _rowError,
            onConfirm: _remove,
            onCancel: () => setState(() {
              _deletingId = null;
              _rowError = null;
            }),
          )
        else
          GpButtons(children: [
            if (status == 'published' && searchUrl.isNotEmpty)
              GpButton.ghost(
                small: true,
                label: 'View on Google',
                icon: Icons.open_in_new,
                onPressed: () => gpOpenUrl(context, searchUrl),
              ),
            if (status == 'scheduled')
              GpButton.ghost(
                small: true,
                label: 'Cancel schedule',
                icon: Icons.event_busy_outlined,
                busy: busy,
                onPressed: busy ? null : () => _unschedule(post),
              ),
            if (canEdit)
              GpButton.ghost(
                small: true,
                label: 'Edit',
                icon: Icons.edit_outlined,
                onPressed: busy ? null : () => _openEditor(post),
              ),
            if (canDelete)
              GpButton.ghost(
                small: true,
                danger: true,
                label: 'Delete',
                icon: Icons.delete_outline,
                onPressed: busy
                    ? null
                    : () => setState(() {
                          _rowError = null;
                          _done = '';
                          _deletingId = id;
                        }),
              ),
          ]),
      ]),
    );
  }

  List<Widget> _body() {
    if (_status == 'loading') {
      return const [GpCardsShimmer(count: 3, height: 120)];
    }
    if (_status == 'error') {
      return [
        PostsErrorNote(
            error: _loadError,
            fallback: "We couldn't load this. Please try again."),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: GpButton(
              label: 'Try again', icon: Icons.refresh, onPressed: () => _load()),
        ),
      ];
    }
    if (_posts.isEmpty) {
      final label = _filters
          .firstWhere((f) => f.$1 == _filter, orElse: () => _filters.first)
          .$2
          .toLowerCase();
      return [
        GpEmpty(
          icon: Icons.article_outlined,
          title: _filter.isNotEmpty ? 'No $label posts' : 'No posts yet',
          message: _filter.isNotEmpty
              ? 'Try another filter, or write a new post.'
              : "Posts tell people what's new: an update, an offer or an event. Write one and publish it now or later.",
          action: _writeButton(),
        ),
      ];
    }
    return [for (final p in _posts) _postCard(p)];
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
      onRefresh: () => _load(quiet: _status == 'ready'),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Expanded(
              child: GpStack(gap: 4, children: [
                Text('Google posts', style: GpText.h3),
                Text('Updates, offers and events shown on your Google profile.',
                    style: GpText.note),
              ]),
            ),
            if (_status == 'ready' && _posts.isNotEmpty) ...[
              const SizedBox(width: 10),
              _writeButton(),
            ],
          ]),
          const SizedBox(height: 14),
          _filtersRow(),
          if (_reloading) const GpLoadingLine('Refreshing…'),
          const SizedBox(height: 12),
          if (_done.isNotEmpty) ...[
            GpCallout(tone: GpTone.ok, text: _done),
            const SizedBox(height: 12),
          ],
          if (_rowError != null && _deletingId == null) ...[
            PostsErrorNote(error: _rowError),
            const SizedBox(height: 12),
          ],
          ..._body(),
        ],
      ),
    );
  }
}
