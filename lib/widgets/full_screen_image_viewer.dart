import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Full-screen photo viewer: swipe between photos, pinch or double-tap to
/// zoom. Each source is a network URL or a local [File].
class FullScreenImageViewer extends StatefulWidget {
  final List<Object> sources;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.sources,
    this.initialIndex = 0,
  });

  /// Opens the viewer over the current screen.
  static Future<void> open(
    BuildContext context, {
    required List<Object> sources,
    int initialIndex = 0,
  }) {
    if (sources.isEmpty) return Future.value();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => FullScreenImageViewer(
          sources: sources,
          initialIndex: initialIndex.clamp(0, sources.length - 1),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  /// Zoom is per page; paging is locked while the current photo is zoomed so
  /// panning a zoomed photo does not flip to the next one.
  final Map<int, TransformationController> _zoom = {};
  bool _zoomed = false;

  TransformationController _controllerFor(int i) =>
      _zoom.putIfAbsent(i, () {
        final c = TransformationController();
        c.addListener(() {
          if (i != _index) return;
          final zoomed = c.value.getMaxScaleOnAxis() > 1.01;
          if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
        });
        return c;
      });

  void _toggleZoom(int i, TapDownDetails details) {
    final c = _controllerFor(i);
    if (c.value.getMaxScaleOnAxis() > 1.01) {
      c.value = Matrix4.identity();
    } else {
      final p = details.localPosition;
      c.value = Matrix4.identity()
        ..translateByDouble(-p.dx * 1.5, -p.dy * 1.5, 0, 1)
        ..scaleByDouble(2.5, 2.5, 1, 1);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _zoom.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _image(Object source) {
    Widget error(_, __, ___) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
              SizedBox(height: 8),
              Text("Image unavailable",
                  style: TextStyle(color: Colors.white54)),
            ],
          ),
        );

    if (source is File) {
      return Image.file(source, fit: BoxFit.contain, errorBuilder: error);
    }
    return CachedNetworkImage(
      imageUrl: source.toString(),
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (c, u, e) => error(c, u, e),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.sources.length;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: _zoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: total,
            onPageChanged: (i) {
              // Reset the zoom of the page being left.
              _zoom[_index]?.value = Matrix4.identity();
              setState(() {
                _index = i;
                _zoomed = false;
              });
            },
            itemBuilder: (_, i) {
              TapDownDetails? lastTap;
              return GestureDetector(
                onDoubleTapDown: (d) => lastTap = d,
                onDoubleTap: () {
                  if (lastTap != null) _toggleZoom(i, lastTap!);
                },
                child: InteractiveViewer(
                  transformationController: _controllerFor(i),
                  minScale: 1,
                  maxScale: 5,
                  child: SizedBox.expand(child: _image(widget.sources[i])),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: "Close",
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (total > 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        "${_index + 1} / $total",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
