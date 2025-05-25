import 'dart:async';

import 'package:async_locks/async_locks.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:kit_mobile/state_management/kit_loginer.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../module/models/module.dart';
import '../../module_info_table/models/module_info_table_cell.dart';
import '../../parsing/models/hierarchic_table_row.dart';
import '../../student/name.dart';
import '../../student/student.dart';
import '../../timetable/models/timetable_weekly.dart';

class CampusManager extends KITLoginer {
  List<HierarchicTableRow> moduleRows = [];
  Map<String, KITModule> rowModules = {}; // INDEXING AS row_id: module

  TimetableWeekly timetable = TimetableWeekly();

  Student student;

  Function() notificationCallback;

  bool isFetchingSchedule = false;
  bool isFetchingModules = false;
  bool allModulesFetched = false;

  Timer? scheduleFetchingTimer;

  bool _isModuleReady(KITModule? module) => module != null && !module.isEmpty;

  List<String> relevantModuleRowIDs = [];
  String get _relevantModuleRowsStorageKey =>
      "RMR ${KITProvider.currentSemesterString}";

  CampusManager(this.student, this.notificationCallback);

  forceRefetchEverything() async {
    scheduleFetchingTimer?.cancel();
    scheduleFetchingTimer = null;
    await clearCookiesAndCache();
    await fetchSchedule();
  }

  Future<http.Response?> _fetchScheduleStage3_ObtainSchedule(
      http.Response previousResponse) async {
    String url =
        "https://campus.studium.kit.edu/redirect.php?system=campus&url=/campus/student/contractview.asp";

    // final allowedCookies = ["_shibsession_campus-prod-sp", "session-campus-prod-sp"];
    var response = await session.get(Uri.parse(url));

    if (isManualRedirectRequired(response)) {
      if (kDebugMode) {
        print("Stage 3: manual redirect is required");
      }
      final currentResponse = await handleNoJSResponse(response.body);
      if (currentResponse == null) {
        if (kDebugMode) {
          print("Failed to handle NO-JS RelayState response!");
        }
        return null;
      }

      response = currentResponse;
    }

    return response;
  }

  fetchSchedule(
      {notify = true,
      retryIfFailed = true,
      secondRetryIfFailed = true,
      refreshSession = true,
      startRefreshTimer = true}) async {
    if (isFetchingSchedule) {
      // TODO: notify user (haptic?)
      if (kDebugMode) {
        print("Rejected fetchSchedule call: already being fetched");
      }
      return;
    }

    if (refreshSession) {
      await clearCookiesAndCache();
    }

    isFetchingSchedule = true;
    await fetchStage0_Init(
        notify: notify,
        retryIfFailed: retryIfFailed,
        secondRetryIfFailed: secondRetryIfFailed);
    http.Response currentResponse = await fetchStage1_TryToOpenLoginPage(
        "https://campus.studium.kit.edu/Shibboleth.sso/Login?target=https://campus.studium.kit.edu/exams/registration.php?login=1");

    // stage 2
    final stage2Response = await fetchStage2_(currentResponse);
    if (stage2Response == null) {
      if (kDebugMode) {
        print("Stage 2 failed!");
      }
    } else {
      currentResponse = stage2Response;
    }

    // stage 3
    final stage3Response =
        await _fetchScheduleStage3_ObtainSchedule(currentResponse);
    if (stage3Response == null) {
      if (kDebugMode) {
        print("Stage 3 failed!");
      }
      return;
    }
    currentResponse = stage3Response;

    // parse the response
    var document = parse(currentResponse.body);

    String firstName = "", lastName = "", matrn = "";
    String degreeProgram = "";
    String ectsAcquired = "";

    // parsing name and matrikelnummer (contained in a div.pagination)
    document.getElementsByClassName("pagination").forEach((element) {
      final divs = element.getElementsByTagName("div");
      if (divs.isNotEmpty) {
        var nameAndMatrn = divs[0].innerHtml;
        nameAndMatrn = nameAndMatrn
            .replaceAll("\n", "")
            .replaceAll(" ", "")
            .replaceAll("(", ",")
            .replaceAll(")", "");
        final nameAndMatrnSplit = nameAndMatrn.split(",");
        if (nameAndMatrnSplit.isNotEmpty) {
          lastName = nameAndMatrnSplit.removeAt(0);
        }

        if (nameAndMatrnSplit.isNotEmpty) {
          firstName = nameAndMatrnSplit.removeAt(0);
        }

        if (nameAndMatrnSplit.isNotEmpty) {
          matrn = nameAndMatrnSplit.removeAt(0);
        }
      }
    });

    Map<int, List<HierarchicTableRow>> rowsSorted = {};

    document.getElementsByClassName("hierarchy1").forEach((element) {
      try {
        HierarchicTableRow.parseTr(element, rowsSorted);
      } catch (exc) {
        if (kDebugMode) {
          print(exc);
        }
      }
    });

    _clearRows(clearRelevants: student.name.firstName.isEmpty);
    document.getElementsByClassName("tablecontent").forEach((tbody) {
      tbody.getElementsByTagName("tr").forEach((tr) {
        try {
          final row = HierarchicTableRow.parseTr(tr, rowsSorted);
          if (row != null) {
            moduleRows.add(row);
          }
        } catch (exc) {
          if (kDebugMode) {
            print(exc);
          }
        }
      });
    });

    if (rowsSorted[1]?.first.mark.replaceAll(",", ".") == null) {
      if (kDebugMode) {
        print(rowsSorted);
        print("No row. Failed to fetch for now. Retrying...");
      }

      if (retryIfFailed) {
        await fetchSchedule(
            retryIfFailed: secondRetryIfFailed, secondRetryIfFailed: false);
      }

      return;
    }

    degreeProgram = rowsSorted[1]?.first.title ?? "";
    ectsAcquired = rowsSorted[1]?.first.pointsAcquired ?? "";

    student.set(
        name: Name(firstName: firstName, lastName: lastName),
        matriculationNumber: matrn,
        degreeProgram: degreeProgram,
        avgMark: rowsSorted[1]?.first.mark ?? "0,0",
        ectsAcquired: ectsAcquired);

    fetchTimetable().then((_) {
      fetchAllModules();
    });

    ready = true;
    notificationCallback();

    if (kDebugMode) {
      print("Got profile data!");
    }

    isFetchingSchedule = false;

    // TODO: reenable
    // tmp: create a lock or something to prevent interface glitches
    if (startRefreshTimer) {
      // scheduleFetchingTimer ??= Timer(const Duration(minutes: 1), forceRefetchEverything);
    }
  }

