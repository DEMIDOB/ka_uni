import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/common_ui/kit_progress_indicator.dart';
import 'package:kit_mobile/constants/view_constants.dart';
import 'package:kit_mobile/local_files_storage/files_manager.dart';
import 'package:kit_mobile/settings/providers/settings_provider.dart';
import 'package:kit_mobile/settings/types/multiple_choice_setting.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:provider/provider.dart';

import '../../credentials/data/credentials_provider.dart';
import '../../info/views/info_view.dart';
import '../../local_files_storage/views/pages/cache_cleaner_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SettingsPageState();
  }
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<KITProvider>(context);
    final credsVM = Provider.of<CredentialsProvider>(context);
    final settingsVM = Provider.of<SettingsProvider>(context);
    final filesVM = Provider.of<IliasFilesProvider>(context);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Einstellungen"),
        actions: [
          CupertinoButton(
              child: Icon(CupertinoIcons.info),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => InfoView())))
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: defaultPagePaddingEdgeInsetsAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // SettingsSectionTitle(title: "Interface"),
              //
              // BlockContainer(
              //   child: Column(
              //     children: [
              //       SettingRow(
              //         title: "LiquidAss",
              //         trailing: CupertinoSwitch(
              //           value: settingsVM.liquidAssEverywhere.value,
              //           onChanged: settingsVM.liquidAssEverywhere.set
              //         )
              //       )
              //     ],
              //   ),
              // ),

              SettingsSectionTitle(title: "Homepage"),

              BlockContainer(
                child: Column(
                  children: [
                    SettingRow(
                        title: "Profil anzeigen",
                        trailing: CupertinoSwitch(
                            value: settingsVM.showingProfile.value,
                            onChanged: settingsVM.showingProfile.set)),
                    SettingRow(
                        title: "Durchschnittsnote anzeigen",
                        trailing: CupertinoSwitch(
                            value: settingsVM.showingAvgMark.value,
                            onChanged: settingsVM.showingAvgMark.set)),
                  ],
                ),
              ),

              SettingsSectionTitle(title: "ILIAS"),

              BlockContainer(
                child: Column(
                  children: [
                    SettingRow(
                        title: "Startseite",
                        trailing: MultipleChoiceSettingDropdown(
                            multipleChoiceSetting: settingsVM.defaultIliasPage))
                  ],
                ),
              ),

              SettingsSectionTitle(title: "Dateicache"),

              BlockContainer(
                child: Column(
                  children: [
                    SettingRow(
                      title: "Größe",
                      trailing: FutureBuilder(
                          future:
                              filesVM.localFileStorageManager.getCacheSize(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Text(
                                  "${(snapshot.data! / 1024 / 1024).toStringAsFixed(1)} MB");
                            }

                            return KITProgressIndicator();
                          }),
                    ),
                    CupertinoButton(
                        child: Text("Verwalten"),
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    CacheCleanerPage())))
                  ],
                ),
              ),

              CupertinoButton(
                  child: Text("Ausloggen"),
                  onPressed: () => credsVM.logout(vm)),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _settingRow(String title, Widget trailing) =>
}

class SettingRow extends StatelessWidget {
  final String title;
  final Widget trailing;

  const SettingRow({super.key, required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium,
        ),
        SizedBox(
          width: 20,
        ),
        trailing
      ],
    );
  }
}

class SettingsSectionTitle extends StatelessWidget {
  final String title;

  const SettingsSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(left: 15, bottom: 2, top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
          )
        ],
      ),
    );
  }
}

class MultipleChoiceSettingDropdown extends StatelessWidget {
  final MultipleChoiceSetting _multipleChoiceSetting;

  const MultipleChoiceSettingDropdown(
      {super.key, required MultipleChoiceSetting multipleChoiceSetting})
      : _multipleChoiceSetting = multipleChoiceSetting;

  @override
  Widget build(BuildContext context) {
    // final settingsVM = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);

    return Expanded(
        child: DropdownButton(
            underline: SizedBox.shrink(),
            borderRadius: BorderRadius.all(appBorderRadius),
            dropdownColor: theme.cardColor,
            elevation: 1,
            alignment: Alignment.centerRight,
            items: _multipleChoiceSetting.choices
                .map((el) => DropdownMenuItem(
                      value: el,
                      alignment: Alignment.centerRight,
                      child: Text(
                        "$el",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ))
                .toList(),
            value: _multipleChoiceSetting.value,
            onChanged: (item) => _multipleChoiceSetting.set(item)));
  }
}
