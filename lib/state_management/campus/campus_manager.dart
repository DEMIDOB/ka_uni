import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:kit_mobile/credentials/models/kit_credentials.dart';
import 'package:kit_mobile/state_management/util/campus_rp_cookies_manager.dart';
import 'package:requests_plus/requests_plus.dart';

import '../../module/models/module.dart';
import '../../module_info_table/models/module_info_table_cell.dart';
import '../../parsing/models/hierarchic_table_row.dart';
import '../../student/name.dart';
import '../../student/student.dart';
import '../../timetable/models/timetable_weekly.dart';

class CampusManager {
  final _cookiesManager = RPCookiesManager();

  String get JSESSIONID => _cookiesManager.JSESSIONID;

  late KITCredentials credentials;

  List<HierarchicTableRow> moduleRows = [];
  Map<String, KITModule> rowModules = {}; // INDEXING AS row_id: module

  TimetableWeekly timetable = TimetableWeekly();

  // Indicators
  bool profileReady = false;

  Student student;

  Function() notificationCallback;

  CampusManager(this.student, this.notificationCallback);

  applyLocalCookiesToUrl(String url) async {
    await _cookiesManager.applyLocalCookiesToUrl(url);
  }

  Future<bool> fetchJSession() async {
    String url = "https://idp.scc.kit.edu/idp/profile/SAML2/Redirect/SSO?execution=e1s1";

    RequestsPlus.clearStoredCookies(url);
    await RequestsPlus.get(url);
    final cookies = await RequestsPlus.getStoredCookies(url);

    if (!cookies.containsKey("JSESSIONID")) {
      if (kDebugMode) {
        print("Failed to obtain JSESSIONID!");
      }
      return false;
    }

    _cookiesManager.JSESSIONID = cookies["JSESSIONID"]!.value;
    // JSESSIONID = _cookiesManager.JSESSIONID;
    // notifyListeners();

    return true;
  }

  forceRefetchEverything() async {
    scheduleFetchingTimer?.cancel();
    scheduleFetchingTimer = null;
    await _cookiesManager.clearCookiesAndCache();
    await fetchSchedule();
  }

  clearCookiesAndCache() async {
    await _cookiesManager.clearCookiesAndCache();
  }

  _fetchScheduleStage0_Init({notify = true, retryIfFailed = true, secondRetryIfFailed = true}) async {
    if (!credentials.isFormatValid) {
      return -1;
    }

    scheduleFetchingTimer = null;

    profileReady = false || profileReady;
    _cookiesManager.clearCookiesAndCache();

    // if (notify) {
    //   notifyListeners();
    // }

    if (!(await fetchJSession())) {
      return -2;
    }

    _cookiesManager.removeLocalCookie("path");
    _cookiesManager.removeLocalCookie("secure");

    return 0;
  }

  Future<http.Response> _fetchScheduleStage1_TryToOpenLoginPage() async {
    String url = "https://campus.studium.kit.edu/Shibboleth.sso/Login?target=https://campus.studium.kit.edu/exams/registration.php?login=1";

    RequestsPlus.addCookie(url, "JSESSIONID", JSESSIONID);
    await _cookiesManager.applyLocalCookiesToUrl(url);
    var response = await RequestsPlus.get(url);
    await _cookiesManager.extractCookiesFromJar(await RequestsPlus.getStoredCookies(url));

    // sometimes, the server wants us to manually redirect us to the login page, idk why
    if (_isManualRedirectRequired(response)) {
      final currentResponse = await _handleNoJSResponse(response.body);
      if (currentResponse == null) {
        if (kDebugMode) {
          print("Stage 1: Manual redirect has failed");
        }
        return response;
      }
      response = currentResponse;
    } else if (kDebugMode) {
      print("Stage 1: No manual redirect is required! Going forward...");
    }

    return response;
  }

