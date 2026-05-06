import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kit_mobile/state_management/kit_loginer.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';

import '../../local_files_storage/models/pinned_file.dart';

class IliasManager extends KITLoginer {
  String _phpsessid = "";
  bool isBusy = false;

  DateTime _lastUpdate = DateTime(2004);

  Future<String> getPHPSESSID() async {
    // while (isBusy);
    if (isBusy) {
      await Future.delayed(Duration(milliseconds: 500));
      return getPHPSESSID();
    }

    if (DateTime.now().isAfter(_lastUpdate.add(Duration(minutes: 30)))) {
      if (kDebugMode) {
        print("Refetching ilias session...");
      }
      await authorize();
      _lastUpdate = DateTime.now();
    }

    if (isBusy) {
      await Future.delayed(Duration(milliseconds: 500));
      return getPHPSESSID();
    }

    return _phpsessid;
  }

  Future<void> authorize(
      {retryIfFailed = true,
      secondRetryIfFailed = true,
      refreshSession = true}) async {
    isBusy = true;

    if (refreshSession) {
      await clearCookiesAndCache();
      _phpsessid = "";
    }

    await fetchJSession();

    await fetchStage0_Init();
    final stage1Response = await fetchStage1_TryToOpenLoginPage(
        "https://ilias.studium.kit.edu/shib_login.php");

    // stage 2
    http.Response? stage2Response;

    stage2Response = await fetchStage2_(stage1Response);
    try {} catch (exc) {
      stage2Response = null;
    }
    if (stage2Response == null) {
      if (kDebugMode) {
        print("Stage 2 failed!");
      }
    }

    if (retryIfFailed && !cookiesContains("PHPSESSID")) {
      await authorize(
          retryIfFailed: secondRetryIfFailed, secondRetryIfFailed: false);
      return;
    }
    _phpsessid = cookiesString.substring(cookiesString.indexOf("PHPSESSID"));
    _phpsessid = _phpsessid.substring(_phpsessid.indexOf("=") + 1);
    _phpsessid = _phpsessid.substring(0, _phpsessid.indexOf(";"));

    _lastUpdate = DateTime.now();

    isBusy = false;
  }

  Future<PinnedFile> downloadFile(String srcUrl, File targetFile) async {
    if (kDebugMode) {
      print("Downloading file to ${targetFile.path} from $srcUrl");
    }

    final response = await session.get(Uri.parse(srcUrl));
    var bytes = response.bodyBytes;
    // print(response.body);

    if (kDebugMode) {
      print("Downloaded ${bytes.lengthInBytes} bytes");
    }

    await targetFile.writeAsBytes(bytes);

    return PinnedFile(
        semesterString: KITProvider.currentSemesterString,
        urlString: srcUrl,
        moduleTitle: "",
        addedAt: DateTime.now().toUtc(),
        customName: "",
        fileSystemPath: targetFile.path);
  }

  logout() async {
    _phpsessid = "";
  }
}
