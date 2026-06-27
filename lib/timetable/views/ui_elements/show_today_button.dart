import 'package:flutter/cupertino.dart';

class ShowTodayButton extends StatelessWidget {
  final int relativeOffset;
  final void Function() onPressed;

  const ShowTodayButton({super.key, required this.relativeOffset, required this.onPressed});

  @override
  Widget build(BuildContext context) {
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
                    Icon(CupertinoIcons.arrow_left),
                    SizedBox(width: 5,),
                  ],
                ),

                Text("heute"),

                (relativeOffset > 0) ? SizedBox.shrink() : Row(
                  children: [
                    SizedBox(width: 5,),
                    Icon(CupertinoIcons.arrow_right)
                  ],
                )
              ],
            )
        )
      ],
    );
  }

}