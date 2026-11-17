// AI assistant chat helpers (website dashboard/AssistantUtils.js): plain
// functions and the chat's turn model. Shapes are GrowthOS's Command Center
// ones (Command) and the coach of contract §7.2.
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../api_services/google_profile_api.dart';
import '../gp_format.dart';

/// Longest message the AI reads (GrowthOS PROMPT_MAX).
const int assistantPromptMax = 500;

/// Photos the assistant takes: PNG, JPEG or WebP, up to 5 MB.
const int assistantPhotoMaxBytes = 5 * 1024 * 1024;
const List<String> _photoTypes = ['image/png', 'image/jpeg', 'image/webp'];
final RegExp _photoName = RegExp(r'\.(png|jpe?g|webp)$', caseSensitive: false);

/// Why a picked file cannot be sent, or "" when it is fine.
Future<String> assistantPhotoProblem(XFile? file) async {
  if (file == null) return 'Choose a photo.';
  final name = file.name.isNotEmpty ? file.name : file.path;
  final type = file.mimeType ?? lookupMimeType(file.path) ?? '';
  final typeOk = _photoTypes.contains(type) || _photoName.hasMatch(name);
  if (!typeOk) return 'Choose a PNG, JPEG or WebP photo.';
  int size;
  try {
    size = await file.length();
  } catch (_) {
    size = 0;
  }
  if (size > assistantPhotoMaxBytes) {
    return 'This photo is bigger than 5 MB. Choose a smaller one.';
  }
  return '';
}

/// The file name to show for a picked photo.
String assistantFileName(XFile file) {
  if (file.name.isNotEmpty) return file.name;
  final parts = file.path.split(Platform.pathSeparator);
  return parts.isEmpty ? file.path : parts.last;
}

/// The words to show for a failed call: the server's message, with fixed
/// words for a few codes.
String assistantErrorText(
  Object? error, [
  String fallback = 'Something went wrong. Please try again.',
]) {
  final code = gpErrorCode(error);
  if (code == 'ai_unavailable') {
    return 'AI is unavailable right now. Please try again later.';
  }
  if (code == 'network') {
    return "We couldn't reach the server. Check your internet connection and try again.";
  }
  return gpErrorMessage(error, fallback);
}

/// An error made here (a file check) that reads like a server error, so the
/// same message line shows it (website messageError).
GpException assistantMessageError(String message) =>
    GpException(status: 0, code: 'client', serverMessage: message);

/// A list from a plain array or a { data } page.
List<dynamic> assistantListOf(Object? value) {
  if (value is GpPage) return value.list;
  if (value is List) return value;
  if (value is Map && value['data'] is List) return value['data'] as List;
  return const [];
}

/// The starter commands as plain strings.
List<String> assistantSuggestionTexts(Object? value) => assistantListOf(value)
    .map((s) => s is String ? s : (s is Map ? s['text'] : null))
    .whereType<String>()
    .where((s) => s.trim().isNotEmpty)
    .toList();

/// Statuses that show why the AI did not (or could not) do it.
const List<String> assistantBlocked = [
  'refused',
  'not_allowed',
  'blocked',
  'unsupported',
  'failed',
];

const Map<String, String> _blockedTitles = {
  'refused': 'The AI does not change this',
  'not_allowed': "You can't do this here",
  'blocked': 'Not possible yet',
  'unsupported': "Can't do this from here",
  'failed': 'This did not work',
};

/// "already saved / already tracked / already on" answers say "Nothing to do".
String assistantBlockedTitle(String status, String? message) =>
    status == 'unsupported' &&
        RegExp(r'\balready\b', caseSensitive: false).hasMatch(message ?? '')
    ? 'Nothing to do'
    : (_blockedTitles[status] ?? '');

/// Internal kinds (they only change GrowthOS's own tracking); every other
/// google_* kind and review replies change Google.
const List<String> _internalKinds = [
  'google_keyword_add',
  'google_keyword_remove',
  'google_goal',
];
bool assistantChangesGoogle(Object? kind) =>
    kind is String &&
    ((kind.startsWith('google_') && !_internalKinds.contains(kind)) ||
        kind == 'review_reply');

