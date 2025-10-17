import 'package:kit_mobile/settings/types/setting.dart';

class StringSetting extends Setting<String> {
  StringSetting({required super.valueKey, required super.defaultValue, super.notifyCallback});
}