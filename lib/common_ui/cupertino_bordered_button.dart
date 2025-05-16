import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoBorderedButton extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Function? onPressed;

  const CupertinoBorderedButton(
      {super.key, required this.title, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // decoration: BoxDecoration(
          // borderRadius: BorderRadius.all(Radius.circular(5)),
          // border: Border.all(
            // color: theme.colorScheme.primary,
          // )),
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(horizontal: 5),
        sizeStyle: CupertinoButtonSize.small,
        onPressed: () {
          if (onPressed != null) {
            onPressed!();
          }
        },
        child: Row(
          children: [
            Text(title),
            SizedBox(
              width: 5,
            ),
            Icon(icon)
          ],
        ),
      ),
    );
  }
}
