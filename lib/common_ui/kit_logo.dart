import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class KITLogo extends StatelessWidget {
  final double width;

  const KITLogo({super.key, this.width = 80});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      // height: 28,
      child: Row(
        children: [
          Text("KA", style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor),),
          Text(".Uni")
        ],
      )
      // child: SvgPicture.asset("assets/images/KIT.svg"),
    );
  }

}