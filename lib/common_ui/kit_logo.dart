import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

class KITLogo extends StatelessWidget {
  final double width;

  const KITLogo({super.key, this.width = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      // height: 28,
      child: SvgPicture.asset("assets/images/KIT.svg"),
    );
  }

}