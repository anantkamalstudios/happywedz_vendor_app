// The "Add photos" form of the Photos tab (website dashboard/PhotosTab.jsx
// PhotoUpload), as a full-screen page: up to [photosPerUpload] photos, one
// Google category, sent one by one (each photo's result shows).
// API: addPhoto(file, category). The page pops with the number of photos sent,
// or null when cancelled.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/common_app_bar.dart';
import '../gp_parts.dart';
import 'posts_utils.dart';

/// GrowthOS PHOTO_CATEGORIES with GrowthOS's plain labels.
const List<(String, String)> photosCategories = [
  ('COVER', 'Cover'),
  ('PROFILE', 'Logo'),
  ('EXTERIOR', 'Exterior'),
  ('INTERIOR', 'Interior'),
  ('PRODUCT', 'Product'),
  ('AT_WORK', 'At work'),
  ('TEAMS', 'Team'),
  ('FOOD_AND_DRINK', 'Food and drink'),
  ('MENU', 'Menu'),
  ('COMMON_AREA', 'Common area'),
  ('ROOMS', 'Rooms'),
  ('ADDITIONAL', 'Other'),
];

final Map<String, String> photosCategoryLabel = {
  for (final c in photosCategories) c.$1: c.$2,
};

/// At most this many photos in one go.
const int photosPerUpload = 10;

/// Cover and Logo are one photo each.
const List<String> _singleCategories = ['COVER', 'PROFILE'];

/// Opens the "Add photos" page. Resolves to the number of photos sent when
/// every photo went through, or null when the vendor left.
Future<int?> openPhotosUpload(BuildContext context) {
  return Navigator.of(context).push<int>(
    MaterialPageRoute(builder: (_) => const GpPhotosUploadScreen()),
  );
}

class _Picked {
  final String key;
  final File file;
  final String name;
  bool? ok; // null = not sent yet
  String message = '';
  _Picked(this.key, this.file, this.name);
}

class GpPhotosUploadScreen extends StatefulWidget {
  const GpPhotosUploadScreen({super.key});

  @override
  State<GpPhotosUploadScreen> createState() => _GpPhotosUploadScreenState();
}

class _GpPhotosUploadScreenState extends State<GpPhotosUploadScreen> {
  final List<_Picked> _files = [];
  String _category = '';
  Map<String, String> _problems = {};
  ({int done, int total})? _busy;
  String? _error;
  bool _picking = false;

  Future<void> _pick() async {
    if (_busy != null || _picking || _files.length >= photosPerUpload) return;
    setState(() => _picking = true);
    List<XFile> picked;
    try {
      picked = await ImagePicker().pickMultiImage();
    } catch (_) {
      if (mounted) {
        setState(() => _picking = false);
        gpToast(context, 'Could not open your photos.', error: true);
      }
      return;
    }
    if (!mounted) return;
    if (picked.isEmpty) {
      setState(() => _picking = false);
      return;
    }
    final room = photosPerUpload - _files.length;
    String? bad;
    final usable = <XFile>[];
    for (final x in picked) {
      final problem = await postsImageProblem(File(x.path));
      if (problem == null) {
        usable.add(x);
      } else {
        bad ??= problem;
      }
    }
    if (!mounted) return;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final added = <_Picked>[];
    for (var i = 0; i < usable.length && i < (room < 0 ? 0 : room); i++) {
      added.add(_Picked('$stamp-$i-${usable[i].name}', File(usable[i].path),
          usable[i].name));
    }
    setState(() {
      _picking = false;
      _files.addAll(added);
      final p = Map<String, String>.from(_problems)..remove('file');
      if (bad != null) {
        p['file'] = 'Some photos were left out: $bad';
      } else if (usable.length > room) {
        p['file'] =
            'At most $photosPerUpload photos in one go. Send these, then add more.';
      }
      _problems = p;
    });
  }

