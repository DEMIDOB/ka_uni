import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class AlphaBadge extends StatelessWidget {
  const AlphaBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (!isAlpha) {
      return const SizedBox(width: 0, height: 0);
    }

    return Container(
      // width: 15,
      // height: 15,
      alignment: Alignment.center,
      padding: EdgeInsets.only(bottom: 3),
      // decoration: BoxDecoration(
          // border: Border.all(color: Colors.red),
          // borderRadius: BorderRadius.all(Radius.circular(5))
      // ),
      child: Text("α", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red, fontSize: 12)),
    );
  }

}