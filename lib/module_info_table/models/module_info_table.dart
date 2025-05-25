import 'package:html/parser.dart';
import 'package:kit_mobile/module/models/module.dart';
import 'package:kit_mobile/module_info_table/models/module_info_table_cell.dart';
import 'package:kit_mobile/module_info_table/models/module_info_table_type.dart';

import '../../parsing/util/remove_html_children.dart';
import 'module_info_table_row.dart';

class ModuleInfoTable {
  int numCols = 0;
  int numRows = 0;

  late ModuleInfoTableType _type;
  ModuleInfoTableType get type => _type;

  String _caption = "";
  set caption(newValue) {
    _caption = newValue;
    _type = ModuleInfoTableType.fromCaption(_caption);
  }
  String get caption => _caption;

  List<String> colTitles = [];
  List<ModuleInfoTableRow> rows = [];

  bool show = true;

  late KITModule parentModule;

  String? iliasLink;
  bool hasFavoriteChild = false;
  
  static ModuleInfoTable? parseFromHtml(String src) {
    final document = parse(src.replaceAll("&nbsp;", " "));
    
    final tableNodes = document.getElementsByTagName("table");
    if (tableNodes.isEmpty) {
      return null;
    }
    
    final tableNode = tableNodes.first;
    
    final headTr = tableNode.getElementsByClassName("tablehead").firstOrNull?.getElementsByTagName("tr").firstOrNull;
    if (headTr == null) {
      return null;
    }
    
    var table = ModuleInfoTable();
    
    headTr.getElementsByTagName("th").forEach((tableColTitleNode) {
      // removeHtmlChildren(tableColTitleNode);
      String text = "";
      for (var child in tableColTitleNode.children) {
        removeHtmlChildren(child);
        text += child.innerHtml;
        child.remove();
      }
      text += tableColTitleNode.innerHtml;
      text = _clearTitle(text);
      table.colTitles.add(text);
    });

    tableNode.getElementsByClassName("tablecontent").firstOrNull?.getElementsByTagName("tr").forEach((trNode) {
      final row = ModuleInfoTableRow.parseFromHtml(trNode);
      // if (row.cells.length - table.colTitles.length == 1) {
      //   final lastCell = row.cells.removeAt(row.cells.length - 1);
      //   lastCell.markMeAsAddToFavorites();
      //   row.favoriteToggleCell = lastCell;
      // }
      for (int i = row.cells.length; i < table.colTitles.length; ++i) {
        row.cells.add(ModuleInfoTableCell.empty);
      }

      if (row.cells.length != table.colTitles.length) {
        return;
      }

      table._preprocessRow(row);
      table.rows.add(row);
    });
    
    return table;
  }

  // Clears column titles as well as table titles (captions)
  static String _clearTitle(String colTitle) {
    return colTitle.replaceAll("&nbsp;", " ").trim();
  }
  
  static List<ModuleInfoTable> extractAllFromHtml(String src) {
    final document = parse(src);

    List<ModuleInfoTable> tables = [];

    final captions = document.getElementsByClassName("table-caption");

    document.getElementsByClassName("table-container").forEach((tableContainerNode) {
      final table = parseFromHtml(tableContainerNode.innerHtml);
      if (table != null) {
        tables.add(table);
      }
    });

    if (tables.length == captions.length) {
      for (int i = 0; i < captions.length; ++i) {
        removeHtmlChildren(captions[i]);
        tables[i].caption = _clearTitle(captions[i].innerHtml);
      }
    }

    return tables;
  }

  bool removeCol({String? name, int? idx}) {
    if (idx == null) {
      if (name == null) {
        return false;
      }

      int idx0 = 0;
      for (final colTitle in colTitles) {
        if (name.toLowerCase().trim() == colTitle.toLowerCase().trim()) {
          break;
        }
        ++idx0;
      }

      idx = idx0;
    }

    if (idx < 0 || idx >= colTitles.length) {
      return false;
    }

    colTitles.removeAt(idx);
    for (var row in rows) {
      try {
        row.cells.removeAt(idx);
      } catch (exc) {

      }
    }

    return true;
  }

  prepare(KITModule parentModule) {
    show = true;
    this.parentModule = parentModule;

    while (removeCol(name: "")) {
       {}
    }

    switch (caption.trim()) {
      case "Teilleistungen":
        removeCol(name: "kennung");
        removeCol(name: "status");
        show = true;
        break;
      case "Leistungsnachweise":
        removeCol(name: "");
        removeCol(name: "prüfung");
        show = true;
        break;
      case "Module":
        removeCol(name: "kennung");
        removeCol(name: "status");
        removeCol(name: "art");
        removeCol(name: "datum");
        show = true;
        break;
    }

  }

  // called after the row is parsed and has finished all its internal processing
  // before adding it to the rows list of the table
  _preprocessRow(ModuleInfoTableRow row) {
    iliasLink ??= row.iliasLink;
    hasFavoriteChild |= row.hasFavoriteChild;
  }
}