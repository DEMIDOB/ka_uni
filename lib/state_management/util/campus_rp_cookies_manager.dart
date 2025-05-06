import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:requests_plus/requests_plus.dart';

class RPCookiesManager {
  final Map<String, String> _cookies = {};
  bool _isFrozen = false;

  freeze() {
    _isFrozen = true;
  }

  unfreeze() {
    _isFrozen = false;
  }

  bool get isFrozen => _isFrozen;

  RPCookiesManager({Map<String, String>? initialCookies}) {
    if (initialCookies !=  null) {
      initialCookies.forEach((name, value) => _cookies[name] = value);
    }
  }

  extractCookiesFromJar(CookieJar cookieJar) {
    if (isFrozen) {
      return;
    }

    cookieJar.forEach((name, cookie) {
      _cookies[name] = cookie.value;
    });
  }

  applyLocalCookiesToUrl(String url, {ignoreFreeze = false}) async {
    // if (!url.startsWith("https://campus.kit.edu")) {
    //   print("fuck off");
    //   return;
    // }

    // for (var entry in _cookies.entries) {
    //   await RequestsPlus.addCookie(url, entry.key, entry.value);
    // }
    if (isFrozen && !ignoreFreeze) {
      return;
    }

    // TODO: remove after all checks
    _cookies.forEach((name, value) {
      RequestsPlus.addCookie(url, name, value);
    });
  }

  removeLocalCookie(String name) {
    _cookies.remove(name);
  }

  filterCookies({List<String>? allowedCookieNames}) {
    allowedCookieNames ??= [];

    final currentCookieNames = _cookies.keys.toList();
    for (final name in currentCookieNames) {
      if (allowedCookieNames.contains(name)) {
        continue;
      }

      _cookies.remove(name);
    }
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

    unfreeze();

    _cookies.clear();

    await extractCookiesFromJar(CookieJar());
    await RequestsPlus.clearStoredCookies("https://campus.studium.kit.edu/");
    await RequestsPlus.clearStoredCookies("https://idp.scc.kit.edu/");
    await RequestsPlus.clearStoredCookies("https://campus.kit.edu/");
    await RequestsPlus.clearStoredCookies("https://ilias.studium.kit.edu/");
  }

  RPCookiesManager clone() => RPCookiesManager(initialCookies: _cookies);
}