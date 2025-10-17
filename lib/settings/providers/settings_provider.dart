import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:kit_mobile/settings/types/multiple_choice_setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../types/bool_setting.dart';
import '../types/setting.dart';

const liquidAssEverywhereKey = "PREF_liquidAssEverywhere";
const showingAvgMarkKey = "PREF_showingAvgMark";
const showingProfileKey = "PREF_showingProfile";
const defaultIliasPageKey  = "PREF_defaultIliasPage";

class SettingsProvider extends ChangeNotifier {
  static SettingsProvider? _instance;

  final BuildContext context;
  SettingsProvider({required this.context}) {
    _instance = this;
    prepare();
  }

  BoolSetting liquidAssEverywhere = BoolSetting(
    valueKey: liquidAssEverywhereKey,
    defaultValue: false,
    notifyCallback: () => _instance?.notifyListeners()
  );

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

  MultipleChoiceSetting<String> defaultIliasPage = MultipleChoiceSetting(
    valueKey: defaultIliasPageKey,
    choices: ["Dashboard", "Meine Kurse & Gruppen"],
    notifyCallback: () => _instance?.notifyListeners()
  );
  
  List<Setting> get settings => [
    liquidAssEverywhere,
    showingAvgMark,
    showingProfile,
    defaultIliasPage
  ];
  
  Future<void> prepare() async {
    await Future.wait(settings.map((el) => el.prepare()));
  }

}






