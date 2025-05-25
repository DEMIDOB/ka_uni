import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ToastsProvider extends ChangeNotifier {
  bool isShowing = false;

  static const defaultAnimationDuration = Duration(milliseconds: 500);
  static const _defaultDuration = Duration(seconds: 3);
  static const _defaultBackgroundColor = Colors.grey;
  static const _defaultForegroundColor = Colors.black;

  showTextToast(String message, {
    Duration duration = _defaultDuration,
    backgroundColor = _defaultBackgroundColor,
    foregroundColor = _defaultForegroundColor}) async {
    if (isShowing) {
      return;
    }

    this.message = message;
    this.backgroundColor = backgroundColor;
    this.foregroundColor = foregroundColor;

    isShowing = true;
    if (kDebugMode) {
      print("Showing $message");
    }
    notifyListeners();

    await Future.delayed(duration);

    isShowing = false;
    notifyListeners();

    Future.delayed(defaultAnimationDuration).whenComplete(() {
      reset(notify: true);
    });

  }

  reset({notify = true}) {
    message = "";
    backgroundColor = _defaultBackgroundColor;
    foregroundColor = _defaultForegroundColor;
    isShowing = false;

    if (notify) {
      notifyListeners();
    }
  }

  Color backgroundColor = _defaultBackgroundColor;
  Color foregroundColor = _defaultForegroundColor;
  String message = "You are not supposed to see this ;)";
}