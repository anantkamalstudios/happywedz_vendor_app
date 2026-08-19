import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_shimmer.dart';

/// ============================================================================
/// AppNetworkImage — safe remote images
/// ============================================================================
///
/// AUDIT NOTE:
/// The app loads remote media from `happywedz-s3-bucket.s3.ap-south-1…` and
/// from `img.youtube.com`. Most call sites used a bare `Image.network(url)` or
/// `NetworkImage(url)` with NO `errorBuilder` and NO `loadingBuilder`:
///
///   • an empty/null URL threw immediately and painted a red error box over
///     the whole tile,
///   • a 404 or an expired S3 link showed Flutter's grey "broken image" glyph,
///   • `NetworkImage` inside a `DecorationImage` cannot report errors at all,
///     so a failed cover image silently rendered as an untinted box.
///
/// `cached_network_image: ^3.4.1` was already a dependency but only two call
/// sites used it. This widget routes every remote image through it and always
/// supplies the four states: loading, success, empty URL, failure.
/// ----------------------------------------------------------------------------
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Icon shown when the URL is missing or the fetch failed.
  final IconData placeholderIcon;

  /// Optional caption under the placeholder icon (e.g. "Image unavailable").
  final String? placeholderLabel;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderLabel,
  });

  bool get _hasUrl {
    final u = url?.trim();
    if (u == null || u.isEmpty) return false;
    // Guard against values that are not actually fetchable URLs — a few API
    // responses return "null" / "undefined" as literal strings.
    if (u == 'null' || u == 'undefined') return false;
    final parsed = Uri.tryParse(u);
    return parsed != null && parsed.hasScheme && parsed.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = _hasUrl
        ? CachedNetworkImage(
            imageUrl: url!.trim(),
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (_, __) => _loading(),
            errorWidget: (_, __, ___) => _placeholder(),
          )
        : _placeholder();

    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _loading() => AppShimmer(
        child: Container(
          width: width,
          height: height,
          color: Colors.white,
        ),
      );

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.shimmerBase,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(placeholderIcon, color: AppColors.textTertiary, size: 28),
          if (placeholderLabel != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                placeholderLabel!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Circular variant for avatars / profile images.
///
/// Replaces `CircleAvatar(backgroundImage: NetworkImage(url))`, which throws
/// an unhandled image exception when `url` is empty and has no way to show a
/// fallback.
class AppNetworkAvatar extends StatelessWidget {
  final String? url;
  final double radius;

  /// Shown when there is no usable image — typically the first letter of the
  /// business/customer name, matching the existing avatars in Enquirys.
  final String? fallbackText;
  final Color backgroundColor;

  const AppNetworkAvatar({
    super.key,
    required this.url,
    this.radius = 24,
    this.fallbackText,
    this.backgroundColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final trimmed = url?.trim();
    final hasUrl = trimmed != null &&
        trimmed.isNotEmpty &&
        trimmed != 'null' &&
        (Uri.tryParse(trimmed)?.hasScheme ?? false);

    // `fallbackText` may be an empty string coming from the API, so take the
    // first character defensively rather than with `text[0]`.
    final initial = (fallbackText ?? '').trim();
    final letter = initial.isNotEmpty ? initial[0].toUpperCase() : '?';

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: trimmed,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => AppShimmer(
                  child: Container(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => _initialAvatar(letter, size),
              )
            : _initialAvatar(letter, size),
      ),
    );
  }

  Widget _initialAvatar(String letter, double size) {
    return Container(
      width: size,
      height: size,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTextStyles.h3.copyWith(
          color: Colors.white,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}