/// The upload a command asks for → its button.
const Map<String, String> assistantUploadLabels = {
  'logo': 'Upload your logo',
  'cover': 'Upload your cover photo',
  'library': 'Upload a photo',
};

/// A coach "upload_photo" purpose → its button.
const Map<String, String> assistantPurposeLabels = {
  'post': 'Upload a photo for a post',
  'photo': 'Upload a photo',
  'logo': 'Upload your logo',
  'cover': 'Upload your cover photo',
};

/// A coach "open_tab" tab → its button.
const Map<String, String> assistantTabLabels = {
  'profile': 'Open Profile',
  'reviews': 'Open Reviews',
  'posts': 'Open Posts',
  'photos': 'Open Photos',
};

const Map<String, String> assistantTabNames = {
  'profile': 'Profile',
  'reviews': 'Reviews',
  'posts': 'Posts',
  'photos': 'Photos',
};

/// A GrowthOS link in a card → the dashboard tab that does the same.
String? assistantTabOfLink(Object? href) {
  if (href is! String) return null;
  bool has(String p) => RegExp(p, caseSensitive: false).hasMatch(href);
  if (has('review')) return 'reviews';
  if (has('post')) return 'posts';
  if (has('photo|librar')) return 'photos';
  if (has('profile|google')) return 'profile';
  return null;
}

/// The WhatsApp share link for the review link.
String assistantWhatsappShareUrl(String reviewUrl) =>
    'https://wa.me/?text=${Uri.encodeComponent('Please leave us a review on Google: $reviewUrl')}';

int _counter = 0;

/// A key for a new turn.
String assistantNewKey() {
  _counter += 1;
  return 'turn-${DateTime.now().millisecondsSinceEpoch}-$_counter';
}

/// One message of the chat and what came back.
class AssistantTurn {
  final String key;

  /// pending | question | command | failed
  final String type;
  final String text;

  /// Photos with the message: { id, kind, name, url } (or `local`: a file path).
  final List<Map<String, dynamic>> attachments;

  /// A local file path shown in place of the attachments.
  final String? preview;

  /// pending: upload | ai
  final String? stage;
  final String? label;
  final String answer;
  final Map<String, dynamic>? command;
  final Object? error;

  /// failed: the uploaded attachment to send again, or the file to upload again.
  final Map<String, dynamic>? attachment;
  final File? file;

  const AssistantTurn({
    required this.key,
    required this.type,
    required this.text,
    this.attachments = const [],
    this.preview,
    this.stage,
    this.label,
    this.answer = '',
    this.command,
    this.error,
    this.attachment,
    this.file,
  });

  AssistantTurn copyWith({
    String? type,
    List<Map<String, dynamic>>? attachments,
    String? stage,
    String? label,
    Map<String, dynamic>? command,
  }) => AssistantTurn(
    key: key,
    type: type ?? this.type,
    text: text,
    attachments: attachments ?? this.attachments,
    preview: preview,
    stage: stage ?? this.stage,
    label: label ?? this.label,
    answer: answer,
    command: command ?? this.command,
    error: error,
    attachment: attachment,
    file: file,
  );

  String get commandId => command == null ? '' : str(command!['id']);
}

List<Map<String, dynamic>> _attachmentsOf(Object? v) => listOf(
  v,
).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();

/// The chat's history rows (questions with their answers, and commands) → turns.
List<AssistantTurn> assistantTurnsFromHistory(Object? rows) =>
    assistantListOf(rows).whereType<Map>().map((raw) {
      final r = Map<String, dynamic>.from(raw);
      return r['kind'] == 'question'
          ? AssistantTurn(
              key: str(r['id']),
              type: 'question',
              text: str(r['text']),
              attachments: _attachmentsOf(r['attachments']),
              answer: str(r['result']),
            )
          : AssistantTurn(
              key: str(r['id']),
              type: 'command',
              text: str(r['text']),
              attachments: _attachmentsOf(r['attachments']),
              command: r,
            );
    }).toList();
