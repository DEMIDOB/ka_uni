import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kit_mobile/home/views/hierarchic_table.dart';
import 'package:kit_mobile/home/views/padded_title.dart';
import 'package:kit_mobile/home/views/relevant_modules.dart';
import 'package:kit_mobile/timetable/views/timetable_weekly_view.dart';
import 'package:provider/provider.dart';

import '../../common_ui/block_container.dart';
import '../../common_ui/kit_logo.dart';
import '../../credentials/data/credentials_provider.dart';
import '../../info/views/info_view.dart';
import '../../state_management/KITProvider.dart';

class KITHomePage extends StatefulWidget {
  const KITHomePage({super.key});

  @override
  State<KITHomePage> createState() => _KITHomePageState();
}

class _KITHomePageState extends State<KITHomePage> {
  @override
  Widget build(BuildContext context) {
    final credsVM = Provider.of<CredentialsProvider>(context);
    final vm = Provider.of<KITProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shadowColor: Colors.black38,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            KITLogo()
          ],
        ),
        centerTitle: true,
        leading: CupertinoButton(
          onPressed: () {
            credsVM.logout(vm);
          },
          child: const Icon(CupertinoIcons.arrow_left_square),
        ),
        actions: [
          CupertinoButton(
            child: Text("il"),
            onPressed: () {
              vm.iliasManager.authorize();
            }
          ),
          CupertinoButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => InfoView()));
            },
            child: const Icon(CupertinoIcons.info),
          )
        ],
      ),
      body: !vm.profileReady ? const Center(child: CupertinoActivityIndicator(),) : RefreshIndicator(
        onRefresh: () async => await _refreshHomeView(vm),
        child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[

                    Padding(
                      padding: EdgeInsets.all(15),
                      child: Column(
                        children: [
                          BlockContainer(
                            innerPadding: EdgeInsets.zero,
                            child: Container(
                              padding: EdgeInsets.zero,
                              height: 80,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Positioned(
                                      left: -30,
                                      child: SvgPicture.asset("assets/images/Fan.svg", width: 150, fit: BoxFit.none,),
                                    ),

                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Hero(tag: "student_name_repr", child: Text(vm.student.name.repr, style: theme.textTheme.headlineSmall)),
                                          Text(vm.student.matriculationNumber),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          Padding(padding: EdgeInsets.all(5)),

                          BlockContainer(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Studiengang", style: theme.textTheme.titleMedium,),
                                const Padding(padding: EdgeInsets.all(10)),
                                Expanded(
                                  child: Text(
                                    vm.student.degreeProgram,
                                    style: theme.textTheme.titleMedium,
                                    maxLines: 2,
                                    textAlign: TextAlign.end,
                                  ),
                                )
                              ],
                            ),
                          ),

                          BlockContainer(
                            padding: EdgeInsets.only(top: 7),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Semester", style: theme.textTheme.titleMedium,),
                                Text(vm.currentSemesterString, style: theme.textTheme.titleMedium,),
                              ],
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              BlockContainer(
                                padding: EdgeInsets.only(top: 7),
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.36,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Note (⌀)", style: theme.textTheme.titleMedium,),

                                      Text(vm.student.avgMark.toString(), style: theme.textTheme.titleMedium,),
                                    ],
                                  ),
                                ),
                              ),

                              BlockContainer(
                                  padding: EdgeInsets.only(top: 7),
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.36,
                                    // padding: EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("LP", style: theme.textTheme.titleMedium,),

                                        Text(vm.student.ectsAcquired, style: theme.textTheme.titleMedium,),
                                      ],
                                    ),
                                  )
                              ),
                            ],
                          ),

                          const Padding(padding: EdgeInsets.all(10)),

                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   crossAxisAlignment: CrossAxisAlignment.center,
                          //   children: [
                          //     Padding(
                          //       padding: EdgeInsets.all(10),
                          //       child: Text("Heute", style: theme.textTheme.titleLarge,),
                          //     ),
                          //
                          //     CupertinoButton(
                          //         child: Text("Woche anzeigen"),
                          //         onPressed: () {
                          //
                          //         }
                          //     )
                          //   ],
                          // ),
                        ],
                      ),
                    ),

                    TimetableWeeklyView(),
                    // TimetableDailyView(tt: vm.timetable.days[DateTime.now().weekday - 1 < 5 ? DateTime.now().weekday - 1 : 1]),

                    const Padding(padding: EdgeInsets.all(10)),

                    PaddedTitle(title: "Aktuelle Module im ${vm.currentSemesterString}"),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: RelevantModulesView(),
                    ),

                    const Padding(padding: EdgeInsets.all(20)),

                    PaddedTitle(title: "Meine Module"),
                    HierarchicTableView(rows: vm.campusManager.moduleRows,)
                  ],
                ),
              )
            ]
        ),
      ),
    );
  }

  Future<void> _refreshHomeView(KITProvider vm) async {
    await vm.forceRefetchEverything();
  }
}