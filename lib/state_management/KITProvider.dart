import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kit_mobile/credentials/models/kit_credentials.dart';
import 'package:kit_mobile/module_info_table/models/module_info_table_cell.dart';
import 'package:kit_mobile/student/name.dart';

import '../module/models/module.dart';
import '../parsing/models/hierarchic_table_row.dart';
import '../student/student.dart';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:requests_plus/requests_plus.dart';

import '../timetable/models/timetable_weekly.dart';

class KITProvider extends ChangeNotifier {
  Student student = Student(
    name: Name(firstName: "", lastName: "", middleName: ""),
    matriculationNumber: "0000000",
    degreeProgram: "",
    ectsAcquired: "",
    avgMark: "0.0",
  );

  KITCredentials _credentials = KITCredentials();
  KITCredentials get credentials => _credentials;

  setCredentials(KITCredentials newCredentials) {
    _credentials = newCredentials;
  }

  String JSESSIONID = "";
  Map<String, String> _localCookies = {};

  bool profileReady = false;

  List<HierarchicTableRow> moduleRows = [];
  Map<String, KITModule> rowModules = {}; // INDEXING AS row_id: module

  TimetableWeekly timetable = TimetableWeekly();
  
  KITProvider() {
    fetchJSession();
    fetchSchedule();
  }
  
  setCookies(CookieJar cookieJar) {
    cookieJar.forEach((name, cookie) {
      _localCookies[name] = cookie.value;
      // print("Set $name: ${cookie.value}");
    });
  }

  Map<String, String> getCookies() {
    Map<String, String> cookiesCopy = {};
    _localCookies.forEach((key, value) {
      cookiesCopy[key] = value;
    });
    return cookiesCopy;
  }

  applyCookies(String url) {

    if (!url.startsWith("https://campus.kit.edu")) {
      return;
    }
    // return;
    // if (kDebugMode) {
    //   print("Applying cookies to $url");
    // }

    _localCookies.forEach((name, value) {
      RequestsPlus.addCookie(url, name, value);
    });
  }

  bool _hasCookie(String name) {
    return _localCookies.containsKey(name.toLowerCase());
  }

  String _getCookie(String name) {
    return _localCookies[name] ?? "";
  }

  String get _cookiesString {
    String cs = "";
    _localCookies.forEach((key, value) {
      cs += "$key=$value;";
    });
    return cs.substring(0, cs.length - 2);
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

    _localCookies["JSESSIONID"] = cookies["JSESSIONID"]!.value;
    JSESSIONID = _localCookies["JSESSIONID"]!;
    notifyListeners();

    return true;
  }

  forceRefetchEverything() async {
    scheduleFetchingTimer?.cancel();
    scheduleFetchingTimer = null;

    await clearCookiesAndCache();
    await fetchSchedule();
  }

  _fetchScheduleStage0_Init({notify = true, retryIfFailed = true, secondRetryIfFailed = true}) async {
    if (!credentials.isFormatValid) {
      return -1;
    }

    final startedWaitingForModulesFetching = DateTime.now();
    // while (isFetchingModules) {
    //   if (DateTime.now().difference(startedWaitingForModulesFetching).inSeconds > 10) {
    //     return -1;
    //   }
    // }

    scheduleFetchingTimer = null;

    profileReady = false || profileReady;
    clearCookiesAndCache();

    if (notify) {
      notifyListeners();
    }

    if (!(await fetchJSession())) {
      return -2;
    }

    _localCookies.remove("path");
    _localCookies.remove("secure");

    return 0;
  }

  Future<http.Response> _fetchScheduleStage1_TryToOpenLoginPage() async {
    String url = "https://campus.studium.kit.edu/Shibboleth.sso/Login?target=https://campus.studium.kit.edu/exams/registration.php?login=1";

    RequestsPlus.addCookie(url, "JSESSIONID", JSESSIONID);
    applyCookies(url);
    var response = await RequestsPlus.get(url);
    await setCookies(await RequestsPlus.getStoredCookies(url));

    // sometimes, the server wants us to manually redirect us to the login page, idk why
    if (_isManualRedirectRequired(response)) {
      final currentResponse = await _handleNoJSResponse(response.body);
      if (currentResponse == null) {
        print("Stage 1: Manual redirect has failed");
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

    await applyCookies(url);
    var response = await RequestsPlus.post(url, body: formData);
    await setCookies(await RequestsPlus.getStoredCookies(url));

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
        print(url);
        await applyCookies(url);
        response = await RequestsPlus.get(url);
        await setCookies(await RequestsPlus.getStoredCookies(url));
      }
    }

    // print(response.body);

    return response;
  }

