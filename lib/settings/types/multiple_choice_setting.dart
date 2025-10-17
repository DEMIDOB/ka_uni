import 'package:kit_mobile/settings/types/setting.dart';

class MultipleChoiceSetting<T> extends Setting<T> {

  final List<T> choices;
  final Set<T> choicesSet;

  MultipleChoiceSetting({
    required super.valueKey,
    required this.choices,
    super.notifyCallback,
  }) : choicesSet = choices.toSet(),
        super(defaultValue: choices.isEmpty ? "" : choices[0]);

  Future<void> set(T newValue) async {
    assert (choicesSet.contains(newValue));
    super.set(newValue);
  }
}
