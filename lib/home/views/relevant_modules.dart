import 'package:flutter/cupertino.dart';
import 'package:kit_mobile/home/views/relevant_module.dart';
import 'package:kit_mobile/module/models/module.dart';
import 'package:provider/provider.dart';

import '../../state_management/kit_provider.dart';

class RelevantModulesView extends StatelessWidget {
  const RelevantModulesView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<KITProvider>(context);
    return SizedBox(
      height: 300,
      child: GridView.count(crossAxisCount: 2,
        scrollDirection: Axis.horizontal,
        children: List.generate(vm.campusManager.relevantModuleRowIDs.length, (idx) {
          final rowID = vm.campusManager.relevantModuleRowIDs[idx];
          var module = vm.campusManager.rowModules[rowID];

          if (module == null) {
            module = KITModule();
            module.title = rowID;
          }

          return RelevantModuleView(module: module);
        },),),
    );
  }

}