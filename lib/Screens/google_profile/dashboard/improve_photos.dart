// "Improve with AI" step 4 (website dashboard/ImprovePhotos.jsx): the
// vendor's storefront photos. The vendor ticks up to 10 and says what each is:
// the cover photo (one), the logo (one) or a photo with Google's category
// (default Other); "Send to Google" sends them (the server takes each photo
// from the vendor's own storefront by its index) and shows each photo's
// result. "Upload photos" sends photos from the phone (website PhotoUpload,
// from PhotosTab.jsx, ported privately below).
// API: storefront → photos [{ index, url }]; sendStorefrontPhotos(items) → { results }; addPhoto.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'improve_utils.dart';

const Map<String, String> _roleWords = {
  'cover': 'the cover photo',
  'logo': 'the logo',
};

class _Pick {
  final bool use;
  final String as;
  const _Pick(this.use, this.as);
  _Pick copyWith({bool? use, String? as}) => _Pick(use ?? this.use, as ?? this.as);
}

class _Result {
  final bool ok;
  final String message;
  const _Result(this.ok, this.message);
}

class ImprovePhotos extends StatefulWidget {
  final ImproveLoader storefront;
  final VoidCallback onSent;
  const ImprovePhotos(
      {super.key, required this.storefront, required this.onSent});

  @override
  State<ImprovePhotos> createState() => _ImprovePhotosState();
}

class _ImprovePhotosState extends State<ImprovePhotos> {
  final Map<int, _Pick> _picks = {};
  final Map<int, _Result> _results = {};
  bool _busy = false;
  Object? _error;
  ImproveMessage? _message;
  bool _uploading = false;

  _Pick _pickOf(int index) => _picks[index] ?? const _Pick(false, defaultPhotoCategory);

  List<Map<String, dynamic>> get _photos => listOf(mapOf(widget.storefront.data)['photos'])
      .map(mapOf)
      .where((p) => p['index'] is int && p['url'] is String && str(p['url']).isNotEmpty)
      .toList();

  void _closeUpload(int sent) {
    setState(() {
      _uploading = false;
      if (sent > 0) {
        _message = ImproveMessage(GpTone.ok,
            '${sent > 1 ? '$sent photos' : 'Photo'} sent to Google. Google checks photos before showing them.');
      }
    });
    if (sent > 0) widget.onSent();
  }

  void _change(int index, {bool? use, String? as}) {
    final photos = _photos;
    int numberOf(int i) => photos.indexWhere((p) => p['index'] == i) + 1;
    final next = Map<int, _Pick>.from(_picks);
    next[index] = _pickOf(index).copyWith(use: use, as: as);
    int? moved;
    // Only one cover and one logo: the photo that had the role before becomes a plain photo.
    final role = next[index]!.as;
    if (as != null && _roleWords.containsKey(role)) {
      for (final key in next.keys.toList()) {
        if (key != index && next[key]!.as == role) {
          next[key] = next[key]!.copyWith(as: defaultPhotoCategory);
          moved = key;
        }
      }
    }
    setState(() {
      _picks
        ..clear()
        ..addAll(next);
      _message = moved == null
          ? null
          : ImproveMessage(GpTone.ok,
              'Storefront photo ${numberOf(moved)} is no longer ${_roleWords[role]}; it is now a photo (Other).');
    });
  }

