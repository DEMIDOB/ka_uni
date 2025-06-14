import 'package:html/dom.dart';

import 'module_info_table_cell.dart';

class ModuleInfoTableRow {
  String id = "";
  List<ModuleInfoTableCell> cells = [];

  ModuleInfoTableCell? appointmentCell;
  ModuleInfoTableCell? favoriteToggleCell;

  // assumption: one ilias-link per row
  String? iliasLink;
  bool hasFavoriteChild = false;

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

      // special properties:
      if (cell.hasIliasLink) {
        // see assumption above
        row.iliasLink = cell.link;
      }

      row.hasFavoriteChild |= cell.isFavorite;
      // special properties end
    }

    return row;
  }
}