  Future<http.Response?> _fetchScheduleStage2_(http.Response previousResponse) async {
    var document = parse(previousResponse.body);
    var forms = document.getElementsByTagName("form");
    String url = "";
    Map<String, dynamic> formData = {};
    bool foundLoginForm = false;

    for (var form in forms) {
      if (form.innerHtml.toLowerCase().contains("login")) {
        final String? action = form.attributes["action"];
        if (action == null) {
          if (kDebugMode) {
            print("login form action is null. Reporting failure...");
          }
          return null;
        }

        // print(action);
        url = "https://idp.scc.kit.edu$action";
        final inputs = form.getElementsByTagName("input");

        for (var input in inputs) {
          String? name = input.attributes["name"];
          if (name != null) {
            formData[name] = input.attributes["value"] ?? "";
          }
        }

        foundLoginForm = true;
        break;
      }
    }

    if (!foundLoginForm) {
      if (kDebugMode) {
        print("Failed to find the login form!");
        print(previousResponse.body);
      }
      return null;
    }

    formData["_eventId_proceed"] = "";
    formData["_shib_idp_revokeConsent"] = false;
    formData["j_username"] = credentials.username;
    formData["j_password"] = credentials.password;

    if (kDebugMode) {
      print("Successfully found the login form. Data provided: $formData");
    }

    await _cookiesManager.applyLocalCookiesToUrl(url);
    var response = await RequestsPlus.post(url, body: formData);
    await _cookiesManager.extractCookiesFromJar(await RequestsPlus.getStoredCookies(url));

    if (_isManualRedirectRequired(response)) {
      final currentResponse = await _handleNoJSResponse(response.body);
      if (currentResponse == null) {
        if (kDebugMode) {
          print("Stage 2: Failed to handle NO-JS RelayState response!");
        }
        return response;
      }

      response = currentResponse;
    } else if (kDebugMode) {
      print("Stage 2: Skipped manual redirect");
    }

    if (response.statusCode == 302) {
      if (kDebugMode) {
        print("Stage 2: redirect required!");
      }

      if (response.headers.containsKey("location")) {
        final location = response.headers["location"]!;
        url = "https://idp.scc.kit.edu$location";
        if (kDebugMode) {
          print(url);
        }
        await _cookiesManager.applyLocalCookiesToUrl(url);
        response = await RequestsPlus.get(url);
        await _cookiesManager.extractCookiesFromJar(await RequestsPlus.getStoredCookies(url));
      }
    }

    return response;
  }

