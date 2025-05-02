import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state_management/KITProvider.dart';
import '../module_info_table.dart';

class ModuleInfoTableSensible extends StatelessWidget {
  final ModuleInfoTable table;

  const ModuleInfoTableSensible({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final vm = Provider.of<KITProvider>(context);

    final termCellIndex = table.colTitles.indexOf("Semester");
    final titleCellIndex = table.colTitles.indexOf("Titel");

    int rowsDrawn = -1;

    return Column(
      children: [
        Text(table.caption, style: theme.textTheme.titleMedium,),

        const SizedBox(height: 10,),

        Column(
          children: table.rows.map((row) {
            final appointmentCell = row.appointmentCell;
            if (appointmentCell != null) {
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    child: Icon(CupertinoIcons.arrow_turn_down_right, size: 15, color: theme.colorScheme.primary,),
                  ),
                  Text(appointmentCell.dateStr),
                  const SizedBox(width: 15,),
                  Text(appointmentCell.timeStr)
                ],
              );
            }

            ++rowsDrawn;

            final titleCell = row.cells[titleCellIndex];
            final termCellBody = termCellIndex != -1 ? row.cells[termCellIndex].body : "";

            return Column(
              children: [
                rowsDrawn == 0 ? SizedBox(height: 0) : Divider(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: mq.size.width * 0.5,
                          child: Text(titleCell.body, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 3,),
                        ),
                        Text(termCellBody),
                      ],
                    ),

                    row.favoriteToggleCell == null ? Text("") : CupertinoButton(
                        child: Icon(row.favoriteToggleCell!.isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star),
                        onPressed: () async {
                          final toggleSuccessful = await vm.toggleIsFavorite(row.favoriteToggleCell!, table.parentModule);
                          if (!toggleSuccessful) {
                            // Fluttertoast.showToast(
                            //     msg: "Fehler!",
                            //     toastLength: Toast.LENGTH_SHORT,
                            //     gravity: ToastGravity.CENTER,
                            //     timeInSecForIosWeb: 1,
                            //     backgroundColor: Colors.red,
                            //     textColor: Colors.white,
                            //     fontSize: 16.0
                            // );
                          } else {
                            // Fluttertoast.showToast(
                            //     msg: row.favoriteToggleCell!.isFavorite ? "Wurde zum Stundenplan hinzugefügt!" : "Wurde vom Stundenplan entfernt!",
                            //     toastLength: Toast.LENGTH_SHORT,
                            //     gravity: ToastGravity.CENTER,
                            //     timeInSecForIosWeb: 1,
                            //     backgroundColor: Colors.grey,
                            //     textColor: Colors.white,
                            //     fontSize: 16.0
                            // );
                          }
                        }
                    )
                  ],
                )
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

}