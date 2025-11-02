import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/home/views/relevant_module.dart';
import 'package:kit_mobile/module/models/module.dart';
import 'package:kit_mobile/utils/date_time_utils.dart';
import 'package:provider/provider.dart';

import '../../state_management/kit_provider.dart';

class RelevantModulesView extends StatelessWidget {
  const RelevantModulesView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<KITProvider>(context);
    final theme = Theme.of(context);
    final modules = vm.campusManager.relevantModuleRowIDs;
    final lastFetchTime = vm.campusManager.lastModuleFetchTime;
    final lastFetchLabel = lastFetchTime != null
        ? formatHumanReadableTimestamp(lastFetchTime)
        : "-";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            "Module zuletzt aktualisiert: $lastFetchLabel",
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: GridView.count(
            crossAxisCount: 2,
            scrollDirection: Axis.horizontal,
            children: List.generate(modules.length, (idx) {
              final rowID = modules[idx];
              var module = vm.campusManager.rowModules[rowID];

              if (module == null) {
                module = KITModule();
                module.title = rowID;
              }

              return RelevantModuleView(module: module);
            }),
          ),
        ),
      ],
    );
  }

}
