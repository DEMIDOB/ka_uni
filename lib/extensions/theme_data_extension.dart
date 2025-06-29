import 'package:flutter/material.dart';

extension LightDarkModeGetter on ThemeData {
  bool get isDarkMode {
    return colorScheme.brightness == Brightness.dark;
  }

  bool get isLightMode => !isDarkMode;
}