  Future<void> _send() async {
    final chosen = _photos.where((p) => _pickOf(p['index'] as int).use).toList();
    if (chosen.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    final items = chosen.map((p) {
      final index = p['index'] as int;
      final as = _pickOf(index).as;
      return _roleWords.containsKey(as)
          ? {'index': index, 'role': as}
          : {'index': index, 'role': 'photo', 'category': as};
    }).toList();
    try {
      final answer = await GoogleProfileApi.instance.sendStorefrontPhotos(items);
      if (!mounted) return;
      final list = listOf(mapOf(answer)['results']);
      final byIndex = <int, _Result>{};
      for (final raw in list) {
        final r = mapOf(raw);
        if (r['index'] is int) {
          byIndex[r['index'] as int] = _Result(
              r['ok'] == true, r['message'] is String ? str(r['message']) : '');
        }
      }
      final sent = byIndex.values.where((r) => r.ok).length;
      final notSent = byIndex.length - sent;
      setState(() {
        _results.addAll(byIndex);
        // Sent photos are unticked, so pressing again only sends the rest.
        byIndex.forEach((key, r) {
          if (r.ok && _picks[key] != null) {
            _picks[key] = _picks[key]!.copyWith(use: false);
          }
        });
        _message = ImproveMessage(
          notSent > 0 ? (sent > 0 ? GpTone.warn : GpTone.bad) : GpTone.ok,
          list.isNotEmpty
              ? '$sent ${sent == 1 ? 'photo' : 'photos'} sent to Google${notSent > 0 ? ', $notSent not sent (see each photo)' : ''}. Google checks photos before showing them.'
              : 'Sent. Google checks photos before showing them.',
        );
      });
      if (sent > 0 || list.isEmpty) widget.onSent();
    } catch (e) {
      if (!mounted || gpHandleLocked(context, e)) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget get _uploadButton => GpButton.ghost(
        label: 'Upload photos',
        icon: Icons.upload_outlined,
        onPressed: _busy
            ? null
            : () => setState(() {
                  _message = null;
                  _uploading = true;
                }),
      );

  Widget? get _uploadForm => _uploading
      ? _PhotoUpload(
          onAdded: _closeUpload,
          onCancel: () => _closeUpload(0),
        )
      : null;

  Widget _note() => _message == null
      ? const SizedBox.shrink()
      : GpCallout(tone: _message!.tone, text: _message!.text);

  Widget _photoTile(Map<String, dynamic> photo, int number, bool full) {
    final index = photo['index'] as int;
    final pick = _pickOf(index);
    final result = _results[index];
    final name = 'Storefront photo $number';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: pick.use ? AppColors.primary : AppColors.border,
            width: pick.use ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          label: name,
          image: true,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: GpImage(url: str(photo['url'])),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: GpStack(gap: 8, children: [
            Semantics(
              label: 'Send $name',
              child: GpCheck(
                value: pick.use,
                onChanged: (_busy || (!pick.use && full))
                    ? null
                    : (on) => _change(index, use: on),
                label: const Text('Send', style: TextStyle(fontSize: 13.5)),
              ),
            ),
            if (pick.use)
              GpStack(gap: 4, children: [
                const Text('Use as', style: GpText.note),
                DropdownButtonFormField<String>(
                  key: ValueKey('as-$index-${pick.as}'),
                  initialValue: pick.as,
                  isExpanded: true,
                  isDense: true,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: gpInputDecoration(),
                  onChanged: _busy
                      ? null
                      : (v) {
                          if (v != null) _change(index, as: v);
                        },
                  items: [
                    const DropdownMenuItem(value: 'cover', child: Text('Cover photo')),
                    const DropdownMenuItem(value: 'logo', child: Text('Logo')),
                    for (final c in improvePhotoCategories)
                      DropdownMenuItem(value: c[0], child: Text('Photo: ${c[1]}')),
                  ],
                ),
              ]),
            if (result != null)
              result.ok
                  ? const GpChip('Sent', tone: GpTone.ok, icon: Icons.check)
                  : Text(
                      'Not sent${result.message.isNotEmpty ? ': ${result.message}' : ''}',
                      style: GpText.error),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sf = widget.storefront;
    if (sf.isLoading) return const GpLoadingLine('Loading your storefront photos…');
    if (sf.isError) {
      return ImproveLoadFailed(
        error: sf.error,
        fallback: "We couldn't load your storefront photos. Please try again.",
        onRetry: () => sf.reload(),
      );
    }
    final photos = _photos;
    if (photos.isEmpty) {
      return GpStack(gap: 10, children: [
        const GpCallout(
          tone: GpTone.warn,
          text:
              'Your storefront has no photos yet. Upload real photos of your work here, or add them to your storefront and come back here.',
        ),
        _note(),
        _uploadForm ??
            GpButtons(children: [
              _uploadButton,
              GpButton.ghost(
                label: 'Open my storefront',
                icon: Icons.open_in_new,
                onPressed: () => gpOpenStorefront(context),
              ),
            ]),
      ]);
    }

    final chosen = photos.where((p) => _pickOf(p['index'] as int).use).length;
    final full = chosen >= photosMax;
    final rows = <Widget>[];
    for (var i = 0; i < photos.length; i += 2) {
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _photoTile(photos[i], i + 1, full)),
        const SizedBox(width: 10),
        Expanded(
          child: i + 1 < photos.length
              ? _photoTile(photos[i + 1], i + 2, full)
              : const SizedBox.shrink(),
        ),
      ]));
    }

    return GpStack(gap: 14, children: [
      const Text(
          'Tick up to $photosMax photos from your storefront. Pick one as your cover photo and one as your logo; the rest go to Google as photos. Only real photos of your work: AI never makes fake photos. Photos that are not on your storefront? Use Upload photos.',
          style: GpText.note),
      GpStack(gap: 10, children: rows),
      if (full)
        const Text(
            'You picked $photosMax, the most for one go. Send these first, then pick more.',
            style: GpText.note),
      ImproveError(_error),
      _note(),
      _uploadForm,
      GpButtons(children: [
        GpButton(
          label: _busy
              ? 'Sending to Google…'
              : chosen > 0
                  ? 'Send $chosen to Google'
                  : 'Tick at least one photo',
          icon: Icons.send_outlined,
          busy: _busy,
          onPressed: (_busy || chosen == 0) ? null : _send,
        ),
        if (!_uploading) _uploadButton,
      ]),
    ]);
  }
}

// ── Upload photos from the phone (website PhotosTab.jsx PhotoUpload) ──────

/// At most this many photos in one go.
const int _photosPerUpload = 10;

/// Cover and Logo are one photo each.
const List<String> _singleCategories = ['COVER', 'PROFILE'];

// GrowthOS PHOTO_CATEGORIES with GrowthOS's plain labels (with Cover and Logo).
const List<List<String>> _uploadCategories = [
  ['COVER', 'Cover'],
  ['PROFILE', 'Logo'],
  ['EXTERIOR', 'Exterior'],
  ['INTERIOR', 'Interior'],
  ['PRODUCT', 'Product'],
  ['AT_WORK', 'At work'],
  ['TEAMS', 'Team'],
  ['FOOD_AND_DRINK', 'Food and drink'],
  ['MENU', 'Menu'],
  ['COMMON_AREA', 'Common area'],
  ['ROOMS', 'Rooms'],
  ['ADDITIONAL', 'Other'],
];

const List<String> _imageTypes = ['image/png', 'image/jpeg', 'image/webp'];
const int _imageMaxBytes = 5 * 1024 * 1024;

/// Why a picked file can't be sent, or null when it is fine.
Future<String?> _imageFileProblem(File file) async {
  final type = lookupMimeType(file.path);
  if (type == null || !_imageTypes.contains(type)) {
    return 'Use a PNG, JPEG or WebP image.';
  }
  try {
    if (await file.length() > _imageMaxBytes) {
      return 'The image is larger than 5 MB. Choose a smaller one.';
    }
  } catch (_) {
    return 'Choose an image.';
  }
  return null;
}

class _UploadItem {
  final String key;
  final File file;
  _Result? result;
  _UploadItem(this.key, this.file);
}

/// The "Add photos" form: up to 10 files, one category, send (one by one;
/// each photo's result shows). [onAdded] runs with the count when every photo was sent.
class _PhotoUpload extends StatefulWidget {
  final ValueChanged<int> onAdded;
  final VoidCallback onCancel;
  const _PhotoUpload({required this.onAdded, required this.onCancel});

