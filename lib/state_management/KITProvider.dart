import 'dart:async';
// import 'dart:html';
// import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:kit_mobile/credentials/models/kit_credentials.dart';
import 'package:kit_mobile/student/name.dart';
import 'package:provider/provider.dart';

import '../module/models/module.dart';
import '../parsing/models/hierarchic_table_row.dart';
import '../student/student.dart';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:requests_plus/requests_plus.dart';

import '../timetable/models/timetable_weekly.dart';

class KITProvider extends ChangeNotifier {
  Student student = Student(
    name: Name(firstName: "Daniil", lastName: "Demidov", middleName: "K"),
    matriculationNumber: "2502709",
    degreeProgram: "Mathematik",
    ectsAcquired: "",
    avgMark: "2.1",
  );

  KITCredentials _credentials = KITCredentials();
  KITCredentials get credentials => _credentials;

  setCredentials(KITCredentials newCredentials) {
    _credentials = newCredentials;
  }

  String JSESSIONID = "";
  Map<String, String> _localCookies = {};

  bool profileReady = false;

  List<HierarchicTableRow> rows = [];

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
    print("Applying cookies to $url");

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

    // RequestsPlus.clearStoredCookies(url);
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

  _fetchScheduleStage0_Init({notify = true, retryIfFailed = true, secondRetryIfFailed = true}) async {
    if (!credentials.isFormatValid) {
      return -1;
    }

    scheduleFetchingTimer = null;

    profileReady = false || profileReady;

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

  // fetchScheduleStage1_

  Timer? scheduleFetchingTimer;
  fetchSchedule({notify = true, retryIfFailed = true, secondRetryIfFailed = true}) async {
    // return await _fetchScheduleStage0_Init(notify: notify, retryIfFailed: retryIfFailed, secondRetryIfFailed: secondRetryIfFailed);
    if (!credentials.isFormatValid) {
      return;
    }

    scheduleFetchingTimer = null;

    profileReady = false || profileReady;

    if (notify) {
      notifyListeners();
    }

    if (!(await fetchJSession())) {
      return;
    }

    _localCookies.remove("path");
    _localCookies.remove("secure");

    String url = "https://campus.studium.kit.edu/Shibboleth.sso/Login?target=https://campus.studium.kit.edu/exams/registration.php?login=1";

    RequestsPlus.addCookie(url, "JSESSIONID", JSESSIONID);
    var response = await RequestsPlus.get(url);
    await setCookies(await RequestsPlus.getStoredCookies(url));

    var document = parse(response.body);
    var forms = document.getElementsByTagName("form");
    print(response.body);

    Map<String, dynamic> formData = {};

    for (var form in forms) {
      if (form.innerHtml.toLowerCase().contains("login")) {
        final String? action = form.attributes["action"];
        if (action == null) {
          if (kDebugMode) {
            print("1st auth stage: action is null. Reporting failure...");
          }
          return;
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

        break;
      }
    }

    formData["_eventId_proceed"] = "";
    formData["_shib_idp_revokeConsent"] = false;
    formData["j_username"] = credentials.username;
    formData["j_password"] = credentials.password;

    await applyCookies(url);
    response = await RequestsPlus.post(url, body: formData);
    await setCookies(await RequestsPlus.getStoredCookies(url));

    forms = document.getElementsByTagName("form");
    formData = {};

    for (var form in forms) {
      if (form.innerHtml.toLowerCase().contains("relaystate")) {
        final String? action = form.attributes["action"];
        if (action == null) {
          if (kDebugMode) {
            print("2nd auth stage: action is null. Reporting failure...");
          }
          return;
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

    applyCookies(url);

    response = await RequestsPlus.post(url, body: formData);
    setCookies(await RequestsPlus.getStoredCookies(url));

    url = "https://campus.studium.kit.edu/redirect.php?system=campus&page=/exams/registration.php&lang=de&url=https://campus.kit.edu/sp/campus/student/contractview.asp";

    await applyCookies(url);
    response = await RequestsPlus.get(url);
    await setCookies(await RequestsPlus.getStoredCookies(url));

    document = parse(response.body);
    forms = document.getElementsByTagName("form");
    formData = {};

    for (var form in forms) {
      if (form.innerHtml.toLowerCase().contains("relaystate")) {
        final String? action = form.attributes["action"];
        if (action == null) {
          if (kDebugMode) {
            print("3rd auth stage: action is null. Reporting failure...");
          }
          return;
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

    await applyCookies(url);
    response = await RequestsPlus.post(url, body: formData);
    await setCookies(await RequestsPlus.getStoredCookies(url));

    if (!response.headers.containsKey("location")) {
      if (kDebugMode) {
        print("4th no location header. Reporting failure...");
      }
      return;
    }

    url = response.headers["location"]!;
    if (url.startsWith("https://campus.kit.edu/sp/https://campus.kit.edu/sp")) {
      print("XUI");
      url = url.substring("https://campus.kit.edu/sp/".length);
    }
    print("Location is $url");

    await applyCookies(url);
    response = await RequestsPlus.get(url);
    await setCookies(await RequestsPlus.getStoredCookies(url));
    
    // parse the response
    document = parse(response.body);
    // print(response.body);

    String firstName = "", lastName = "", matrn = "";
    String degreeProgram = "";
    String ectsAcquired = "";

    // print(response.body);

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
    // rowsSorted[]

    document.getElementsByClassName("hierarchy1").forEach((element) {
      try {
        HierarchicTableRow.parseTr(element, rowsSorted);
      } catch (exc) {
        if (kDebugMode) {
          print(exc);
        }
      }

    });

    rows = [];
    document.getElementsByClassName("tablecontent").forEach((tbody) {
      tbody.getElementsByTagName("tr").forEach((tr) {
        try {
          final row = HierarchicTableRow.parseTr(tr, rowsSorted);
          if (row != null) {
            rows.add(row);
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

      // profileReady = false;

      if (retryIfFailed) {
        await fetchSchedule(retryIfFailed: secondRetryIfFailed);
      }

      return;
    }

    degreeProgram = rowsSorted[1]?.first.title ?? "";
    ectsAcquired = rowsSorted[1]?.first.pointsAcquired ?? "";

    student = Student(name: Name(firstName: firstName, lastName: lastName), matriculationNumber: matrn, degreeProgram: degreeProgram, avgMark: rowsSorted[1]?.first.mark ?? "0,0", ectsAcquired: ectsAcquired);

    fetchTimetable();

    profileReady = true;
    notifyListeners();

    if (kDebugMode) {
      print("Got profile data!");
    }

    scheduleFetchingTimer ??= Timer(const Duration(seconds: 60), fetchSchedule);
  }

  Future<void> fetchTimetable() async {
    if (kDebugMode) {
      print("Fetching timetable...");
    }
    final url = "https://campus.studium.kit.edu/redirect.php?system=campus&page=/events/timetable.php&lang=de&url=https://campus.kit.edu/sp/campus/student/timetable.asp";
    applyCookies(url);
    final response = await RequestsPlus.get(url);
    // print(response.body);
    final timetableUpdate = TimetableWeekly.parseFromHtmlString(response.body);
    if (timetableUpdate == null) {
      if (kDebugMode) {
        print("Failed to update the timetable!");
      }
      return;
    }
    timetable = timetableUpdate;
    notifyListeners();
  }

  Future<KITModule> fetchModule(HierarchicTableRow row) async {
    final url = row.href;

    await applyCookies(url);
    final response = await RequestsPlus.get(url);
    var module = KITModule();
    
    module.parseModulePage(response.body);
    if (kDebugMode) {
      print(module.toString());
    }

    if (module.grade == "0,0" && row.mark.isNotEmpty) {
      module.grade = row.mark;
    }

    if (module.title.trim().isEmpty) {
      module.title = row.title;
    }

    return module;
  }
}

