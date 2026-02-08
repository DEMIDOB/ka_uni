import 'package:flutter/material.dart';
import 'package:kit_mobile/constants/view_constants.dart';
import 'package:kit_mobile/settings/providers/settings_provider.dart';
import 'package:liquid_glass_widgets/widgets/containers/glass_container.dart';
import 'package:provider/provider.dart';

class BlockContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? innerPadding;
  final double opacity;

  const BlockContainer(
      {super.key,
      required this.child,
      this.padding,
      this.innerPadding,
      this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    final settingsVM = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);

    if (settingsVM.liquidAssEverywhere.value) {
      return Padding(
        padding: padding ?? EdgeInsets.all(3),
        child: GlassContainer(
          child: Padding(
            padding: innerPadding ??
                const EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
            child: child,
          ),
        ),
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(appBorderRadius),
          color: theme.cardColor,
        ),
        padding: innerPadding ??
            const EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
        child: child,
      ),
    );
  }
}