  @override
  State<_PhotoUpload> createState() => _PhotoUploadState();
}

class _PhotoUploadState extends State<_PhotoUpload> {
  final List<_UploadItem> _files = [];
  String? _category;
  final Map<String, String> _problems = {};

  /// While sending: [done, total].
  List<int>? _busy;
  Object? _error;
  int _seq = 0;

  Future<void> _pick() async {
    List<XFile> picked;
    try {
      picked = await ImagePicker().pickMultiImage(imageQuality: 100);
    } catch (_) {
      return;
    }
    if (!mounted || picked.isEmpty) return;
    final room = _photosPerUpload - _files.length;
    String? bad;
    final usable = <File>[];
    for (final x in picked) {
      final f = File(x.path);
      final problem = await _imageFileProblem(f);
      if (problem != null) {
        bad ??= problem;
      } else {
        usable.add(f);
      }
    }
    if (!mounted) return;
    setState(() {
      for (final f in usable.take(room < 0 ? 0 : room)) {
        _seq += 1;
        _files.add(_UploadItem('$_seq', f));
      }
      if (bad != null) {
        _problems['file'] = 'Some photos were left out: $bad';
      } else if (usable.length > room) {
        _problems['file'] =
            'At most $_photosPerUpload photos in one go. Send these, then add more.';
      } else {
        _problems.remove('file');
      }
    });
  }

