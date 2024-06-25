import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../state_management/KITProvider.dart';
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
    final vm = Provider.of<KITProvider>(context);

    final lowerCaseCaption = widget.table.caption.toLowerCase();

    int rowsDrawn = -1;

    // TODO: make a regex check :)
    if (lowerCaseCaption.contains("prüfung") ||
        lowerCaseCaption.contains("teilleistungen") ||
        lowerCaseCaption.contains("veranstaltungen")) {
      final titleIndex = widget.table.colTitles.indexOf("Titel");
      final termIndex = widget.table.colTitles.indexOf("Semester");

      if (titleIndex != -1) {
        return Column(
          children: [
            Text(widget.table.caption, style: theme.textTheme.titleMedium,),

            const SizedBox(height: 10,),

            Column(
              children: widget.table.rows.map((row) {
                final appointmentCell = row.appointmentCell;
                if (appointmentCell != null) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        child: Icon(CupertinoIcons.arrow_turn_down_right, size: 15, color: theme.primaryColor,),
                      ),
                      Text(appointmentCell.dateStr),
                      const SizedBox(width: 15,),
                      Text(appointmentCell.timeStr)
                    ],
                  );
                }

                ++rowsDrawn;

                final titleCell = row.cells[titleIndex];
                final termCellBody = termIndex != -1 ? row.cells[termIndex].body : "";

                return Column(
                  children: [
                    rowsDrawn == 0 ? SizedBox(height: 0) : Divider(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: mq.size.width * 0.5,
                              child: Text(titleCell.body, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 3,),
                            ),
                            Text(termCellBody),
                          ],
                        ),

                        row.favoriteToggleCell == null ? Text("") : CupertinoButton(
                          child: Icon(row.favoriteToggleCell!.isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star),
                          onPressed: () async {
                            // TODO: signal if something went wrong!!!!!!
                            final toggleSuccessful = await vm.toggleIsFavorite(row.favoriteToggleCell!, widget.table.parentModule);
                            if (!toggleSuccessful) {
                              Fluttertoast.showToast(
                                  msg: "Fehler!",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0
                              );
                            } else {
                              Fluttertoast.showToast(
                                  msg: row.favoriteToggleCell!.isFavorite ? "Wurde zum Stundenplan hinzugefügt!" : "Wurde vom Stundenplan entfernt!",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.grey,
                                  textColor: Colors.white,
                                  fontSize: 16.0
                              );
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