import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/ilias/views/ilias_page_view.dart';
import 'package:kit_mobile/module/models/module.dart';
import 'package:kit_mobile/parsing/models/hierarchic_table_row.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:provider/provider.dart';

import '../../module/views/module_page.dart';

class RelevantModuleView extends StatelessWidget {
  final KITModule module;

  const RelevantModuleView({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = Provider.of<KITProvider>(context);

    return Stack(
      children: [
        BlockContainer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(_sanitizeModuleTitle(module.title), maxLines: 3, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),),
                ),


                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(CupertinoIcons.info_circle),
                        onPressed: () async {
                          final moduleToShow = _getModuleToShow(vm);
                          Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => ModuleView(module: moduleToShow)));
                        }
                    ),

                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text("ILIAS"),
                      onPressed: () async {
                        // await vm.iliasManager.authorize();
                        final moduleToShow = await _getModuleToShow(vm);
                        Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => IliasPageView(moduleToShow, PHPSESSID_Future: vm.iliasManager.getPHPSESSID())));
                      },

                    ),

                  ],
                )


              ],
            )
        ),

        Opacity(
          opacity: 1,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                module.hasFavoriteChild ? Padding(
                  padding: EdgeInsets.all(3),
                  // width: 20,
                  // height: 20,
                  child: BlockContainer(
                    padding: EdgeInsets.zero,
                    opacity: 0.8,
                    child: Padding(padding: EdgeInsets.all(0), child: Icon(Icons.star, color: theme.colorScheme.primary, size: 15,),) ,
                  )
                ) : Text("")
              ],
            )
        )
      ],
    );
  }

  Future<KITModule> _getModuleToShow(KITProvider vm) async {
    Future<KITModule> moduleToShow = Future.value(module);
    if (module.hierarchicalTableRowId.isEmpty) {
      HierarchicTableRow? rowToShow;
      for (final row in vm.campusManager.moduleRows) {
        if (row.id.contains(module.title)) {
          rowToShow = row;
          break;
        }
      }
      if (rowToShow == null) {
        return moduleToShow;
      }
      moduleToShow = vm.getOrFetchModuleForRow(rowToShow);
    }

    return moduleToShow;
  }

  String _sanitizeModuleTitle(String title) {
    // this method solves the problem when a hierarchic table's entry
    // like "Lineare Algebra - Prüfung" is used as module.title
    // so we split by "-" and filter out words like ["Prüfung", "Klausur"]
    // IMPORTANT: if you encounter some other

    const filterOutLower = ["prüfung", "klausur"]; // lowercased!

    // the initial split by "-"
    final split = title.split("-");

    split.removeWhere((entry) {
      final entryLower = entry.toLowerCase();
      for (final ignored in filterOutLower) {
        if (entryLower.contains(ignored)) {
          // ignore immediately
          return true;
        }
      }

      return false;
    });

    return split.join("-");
  }

}