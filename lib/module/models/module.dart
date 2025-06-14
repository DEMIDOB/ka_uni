import 'package:html/parser.dart';
import 'package:kit_mobile/parsing/models/hierarchic_table_row.dart';

import '../../module_info_table/models/module_info_table.dart';

class KITModule {
  String id = "";
  String title = "";
  String assignmentType = "";
  String examDateStr = "unbekannt";
  DateTime examDate = DateTime.now();
  String grade = "0,0";
  String pointsAcquired = "0,0";
  String pointsAvailable = "0,0";
  String hierarchicalTableRowId = "";
  String? iliasLink = "";
  HierarchicTableRow? row;

  List<ModuleInfoTable> tables = [];

  DateTime lastUpdated = DateTime.fromMillisecondsSinceEpoch(0);

  bool hasFavoriteChild = false;

  // Module({required this.csbrId, required this.title, required this.avgMark, required this.pointsAcquired});
  
  parseModulePage(String src) {
    final document = parse(src.replaceAll("&nbsp;", " "));
    
    // get id
    var elements = document.getElementById("csbr_id-field")?.getElementsByClassName("element");
    if (elements != null && elements.isNotEmpty) {
      id = elements.first.innerHtml;
    }

    // get title
    elements = document.getElementById("cabr_name-field")?.getElementsByClassName("element");
    if (elements != null && elements.isNotEmpty) {
      title = elements.first.innerHtml;
    }

    // get assignment type
    elements = document.getElementById("csbr_assignmenttype-field")?.getElementsByClassName("element");
    if (elements != null && elements.isNotEmpty) {
      assignmentType = elements.first.innerHtml;
    }

    // get exam date
    elements = document.getElementById("cagr_examdate-field")?.getElementsByClassName("element");
    if (elements != null && elements.isNotEmpty) {
      examDateStr = elements.first.innerHtml;
    }

    // get grade
    elements = document.getElementById("cagr_grade-field")?.getElementsByClassName("element");
    if (elements != null && elements.isNotEmpty) {
      final gradeNode = elements.first;
      if (gradeNode.hasChildNodes()) {
        for (var child in gradeNode.children) {
          child.remove();
        }
      }

      grade = gradeNode.innerHtml;
    }

    // get LP
    elements = document.getElementById("csbr_credits-field")?.getElementsByClassName("element");
    if (elements != null && elements.isNotEmpty) {
      for (var child in elements.first.children) {
        child.remove();
      }
      pointsAcquired = elements.first.innerHtml;
    }

    // get possible LP
    elements = document.getElementById("csbr_requiredcredits-field")?.getElementsByClassName("element");
    if (elements != null && elements.isNotEmpty) {
      for (var child in elements.first.children) {
        child.remove();
      }
      pointsAvailable = elements.first.innerHtml;
    }

    // parse exam date
    final examDateStrSplit = examDateStr.trim().split(".");
    List<int> dateSplitInt = [];
    for (var element in examDateStrSplit) {
      final currentDateElementInt = int.tryParse(element);
      if (currentDateElementInt != null) {
        dateSplitInt.add(currentDateElementInt);
      }
    }

    if (dateSplitInt.length == 3) {
      examDate = DateTime(dateSplitInt[2], dateSplitInt[1], dateSplitInt[0]);
    }

    // parse all tables
    tables = ModuleInfoTable.extractAllFromHtml(src);
    for (final table in tables) {
      table.prepare(this);

      if (table.iliasLink != null) {
        iliasLink = table.iliasLink;
      }

      hasFavoriteChild |= table.hasFavoriteChild;
    }

    lastUpdated = DateTime.now();
  }

  String get timeAxisPositionString {
    if (!examDateKnown) {
      return "Das Prüfungsdatum ist unbekannt";
    }
    final delta = examDate.difference(DateTime.now());

    if (isUpcoming) {
      return "in ${delta.inDays} Tagen";
    }

    return "war vor ${-delta.inDays} Tagen";
  }

  bool get isUpcoming {
    return DateTime.now().isBefore(examDate);
  }

  bool get examDateKnown {
    return examDateStr != "unbekannt";
  }

  bool get isEmpty => id == "";

  bool get requiresUpdate {
    return isEmpty || DateTime.now().difference(lastUpdated).inMinutes > 5;
  }

  @override
  String toString() {
    return """KITModule(
  id: $id,
  title: $title,
  assignmentType: $assignmentType,
  examDateStr: $examDateStr,
  grade: $grade,
  pointsAcquired: $pointsAcquired
)""";
  }
}