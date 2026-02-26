import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kit_mobile/credentials/models/auth_result.dart';
import 'package:kit_mobile/credentials/models/kit_credentials.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';

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

  Future<bool> loadCredentials({Function? callback, notify = true}) async {
    final all = await _storage.readAll(
        iOptions: _iOSOptions, aOptions: _androidOptions);

    credentials.valid = all.containsKey("username") &&
        all.containsKey("password") &&
        all.containsKey("isLoggedIn") &&
        ((all["isLoggedIn"]?.length ?? 0) > 0);

    if (credentials.valid) {
      credentials.username = all["username"]!;
      credentials.password = all["password"]!;
      displayName = all["userDisplayName"] ?? credentials.username;
    }

    credentialsLoaded = true;
    loggingIn = false;

    if (notify) notifyListeners();

    callback?.call(this);

    return credentials.valid;
  }

  _writeCredentials() async {
    final username = credentials.username;
    final password = credentials.password;
    final isValid = credentials.valid;

    if (displayName.isEmpty) {
      displayName = credentials.username;
    }

    if (kDebugMode) {
      print("Validating validity of credentials: ${credentials.valid}");
    }

    await _storage.write(
        key: "username",
        value: username,
        iOptions: _iOSOptions,
        aOptions: _androidOptions);
    await _storage.write(
        key: "password",
        value: password,
        iOptions: _iOSOptions,
        aOptions: _androidOptions);
    await _storage.write(
        key: "isLoggedIn",
        value: isValid ? "1" : "",
        iOptions: _iOSOptions,
        aOptions: _androidOptions);
    await _storage.write(
        key: "userDisplayName",
        value: displayName,
        iOptions: _iOSOptions,
        aOptions: _androidOptions);

    if (isAlpha) {
      await _storage.write(
          key: "alpha",
          value: "hero",
          iOptions: _iOSOptions,
          aOptions: _androidOptions);
    }

    if (kDebugMode) {
      print("VALID one more time: ${credentials.valid}");
    }

    // displayName = credentials.username;
    notifyListeners();
  }

  _clearCredentials() async {
    if (kDebugMode) {
      print("Clearing credentials...");
    }
    credentials = KITCredentials();
    await _writeCredentials();
  }

  setDisplayName(String val) async {
    displayName = val;
    await _storage.write(
        key: "userDisplayName",
        value: val,
        iOptions: _iOSOptions,
        aOptions: _androidOptions);
  }

  Future<AuthResult> submit(
      String typedUsername, String typedPassword, KITProvider vm) async {
    if (displayName.isEmpty) {
      displayName = typedUsername;
      notifyListeners();
    }

    KITCredentials newCredentials =
        KITCredentials(username: typedUsername, password: typedPassword);

    if (!newCredentials.isFormatValid) {
      if (kDebugMode) {
        print("The username format is invalid!");
      }
      return AuthResult.wrongUsernameFormat;
    }

    credentials = newCredentials;

    return await login(vm, clearCookiesAndCache: true);
  }

  Future<AuthResult> login(KITProvider vm,
      {clearCookiesAndCache = true}) async {
    loggingIn = true;
    notifyListeners();

    if (clearCookiesAndCache) {
      await vm.clearCookiesAndCache();
    }

    if (!credentials.isFormatValid) {
      return AuthResult.wrongUsernameFormat;
    }

    vm.setCredentials(credentials);
    // await vm.iliasManager.authorize();
    await vm.fetchSchedule(secondRetryIfFailed: false, ignoreIfCached: true);

    if (!vm.profileReady) {
      credentials.valid = false;
      loggingIn = false;
      notifyListeners();
      return AuthResult.fail;
    }

    credentials.valid = true;
    setDisplayName(vm.student.name.repr);
    if (kDebugMode) {
      print(
          "Successfully logged in and writing credentials which are valid: ${credentials.valid}");
    }
    await _writeCredentials();

    loggingIn = false;
    notifyListeners();

    return AuthResult.ok;
  }

  logout(KITProvider vm) async {
    await _clearCredentials();
    // i do not really like how this is implemented. I'll rewrite this in the future
    vm.campusManager.ready = false;
    vm.campusManager.scheduleFetchingTimer?.cancel();
    vm.campusManager.resetRelevantModules();
    await vm.campusManager.clearStudentData();
    await vm.campusManager.clearCachedTimetableData();
    await vm.iliasManager.logout();
    vm.setCredentials(credentials);
    notifyListeners();
    vm.notifyListeners();
    // vm.clearData();
  }

  IOSOptions get _iOSOptions => const IOSOptions(accountName: "kit-student");

  AndroidOptions get _androidOptions =>
      const AndroidOptions(encryptedSharedPreferences: true);
}
