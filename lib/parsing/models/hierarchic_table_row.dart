import 'dart:math';


class HierarchicTableRow  {
  final int level;
  String title;
  String href;
  final String type;
  final String statusStr;
  String mark;
  final String pointsAcquired;
  final String pointsMax;
  int year = 0;

  String technicalName = "";

  List<HierarchicTableRow> children = [];

  HierarchicTableRow({required this.level, required this.title, required this.href, required this.type, required this.statusStr, required this.mark, required this.pointsAcquired, required this.pointsMax});

  String get id => "${level}_${title}_$year";
  
  bool get isMarkEmpty => mark.isEmpty || mark.startsWith("0") || mark.startsWith("&");
  
  int get relevancyRank {
    return isMarkEmpty ? 10 : 1;
  }

  static HierarchicTableRow? parseTr(element, Map<int, List<HierarchicTableRow>> rowsSorted) {
    HierarchicTableRow? newRow;

    int level = 0;
    final classes = element.attributes["class"]?.split(" ");
    if (classes == null) {
      return null;
    }

    for (var rowClass in classes) {
      if (rowClass.contains("hierarchy")) {
        level = int.parse(rowClass[rowClass.length - 1]);
        break;
      }
    }

    final cells = element.getElementsByTagName("td");
    final firstLink = cells[1].getElementsByTagName("a").first;

    if (firstLink == null) {
      return null;
    }

    firstLink.children.forEach((child) {
      child.remove();
    });

    if (cells.length >= 8) {
      newRow = HierarchicTableRow(
        level: level,
        title: firstLink.innerHtml,
        href: firstLink.attributes["href"],
        type: cells[2].innerHtml,
        statusStr: "",
        mark: cells[4].innerHtml,
        pointsAcquired: cells[6].innerHtml,
        pointsMax: cells[7].innerHtml,
      );
    }

    if (newRow == null) {
      return null;
    }

    if (newRow.mark.contains(",")) {
      final commaIndex = newRow.mark.lastIndexOf(",");
      newRow.mark = newRow.mark.substring(max(0, commaIndex - 1), min(commaIndex + 2, newRow.mark.length));
    }

    newRow.clearTitle();
    newRow.clearHref();

    if (level > 1) {
      if (rowsSorted.containsKey(level - 1)) {
        rowsSorted[level - 1]?.last.children.add(newRow);
      }
    }

    if (rowsSorted[level] == null) {
      rowsSorted[level] = [];
    }

    rowsSorted[level]!.add(newRow);

    return newRow;
  }

  // often there is is a title like T-MATH-106335 – Analysis 1 where the first
  // part before the long "–" is some technical name of the entry
  // so we remove that from the title and store in a separate variable
  clearTitle() {
    final titleSplit = title.split("–");
    if (titleSplit.length > 1) {
      String newTitle = "";
      for (int i = 1; i < titleSplit.length; ++i) {
        newTitle += "${titleSplit[i].trim()} ";
      }
      newTitle = newTitle.trim();

      final newTitleSplit = newTitle.split(" ");
      newTitle = "";
      for (var element in newTitleSplit) {
        final num = int.tryParse(element);
        if (num == null || (num / 1000).floor() != 2) {
          newTitle += "$element ";
        } else {
          year = num;
        }
      }

      title = newTitle.trim();
      technicalName = titleSplit.first.trim();
    }
  }

  clearHref() {
    final base = "https://campus.kit.edu/sp/";
    while (href.startsWith("../")) {
      href = href.substring(3);
    }

    href = base + href;
  }
}