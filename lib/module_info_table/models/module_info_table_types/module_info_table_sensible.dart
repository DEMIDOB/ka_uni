import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:kit_mobile/common_ui/kit_progress_indicator.dart';
import 'package:kit_mobile/module_info_table/views/appointment_cell.dart';
import 'package:provider/provider.dart';

import '../../../state_management/kit_provider.dart';
import '../../../toasts/models/toasts_provider.dart';
import '../module_info_table.dart';

class ModuleInfoTableSensible extends StatefulWidget {
  final ModuleInfoTable table;

  const ModuleInfoTableSensible({super.key, required this.table});

  @override
  State<StatefulWidget> createState() {
    return _ModuleInfoTableSensibleState();
  }

}

class _ModuleInfoTableSensibleState extends State<ModuleInfoTableSensible> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final vm = Provider.of<KITProvider>(context);
    final toastsProvider = Provider.of<ToastsProvider>(context);

    final table = widget.table;

    final termCellIndex = table.termCellIndex;
    final titleCellIndex = table.titleCellIndex;

    // rowsDrawn is used to skip the first divider
    int rowsDrawn = -1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(table.caption, style: theme.textTheme.titleMedium,),
            _isBusy ? SizedBox(width: 5,) : SizedBox.shrink(),
            _isBusy ? KITProgressIndicator() : SizedBox.shrink()
          ],
        ),

        const SizedBox(height: 10,),

        Column(
          children: table.rows.map((row) {
            final appointmentCell = row.appointmentCell;
            if (appointmentCell != null) {
              return AppointmentCell(cellData: appointmentCell);
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

                    (row.favoriteToggleCell == null || titleCell.body.toLowerCase().contains("tutorium")) ? Text("") : CupertinoButton(
                        child: Icon(row.favoriteToggleCell!.isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star),
                        onPressed: () async {
                          setState(() {
                            _isBusy = true;
                          });
                          // final toggleSuccessful = await vm.toggleIsFavorite(row.favoriteToggleCell!, table.parentModule);
                          final toggleSuccessful = await vm.toggleIsFavoriteFuzzy(titleCell.body, table.caption, table.parentModule.title);
                          if (!toggleSuccessful) {
                            toastsProvider.showTextToast("Die Sitzung ist abgelaufen. Das kann ein bisschen länger dauern...");
                            // retry ONE MORE TIME after refetching everything
                            await vm.forceRefetchEverything(allModulesAsWell: false);

                            if (table.parentModule.row == null) {
                              await Haptics.vibrate(HapticsType.error);
                              toastsProvider.showTextToast("Fehler beim Hinzufügen von ${titleCell.body} zum Stundenplan");
                              setState(() {
                                _isBusy = false;
                              });
                              await vm.campusManager.fetchAllModules();
                              return;
                            }

                            final newRowEntry = vm.fuzzyFindHierarchicTableRowSimilarTo(table.parentModule.row!);

                            if (newRowEntry == null) {
                              await Haptics.vibrate(HapticsType.error);
                              toastsProvider.showTextToast("Fehler beim Hinzufügen von ${titleCell.body} zum Stundenplan");
                              setState(() {
                                _isBusy = false;
                              });
                              await vm.campusManager.fetchAllModules();
                              return;
                            }

                            // we only fetch the needed module for now (all the others later)
                            await vm.getOrFetchModuleForRow(newRowEntry);

                            // the url or other data could have been changed after refetching everything,
                            // although we assume that we can still find this entry by the module title,
                            // caption (aka name) of the table and the title of this "row"
                            final secondToggleSuccessful = await vm.toggleIsFavoriteFuzzy(titleCell.body, table.caption, table.parentModule.title);

                            if (!secondToggleSuccessful) {
                              await Haptics.vibrate(HapticsType.error);
                              toastsProvider.showTextToast("Fehler beim Hinzufügen von ${titleCell.body} zum Stundenplan");
                            } else {
                              _onToggleFavoriteSuccess(row.favoriteToggleCell!.isFavorite, toastsProvider);
                            }

                            vm.campusManager.fetchAllModules();
                          } else {
                            _onToggleFavoriteSuccess(row.favoriteToggleCell!.isFavorite, toastsProvider);
                          }

                          setState(() {
                            _isBusy = false;
                          });
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

  Future<void> _onToggleFavoriteSuccess(bool newValue, ToastsProvider toastsProvider) async {
    toastsProvider.showTextToast(newValue ? "Wurde zum Stundenplan hinzugefügt!" : "Wurde vom Stundenplan entfernt!");
    await Haptics.vibrate(HapticsType.success);
  }
}