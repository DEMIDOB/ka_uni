import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/ilias/views/ilias_page_view.dart';
import 'package:kit_mobile/module/models/module.dart';

import '../../module/views/module_page.dart';

class RelevantModuleView extends StatelessWidget {
  final KITModule module;

  const RelevantModuleView({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        BlockContainer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(module.title, maxLines: 3, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),),
                ),


                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(CupertinoIcons.info_circle),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => ModuleView(module: Future.value(module))))
                    ),

                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text("ILIAS"),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => IliasPageView(module)));
                      },

                    ),

                  ],
                )


              ],
            )
        ),

        Opacity(
          opacity: 0.7,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                module.hasFavoriteChild ? Padding(padding: EdgeInsets.all(10), child: Icon(Icons.star, color: Colors.amber,),) : Text("")
              ],
            )
        )
      ],
    );
  }

}