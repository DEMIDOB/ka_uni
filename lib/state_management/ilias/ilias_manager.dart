import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kit_mobile/state_management/kit_loginer.dart';

class IliasManager extends KITLoginer {
  String _phpsessid = "";
  bool isBusy = false;

  DateTime _lastUpdate = DateTime(2004);

  Future<String> getPHPSESSID() async {
    if (DateTime.now().isAfter(_lastUpdate.add(Duration(minutes: 30)))) {
      if (kDebugMode) {
        print("Refetching ilias session...");
      }
      await authorize();
      _lastUpdate = DateTime.now();
    }

    return _phpsessid;
  }

  Future<void> authorize({retryIfFailed = true, secondRetryIfFailed = true, refreshSession = true}) async {

    isBusy = true;

    if (refreshSession) {
      await clearCookiesAndCache();
    }

    await fetchJSession();

    await fetchStage0_Init();
    final stage1Response = await fetchStage1_TryToOpenLoginPage("https://ilias.studium.kit.edu/shib_login.php");

    // stage 2
    http.Response? stage2Response;

    stage2Response = await fetchStage2_(stage1Response);
    try {
    } catch (exc) {
      stage2Response = null;
    }
    if (stage2Response == null) {
      if (kDebugMode) {
        print("Stage 2 failed!");
      }

    }

    if (retryIfFailed && !cookiesContains("PHPSESSID")) {
      await authorize(retryIfFailed: secondRetryIfFailed, secondRetryIfFailed: false);
      return;
    }
    _phpsessid = cookiesString.substring(cookiesString.indexOf("PHPSESSID"));
    _phpsessid = _phpsessid.substring(_phpsessid.indexOf("=") + 1);
    _phpsessid = _phpsessid.substring(0, _phpsessid.indexOf(";"));

    isBusy = false;
  }

  logout() async {
    _phpsessid = "";
  }
}