class Name {
  final String firstName;
  final String lastName;
  final String? middleName;

  Name({required this.firstName, required this.lastName, this.middleName});

  static Name get empty => Name(firstName: "", lastName: "");

  String get repr {
    if (middleName != null) {
      return "$firstName ${middleName!} $lastName";
    }

    return "$firstName $lastName";
  }
}