import 'package:flutter/material.dart';

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
          color: theme.colorScheme.brightness == Brightness.light ? theme.scaffoldBackgroundColor : Colors.black.withOpacity(1),
          // color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              spreadRadius: 1,
              blurRadius: 2,
            )
          ]
        ),
        padding: innerPadding ?? const EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
        child: child,
      ),
    );
  }

}