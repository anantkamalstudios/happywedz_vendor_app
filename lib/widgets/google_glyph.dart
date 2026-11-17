import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Google "G" in its four brand colours, drawn so it stays sharp at any
/// size without an image asset — the counterpart of `InstagramGlyph`.
class GoogleGlyph extends StatelessWidget {
  final double size;

  const GoogleGlyph({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (s - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Angles run clockwise from 3 o'clock. The G is open between -45° and 0°.
    canvas.drawArc(rect, _rad(0), _rad(45), false, arc(_blue));
    canvas.drawArc(rect, _rad(45), _rad(110), false, arc(_green));
    canvas.drawArc(rect, _rad(155), _rad(55), false, arc(_yellow));
    canvas.drawArc(rect, _rad(210), _rad(105), false, arc(_red));

    // The blue crossbar, from the centre to the outer edge.
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - stroke / 2,
        center.dx + radius + stroke / 2,
        center.dy + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
