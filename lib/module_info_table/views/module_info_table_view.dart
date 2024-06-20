import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    return Column(
      children: [
        Text(widget.table.caption, style: theme.textTheme.titleMedium,),

        SizedBox(height: 10,),

        Table(
          border: TableBorder.all(color: Colors.black, borderRadius: BorderRadius.all(Radius.circular(8))),
          children: [
            TableRow(
              children: widget.table.colTitles.map((title) {
                return Padding(padding: EdgeInsets.all(5), child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),));
              }).toList()
            )
          ] + widget.table.rows.map((row) {
            return TableRow(
              children: row.cells.map((cell) {
                return Padding(padding: EdgeInsets.all(5), child: Text(cell.body, maxLines: 10,),);
              }).toList(),
            );
          }).toList(),
        ),

      ],
    ) ;
  }

}