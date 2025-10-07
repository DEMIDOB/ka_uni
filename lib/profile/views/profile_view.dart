import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kit_mobile/settings/providers/settings_provider.dart';
import 'package:provider/provider.dart';

import '../../common_ui/block_container.dart';
import '../../common_ui/cupertino_bordered_button.dart';
import '../../credentials/data/credentials_provider.dart';
import '../../ilias/views/ilias_page_view.dart';
import '../../module/models/module.dart';
import '../../state_management/kit_provider.dart';
import '../../timetable/pages/timetable_edit_page.dart';
import '../../toasts/models/toasts_provider.dart';

class ProfileView extends StatelessWidget {
  final GlobalKey relevantModulesTitleKey;

  const ProfileView({super.key, required this.relevantModulesTitleKey});

  @override
  Widget build(BuildContext context) {
    final credsVM = Provider.of<CredentialsProvider>(context);
    final vm = Provider.of<KITProvider>(context);
    final toastsProvider = Provider.of<ToastsProvider>(context);
    final settingsVM = Provider.of<SettingsProvider>(context);

    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          BlockContainer(
            padding: EdgeInsets.zero,
            innerPadding: EdgeInsets.zero,
            child: Container(
              padding: EdgeInsets.zero,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: -30,
                      child: SvgPicture.asset("assets/images/Fan.svg", width: 150, fit: BoxFit.none,),
                    ),

                    GestureDetector(
                      onLongPress: () async => toastsProvider.showTextToast("Hi :)"),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Hero(tag: "student_name_repr", child: Text(vm.student.name.repr, style: theme.textTheme.headlineSmall)),
                            Text(vm.student.matriculationNumber),
                          ],
                        ),
                      ),
                    )
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
                Text(KITProvider.currentSemesterString, style: theme.textTheme.titleMedium,),
              ],
            ),
          ),

          !settingsVM.showingAvgMark.value ?
          BlockContainer(
              padding: EdgeInsets.only(top: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Leistungspunkte", style: theme.textTheme.titleMedium,),

                  Text(vm.student.ectsAcquired, style: theme.textTheme.titleMedium,),
                ],
              )
          )
              : Row(
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

          // const Padding(padding: EdgeInsets.all(10)),

          // _controlsRow(context, vm)
        ],
      ),
    );
  }

  Widget _controlsRow(BuildContext context, KITProvider vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CupertinoBorderedButton(
            title: "Module",
            icon: CupertinoIcons.arrow_turn_left_down,
            onPressed: () {
              Scrollable.ensureVisible(relevantModulesTitleKey.currentContext!);
            }
        ),

        CupertinoBorderedButton(
            title: "Stundenplan",
            icon: CupertinoIcons.pencil_circle,
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => TimetableEditPage()));
            }
        ),

        CupertinoBorderedButton(
            title: "ILIAS",
            icon: CupertinoIcons.globe,
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => IliasPageView(KITModule(), PHPSESSID: vm.iliasManager.getPHPSESSID())));
            }
        ),
      ],
    );
  }

}