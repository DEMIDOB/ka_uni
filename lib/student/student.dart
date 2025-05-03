import 'name.dart';

class Student {
  Name name;
  String matriculationNumber;
  String degreeProgram;
  String avgMark;
  String ectsAcquired;

  Student({required this.name, required this.matriculationNumber, required this.degreeProgram, required this.avgMark, required this.ectsAcquired});

  set({name, matriculationNumber, degreeProgram, avgMark, ectsAcquired}) {
    this.name = name;
    this.matriculationNumber = matriculationNumber;
    this.degreeProgram = degreeProgram;
    this.avgMark = avgMark;
    this.ectsAcquired = ectsAcquired;
  }

  static Student get empty => Student(name: Name.empty, matriculationNumber: "", degreeProgram: "", avgMark: "0,0", ectsAcquired: "0,0");

  String get repr => "${name.repr} ($matriculationNumber)";
}