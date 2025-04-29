import 'package:html/dom.dart';

import 'module_info_table_cell.dart';

class ModuleInfoTableRow {
  String id = "";
  List<ModuleInfoTableCell> cells = [];

  ModuleInfoTableCell? appointmentCell;
  ModuleInfoTableCell? favoriteToggleCell;

  static ModuleInfoTableRow parseFromHtml(Element node) {
    ModuleInfoTableRow row = ModuleInfoTableRow();

    row.id = node.attributes["id"] ?? "";
    row.cells = node.getElementsByTagName("td").map((e) => ModuleInfoTableCell.parseFromHtml(e)).toList();

    for (final cell in row.cells) {
      if (cell.isAppointment) {
        row.appointmentCell = cell;
      }

      if (cell.doesToggleFavorite) {
        row.favoriteToggleCell = cell;
      }
    }

    return row;
  }
}