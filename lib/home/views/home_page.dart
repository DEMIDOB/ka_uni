import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/kit_progress_indicator.dart';
import 'package:kit_mobile/constants/view_constants.dart';
import 'package:kit_mobile/home/views/hierarchic_table.dart';
import 'package:kit_mobile/home/views/padded_title.dart';
import 'package:kit_mobile/home/views/relevant_modules.dart';
import 'package:kit_mobile/local_files_storage/views/pinned_files_list_view.dart';
import 'package:kit_mobile/profile/views/profile_view.dart';
import 'package:kit_mobile/settings/providers/settings_provider.dart';
import 'package:kit_mobile/timetable/pages/timetable_edit_page.dart';
import 'package:kit_mobile/timetable/views/timetable_weekly_view.dart';
import 'package:kit_mobile/toasts/models/toasts_provider.dart';
import 'package:provider/provider.dart';

import '../../common_ui/kit_logo.dart';
import '../../local_files_storage/views/pages/files_cache_page.dart';
import '../../state_management/kit_provider.dart';

class KITHomePage extends StatefulWidget {
  const KITHomePage({super.key});

  @override
  State<KITHomePage> createState() => _KITHomePageState();
}

class _KITHomePageState extends State<KITHomePage> {
  final _relevantModulesTitleKey = GlobalKey();

  // bool _showProfile = true;

  @override
  Widget build(BuildContext context) {
    // final credsVM = Provider.of<CredentialsProvider>(context);
    final vm = Provider.of<KITProvider>(context);
    final toastsProvider = Provider.of<ToastsProvider>(context);
    final settingsVM = Provider.of<SettingsProvider>(context);

    final theme = Theme.of(context);

    return Scaffold(
        appBar: AppBar(
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // backgroundColor: Theme.of(context).colorScheme.surface,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: settingsVM.showingProfile.value
                    ? const KITLogo()
                    : Row(
                        children: [
                          Text(
                            "Hi, ",
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            vm.student.name.firstName,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(color: theme.colorScheme.primary),
                          )
                        ],
                      ),
              )
            ],
          ),
          centerTitle: true,
          // backgroundColor: Colors.transparent,
          // shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          )),
          // surfaceTintColor: Colors.transparent,
          leading: vm.profileReady ? SizedBox.shrink() : KITProgressIndicator(),
          // leading: !kDebugMode
          //     ? null
          //     : CupertinoButton(
          //         child: Icon(
          //           CupertinoIcons.check_mark_circled_solid,
          //           color: Colors.red,
          //         ),
          //         onPressed: () async {
          //           await vm.prepareCachedData();
          //
          //           await credsVM.loadCredentials();
          //           await vm.setCredentials(credsVM.credentials);
          //           print(
          //               "${credsVM.credentials}, ${credsVM.credentials.valid}");
          //           if (credsVM.credentialsLoaded &&
          //               credsVM.credentials.valid) {
          //             await credsVM.login(vm);
          //             await vm.fetchSchedule();
          //             await vm.campusManager.fetchAllModules();
          //           }
          //         }),
          actions: [
            CupertinoButton(
              onPressed: () {
                // Navigator.of(context).push(MaterialPageRoute(builder: (context) => InfoView()));
                setState(() {
                  // _showProfile = !_showProfile;
                  settingsVM.showingProfile.toggle();
                });
              },
              // child: const Icon(CupertinoIcons.info),
              child: AnimatedRotation(
                curve: defaultChevronRotationAnimationCurve,
                turns: settingsVM.showingProfile.value ? 0 : -0.25,
                duration: defaultChevronRotationAnimationDuration,
                child: Icon(CupertinoIcons.chevron_down),
              ),
            )
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: settingsVM.showingProfile.value
                          ? ProfileView(
                              relevantModulesTitleKey: _relevantModulesTitleKey,
                            )
                          : SizedBox(),
                    ),
                    TimetableWeeklyView(),
                    CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  TimetableEditPage()));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.pencil_circle),
                            Text("Stundenplan bearbeiten"),
                          ],
                        )),
                    const Padding(padding: EdgeInsets.all(10)),
                    Row(
                      children: [
                        PaddedTitle(
                            key: _relevantModulesTitleKey,
                            title:
                                "Aktuelle Module im ${KITProvider.currentSemesterString}"),
                        (vm.campusManager.isFetchingSchedule ||
                                vm.campusManager.isFetchingModules)
                            ? KITProgressIndicator()
                            : SizedBox(
                                width: 0,
                                height: 0,
                              ),
                        Spacer(),
                        CupertinoButton(
                          onPressed: () {
                            toastsProvider
                                .showTextToast("Module werden neu geladen...");
                            vm.forceRefetchEverything();
                          },
                          padding: EdgeInsets.all(10),
                          child: Icon(CupertinoIcons.refresh),
                        )
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: RelevantModulesView(),
                    ),
                    const Padding(padding: EdgeInsets.all(20)),
                    PaddedTitle(
                      title: "Angeheftete Dateien",
                      trailing: CupertinoButton(
                          child: Text("Alle ansehen"),
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      FilesCachePage()))),
                    ),
                    PinnedFilesListView(),
                    const Padding(padding: EdgeInsets.all(20)),
                    PaddedTitle(title: "Meine Module"),
                    HierarchicTableView(
                      rows: vm.campusManager.moduleRows,
                    )
                  ],
                )
              ]),
            ),
          ],
        ));
  }

  // Future<void> _refreshHomeView(KITProvider vm) async {
  //   await vm.forceRefetchEverything();
  // }
}
