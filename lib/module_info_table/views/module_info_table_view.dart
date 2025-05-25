import 'package:flutter/material.dart';
import 'package:kit_mobile/module_info_table/models/module_info_table_types/module_info_table_generic.dart';
import 'package:kit_mobile/module_info_table/models/module_info_table_types/module_info_table_sensible.dart';

// import 'package:fluttertoast/fluttertoast.dart';

import '../models/module_info_table.dart';

class ModuleInfoTableView extends StatefulWidget {
  final ModuleInfoTable table;

  const ModuleInfoTableView({super.key, required this.table});

  @override
  State<StatefulWidget> createState() {
    return _ModuleInfoTableViewState();
  }

}

class _ModuleInfoTableViewState extends State<ModuleInfoTableView> {
  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    // final mq = MediaQuery.of(context);

    // we draw a nicer view if the table is of one of the following types
    if (widget.table.type.isSensible) {
      final titleCellIndex = widget.table.colTitles.indexOf("Titel");

      // ...making sure that there is a sensible title
      if (titleCellIndex != -1) {
        return ModuleInfoTableSensible(table: widget.table,);
      }
    }

    return ModuleInfoTableGeneric(table: widget.table);
  }

}