import 'package:flutter/foundation.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:kit_mobile/tutorials/models/tutorial.dart';
import 'package:kit_mobile/timetable/models/timetable_weekly.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialManager extends ChangeNotifier {
  final Map<String, List<Tutorial>> _tutorialsBySemester = {};
  final Set<String> _loadedSemesters = {};
  final Set<String> _loadingSemesters = {};

  TutorialManager() {
    _loadSemester(KITProvider.currentSemesterString);
  }

  bool isSemesterLoaded(String semesterString) =>
      _loadedSemesters.contains(semesterString);

  List<Tutorial> tutorialsForSemester(String semesterString) =>
      List.unmodifiable(_tutorialsBySemester[semesterString] ?? const []);

  List<Tutorial> tutorialsForWeekday(
      String semesterString, Weekday weekday) {
    final tutorials = _tutorialsBySemester[semesterString];
    if (tutorials == null) {
      return const [];
    }

    return tutorials
        .where((tutorial) => tutorial.weekday == weekday)
        .toList(growable: false);
  }

  Future<void> ensureSemesterLoaded(String semesterString) async {
    if (isSemesterLoaded(semesterString)) {
      return;
    }
    await _loadSemester(semesterString);
  }

  Future<void> addOrUpdateTutorial(Tutorial tutorial) async {
    await _ensureSemestersListContains(tutorial.semesterString);
    await _loadSemester(tutorial.semesterString);

    final tutorials =
        List<Tutorial>.from(_tutorialsBySemester[tutorial.semesterString] ?? []);
    final idx = tutorials.indexWhere(
        (existing) => existing.tutorialId == tutorial.tutorialId);

    final sanitizedTitle = tutorial.moduleTitle.trim().isEmpty
        ? tutorial.moduleTitle
        : tutorial.moduleTitle.trim();
    final normalizedTutorial = tutorial.copyWith(
      moduleTitle: sanitizedTitle,
      notes: tutorial.notes,
    );

    if (idx >= 0) {
      tutorials[idx] = normalizedTutorial;
    } else {
      tutorials.add(normalizedTutorial);
    }

    tutorials.sort(_tutorialComparator);
    _tutorialsBySemester[tutorial.semesterString] = tutorials;
    await _persistSemester(tutorial.semesterString);
    notifyListeners();
  }

  Future<void> removeTutorial({
    required String semesterString,
    required String tutorialId,
  }) async {
    await _loadSemester(semesterString);

    final tutorials =
        List<Tutorial>.from(_tutorialsBySemester[semesterString] ?? const []);
    tutorials.removeWhere((tutorial) => tutorial.tutorialId == tutorialId);

    // if (!removed) {
    //   return;
    // }

    tutorials.sort(_tutorialComparator);
    _tutorialsBySemester[semesterString] = tutorials;
    await _persistSemester(semesterString);
    notifyListeners();
  }

  Future<void> _loadSemester(String semesterString) async {
    if (_loadedSemesters.contains(semesterString) ||
        _loadingSemesters.contains(semesterString)) {
      return;
    }

    _loadingSemesters.add(semesterString);

    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_tutorialsKeyForSemester(semesterString));

    if (rawList == null) {
      _tutorialsBySemester[semesterString] = [];
      _loadedSemesters.add(semesterString);
      _loadingSemesters.remove(semesterString);
      notifyListeners();
      return;
    }

    final tutorials = rawList
        .map(Tutorial.tryDecode)
        .whereType<Tutorial>()
        .where((tutorial) => tutorial.semesterString == semesterString)
        .toList();

    tutorials.sort(_tutorialComparator);
    _tutorialsBySemester[semesterString] = tutorials;
    _loadedSemesters.add(semesterString);
    _loadingSemesters.remove(semesterString);
    notifyListeners();
  }

  Future<void> _ensureSemestersListContains(String semesterString) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _semestersListKeyFor(semesterString);
    final stored = prefs.getStringList(key) ?? <String>[];
    if (stored.contains(semesterString)) {
      return;
    }

    final updated = List<String>.from(stored)..add(semesterString);
    await prefs.setStringList(key, updated);
  }

  Future<void> _persistSemester(String semesterString) async {
    final prefs = await SharedPreferences.getInstance();
    final tutorials = _tutorialsBySemester[semesterString] ?? const [];
    final encoded =
        tutorials.map((tutorial) => tutorial.encode()).toList(growable: false);
    await prefs.setStringList(_tutorialsKeyForSemester(semesterString), encoded);
  }

  static int _tutorialComparator(Tutorial a, Tutorial b) {
    if (a.weekday == b.weekday) {
      return a.blockIndex.compareTo(b.blockIndex);
    }
    return a.weekday.idx.compareTo(b.weekday.idx);
  }

  String _tutorialsKeyForSemester(String semesterString) =>
      'DATA_tutorialsFor$semesterString';

  String _semestersListKeyFor(String semesterString) =>
      'DATA_semestersWithTutorials$semesterString';
}
