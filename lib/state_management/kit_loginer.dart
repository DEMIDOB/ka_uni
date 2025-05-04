import 'package:flutter/foundation.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:kit_mobile/state_management/util/campus_rp_cookies_manager.dart';
import 'package:requests_plus/requests_plus.dart';

import '../credentials/models/kit_credentials.dart';

class KITLoginer {
  final cookiesManager = RPCookiesManager();
  late KITCredentials credentials;

  bool ready = false;

  String get JSESSIONID => cookiesManager.JSESSIONID;

  clearCookiesAndCache() async {
    await cookiesManager.clearCookiesAndCache();
  }

  applyLocalCookiesToUrl(String url) async {
    await cookiesManager.applyLocalCookiesToUrl(url);
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

    cookiesManager.JSESSIONID = cookies["JSESSIONID"]!.value;
    // JSESSIONID = cookiesManager.JSESSIONID;
    // notifyListeners();

    return true;
  }
  
  fetchStage0_Init({notify = true, retryIfFailed = true, secondRetryIfFailed = true}) async {
    if (!credentials.isFormatValid) {
      return -1;
    }

    // scheduleFetchingTimer = null;

    ready = false || ready;
    cookiesManager.clearCookiesAndCache();

    // if (notify) {
    //   notifyListeners();
    // }

    if (!(await fetchJSession())) {
      return -2;
    }

    cookiesManager.removeLocalCookie("path");
    cookiesManager.removeLocalCookie("secure");

    return 0;
  }

  Future<http.Response> fetchStage1_TryToOpenLoginPage(String url) async {
    RequestsPlus.addCookie(url, "JSESSIONID", JSESSIONID);
    await cookiesManager.applyLocalCookiesToUrl(url);
    var response = await RequestsPlus.get(url);
    await cookiesManager.extractCookiesFromJar(await RequestsPlus.getStoredCookies(url));

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

    await cookiesManager.applyLocalCookiesToUrl(url);
    var response = await RequestsPlus.post(url, body: formData);
    await cookiesManager.extractCookiesFromJar(await RequestsPlus.getStoredCookies(url));

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
        await cookiesManager.applyLocalCookiesToUrl(url);
        response = await RequestsPlus.get(url);
        await cookiesManager.extractCookiesFromJar(await RequestsPlus.getStoredCookies(url));
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
      print("Handling no-js redirect: url is $url, cookies: ${cookiesManager.cookiesString}");
      print("formData: ${formData.keys}");
    }

    await cookiesManager.applyLocalCookiesToUrl(url);
    var response = await RequestsPlus.post(url, body: formData, followRedirects: true);
    await cookiesManager.extractCookiesFromJar(await RequestsPlus.getStoredCookies(url));

    if (response.statusCode == 302 && response.headers.containsKey("location")) {
      url = response.headers["location"]!;
      await cookiesManager.applyLocalCookiesToUrl(url);
      response = await RequestsPlus.get(url);
    }

    return response;
  }

}