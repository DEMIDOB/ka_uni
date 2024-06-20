import 'package:flutter/cupertino.dart';

class KITProgressIndicator extends StatelessWidget {
  final bool animating;

  const KITProgressIndicator({super.key, this.animating = true});

  @override
  Widget build(BuildContext context) {
    return CupertinoActivityIndicator(animating: animating,);
  }

}