import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kit_mobile/credentials/models/auth_result.dart';
import 'package:kit_mobile/credentials/models/kit_credentials.dart';
import 'package:kit_mobile/state_management/KITProvider.dart';
import 'package:requests_plus/requests_plus.dart';

import '../../main.dart';

class CredentialsProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  CredentialsProvider() {
    loadCredentials();
  }

  KITCredentials credentials = KITCredentials();
  bool credentialsLoaded = false;
  bool loggingIn = false;

  String displayName = "";

  Future<void> loadCredentials() async {
    final all = await _storage.readAll(
      iOptions: _iOSOptions,
      aOptions: _androidOptions
    );

    credentials.valid = all.containsKey("username") && all.containsKey("password") && all.containsKey("isLoggedIn") && ((all["isLoggedIn"]?.length ?? 0) > 0);

    if (credentials.valid) {
      credentials.username = all["username"]!;
      credentials.password = all["password"]!;
      displayName = all["userDisplayName"] ?? credentials.username;
    }

    credentialsLoaded = true;
    loggingIn = false;

    notifyListeners();
  }

  _writeCredentials() async {
    if (displayName.isEmpty) {
      displayName = credentials.username;
    }

    await _storage.write(key: "username",        value: credentials.username,         iOptions: _iOSOptions, aOptions: _androidOptions);
    await _storage.write(key: "password",        value: credentials.password,         iOptions: _iOSOptions, aOptions: _androidOptions);
    await _storage.write(key: "isLoggedIn",      value: credentials.valid ? "1" : "", iOptions: _iOSOptions, aOptions: _androidOptions);
    await _storage.write(key: "userDisplayName", value: displayName,                  iOptions: _iOSOptions, aOptions: _androidOptions);

    if (isAlpha) {
      await _storage.write(key: "alpha", value: "hero", iOptions: _iOSOptions, aOptions: _androidOptions);
    }

    // displayName = credentials.username;
    notifyListeners();
  }

  _clearCredentials() async {
    credentials = KITCredentials();
    await _writeCredentials();
  }

  // enterUsername(String value) async {
  //   credentials.username = value;
  //   await _writeCredentials();
  // }
  //
  // enterPassword(String value) async {
  //   credentials.password = value;
  //   await _writeCredentials();
  // }

  setDisplayName(String val) async {
    displayName = val;
    await _storage.write(key: "userDisplayName", value: val, iOptions: _iOSOptions, aOptions: _androidOptions);
  }

  Future<AuthResult> submit(String typedUsername, String typedPassword, KITProvider vm) async {
    if (displayName.isEmpty) {
      displayName = typedUsername;
      notifyListeners();
    }

    KITCredentials newCredentials = KITCredentials(username: typedUsername, password: typedPassword);
    if (kDebugMode) {
      print("Submitted $newCredentials");
    }

    if (!newCredentials.isFormatValid) {
      if (kDebugMode) {
        print("The username format is invalid!");
      }
      return AuthResult.wrongUsernameFormat;
    }

    credentials = newCredentials;

    return await login(vm, clearCookiesAndCache: true);
  }

  Future<AuthResult> login(KITProvider vm, {clearCookiesAndCache = true}) async {
    loggingIn = true;
    notifyListeners();

    if (clearCookiesAndCache) {
      await vm.clearCookiesAndCache();
    }

    if (!credentials.isFormatValid) {
      return AuthResult.wrongUsernameFormat;
    }

    vm.setCredentials(credentials);
    await vm.fetchSchedule(secondRetryIfFailed: false);

    if (!vm.profileReady) {
      credentials.valid = false;
      loggingIn = false;
      notifyListeners();
      return AuthResult.fail;
    }

    credentials.valid = true;
    setDisplayName(vm.student.name.repr);
    _writeCredentials();

    loggingIn = false;
    notifyListeners();

    return AuthResult.ok;
  }

  logout(KITProvider vm) async {
    _clearCredentials();
    vm.profileReady = false;
    vm.scheduleFetchingTimer?.cancel();
    vm.setCredentials(credentials);
    notifyListeners();
    vm.notifyListeners();
    // vm.clearData();
  }

  IOSOptions get _iOSOptions => const IOSOptions(
    accountName: "kit-student"
  );

  AndroidOptions get _androidOptions => const AndroidOptions(
    encryptedSharedPreferences: true
  );
}