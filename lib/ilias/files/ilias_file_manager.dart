import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../state_management/kit_provider.dart';

class IliasFile {
  final String semesterString;
  final String urlString;
  final String moduleTitle;
  final DateTime addedAt;
  final String customName;

  const IliasFile({
    required this.semesterString,
    required this.urlString,
    required this.moduleTitle,
    required this.addedAt,
    required this.customName,
  });

  Map<String, String> toMap() => {
        'semesterString': semesterString,
        'urlString': urlString,
        'moduleTitle': moduleTitle,
        'addedAt': addedAt.toUtc().toIso8601String(),
        'customName': customName,
      };

  static IliasFile? fromMap(Map<String, dynamic> map) {
    final semester = map['semesterString'];
    final url = map['urlString'];
    final title = map['moduleTitle'];
    final addedAtRaw = map['addedAt'];
    final customNameRaw = map['customName'];

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

      return IliasFile(
        semesterString: semester,
        urlString: url,
        moduleTitle: title,
        addedAt: addedAt,
        customName: resolvedCustomName,
      );
    }

    return null;
  }

  String encode() => jsonEncode(toMap());

  static IliasFile? tryDecode(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        return IliasFile.fromMap(decoded);
      }
    } catch (_) {
      // Ignore malformed entries.
    }
    return null;
  }

  IliasFile copyWith({
    String? semesterString,
    String? urlString,
    String? moduleTitle,
    DateTime? addedAt,
    String? customName,
  }) {
    return IliasFile(
      semesterString: semesterString ?? this.semesterString,
      urlString: urlString ?? this.urlString,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      addedAt: addedAt ?? this.addedAt,
      customName: customName ?? this.customName,
    );
  }
}

class IliasFileManager extends ChangeNotifier {
  String get currentSemestersListKey =>
      "DATA_semestersWithFiles${KITProvider.currentSemesterString}";
  String _filesKeyForSemester(String semesterString) =>
      "DATA_filesFor$semesterString";

  Future<List<String>> getSemestersList() async {
    final prefs = await SharedPreferences.getInstance();

    var semesters = prefs.getStringList(currentSemestersListKey) ??
        [KITProvider.currentSemesterString];

    if (semesters.isEmpty) {
      semesters = [KITProvider.currentSemesterString];
      await prefs.setStringList(currentSemestersListKey, semesters);
    }

    for (final semester in semesters) {
      await _ensureFilesListExists(prefs, semester);
    }

    return semesters;
  }

  Future<void> addCurrentSemesterToSemestersList() async {
    final prefs = await SharedPreferences.getInstance();
    await _addSemesterToSemestersList(prefs, KITProvider.currentSemesterString);
  }

  Future<void> addFile(IliasFile file) async {
    final prefs = await SharedPreferences.getInstance();
    await _addSemesterToSemestersList(prefs, file.semesterString);

    final key = _filesKeyForSemester(file.semesterString);
    final storedEntries = prefs.getStringList(key) ?? <String>[];
    final updatedEntries = List<String>.from(storedEntries);

    // Ensure only one entry per URL to avoid duplicates.
    updatedEntries.removeWhere((stored) {
      final decoded = IliasFile.tryDecode(stored);
      return decoded != null && decoded.urlString == file.urlString;
    });
    final normalizedFile = file.copyWith(
      addedAt: file.addedAt.toUtc(),
      customName: _normalizeCustomName(file.customName, file.moduleTitle),
    );
    updatedEntries.add(normalizedFile.encode());

    await prefs.setStringList(key, updatedEntries);
    notifyListeners();
  }

  Future<void> setFilesForSemester(
      String semesterString, List<IliasFile> files) async {
    final prefs = await SharedPreferences.getInstance();
    await _addSemesterToSemestersList(prefs, semesterString);

    final encodedFiles = files
        .map(
          (file) => file
              .copyWith(
                addedAt: file.addedAt.toUtc(),
                customName: _normalizeCustomName(file.customName, file.moduleTitle),
              )
              .encode(),
        )
        .toList();
    await prefs.setStringList(_filesKeyForSemester(semesterString), encodedFiles);
    notifyListeners();
  }

  Future<void> updateFileCustomName({
    required String semesterString,
    required String urlString,
    required String customName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureFilesListExists(prefs, semesterString);

    final key = _filesKeyForSemester(semesterString);
    final storedEntries = prefs.getStringList(key) ?? <String>[];

    if (storedEntries.isEmpty) {
      return;
    }

    final List<String> updatedEntries = [];
    var updated = false;

    for (final entry in storedEntries) {
      final decoded = IliasFile.tryDecode(entry);
      if (decoded == null) {
        updatedEntries.add(entry);
        continue;
      }

      if (!updated && decoded.urlString == urlString) {
        final updatedFile = decoded.copyWith(
          customName: _normalizeCustomName(customName, decoded.moduleTitle),
          addedAt: decoded.addedAt.toUtc(),
        );
        updatedEntries.add(updatedFile.encode());
        updated = true;
      } else {
        updatedEntries.add(decoded
            .copyWith(
              addedAt: decoded.addedAt.toUtc(),
              customName: _normalizeCustomName(
                decoded.customName,
                decoded.moduleTitle,
              ),
            )
            .encode());
      }
    }

    if (!updated) {
      return;
    }

    await prefs.setStringList(key, updatedEntries);
    notifyListeners();
  }

  Future<void> removeFile({
    required String semesterString,
    required String urlString,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureFilesListExists(prefs, semesterString);

    final key = _filesKeyForSemester(semesterString);
    final storedEntries = prefs.getStringList(key) ?? <String>[];

    if (storedEntries.isEmpty) {
      return;
    }

    final updatedEntries = storedEntries.where((entry) {
      final decoded = IliasFile.tryDecode(entry);
      if (decoded == null) {
        return true;
      }
      return decoded.urlString != urlString;
    }).toList();

    if (updatedEntries.length == storedEntries.length) {
      return;
    }

    await prefs.setStringList(key, updatedEntries);
    notifyListeners();
  }

  Future<List<IliasFile>> getFilesForSemester(String semesterString) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureFilesListExists(prefs, semesterString);

    final entries =
        prefs.getStringList(_filesKeyForSemester(semesterString)) ?? <String>[];
    return entries
        .map(IliasFile.tryDecode)
        .whereType<IliasFile>()
        .toList(growable: false);
  }

  Future<Map<String, List<IliasFile>>> getFilesGroupedBySemester() async {
    final semesters = await getSemestersList();
    final Map<String, List<IliasFile>> grouped = {};

    for (final semester in semesters) {
      grouped[semester] = await getFilesForSemester(semester);
    }

    return grouped;
  }

  String _normalizeCustomName(String customName, String fallbackTitle) {
    final trimmedName = customName.trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }

    final trimmedFallback = fallbackTitle.trim();
    if (trimmedFallback.isNotEmpty) {
      return trimmedFallback;
    }

    return "Unbenannte Datei";
  }

  Future<void> _addSemesterToSemestersList(
      SharedPreferences prefs, String semesterString) async {
    final stored = prefs.getStringList(currentSemestersListKey) ?? <String>[];

    if (!stored.contains(semesterString)) {
      final updated = List<String>.from(stored)..add(semesterString);
      await prefs.setStringList(currentSemestersListKey, updated);
    }

    await _ensureFilesListExists(prefs, semesterString);
  }

  Future<void> _ensureFilesListExists(
      SharedPreferences prefs, String semesterString) async {
    final key = _filesKeyForSemester(semesterString);
    if (!prefs.containsKey(key)) {
      await prefs.setStringList(key, <String>[]);
    }
  }
}
