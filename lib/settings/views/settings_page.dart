import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/constants.dart';
import 'package:kit_mobile/settings/providers/settings_provider.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:provider/provider.dart';

import '../../credentials/data/credentials_provider.dart';

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

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Einstellungen"),
      ),

      body: SingleChildScrollView(
        child: Container(
          padding: defaultPagePaddingEdgeInsetsAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BlockContainer(
                child: Column(
                 children: [
                   SettingRow(
                     title: "Profil anzeigen",
                     trailing: CupertinoSwitch(
                       value: settingsVM.showingProfile.value,
                       onChanged: settingsVM.showingProfile.set
                     )
                   ),

                   SettingRow(
                       title: "Durchschnittsnote anzeigen",
                       trailing: CupertinoSwitch(
                           value: settingsVM.showingAvgMark.value,
                           onChanged: settingsVM.showingAvgMark.set
                       )
                   ),
                 ],
                ),
              ),
              CupertinoButton(child: Text("Ausloggen"), onPressed: () => credsVM.logout(vm)),
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

    return
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodyMedium,),
          trailing
        ],
      );
  }

}