import 'package:flutter/material.dart';

extension on ThemeData {
  bool get isDarkMode {
    return colorScheme.brightness == Brightness.dark;
  }
}

class BlockContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? innerPadding;

  const BlockContainer({super.key, required this.child, this.padding, this.innerPadding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ?? EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          color: theme.isDarkMode ? theme.cardColor : theme.scaffoldBackgroundColor,
          // color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withOpacity(theme.isDarkMode ? 0 : 0.2), // 0.25
              spreadRadius: 0.5, // 1
              blurRadius: 4, // 2
            )
          ]
        ),
        padding: innerPadding ?? const EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
        child: child,
      ),
    );
  }

}