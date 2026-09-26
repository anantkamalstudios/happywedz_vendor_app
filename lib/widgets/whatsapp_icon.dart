import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// The WhatsApp logo, in WhatsApp green by default. Use it on every
/// "WhatsApp" / "Send on WhatsApp" action instead of a generic chat icon.
class WhatsAppIcon extends StatelessWidget {
  static const Color green = Color(0xFF1FA855);

  final double size;
  final Color? color;

  const WhatsAppIcon({super.key, this.size = 16, this.color = green});

  @override
  Widget build(BuildContext context) =>
      FaIcon(FontAwesomeIcons.whatsapp, size: size, color: color);
}