  Future<void> _submit() async {
    final waiting = _files.where((f) => f.result?.ok != true).toList();
    final found = <String, String>{};
    if (waiting.isEmpty) found['file'] = 'Choose at least one photo.';
    if (_category == null) {
      found['category'] = 'Choose a category.';
    } else if (_singleCategories.contains(_category) && waiting.length > 1) {
      found['category'] =
          'Cover and Logo take one photo. Keep one photo, or choose another category.';
    }
    setState(() {
      _problems
        ..clear()
        ..addAll(found);
      _error = null;
    });
    if (found.isNotEmpty) return;
    var sent = 0;
    for (var i = 0; i < waiting.length; i++) {
      final item = waiting[i];
      setState(() => _busy = [i, waiting.length]);
      _Result result;
      try {
        await GoogleProfileApi.instance.addPhoto(item.file, _category!);
        result = const _Result(true, '');
        sent += 1;
      } catch (e) {
        if (!mounted || gpHandleLocked(context, e)) return;
        result = _Result(false, gpErrorMessage(e, 'Not sent. Please try again.'));
      }
      if (!mounted) return;
      setState(() => item.result = result);
    }
    if (!mounted) return;
    setState(() => _busy = null);
    if (sent == waiting.length) {
      widget.onAdded(sent);
    } else {
      setState(() => _error = ImproveLocalError(
          '$sent of ${waiting.length} photos sent. The others show why; press the button to try them again.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _busy != null;
    final left = _files.where((f) => f.result?.ok != true).length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: GpStack(gap: 12, children: [
        const Text('Add photos to Google', style: GpText.h3),
        const Text(
            'Use real photos of your work or place, up to $_photosPerUpload at a time. Google checks new photos before showing them.',
            style: GpText.note),
        if (_files.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < _files.length; i++)
              _thumb(_files[i], i + 1, busy),
          ]),
        GpStack(gap: 6, children: [
          const Text.rich(TextSpan(text: 'Photos ', style: GpText.label, children: [
            TextSpan(
                text: '(required)',
                style: TextStyle(
                    fontWeight: FontWeight.w400, color: AppColors.textTertiary)),
          ])),
          GpButton.ghost(
            label: 'Choose photos',
            icon: Icons.photo_library_outlined,
            small: true,
            onPressed: (busy || _files.length >= _photosPerUpload) ? null : _pick,
          ),
          const Text(
              'PNG, JPEG or WebP, up to 5 MB each, at least 250 × 250 pixels. You can pick several at once.',
              style: GpText.note),
          if (_problems['file'] != null)
            Text(_problems['file']!, style: GpText.error),
        ]),
        GpDropdown<String>(
          label: 'Category (required)',
          value: _category,
          hint: 'Choose',
          error: _problems['category'],
          onChanged: busy ? null : (v) => setState(() => _category = v),
          items: [
            for (final c in _uploadCategories)
              DropdownMenuItem(value: c[0], child: Text(c[1])),
          ],
        ),
        ImproveErrorNote(_error),
        GpButtons(children: [
          GpButton(
            label: busy
                ? 'Sending ${_busy![0] + 1} of ${_busy![1]}…'
                : left > 1
                    ? 'Add $left photos'
                    : 'Add photo',
            icon: Icons.upload_outlined,
            busy: busy,
            onPressed: busy ? null : _submit,
          ),
          GpButton.ghost(
              label: 'Cancel', onPressed: busy ? null : widget.onCancel),
        ]),
      ]),
    );
  }

  Widget _thumb(_UploadItem f, int number, bool busy) {
    final r = f.result;
    return SizedBox(
      width: 96,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(f.file,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                semanticLabel: 'Photo $number',
                errorBuilder: (_, __, ___) => Container(
                    width: 96, height: 96, color: AppColors.border)),
          ),
          if (r == null && !busy)
            Positioned(
              top: 2,
              right: 2,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _files.remove(f)),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline,
                        size: 16,
                        color: AppColors.error,
                        semanticLabel: 'Remove photo $number'),
                  ),
                ),
              ),
            ),
        ]),
        if (r != null) ...[
          const SizedBox(height: 4),
          r.ok
              ? const GpChip('Sent', tone: GpTone.ok)
              : Text(r.message, style: GpText.error),
        ],
      ]),
    );
  }
}