  Future<void> _submit() async {
    if (_busy != null) return;
    final waiting = _files.where((f) => f.ok != true).toList();
    final found = <String, String>{};
    if (waiting.isEmpty) found['file'] = 'Choose at least one photo.';
    if (_category.isEmpty) {
      found['category'] = 'Choose a category.';
    } else if (_singleCategories.contains(_category) && waiting.length > 1) {
      found['category'] =
          'Cover and Logo take one photo. Keep one photo, or choose another category.';
    }
    setState(() {
      _problems = found;
      _error = null;
    });
    if (found.isNotEmpty) return;

    var sent = 0;
    for (var i = 0; i < waiting.length; i++) {
      final item = waiting[i];
      setState(() => _busy = (done: i, total: waiting.length));
      try {
        await GoogleProfileApi.instance.addPhoto(item.file, _category);
        item.ok = true;
        item.message = '';
        sent += 1;
      } catch (failure) {
        if (!mounted) return;
        if (gpHandleLocked(context, failure)) return;
        item.ok = false;
        item.message = gpErrorMessage(failure, 'Not sent. Please try again.');
      }
      if (!mounted) return;
      setState(() {});
    }
    if (!mounted) return;
    setState(() => _busy = null);
    if (sent == waiting.length) {
      Navigator.of(context).pop(sent);
    } else {
      setState(() => _error =
          '$sent of ${waiting.length} photos sent. The others show why; press the button to try them again.');
    }
  }

  Widget _thumb(int i, _Picked f) {
    return SizedBox(
      width: 96,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(f.file,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                semanticLabel: 'Photo ${i + 1}: ${f.name}',
                errorBuilder: (_, __, ___) => Container(
                      width: 96,
                      height: 96,
                      color: AppColors.background,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.textTertiary),
                    )),
          ),
          if (f.ok == null && _busy == null)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 1,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _files.remove(f)),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(Icons.delete_outline,
                        size: 16,
                        color: AppColors.error,
                        semanticLabel: 'Remove photo ${i + 1}'),
                  ),
                ),
              ),
            ),
        ]),
        if (f.ok == true) ...[
          const SizedBox(height: 4),
          const GpChip('Sent', tone: GpTone.ok),
        ] else if (f.ok == false) ...[
          const SizedBox(height: 4),
          Text(f.message, style: GpText.error),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final left = _files.where((f) => f.ok != true).length;
    final busy = _busy;
    final bottom = MediaQuery.of(context).padding.bottom;
    return PopScope(
      canPop: busy == null,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CommonAppBar(title: 'Add photos to Google'),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottom),
          children: [
            const Text(
                'Use real photos of your work or place, up to $photosPerUpload at a time. Google checks new photos before showing them.',
                style: GpText.note),
            const SizedBox(height: 14),
            GpCard(
              child: GpStack(gap: 12, children: [
                const Text.rich(TextSpan(
                  text: 'Photos',
                  style: GpText.label,
                  children: [
                    TextSpan(
                        text: ' (required)',
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: AppColors.textTertiary)),
                  ],
                )),
                if (_files.isNotEmpty)
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    for (var i = 0; i < _files.length; i++) _thumb(i, _files[i]),
                  ]),
                GpButton.ghost(
                  label: _files.isEmpty ? 'Choose photos' : 'Add more photos',
                  icon: Icons.add_photo_alternate_outlined,
                  busy: _picking,
                  onPressed: busy != null || _files.length >= photosPerUpload
                      ? null
                      : _pick,
                ),
                const Text(
                    'PNG, JPEG or WebP, up to 5 MB each, at least 250 × 250 pixels. You can pick several at once.',
                    style: GpText.note),
                if (_problems['file'] != null)
                  Text(_problems['file']!, style: GpText.error),
              ]),
            ),
            GpCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text.rich(TextSpan(
                  text: 'Category',
                  style: GpText.label,
                  children: [
                    TextSpan(
                        text: ' (required)',
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: AppColors.textTertiary)),
                  ],
                )),
                const SizedBox(height: 6),
                GpDropdown<String>(
                  label: '',
                  value: _category.isEmpty ? null : _category,
                  hint: 'Choose',
                  error: _problems['category'],
                  items: [
                    for (final c in photosCategories)
                      DropdownMenuItem(value: c.$1, child: Text(c.$2)),
                  ],
                  onChanged: busy != null
                      ? null
                      : (v) => setState(() => _category = v ?? ''),
                ),
              ]),
            ),
            if (_error != null) ...[
              GpCallout(tone: GpTone.bad, text: _error),
              const SizedBox(height: 12),
            ],
            GpButton(
              expand: true,
              icon: Icons.upload_outlined,
              busy: busy != null,
              label: busy != null
                  ? 'Sending ${busy.done + 1} of ${busy.total}…'
                  : left > 1
                      ? 'Add $left photos'
                      : 'Add photo',
              onPressed: busy != null ? null : _submit,
            ),
            const SizedBox(height: 10),
            GpButton.ghost(
              expand: true,
              label: 'Cancel',
              onPressed: busy != null ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