  Future<http.Response?> _fetchScheduleStage3_ObtainSchedule(http.Response previousResponse) async {
    String url = "https://campus.studium.kit.edu/redirect.php?system=campus&url=/campus/student/contractview.asp";

    await applyCookies(url);
    var response = await RequestsPlus.get(url);
    await setCookies(await RequestsPlus.getStoredCookies(url));

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

    // print(response.body);
    // print(response.statusCode);

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
      print("Handling no-js redirect: url is $url, cookies: $_cookiesString");
      print("formData: ${formData.keys}");
    }

    await applyCookies(url);
    var response = await RequestsPlus.post(url, body: formData, followRedirects: true);
    await setCookies(await RequestsPlus.getStoredCookies(url));

    if (response.statusCode == 302 && response.headers.containsKey("location")) {
      url = response.headers["location"]!;
      applyCookies(url);
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

  String overlayHtmlData = "";
  dismissOverlayHtml() {
    overlayHtmlData = "";
    notifyListeners();
  }

  Timer? scheduleFetchingTimer;
  fetchSchedule({notify = true, retryIfFailed = true, secondRetryIfFailed = true, refreshSession = true, startRefreshTimer = true}) async {
    if (refreshSession) {
      await clearCookiesAndCache();
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

    moduleRows = [];
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

    student = Student(name: Name(firstName: firstName, lastName: lastName), matriculationNumber: matrn, degreeProgram: degreeProgram, avgMark: rowsSorted[1]?.first.mark ?? "0,0", ectsAcquired: ectsAcquired);

    fetchTimetable().then((_) {
      fetchAllModules();
    });

    profileReady = true;
    notifyListeners();

    if (kDebugMode) {
      print("Got profile data!");
    }

    isFetchingSchedule = false;

    // tmp: create a lock or something to prevent interface glitches
    if (startRefreshTimer) {
      scheduleFetchingTimer ??= Timer(const Duration(minutes: 1), forceRefetchEverything);
    }
  }

  Future<void> fetchTimetable({retryIfFailed = true}) async {
    if (kDebugMode) {
      print("Fetching timetable...");
    }
    final url = "https://campus.studium.kit.edu/redirect.php?system=campus&url=/campus/student/timetable.asp";
    applyCookies(url);
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
    notifyListeners();
  }

  Future<void> fetchAllModules() async {
    isFetchingModules = true;

    if (kDebugMode) {
      print("Fetching all modules");
    }

    for (final row in moduleRows) {
      if (rowModules.containsKey(row.id) && !rowModules[row.id]!.requiresUpdate) {
        continue;
      }
      final module = await fetchModule(row, recursiveRetry: false);
    }

    isFetchingModules = false;
    allModulesFetched = true;
    if (kDebugMode) {
      print("Finished fetching modules!");
    }
  }

  Future<KITModule> fetchModule(HierarchicTableRow row, {recursiveRetry = true}) async {
    final url = row.href;

    await applyCookies(url);
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

    return module;
  }

  bool _isModuleReady(KITModule? module) => module != null && !module.isEmpty;

  Future<KITModule> getOrFetchModule(HierarchicTableRow row) async {
    var module = rowModules[row.id];

    if (_isModuleReady(module)) {
      return module!;
    }

    final completer = Completer();
    Timer(const Duration(seconds: 1), () => completer.complete());
    await completer.future;

    module = rowModules[row.id];
    if (_isModuleReady(module)) {
      return module!;
    }

    return fetchModule(row);
  }

  Future<void> clearCookiesAndCache() async {
    if (kDebugMode) {
      print("Clearing cookies and cache...");
    }
    _localCookies = {};
    await setCookies(CookieJar());
    await RequestsPlus.clearStoredCookies("https://campus.studium.kit.edu/");
    await RequestsPlus.clearStoredCookies("https://idp.scc.kit.edu/");
    await RequestsPlus.clearStoredCookies("https://campus.kit.edu/");
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
      notifyListeners();
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

    notifyListeners();

    return ok;
  }
}

