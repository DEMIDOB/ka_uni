import 'package:kit_mobile/settings/types/setting.dart';

class BoolSetting extends Setting<bool> {
  BoolSetting({required super.valueKey, required super.defaultValue, super.notifyCallback});

  Future<void> toggle() async {
    await set(!value);
  }
}