  Future<http.Response?> _fetchScheduleStage3_ObtainSchedule(http.Response previousResponse) async {
    String url = "https://campus.studium.kit.edu/redirect.php?system=campus&url=/campus/student/contractview.asp";

    final allowedCookies = ["_shibsession_campus-prod-sp", "session-campus-prod-sp"];
    _cookiesManager.filterCookies(allowedCookieNames: allowedCookies);
    await _cookiesManager.applyLocalCookiesToUrl(url);
    var response = await RequestsPlus.get(url);
    await _cookiesManager.extractCookiesFromJar(await RequestsPlus.getStoredCookies(url));

    if (_isManualRedirectRequired(response)) {
      if (kDebugMode) {
        print("Stage 3: manual redirect is required");
      }
      final currentResponse = await _handleNoJSResponse(response.body);
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

  Future<http.Response?> _handleNoJSResponse(String body) async {
    if (kDebugMode) {
      print("Attempting to handle the no-js manual redirect...");
    }

    final document = parse(body);
    final forms = document.getElementsByTagName("form");
    Map<String, dynamic> formData = {};
    String url = "";

    for (var form in forms) {
      if (form.innerHtml.toLowerCase().contains("relaystate")) {
        final String? action = form.attributes["action"];
        if (action == null) {
          if (kDebugMode) {
            print("Handling no-js redirect: action is null. Reporting failure...");
          }
          return null;
        }

        url = action;
        final inputs = form.getElementsByTagName("input");

        for (var input in inputs) {
          String? name = input.attributes["name"];
          if (name != null) {
            formData[name] = input.attributes["value"] ?? "";
          }
        }

        break;
      }
    }

    if (url.isEmpty) {
      if (kDebugMode) {
        print("Handling no-js redirect: url is empty. Reporting failure...");
      }
      return null;
    }

    if (kDebugMode) {
      print("Handling no-js redirect: url is $url, cookies: ${_cookiesManager.cookiesString}");
      print("formData: ${formData.keys}");
    }

    await _cookiesManager.applyLocalCookiesToUrl(url);
    var response = await RequestsPlus.post(url, body: formData, followRedirects: true);
    await _cookiesManager.extractCookiesFromJar(await RequestsPlus.getStoredCookies(url));

    if (response.statusCode == 302 && response.headers.containsKey("location")) {
      url = response.headers["location"]!;
      await _cookiesManager.applyLocalCookiesToUrl(url);
      response = await RequestsPlus.get(url);
    }

    return response;
  }

  bool _isManualRedirectRequired(http.Response response) {
    return response.body.contains("you must press the Continue button") || response.body.contains("relaystate");
  }

  // fetchScheduleStage1_
  bool isFetchingSchedule = false;
  bool isFetchingModules = false;
  bool allModulesFetched = false;

  Timer? scheduleFetchingTimer;
  fetchSchedule({notify = true, retryIfFailed = true, secondRetryIfFailed = true, refreshSession = true, startRefreshTimer = true}) async {
    if (refreshSession) {
      await _cookiesManager.clearCookiesAndCache();
    }

    isFetchingSchedule = true;
    await _fetchScheduleStage0_Init(notify: notify, retryIfFailed: retryIfFailed, secondRetryIfFailed: secondRetryIfFailed);
    http.Response response = await _fetchScheduleStage1_TryToOpenLoginPage();

    // stage 2
    final stage2Response = await _fetchScheduleStage2_(response);
    if (stage2Response == null) {
      if (kDebugMode) {
        print("Stage 2 failed!");
      }
    } else {
      response = stage2Response;
    }

    // stage 3
    final stage3Response = await _fetchScheduleStage3_ObtainSchedule(response);
    if (stage3Response == null) {
      if (kDebugMode) {
        print("Stage 3 failed!");
      }
      return;
    }
    response = stage3Response;

    // parse the response
    var document = parse(response.body);

    String firstName = "", lastName = "", matrn = "";
    String degreeProgram = "";
    String ectsAcquired = "";

    // parsing name and matrikelnummer (contained in a div.pagination)
    document.getElementsByClassName("pagination").forEach((element) {
      final divs = element.getElementsByTagName("div");
      if (divs.isNotEmpty) {
        var nameAndMatrn = divs[0].innerHtml;
        nameAndMatrn = nameAndMatrn.replaceAll("\n", "").replaceAll(" ", "").replaceAll("(", ",").replaceAll(")", "");
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

    _clearRows();
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
        await fetchSchedule(retryIfFailed: secondRetryIfFailed, secondRetryIfFailed: false);
      }

      return;
    }

    degreeProgram = rowsSorted[1]?.first.title ?? "";
    ectsAcquired = rowsSorted[1]?.first.pointsAcquired ?? "";

    student.set(name: Name(firstName: firstName, lastName: lastName), matriculationNumber: matrn, degreeProgram: degreeProgram, avgMark: rowsSorted[1]?.first.mark ?? "0,0", ectsAcquired: ectsAcquired);

    fetchTimetable().then((_) {
      fetchAllModules();
    });

    profileReady = true;
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

  Future<void> fetchAllModules() async {
    isFetchingModules = true;

    if (kDebugMode) {
      print("Fetching all modules");
    }

    for (final row in moduleRows) {
      if (row.level < 4) {
        continue;
      }

      if (kDebugMode) print("Fetching ${row.title}");
      // if (rowModules.containsKey(row.id) && !rowModules[row.id]!.requiresUpdate) {
      //   if (kDebugMode) print("oh, actually not");
      //   return;
      // }
      final newModule = await getOrFetchModuleForRow(row, retryIfFailed: false);
      if (newModule.iliasLink != null) {
        _addRelevantModuleRow(row);
      }
    }

    isFetchingModules = false;
    allModulesFetched = true;
    if (kDebugMode) {
      print("Finished fetching modules!");
    }
  }

  Future<KITModule> fetchModule(HierarchicTableRow row, {recursiveRetry = true}) async {
    final url = row.href;

    await _cookiesManager.applyLocalCookiesToUrl(url);
    final response = await RequestsPlus.get(url);

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

    module.hierarchicalTableRowId = row.id;

    final prevModuleData = rowModules[module.hierarchicalTableRowId];
    if (prevModuleData != null && module.isEmpty && !prevModuleData.isEmpty) {
      _addRelevantModuleRow(row);
      return prevModuleData;
    }

    if (module.isEmpty && recursiveRetry) {
      if (kDebugMode) {
        print("Failed to fetch the module. Possible reason: session expired. Retrying...");
      }
      await forceRefetchEverything();
      return fetchModule(row, recursiveRetry: false);
    }

    rowModules[module.hierarchicalTableRowId] = module;

    _addRelevantModuleRow(row);
    return module;
  }

  Future<KITModule> getOrFetchModuleForRow(HierarchicTableRow row, {retryIfFailed = true}) async {
    var module = rowModules[row.id];

    if (_isModuleReady(module)) {
      return module!;
    }

    final completer = Completer();
    Timer(const Duration(seconds: 1), () => completer.complete());
    await completer.future;

    module = rowModules[row.id];
    if (_isModuleReady(module)) {
      _addRelevantModuleRow(row);
      return module!;
    }

    return fetchModule(row, recursiveRetry: retryIfFailed);
  }

  bool _isModuleReady(KITModule? module) => module != null && !module.isEmpty;

  List<String> relevantModuleRowIDs = [];

  _addRelevantModuleRow(HierarchicTableRow row, {keepSorted = true}) {
    if (kDebugMode) {
      // print("Requested to add ${row.title} as relevant");
    }
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
      if (kDebugMode) print("ilias link is not there :(");
      return;
    }

    // there is not so many of them
    if (relevantModuleRowIDs.contains(row.id)) {
      if (kDebugMode) print("There already exists this module");
      return;
    }

    if (keepSorted) {
      if (kDebugMode) print("Sorting! (${row.mark})");

      bool hasNumber = false;
      for (final num in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]) {
        if (row.mark.contains("${num}")) {
          if (kDebugMode) print("has number");
          hasNumber = true;
          break;
        }
      }

      if (hasNumber) {
        relevantModuleRowIDs.add(row.id);
      }
      else {
        int insertAt = 0;
        while (insertAt < relevantModuleRowIDs.length && !module.hasFavoriteChild && rowModules[relevantModuleRowIDs[insertAt]]!.hasFavoriteChild) {
          insertAt++;
        }
        relevantModuleRowIDs.insert(insertAt, row.id);
      }
    } else {
      if (kDebugMode) print("Not soring -_-");
      relevantModuleRowIDs.add(row.id);
    }

    notificationCallback();
  }

  Future<bool> toggleIsFavorite(ModuleInfoTableCell cell, KITModule inModule, {visual=true}) async {
    if (cell.objectValue.isEmpty) {
      if (kDebugMode) {
        print("Failed to toggle a non-toggable cell ${cell.body}");
      }
      return false;
    }

    String action = cell.isFavorite ? "removeeventfavorite" : "addeventfavorite";
    bool newSupposedValue = !cell.isFavorite;
    if (visual) {
      cell.isFavorite = newSupposedValue;
      notificationCallback();
    }

    const url = "https://campus.kit.edu/sp/campus/student/specificModuleView.asp";

    final response = await RequestsPlus.post(url, body: {action: cell.objectValue}, followRedirects: true);
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
  _clearRows() {
    moduleRows = [];
    relevantModuleRowIDs = [];
  }


  Future<void> fetchTimetable({retryIfFailed = true}) async {
    if (kDebugMode) {
      print("Fetching timetable...");
    }
    final url = "https://campus.studium.kit.edu/redirect.php?system=campus&url=/campus/student/timetable.asp";
    await _cookiesManager.applyLocalCookiesToUrl(url);
    final response = await RequestsPlus.get(url);

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