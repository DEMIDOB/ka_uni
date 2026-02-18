import 'package:flutter/foundation.dart';
import 'package:kit_mobile/local_files_storage/local_file_storage_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state_management/kit_provider.dart';
import 'models/pinned_file.dart';

const String semestersListKey = "DATA_semestersWithFiles";

class IliasFilesProvider extends ChangeNotifier {
  LocalFileStorageManager localFileStorageManager = LocalFileStorageManager();

  String _filesKeyForSemester(String semesterString) =>
      "DATA_filesFor$semesterString";

  Future<List<String>> getSemestersList() async {
    final prefs = await SharedPreferences.getInstance();

    var semesters = prefs.getStringList(semestersListKey) ??
        [KITProvider.currentSemesterString];

    if (semesters.isEmpty) {
      semesters = [KITProvider.currentSemesterString];
      await prefs.setStringList(semestersListKey, semesters);
    }

    for (final semester in semesters) {
      await _ensurePinnedFilesListExists(prefs, semester);
    }

    return semesters;
  }

  Future<void> addCurrentSemesterToSemestersList() async {
    final prefs = await SharedPreferences.getInstance();
    await _addSemesterToSemestersList(prefs, KITProvider.currentSemesterString);
  }

  Future<void> addPinnedFile(PinnedFile newFile) async {
    final prefs = await SharedPreferences.getInstance();
    await _addSemesterToSemestersList(prefs, newFile.semesterString);

    final key = _filesKeyForSemester(newFile.semesterString);
    final storedEntries = prefs.getStringList(key) ?? <String>[];
    final updatedEntries = List<String>.from(storedEntries);

    // Ensure only one entry per URL to avoid duplicates.
    updatedEntries.removeWhere((stored) {
      final decoded = PinnedFile.tryDecode(stored);
      return decoded != null && decoded.urlString == newFile.urlString;
    });
    final normalizedFile = newFile.copyWith(
      addedAt: newFile.addedAt.toUtc(),
      customName: _normalizeCustomName(newFile.customName, newFile.moduleTitle),
    );
    updatedEntries.add(normalizedFile.encode());

    await prefs.setStringList(key, updatedEntries);
    notifyListeners();
  }

  Future<void> setPinnedFilesListForSemester(
      String semesterString, List<PinnedFile> files) async {
    final prefs = await SharedPreferences.getInstance();
    await _addSemesterToSemestersList(prefs, semesterString);

    final encodedFiles = files
        .map(
          (file) => file
              .copyWith(
                addedAt: file.addedAt.toUtc(),
                customName:
                    _normalizeCustomName(file.customName, file.moduleTitle),
              )
              .encode(),
        )
        .toList();

    await prefs.setStringList(
        _filesKeyForSemester(semesterString), encodedFiles);
    notifyListeners();
  }

  Future<void> updatePinnedFileCustomName({
    required String semesterString,
    required String urlString,
    required String customName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensurePinnedFilesListExists(prefs, semesterString);

    final key = _filesKeyForSemester(semesterString);
    final storedEntries = prefs.getStringList(key) ?? <String>[];

    if (storedEntries.isEmpty) {
      return;
    }

    final List<String> updatedEntries = [];
    var updated = false;

    for (final entry in storedEntries) {
      final decoded = PinnedFile.tryDecode(entry);
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

  Future<void> unpinFile({
    required String semesterString,
    required String urlString,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensurePinnedFilesListExists(prefs, semesterString);

    final key = _filesKeyForSemester(semesterString);
    final storedEntries = prefs.getStringList(key) ?? <String>[];

    if (storedEntries.isEmpty) {
      return;
    }

    final updatedEntries = storedEntries.where((entry) {
      final decoded = PinnedFile.tryDecode(entry);
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

  Future<List<PinnedFile>> getFilesForSemester(String semesterString) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensurePinnedFilesListExists(prefs, semesterString);

    final entries =
        prefs.getStringList(_filesKeyForSemester(semesterString)) ?? <String>[];
    return entries
        .map(PinnedFile.tryDecode)
        .whereType<PinnedFile>()
        .toList(growable: false);
  }

  Future<List<PinnedFile>> getFilesForCurrentSemester() async {
    return getFilesForSemester(KITProvider.currentSemesterString);
  }

  Future<Map<String, List<PinnedFile>>> getFilesGroupedBySemester() async {
    final semesters = await getSemestersList();
    final Map<String, List<PinnedFile>> grouped = {};

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
    final stored = prefs.getStringList(semestersListKey) ?? <String>[];

    if (!stored.contains(semesterString)) {
      final updated = List<String>.from(stored)..add(semesterString);
      await prefs.setStringList(semestersListKey, updated);
    }

    await _ensurePinnedFilesListExists(prefs, semesterString);
  }

  Future<void> _ensurePinnedFilesListExists(
      SharedPreferences prefs, String semesterString) async {
    final key = _filesKeyForSemester(semesterString);
    if (!prefs.containsKey(key)) {
      await prefs.setStringList(key, <String>[]);
    }
  }
}
