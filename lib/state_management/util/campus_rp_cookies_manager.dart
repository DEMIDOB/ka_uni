import 'package:flutter/foundation.dart';
import 'package:requests_plus/requests_plus.dart';

class CampusRPCookiesManager {
  final Map<String, String> _cookies = {};

  extractCookiesFromJar(CookieJar cookieJar) {
    cookieJar.forEach((name, cookie) {
      _cookies[name] = cookie.value;
    });
  }

  applyLocalCookiesToUrl(String url) async {
    // if (!url.startsWith("https://campus.kit.edu")) {
    //   print("fuck off");
    //   return;
    // }

    // for (var entry in _cookies.entries) {
    //   await RequestsPlus.addCookie(url, entry.key, entry.value);
    // }

    print(_cookies);
    // TODO: remove after all checks 
    _cookies.forEach((name, value) {
      RequestsPlus.addCookie(url, name, value);
    });
  }

  removeLocalCookie(String name) {
    _cookies.remove(name);
  }

  String get cookiesString {
    String cs = "";
    _cookies.forEach((key, value) {
      cs += "$key=$value;";
    });
    return cs.substring(0, cs.length - 2);
  }

  String get JSESSIONID => _cookies["JSESSIONID"] ?? "";
  set JSESSIONID(String newValue) {
    _cookies["JSESSIONID"] = newValue;
  }

  Future<void> clearCookiesAndCache() async {
    if (kDebugMode) {
      print("Clearing cookies and cache...");
    }

    _cookies.clear();

    await extractCookiesFromJar(CookieJar());
    await RequestsPlus.clearStoredCookies("https://campus.studium.kit.edu/");
    await RequestsPlus.clearStoredCookies("https://idp.scc.kit.edu/");
    await RequestsPlus.clearStoredCookies("https://campus.kit.edu/");
  }
}