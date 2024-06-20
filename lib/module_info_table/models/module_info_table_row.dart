import 'package:html/dom.dart';
import 'package:kit_mobile/module_info_table/views/module_info_table_view.dart';

import 'module_info_table_cell.dart';

class ModuleInfoTableRow {
  String id = "";
  List<ModuleInfoTableCell> cells = [];

  ModuleInfoTableCell? favoriteToggleCell;

  static ModuleInfoTableRow parseFromHtml(Element node) {
    ModuleInfoTableRow row = ModuleInfoTableRow();

    row.id = node.attributes["id"] ?? "";
    row.cells = node.getElementsByTagName("td").map((e) => ModuleInfoTableCell.parseFromHtml(e)).toList();

    return row;
  }
}