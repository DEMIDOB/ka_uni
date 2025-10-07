import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

const showingAvgMarkKey = "PREF_showingAvgMark";
const showingProfileKey = "PREF_showingProfile";

class SettingsProvider extends ChangeNotifier {
  static SettingsProvider? _instance;

  final BuildContext context;
  SettingsProvider({required this.context}) {
    _instance = this;
    prepare();
  }

  BoolSetting showingAvgMark = BoolSetting(
    valueKey: showingAvgMarkKey,
    defaultValue: true,
    notifyCallback: () => _instance?.notifyListeners()
  );

  BoolSetting showingProfile = BoolSetting(
    valueKey: showingProfileKey,
    defaultValue: true,
    notifyCallback: () => _instance?.notifyListeners()
  );
  
  List<BoolSetting> get settings => [showingAvgMark, showingProfile];
  
  Future<void> prepare() async {
    await Future.wait(settings.map((el) => el.prepare()));
  }

}

class BoolSetting {
  Function? notifyCallback;
  final String valueKey;

  late bool _value;

  BoolSetting({required this.valueKey, required defaultValue, this.notifyCallback}) {
    _value = defaultValue;
  }

  bool get value => _value;

  Future<void> prepare() async {
    final prefs = await SharedPreferences.getInstance();
    bool? value = prefs.getBool(valueKey);

    if (value == null) {
      await set(_value);
      return;
    }

    _value = value;
  }

  Future<void> set(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    _value = newValue;
    await prefs.setBool(valueKey, newValue);

    if (notifyCallback != null) {
      notifyCallback!();
    }
  }

  Future<void> toggle() async {
    await set(!value);
  }

}