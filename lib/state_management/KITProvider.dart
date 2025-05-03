import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kit_mobile/credentials/models/kit_credentials.dart';
import 'package:kit_mobile/module_info_table/models/module_info_table_cell.dart';
import 'package:kit_mobile/state_management/util/campus_rp_cookies_manager.dart';
import 'package:kit_mobile/student/name.dart';

import '../module/models/module.dart';
import '../parsing/models/hierarchic_table_row.dart';
import '../student/student.dart';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:requests_plus/requests_plus.dart';

import '../timetable/models/timetable_weekly.dart';
import 'campus/campus_manager.dart';

class KITProvider extends ChangeNotifier {
  Student student = Student(
    name: Name(firstName: "", lastName: "", middleName: ""),
    matriculationNumber: "0000000",
    degreeProgram: "",
    ectsAcquired: "",
    avgMark: "0.0",
  );

  setCredentials(KITCredentials newCredentials) {
    // _credentials = newCredentials;
    campusManager.credentials = newCredentials;
  }

  String get JSESSIONID => campusManager.JSESSIONID;
  late final CampusManager campusManager;

  bool get profileReady => campusManager.profileReady;

  TimetableWeekly get timetable => campusManager.timetable;

  KITProvider() {
    if (kDebugMode) {
      print("Instantiating a KITProvider...");
    }
    campusManager = CampusManager(student, notifyListeners);
    campusManager.fetchJSession();
    // fetchSchedule();
  }


  forceRefetchEverything() async {
    campusManager.forceRefetchEverything();
  }

  String overlayHtmlData = "";
  dismissOverlayHtml() {
    overlayHtmlData = "";
    notifyListeners();
  }

  fetchSchedule({notify = true, retryIfFailed = true, secondRetryIfFailed = true, refreshSession = true, startRefreshTimer = true}) async {
    return await campusManager.fetchSchedule();
  }

  Future<KITModule> getOrFetchModuleForRow(HierarchicTableRow row) async {
    return await campusManager.getOrFetchModuleForRow(row);
  }

  Future<bool> toggleIsFavorite(ModuleInfoTableCell cell, KITModule inModule, {visual = true}) async {
    return await campusManager.toggleIsFavorite(cell, inModule, visual: visual);
  }

  String get currentSemesterString {
    final now = DateTime.now();
    if ([10, 11, 12, 1, 2, 3].contains(now.month)) {
      return "WS ${now.year}";
    }

    return "SS ${now.year}";
  }

  clearCookiesAndCache() async {
    await campusManager.clearCookiesAndCache();
  }

}
