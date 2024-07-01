import 'package:flutter/cupertino.dart';

class KITProgressIndicator extends StatelessWidget {
  final bool animating;
  final Color? color;

  const KITProgressIndicator({super.key, this.animating = true, this.color});

  @override
  Widget build(BuildContext context) {
    return CupertinoActivityIndicator(animating: animating, color: color,);
  }

}