import 'package:flutter/material.dart';
import 'package:kit_mobile/module/views/module_page.dart';
import 'package:kit_mobile/state_management/KITProvider.dart';
import 'package:provider/provider.dart';

import '../../parsing/models/hierarchic_table_row.dart';

class HierarchicTableView extends StatelessWidget {
  final List<HierarchicTableRow> rows;

  const HierarchicTableView({super.key, required this.rows});
  final minLevelToShow = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = Provider.of<KITProvider>(context);

    return Column(
      children: rows.map((row) {
        if (row.level < minLevelToShow) {
          return SizedBox(width: 0, height: 0,);
        }

        return GestureDetector(
          onTap: () {
            final moduleFuture = vm.getOrFetchModuleForRow(row);
            Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => ModuleView(module: moduleFuture)));
          },
          child: Padding(
            padding: EdgeInsets.only(left: 10 + (row.level - minLevelToShow) * 20, top: row.level == minLevelToShow ? 8 : 6, bottom: row.level == minLevelToShow ? 8 : 0, right: 10),
            child: Column(
              children: [
                (row.level == minLevelToShow ? Divider() : SizedBox(height: 0,)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(row.title, maxLines: 3, style: row.level == minLevelToShow ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium,)),

                    Text(row.mark.length < 6 ? row.mark : "")
                  ],
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }


}