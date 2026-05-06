import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common_ui/kit_logo.dart';
import '../../settings/providers/settings_provider.dart';
import '../../state_management/kit_provider.dart';

class KaUniAppBarTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<KITProvider>(context);
    final settingsVM = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);

    return Row(
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
    );
  }

}