  Future<void> fetchModulesForRows(List<HierarchicTableRow> rowsToFetch,
      {inParallel = true}) async {
    if (rowsToFetch.isEmpty) {
      return;
    }

    if (inParallel) {
      List<Future<KITModule>> newModuleFutures = [];

      for (final row in rowsToFetch) {
        if (row.level < 4) {
          continue;
        }

        final newModuleFuture =
            getOrFetchModuleForRow(row, retryIfFailed: false);
        newModuleFutures.add(newModuleFuture);
      }

      final newModules = await Future.wait(newModuleFutures);

      for (final newModule in newModules) {
        if (newModule.iliasLink != null && newModule.row != null) {
          _addRelevantModuleRow(newModule.row!);
        }
      }
    } else {
      for (final row in rowsToFetch) {
        if (row.level < 4) {
          continue;
        }

        final newModule =
            await getOrFetchModuleForRow(row, retryIfFailed: false);
        if (newModule.iliasLink != null) {
          _addRelevantModuleRow(row);
        }
      }
    }
  }

  Future<void> fetchAllModules({inParallel = true}) async {
    isFetchingModules = true;

    if (kDebugMode) {
      print("Fetching all modules");
    }

    await prepareRelevantModuleRows();
    List<HierarchicTableRow> rowsToFetch = [], lessImportantRows = [];
    List<HierarchicTableRow> preSort =
        List<HierarchicTableRow>.from(moduleRows);
    preSort.sort((row1, row2) {
      return -(row1.relevancyRank - row2.relevancyRank);
    });

    for (final row in preSort) {
      if (relevantModuleRowIDs.contains(row.id)) {
        rowsToFetch.add(row);
      } else {
        lessImportantRows.add(row);
      }
    }

    // rowsToFetch = rowsToFetch + lessImportantRows;

    if (kDebugMode) {
      for (final row in rowsToFetch) {
        print("Fethcing ${row.title}");
      }
    }

    await fetchModulesForRows(rowsToFetch, inParallel: inParallel);
    if (kDebugMode) {
      print("Fetched the most important rows!");
    }
    await fetchModulesForRows(lessImportantRows, inParallel: inParallel);

    isFetchingModules = false;
    allModulesFetched = true;
    if (kDebugMode) {
      print("Finished fetching modules!");
    }
  }

  Future<KITModule> fetchModule(HierarchicTableRow row,
      {recursiveRetry = true}) async {
    final url = row.href;

    final response = await session.get(Uri.parse(url));

    var module = KITModule();

    if (rowModules.containsKey(row.id)) {
      module = rowModules[row.id]!;
    }

    module.parseModulePage(response.body);

    if (module.grade == "0,0" && row.mark.isNotEmpty) {
      module.grade = row.mark;
    }

    if (module.title.trim().isEmpty) {
      module.title = row.title;
    }

    module.row = row;
    module.hierarchicalTableRowId = row.id;

    final prevModuleData = rowModules[module.hierarchicalTableRowId];
    if (prevModuleData != null && module.isEmpty && !prevModuleData.isEmpty) {
      _addRelevantModuleRow(row);
      return prevModuleData;
    }

    if (module.isEmpty && recursiveRetry) {
      if (kDebugMode) {
        print(
            "Failed to fetch the module. Possible reason: session expired. Retrying...");
      }
      await forceRefetchEverything();
      return fetchModule(row, recursiveRetry: false);
    }

    rowModules[module.hierarchicalTableRowId] = module;

    _addRelevantModuleRow(row);
    return module;
  }

