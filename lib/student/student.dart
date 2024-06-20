import 'name.dart';

class Student {
  final Name name;
  final String matriculationNumber;
  final String degreeProgram;
  final String avgMark;
  final String ectsAcquired;

  Student({required this.name, required this.matriculationNumber, required this.degreeProgram, required this.avgMark, required this.ectsAcquired});

  static Student get empty => Student(name: Name.empty, matriculationNumber: "", degreeProgram: "", avgMark: "0,0", ectsAcquired: "0,0");

  String get repr => "${name.repr} ($matriculationNumber)";
}