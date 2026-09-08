import 'package:flutter/foundation.dart';

class KITCredentials {
  String username;
  String password;

  bool _valid = false;

  set valid(bool newValue) {
    _valid = newValue;
  }

  bool get valid => _valid;

  KITCredentials({this.username = "", this.password = "", valid}) {
    _valid = valid ?? false;
  }

  bool get isFormatValid {
    final exp = RegExp(r'u([a-z]){4}');
    final matches = exp.allMatches(username);
    return matches.length == 1 && matches.firstOrNull?.input == username;
  }

  @override
  String toString() {
    return "KITCredentials($username, $password)";
  }
}
