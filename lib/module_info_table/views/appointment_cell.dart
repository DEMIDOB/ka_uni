import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/module_info_table/models/module_info_table_cell.dart';

class AppointmentCell extends StatelessWidget {
  final ModuleInfoTableCell cellData;

  const AppointmentCell({super.key, required this.cellData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          child: Icon(CupertinoIcons.arrow_turn_down_right, size: 15, color: theme.colorScheme.primary,),
        ),
        Text(cellData.dateStr),
        const SizedBox(width: 15,),
        Text(cellData.timeStr)
      ],
    );
  }

}