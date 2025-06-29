import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Einstellungen"),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            CupertinoButton(child: Text("Ausloggen"), onPressed: () => credsVM.logout(vm))
          ],
        ),
      ),
    );
  }

}