// AI assistant chat bubbles (website dashboard/AssistantMessage.jsx): the
// vendor's message (with its photo), the assistant's message and the "the AI
// is writing" indicator. Server photos load with the vendor's token (GpImage).
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';

/// A photo of the chat: a local file, or a URL (server or Google).
class AssistantPhoto extends StatelessWidget {
  final String? localPath;
  final String? url;
  final double size;
  const AssistantPhoto({super.key, this.localPath, this.url, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    if (localPath != null && localPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.file(
          File(localPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => SizedBox(
            width: size,
            height: size,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      );
    }
    return GpImage(url: url, width: size, height: size, borderRadius: radius);
  }
}

/// The vendor's message, on the right.
class AssistantUserBubble extends StatelessWidget {
  final String text;
  final List<Map<String, dynamic>> attachments;
  final String? localPreview;

  const AssistantUserBubble({
    super.key,
    required this.text,
    this.attachments = const [],
    this.localPreview,
  });

  @override
  Widget build(BuildContext context) {
    final photos = attachments
        .where(
          (a) =>
              a['kind'] == 'image' ||
              str(a['url']).isNotEmpty ||
              str(a['local']).isNotEmpty,
        )
        .toList();
    final hasPreview = localPreview != null && localPreview!.isNotEmpty;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 40),
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Semantics(
            label: 'You',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasPreview || photos.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: hasPreview
                        ? [AssistantPhoto(localPath: localPreview)]
                        : [
                            for (final a in photos)
                              AssistantPhoto(
                                localPath: str(a['local']).isEmpty
                                    ? null
                                    : str(a['local']),
                                url: str(a['url']).isEmpty
                                    ? null
                                    : str(a['url']),
                                size: photos.length > 1 ? 80 : 120,
                              ),
                          ],
                  ),
                  const SizedBox(height: 8),
                ],
                SelectableText(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The assistant's message, on the left, with its mark.
class AssistantBubble extends StatelessWidget {
  final Widget child;
  final bool wide;
  const AssistantBubble({super.key, required this.child, this.wide = false});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: wide ? double.infinity : width * 0.8,
              ),
              child: Container(
                width: wide ? double.infinity : null,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Semantics(label: 'AI assistant', child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown while the AI works on an answer (it can take up to a minute).
class AssistantTyping extends StatelessWidget {
  final String label;
  const AssistantTyping({
    super.key,
    this.label = 'The AI is writing… This can take up to a minute.',
  });

  @override
  Widget build(BuildContext context) {
    return AssistantBubble(child: GpLoadingLine(label));
  }
}

/// A red message line (website `.gp-a-error`).
class AssistantErrorText extends StatelessWidget {
  final String text;
  const AssistantErrorText(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.error),
  );
}

/// The assistant's plain text (website `.gp-a-text`).
class AssistantText extends StatelessWidget {
  final String text;
  final bool selectable;
  const AssistantText(this.text, {super.key, this.selectable = false});

  static const TextStyle style = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) => selectable
      ? SelectableText(text, style: style)
      : Text(text, style: style);
}
