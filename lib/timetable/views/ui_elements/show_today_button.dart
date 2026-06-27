import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ShowTodayButton extends StatelessWidget {
  final int relativeOffset;
  final void Function() onPressed;

  final double arrowTextGapSize;
  final FontWeight textFontWeight, arrowFontWeight;

  const ShowTodayButton({
    super.key,
    required this.relativeOffset,
    required this.onPressed,
    this.arrowTextGapSize = 3,
    this.textFontWeight = FontWeight.bold,
    this.arrowFontWeight = FontWeight.bold
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        (relativeOffset).abs() <= 1 ? SizedBox.shrink() : CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 0),
            onPressed: onPressed,

            child: Row(
              children: [
                (relativeOffset < 0) ? SizedBox.shrink() : Row(
                  children: [
                    Icon(CupertinoIcons.arrow_left, fontWeight: arrowFontWeight),
                    SizedBox(width: arrowTextGapSize,),
                  ],
                ),

                Text("heute", style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: textFontWeight
                ),),

                (relativeOffset > 0) ? SizedBox.shrink() : Row(
                  children: [
                    SizedBox(width: arrowTextGapSize,),
                    Icon(CupertinoIcons.arrow_right, fontWeight: arrowFontWeight,)
                  ],
                )
              ],
            )
        )
      ],
    );
  }

}