  Future<KITModule> getOrFetchModuleForRow(HierarchicTableRow row,
      {retryIfFailed = true}) async {
    var module = rowModules[row.id];

    if (_isModuleReady(module)) {
      return module!;
    }

    module = rowModules[row.id];
    if (_isModuleReady(module)) {
      _addRelevantModuleRow(row);
      return module!;
    }

    return fetchModule(row, recursiveRetry: retryIfFailed);
  }

  Future<void> prepareRelevantModuleRows() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_relevantModuleRowsStorageKey);
    if (kDebugMode) {
      print("Stored $stored");
    }
    relevantModuleRowIDs = stored ?? relevantModuleRowIDs;
  }

  storeRelevantModuleRows() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _relevantModuleRowsStorageKey, relevantModuleRowIDs);
  }

  resetRelevantModules() async {
    relevantModuleRowIDs = [];
    await storeRelevantModuleRows();
    if (kDebugMode) {
      print("Done resetting relevant modules!");
    }
  }

  final Lock _addRelevantModuleLock = Lock();
  _addRelevantModuleRow(HierarchicTableRow row, {keepSorted = true}) async {
    await _addRelevantModuleLock.run(() async {
      final module = rowModules[row.id];
      if (module == null) {
        if (kDebugMode) print("Somehow module is null :(");
        return;
      }

      // final rowLevelAccepted = 3;
      // if (row.level != rowLevelAccepted) {
      //   return;
      // }

      // double-check if the module is relevant (there must be an ilias-course link)
      if (module.iliasLink == null || module.iliasLink!.isEmpty) {
        if (kDebugMode) print("${module.title} ilias link is not there :(");
        return;
      }

      // there is not so many of them
      while (relevantModuleRowIDs.remove(row.id)) {
        if (kDebugMode) print("There already exists this module");
      }

      if (keepSorted) {
        if (kDebugMode) print("Sorting! (${row.mark})");

        bool hasNumber = false;
        for (final num in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]) {
          if (row.mark.contains("$num")) {
            if (kDebugMode) print("has number");
            hasNumber = true;
            break;
          }
        }

        if (hasNumber) {
          relevantModuleRowIDs.add(row.id);
        } else {
          int insertAt = 0;
          while (insertAt < relevantModuleRowIDs.length &&
              !module.hasFavoriteChild &&
              rowModules[relevantModuleRowIDs[insertAt]]!.hasFavoriteChild) {
            insertAt++;
          }
          relevantModuleRowIDs.insert(insertAt, row.id);
        }
      } else {
        if (kDebugMode) print("Not soring -_-");
        relevantModuleRowIDs.add(row.id);
      }

      storeRelevantModuleRows();
      notificationCallback();
    });
  }

  Future<bool> toggleIsFavorite(ModuleInfoTableCell cell, KITModule inModule,
      {visual = true}) async {
    if (cell.objectValue.isEmpty) {
      if (kDebugMode) {
        print("Failed to toggle a non-toggable cell ${cell.body}");
      }
      return false;
    }

    String action =
        cell.isFavorite ? "removeeventfavorite" : "addeventfavorite";
    bool newSupposedValue = !cell.isFavorite;
    if (visual) {
      cell.isFavorite = newSupposedValue;
      notificationCallback();
    }

    const url =
        "https://campus.kit.edu/sp/campus/student/specificModuleView.asp";

    final response =
        await session.post(Uri.parse(url), body: {action: cell.objectValue});
    final ok = !response.body.toLowerCase().contains("sitzung ist abgelaufen");

    for (final row in moduleRows) {
      if (row.id == inModule.hierarchicalTableRowId) {
        fetchModule(row).then((_) => fetchTimetable());
        break;
      }
    }

    if (!ok) {
      cell.isFavorite = !cell.isFavorite;
    }

    notificationCallback();

    return ok;
  }

  // Rows:
  _clearRows({clearRelevants = false}) {
    moduleRows = [];
    if (clearRelevants) {
      relevantModuleRowIDs = [];
    }
  }

  Future<void> fetchTimetable({retryIfFailed = true}) async {
    if (kDebugMode) {
      print("Fetching timetable...");
    }
    final url =
        "https://campus.studium.kit.edu/redirect.php?system=campus&url=/campus/student/timetable.asp";
    final response = await session.get(Uri.parse(url));

    final timetableUpdate = TimetableWeekly.parseFromHtmlString(response.body);
    if (timetableUpdate == null) {
      if (kDebugMode) {
        print("Failed to update the timetable!");
      }
      if (retryIfFailed) {
        return fetchTimetable(retryIfFailed: false);
      }
      return;
    }
    timetable = timetableUpdate;
    notificationCallback();
  }
}
