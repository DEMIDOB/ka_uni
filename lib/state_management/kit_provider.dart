import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:kit_mobile/credentials/models/kit_credentials.dart';
import 'package:kit_mobile/geo/network/KITTopographyManager.dart';
import 'package:kit_mobile/module_info_table/models/module_info_table_cell.dart';
import 'package:kit_mobile/state_management/ilias/ilias_manager.dart';

import '../local_files_storage/files_manager.dart';
import '../module/models/module.dart';
import '../module_info_table/models/module_info_table.dart';
import '../parsing/models/hierarchic_table_row.dart';
import '../student/student.dart';
import '../timetable/models/timetable_weekly.dart';
import 'campus/campus_manager.dart';

class KITProvider extends ChangeNotifier {
  Student student = Student.empty;

  void setCredentials(KITCredentials newCredentials) {
    // _credentials = newCredentials;
    campusManager.credentials = newCredentials;
    iliasManager.credentials = newCredentials;
  }

  String get JSESSIONID => campusManager.JSESSIONID;
  late final CampusManager campusManager;
  late final IliasManager iliasManager;
  late final KITTopographyManager topographyManager;
  late final IliasFilesProvider iliasFileManager;

  bool get profileReady => campusManager.ready;

  TimetableWeekly get timetable => campusManager.timetable;

  KITProvider() {
    if (kDebugMode) {
      print("Instantiating a KITProvider...");
    }
    campusManager = CampusManager(student, notifyListeners);
    campusManager.fetchJSession();

    iliasManager = IliasManager();
    iliasManager.fetchJSession();
    // fetchSchedule();

    topographyManager = KITTopographyManager();
    topographyManager.fetchPlaces();

    iliasFileManager = IliasFilesProvider();
  }

  Future<bool> tryPreloadCache(KITCredentials credentials) async {
    if (!credentials.valid) {
      return false;
    }

    await loadCachedDataAndNotify();
    await prepareCachedData();
    setCredentials(credentials);
    campusManager.ready = true;
    iliasManager.authorize();

    return true;
  }

  Future<void> forceRefetchEverything({bool allModulesAsWell=true}) async {
    await campusManager.forceRefetchEverything(allModulesAsWell: allModulesAsWell);
  }

  HierarchicTableRow? fuzzyFindHierarchicTableRowSimilarTo(HierarchicTableRow exampleRow) {
    int bestMatch = 0;
    HierarchicTableRow? bestMatchRow;

    for (final row in campusManager.moduleRows) {
      final currentMatch = ratio(row.title, exampleRow.title) + ratio(row.id, exampleRow.id) + ratio(row.type, exampleRow.type);
      if (currentMatch >= bestMatch) {
        bestMatch = currentMatch;
        bestMatchRow = row;
      }
    }

    return bestMatchRow;
  }

  String overlayHtmlData = "";
  void dismissOverlayHtml() {
    overlayHtmlData = "";
    notifyListeners();
  }

  Future<void> loadCachedDataAndNotify() async {
    await campusManager.loadStudentData();
    await campusManager.loadCachedTimetable();
    notifyListeners();
  }

  Future fetchSchedule(
      {notify = true,
      retryIfFailed = true,
      secondRetryIfFailed = true,
      refreshSession = true,
      startRefreshTimer = true,
      ignoreIfCached = false}) async {
    final fetchResult = await campusManager.fetchSchedule();
    // Future.delayed(Duration(seconds: 1), iliasManager.authorize);
    return fetchResult;
  }

  Future<KITModule> getOrFetchModuleForRow(HierarchicTableRow row) async {
    return await campusManager.getOrFetchModuleForRow(row);
  }

  Future<bool> toggleIsFavorite(ModuleInfoTableCell cell, KITModule inModule,
      {visual = true}) async {
    return await campusManager.toggleIsFavorite(cell, inModule, anticipate: visual);
  }

  Future<bool> toggleIsFavoriteFuzzy(String targetRowTitleCellBody, String targetTableCaption, String targetModuleTitle) async {
    // 1. try to find the module
    int bestMatchScore = 0, currentScore = 0;
    KITModule? bestMatchModule;

    for (final rowId in campusManager.rowModules.keys) {
      final module = campusManager.rowModules[rowId]!;
      currentScore = ratio(module.title, targetModuleTitle);

      if (currentScore >= bestMatchScore) {
        bestMatchScore = currentScore;
        bestMatchModule = module;
      }
    }

    if (bestMatchModule == null) {
      if (kDebugMode) {
        print("Could not find module with title $targetModuleTitle");
      }
      return false;
    }

    if (kDebugMode) {
      print("Found module with title $targetModuleTitle, score: $bestMatchScore");
    }

    // 2. try to find the table
    int bestMatchTableScore = 0;
    ModuleInfoTable? bestMatchTable;

    for (final table in bestMatchModule.tables) {
      currentScore = ratio(table.caption, targetTableCaption);

      if (currentScore >= bestMatchTableScore) {
        bestMatchTableScore = currentScore;
        bestMatchTable = table;
      }
    }

    if (bestMatchTable == null) {
      if (kDebugMode) {
        print("Could not find table with caption $targetTableCaption");
      }
      return false;
    }

    if (kDebugMode) {
      print("Found table with caption $targetTableCaption, score: $bestMatchTableScore");
    }

    // 3. try to find the cell
    int bestMatchRowScore = 0;
    ModuleInfoTableCell? bestMatchCell;

    final titleCellIndex = bestMatchTable.titleCellIndex;

    for (final row in bestMatchTable.rows) {
      if (row.cells.length <= titleCellIndex) {
        if (kDebugMode) {
          print("Unexpected behavior: row.cells.length <= titleCellIndex");
        }

        continue;
      }
      currentScore = ratio(row.cells[titleCellIndex].body, targetRowTitleCellBody);

      if (currentScore >= bestMatchRowScore && row.favoriteToggleCell != null) {
        bestMatchRowScore = currentScore;
        bestMatchCell = row.favoriteToggleCell;
      }
    }

    if (bestMatchCell == null) {
      if (kDebugMode) {
        print("Could not find row with title $targetRowTitleCellBody, score: $bestMatchRowScore");
      }
      return false;
    }

    return await toggleIsFavorite(bestMatchCell, bestMatchModule);
  }

  static String get currentSemesterString {
    final now = DateTime.now();

    // Winter (handles year transition)
    if ([10, 11, 12].contains(now.month)) {
      return "WS ${now.year % 100}/${(now.year + 1) % 100}";
    }

    if ([1, 2, 3].contains(now.month)) {
      return "WS ${(now.year - 1) % 100}/${now.year % 100}";
    }

    // Summer
    return "SS ${now.year}";
  }

  // TODO: RENAME
  Future<void> clearCookiesAndCache() async {
    await campusManager.clearCookiesAndCache();
  }

  Future<void> prepareCachedData() async {
    await campusManager.prepareRelevantModuleRows();
    notifyListeners();
  }
}
