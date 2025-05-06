import 'package:flutter/foundation.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:http_session/http_session.dart';

import '../credentials/models/kit_credentials.dart';

class KITLoginer {
  late KITCredentials credentials;

  bool ready = false;

  final HttpSession session = HttpSession(acceptBadCertificate: true, maxRedirects: 15);
  String _JSESSIONID = "";
  String get JSESSIONID => _JSESSIONID;

  clearCookiesAndCache() {
    session.clear();
  }

  String get cookiesString {
    final cookies = session.cookieStore.cookies;
    return cookies.map((c) => "${c.name}=${c.value}").join("; ");
  }

  bool cookiesContains(String cookieName) {
    final cookies = session.cookieStore.cookies;

    for (final cookie in cookies) {
      if (cookie.name.contains(cookieName)) {
        return true;
      }
    }

    return false;
  }

  Future<bool> fetchJSession() async {
    String url = "https://idp.scc.kit.edu/idp/profile/SAML2/Redirect/SSO?execution=e1s1";

    await session.get(Uri.parse(url));
    if (cookiesContains("JSESSIONID")) {
      return true;
    }

    if (kDebugMode) {
      print("Failed to fetch JSESSIONID!");
    }

    return false;
  }
  
  fetchStage0_Init({notify = true, retryIfFailed = true, secondRetryIfFailed = true}) async {
    if (!credentials.isFormatValid) {
      return -1;
    }

    // scheduleFetchingTimer = null;

    ready = false || ready;
    clearCookiesAndCache();

    // if (notify) {
    //   notifyListeners();
    // }

    if (!(await fetchJSession())) {
      return -2;
    }

    return 0;
  }

  Future<http.Response> fetchStage1_TryToOpenLoginPage(String url) async {
    var response = await session.get(Uri.parse(url));

    // sometimes, the server wants us to manually redirect us to the login page, idk why
    if (isManualRedirectRequired(response)) {
      final currentResponse = await handleNoJSResponse(response.body);
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

  Future<http.Response?> fetchStage2_(http.Response previousResponse) async {
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

        url = "https://idp.scc.kit.edu$action";
        final inputs = form.getElementsByTagName("input");
        print("xui: $url");

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
    formData["_shib_idp_revokeConsent"] = "false";
    formData["j_username"] = credentials.username;
    formData["j_password"] = credentials.password;

    if (kDebugMode) {
      print("Successfully found the login form. Data provided: $formData");
      print("fucking next");
    }

    var response = await session.post(Uri.parse(url), body: formData);
    print(0/0);
    print("XUIXUI $response.body");

    if (isManualRedirectRequired(response)) {
      final currentResponse = await handleNoJSResponse(response.body);
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

        response = await session.get(Uri.parse(url));
      }
    }

    return response;
  }

  bool isManualRedirectRequired(http.Response response) {
    return response.body.contains("you must press the Continue button") || response.body.contains("relaystate");
  }

  Future<http.Response?> handleNoJSResponse(String body) async {
    if (kDebugMode) {
      print("Attempting to handle the no-js manual redirect...");
    }

    final document = parse(body);
    final forms = document.getElementsByTagName("form");
    Map<String, String> formData = {};
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
      print("Handling no-js redirect: url is $url, cookies: ${session.cookieStore.cookies.toString()}");
      print("formData: ${formData.keys}");
    }

    var response = await session.post(Uri.parse(url), body: formData);

    if (response.statusCode == 302 && response.headers.containsKey("location")) {
      url = response.headers["location"]!;
      response = await session.get(Uri.parse(url));
    }

    return response;
  }

}