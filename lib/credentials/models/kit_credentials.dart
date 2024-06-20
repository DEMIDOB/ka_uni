class KITCredentials {
  String username;
  String password;

  bool valid;

  KITCredentials({this.username = "", this.password = "", this.valid = false});

  bool get isFormatValid {
    final exp = RegExp(r'u([a-z]){4}');
    final matches = exp.allMatches(username);
    // print(matches.firstOrNull?.input);
    return matches.length == 1 && matches.firstOrNull?.input == username;
  }

  String toString() {
    return "KITCredentials($username, $password)";
  }
}