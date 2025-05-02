import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:kit_mobile/module_info_table/views/module_info_table_view.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/common_ui/kit_progress_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/module.dart';

class ModuleView extends StatefulWidget {
  Future<KITModule> module;

  ModuleView({super.key, required this.module});

  @override
  State<StatefulWidget> createState() {
    return _ModuleViewState();
  }

}

class _ModuleViewState extends State<ModuleView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder(
      future: widget.module,
      builder: (BuildContext context, AsyncSnapshot<KITModule> moduleSnapshot) {
        if (!moduleSnapshot.hasData || moduleSnapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Modul", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.normal),),
            ),
            body: const Center(
              child: KITProgressIndicator(),
            ),
          );
        }

        final module = moduleSnapshot.data!;

        final double iconDescriptionPadding = 2;

        return Scaffold(
          appBar: AppBar(
            title: Text("Modul", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.normal),),
            actions: [
              (module.iliasLink != null && module.iliasLink!.isNotEmpty) ? CupertinoButton(child: Text("ILIAS"), onPressed: () {
                // print(module.iliasLink);
                FlutterWebBrowser.openWebPage(url: module.iliasLink!);
              } ) : Text("")
            ],
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: ListView(
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(padding: EdgeInsets.only(top: 15),),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Text(module.title, style: theme.textTheme.headlineMedium, maxLines: 5,),
                    ),
                    // Icon(CupertinoIcons.star)
                  ],
                ),

                Padding(padding: EdgeInsets.only(top: 20)),

                Container(
                  padding: EdgeInsets.only(left: 15),
                  child: Text(module.id),
                ),

                BlockContainer(
                  child: Column(
                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(module.isUpcoming ? CupertinoIcons.clock : (module.examDateKnown ? CupertinoIcons.check_mark_circled : CupertinoIcons.question_circle), color: module.examDateKnown ? theme.colorScheme.primary : theme.disabledColor,),
                              Padding(padding: EdgeInsets.all(iconDescriptionPadding),),
                              Text(module.timeAxisPositionString,) // style: theme.textTheme.bodyMedium?.copyWith(color: module.examDateKnown ? theme.colorScheme.primary : theme.disabledColor),)
                            ],
                          ),

                          !module.examDateKnown ? Text("") : Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(CupertinoIcons.calendar_circle, color: module.examDateKnown ? theme.colorScheme.primary : theme.disabledColor,),
                              Padding(padding: EdgeInsets.all(iconDescriptionPadding),),
                              Text(module.examDateStr,) // style: theme.textTheme.bodyMedium?.copyWith(color: module.examDateKnown ? theme.colorScheme.primary : theme.disabledColor),)
                            ],
                          )
                        ],
                      ),

                      // Padding(
                      //   padding: EdgeInsets.only(top: 5),
                      // ),

                      Divider(),

                      // Padding(
                      //   padding: EdgeInsets.only(top: 5),
                      // ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(CupertinoIcons.pencil_outline, color: theme.colorScheme.primary,),
                              Padding(padding: EdgeInsets.all(iconDescriptionPadding),),
                              Text(module.grade.isNotEmpty ? module.grade : "0,0",)
                            ],
                          ),

                          VerticalDivider(color: Colors.black,),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(CupertinoIcons.book_circle, color: theme.colorScheme.primary,),
                              Padding(padding: EdgeInsets.all(iconDescriptionPadding),),
                              Text("${module.pointsAcquired} / ${module.pointsAvailable} LP",)
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),

                Column(
                  children: module.tables.map((table) => BlockContainer(
                    padding: EdgeInsets.only(top: 20, left: 4, right: 4),
                    child: ModuleInfoTableView(table: table),)
                  ).toList(),
                )

              ],
            ),
          ),
        );
      }
    );
  }

}