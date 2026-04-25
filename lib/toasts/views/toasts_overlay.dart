import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/extensions/theme_data_extension.dart';
import 'package:provider/provider.dart';

import '../models/toasts_provider.dart';

class ToastsOverlay extends StatelessWidget {
  const ToastsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final toastsProvider = Provider.of<ToastsProvider>(context);
    final theme = Theme.of(context);

    return SafeArea(child:
      Column(
        children: [
          Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedOpacity(
                opacity: toastsProvider.isShowing ? 1 : 0,
                duration: ToastsProvider.defaultAnimationDuration,
                child: IgnorePointer(
                  ignoring: !toastsProvider.isShowing,
                  child: BlockContainer(
                    withShadow: true,
                    backgroundColor: theme.isLightMode ? theme.cardColor : Colors.black,
                    child: Text(
                      toastsProvider.message,
                      style: theme.textTheme.bodyMedium?.copyWith(color: toastsProvider.foregroundColor),
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      )
    );
  }

}