// Photos tab (website dashboard/PhotosTab.jsx). The profile's photos as of the
// last sync, with a category filter; add photos with Google's photo category
// (PNG, JPEG or WebP up to 5 MB, checked before sending); delete one with a
// check; refresh from Google.
// API: photos / addPhoto / deletePhoto / syncGoogle.
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_shimmer.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'photos_upload.dart';
import 'posts_utils.dart';

class GpPhotosTab extends StatefulWidget {
  final Map<String, dynamic> view;
  final void Function(String tabId) onOpenTab;
  final VoidCallback onChanged;

  const GpPhotosTab(
      {super.key,
      required this.view,
      required this.onOpenTab,
      required this.onChanged});

  @override
  State<GpPhotosTab> createState() => _GpPhotosTabState();
}

class _GpPhotosTabState extends State<GpPhotosTab> {
  String _status = 'loading'; // loading | ready | error
  Map<String, dynamic> _data = {};
  Object? _loadError;
  String? _deleting; // photo name being deleted
  Object? _deleteError;
  String _done = '';
  bool _syncing = false;
  Object? _syncError;
  String _category = ''; // '' = all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _status = 'loading';
        _loadError = null;
      });
    }
    try {
      final data = mapOf(await GoogleProfileApi.instance.photos());
      if (!mounted) return;
      setState(() {
        _status = 'ready';
        _data = data;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      if (gpHandleLocked(context, error)) return;
      if (quiet && _status == 'ready') return;
      setState(() {
        _status = 'error';
        _loadError = error;
      });
    }
  }

  Future<void> _openUpload() async {
    setState(() {
      _done = '';
      _deleteError = null;
      _syncError = null;
    });
    final n = await openPhotosUpload(context);
    if (!mounted || n == null || n == 0) return;
    setState(() => _done = n > 1
        ? '$n photos sent to Google. They show here after Google checks them.'
        : 'Photo sent to Google. It shows here after Google checks it.');
    _load(quiet: true);
  }

  Future<void> _syncGoogle() async {
    setState(() {
      _syncing = true;
      _syncError = null;
      _done = '';
    });
    try {
      await GoogleProfileApi.instance.syncGoogle();
      if (!mounted) return;
      setState(() =>
          _done = 'Read from Google. Photos added on Google now show here too.');
      await _load(quiet: true);
    } catch (error) {
      if (!mounted) return;
      if (gpHandleLocked(context, error)) return;
      setState(() => _syncError = error);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _remove(Map<String, dynamic> photo) async {
    final name = str(photo['name']);
    final ok = await gpConfirm(
      context,
      title: 'Delete this photo?',
      message: 'It is also removed from your Google profile.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() {
      _deleting = name;
      _deleteError = null;
      _done = '';
    });
    try {
      await GoogleProfileApi.instance.deletePhoto(name);
      if (!mounted) return;
      setState(() =>
          _done = 'Photo deleted. It is removed from your Google profile too.');
      await _load(quiet: true);
    } catch (error) {
      if (!mounted) return;
      if (gpHandleLocked(context, error)) return;
      setState(() => _deleteError = error);
    } finally {
      if (mounted) setState(() => _deleting = null);
    }
  }

  String _dateOf(Object? iso) {
    final s = str(iso);
    if (s.isEmpty) return '';
    return formatDay(s.length >= 10 ? s.substring(0, 10) : s);
  }

  Widget _addButton() => GpButton(
        label: 'Add a photo',
        icon: Icons.add,
        onPressed: _openUpload,
      );

  Widget? _googleLink() {
    final uri = str(_data['maps_uri']);
    if (uri.isEmpty) return null;
    return GpButton.ghost(
      label: 'See your profile on Google',
      icon: Icons.open_in_new,
      onPressed: () => gpOpenUrl(context, uri),
    );
  }

  Widget _syncButton() => GpButton.ghost(
        small: true,
        label: _syncing ? 'Reading Google…' : 'Refresh from Google',
        icon: Icons.refresh,
        busy: _syncing,
        onPressed: _syncing ? null : _syncGoogle,
      );

  Widget _chip(String label, String id) {
    final active = _category == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        showCheckmark: false,
        onSelected: (_) => setState(() => _category = id),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textPrimary),
        side: BorderSide(
            color: active ? AppColors.primary : AppColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _tile(Map<String, dynamic> photo) {
    final name = str(photo['name']);
    final category = photosCategoryLabel[str(photo['category'])];
    final date = _dateOf(photo['created_at']);
    final caption =
        [category, date].where((s) => s != null && s.isNotEmpty).join(' · ');
    final url = str(photo['thumbnail_url']).isNotEmpty
        ? str(photo['thumbnail_url'])
        : str(photo['url']);
    final busy = _deleting == name;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            GpImage(url: url.isEmpty ? null : url),
            if (busy)
              Container(
                color: Colors.white.withValues(alpha: 0.6),
                alignment: Alignment.center,
                child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5)),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 2, 2, 2),
          child: Row(children: [
            Expanded(
              child: Text(caption.isEmpty ? 'Photo' : caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GpText.note),
            ),
            IconButton(
              tooltip: 'Delete photo',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.error),
              onPressed: _deleting != null ? null : () => _remove(photo),
            ),
          ]),
        ),
      ]),
    );
  }

  List<Widget> _body() {
    if (_status == 'loading') {
      return const [GridShimmer(itemCount: 6, crossAxisCount: 2)];
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
    final google = mapOf(_data['google']);
    if (google.isNotEmpty && google['available'] == false) {
      return [
        GpCallout(
          tone: GpTone.warn,
          text: postsGoogleBlockText[str(google['reason'])] ??
              'Photos from Google are not available right now. Please try again later.',
        ),
      ];
    }
    final photos = listOf(_data['photos']).map(mapOf).toList();
    if (photos.isEmpty) {
      return [
        GpEmpty(
          icon: Icons.image_outlined,
          title: 'No photos on your profile yet',
          message:
              'Profiles with real photos get more attention. Add your first photo.',
          action: GpButtons(children: [_addButton(), _googleLink()]),
        ),
        Center(child: _syncButton()),
      ];
    }

    final total = numOf(_data['total']);
    final count = total != null && total > photos.length
        ? 'Showing ${photos.length} of ${total.toInt()} photos'
        : '${photos.length} ${photos.length == 1 ? 'photo' : 'photos'}';
    final synced = str(_data['synced_at']).isNotEmpty
        ? ' · updated from Google ${formatWhen(_data['synced_at'])}'
        : '';

    // The categories these photos are in, in Google's order.
    final present = photosCategories
        .where((c) => photos.any((p) => str(p['category']) == c.$1))
        .toList();
    final category =
        present.any((c) => c.$1 == _category) ? _category : '';
    final shown = category.isEmpty
        ? photos
        : photos.where((p) => str(p['category']) == category).toList();

    return [
      Text('$count$synced', style: GpText.note),
      const SizedBox(height: 10),
      GpButtons(children: [_addButton(), _googleLink(), _syncButton()]),
      const SizedBox(height: 14),
      if (present.length > 1) ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chip('All', ''),
            for (final c in present) _chip(c.$2, c.$1),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      if (_deleteError != null) ...[
        PostsErrorNote(error: _deleteError),
        const SizedBox(height: 12),
      ],
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: shown.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (_, i) => _tile(shown[i]),
      ),
    ];
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
          const Text('Photos on Google', style: GpText.h3),
          const SizedBox(height: 4),
          const Text('The photos people see on your Google profile.',
              style: GpText.note),
          const SizedBox(height: 14),
          if (_done.isNotEmpty) ...[
            GpCallout(tone: GpTone.ok, text: _done),
            const SizedBox(height: 12),
          ],
          if (_syncError != null) ...[
            PostsErrorNote(error: _syncError),
            const SizedBox(height: 12),
          ],
          ..._body(),
        ],
      ),
    );
  }
}
