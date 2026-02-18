import 'dart:convert';

class PinnedFile {
  final String semesterString;
  final String urlString;
  final String moduleTitle;
  final DateTime addedAt;
  final String customName;
  final String fileSystemPath;

  const PinnedFile(
      {required this.semesterString,
      required this.urlString,
      required this.moduleTitle,
      required this.addedAt,
      required this.customName,
      required this.fileSystemPath});

  Map<String, String> toMap() => {
        'semesterString': semesterString,
        'urlString': urlString,
        'moduleTitle': moduleTitle,
        'addedAt': addedAt.toUtc().toIso8601String(),
        'customName': customName,
        'fileSystemPath': fileSystemPath
      };

  static PinnedFile? fromMap(Map<String, dynamic> map) {
    final semester = map['semesterString'];
    final url = map['urlString'];
    final title = map['moduleTitle'];
    final addedAtRaw = map['addedAt'];
    final customNameRaw = map['customName'];
    final fileSystemPath = map['fileSystemPath'];

    if (semester is String && url is String && title is String) {
      DateTime? addedAt;
      if (addedAtRaw is String) {
        addedAt = DateTime.tryParse(addedAtRaw);
      } else if (addedAtRaw is int) {
        addedAt = DateTime.fromMillisecondsSinceEpoch(addedAtRaw, isUtc: true);
      }

      addedAt = (addedAt ?? DateTime.now()).toUtc();
      final fallbackTitle = title.trim();
      final resolvedCustomName =
          customNameRaw is String && customNameRaw.trim().isNotEmpty
              ? customNameRaw.trim()
              : fallbackTitle.isNotEmpty
                  ? fallbackTitle
                  : "Unbenannte Datei";

      return PinnedFile(
        semesterString: semester,
        urlString: url,
        moduleTitle: title,
        addedAt: addedAt,
        customName: resolvedCustomName,
        fileSystemPath: fileSystemPath ?? "",
      );
    }

    return null;
  }

  String encode() => jsonEncode(toMap());

  static PinnedFile? tryDecode(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        return PinnedFile.fromMap(decoded);
      }
    } catch (_) {
      // Ignore malformed entries.
    }
    return null;
  }

  PinnedFile copyWith(
      {String? semesterString,
      String? urlString,
      String? moduleTitle,
      DateTime? addedAt,
      String? customName,
      String? fileSystemPath}) {
    return PinnedFile(
      semesterString: semesterString ?? this.semesterString,
      urlString: urlString ?? this.urlString,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      addedAt: addedAt ?? this.addedAt,
      customName: customName ?? this.customName,
      fileSystemPath: fileSystemPath ?? this.fileSystemPath,
    );
  }
}
