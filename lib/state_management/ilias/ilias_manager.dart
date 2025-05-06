import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kit_mobile/state_management/kit_loginer.dart';

class IliasManager extends KITLoginer {
  String PHPSESSID = "";
  bool isBusy = false;

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
    PHPSESSID = cookiesString.substring(cookiesString.indexOf("PHPSESSID"));
    PHPSESSID = PHPSESSID.substring(PHPSESSID.indexOf("=") + 1);
    PHPSESSID = PHPSESSID.substring(0, PHPSESSID.indexOf(";"));

    isBusy = false;
  }

  logout() async {
    PHPSESSID = "";
  }
}