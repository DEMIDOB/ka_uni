import 'package:flutter/material.dart';
import 'package:kit_mobile/state_management/KITProvider.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'alpha_badge.dart';

class KITLogo extends StatelessWidget {
  final double width;

  const KITLogo({super.key, this.width = isAlpha ? 150 : 80});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = Provider.of<KITProvider>(context);

    return SizedBox(
      // width: width,
      // height: 28,
      child: GestureDetector(
        onLongPress: () {
          vm.campusManager.resetRelevantModules();
        },
        child: Row(
          children: [

            Text("KA", style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),),
            const Text(".Uni"),

            const SizedBox(width: 2,),

            !isAlpha ? const Text("") : const AlphaBadge()
          ],
        )
        // child: SvgPicture.asset("assets/images/KIT.svg"),
      )
    );
  }

}