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

  copyFrom(Student otherStudent) {
    name = otherStudent.name;
    matriculationNumber = otherStudent.matriculationNumber;
    degreeProgram = otherStudent.degreeProgram;
    avgMark = otherStudent.avgMark;
    ectsAcquired = otherStudent.ectsAcquired;
  }

  static Student get empty => Student(name: Name.empty, matriculationNumber: "", degreeProgram: "", avgMark: "0,0", ectsAcquired: "0,0");

  String get repr => "${name.repr} ($matriculationNumber)";

  Map<String, dynamic> toJson() {
    return {
      'name': name.toJson(),
      'matriculationNumber': matriculationNumber,
      'degreeProgram': degreeProgram,
      'avgMark': avgMark,
      'ectsAcquired': ectsAcquired,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: Name.fromJson(json['name']),
      matriculationNumber: json['matriculationNumber'] ?? "",
      degreeProgram: json['degreeProgram'] ?? "",
      avgMark: json['avgMark'] ?? "0,0",
      ectsAcquired: json['ectsAcquired'] ?? "0,0",
    );
  }
}