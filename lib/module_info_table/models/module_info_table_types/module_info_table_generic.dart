import 'package:flutter/material.dart';
import 'package:kit_mobile/module_info_table/models/module_info_table.dart';

class ModuleInfoTableGeneric extends StatelessWidget {
  final ModuleInfoTable table;

  const ModuleInfoTableGeneric({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(table.caption, style: theme.textTheme.titleMedium,),

        SizedBox(height: 10,),

        Table(
          border: TableBorder.all(color: Colors.black, borderRadius: BorderRadius.all(Radius.circular(8))),
          children: [
            TableRow(
                children: table.colTitles.map((title) {
                  return Padding(padding: EdgeInsets.all(5), child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),));
                }).toList()
            )
          ] + table.rows.map((row) {
            return TableRow(
              children: row.cells.map((cell) {
                return Padding(padding: EdgeInsets.all(5), child: Text(cell.body, maxLines: 10,),);
              }).toList(),
            );
          }).toList(),
        ),

      ],
    );
  }


}