import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/home/views/home_page.dart';

class KITNavContainer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _KITNavContainerState();
  }

}

class _KITNavContainerState extends State<KITNavContainer> {
  int _selectedPage = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // bottomSheet: SafeArea(
      //   child: Padding(
      //     padding: EdgeInsets.symmetric(vertical: 10, horizontal: 50),
      //     child: BlockContainer(
      //       child: Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceAround,
      //         children: [
      //           customBottomNavBarButton(1, CupertinoIcons.home)
      //         ],
      //       )
      //     ),
      //   ),
      // ),
      body: KITHomePage(),
    );
  }

  Widget customBottomNavBarButton(int targetIdx, IconData icon, {String title = ""}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 50,
        child: Column(
          children: [
            Icon(icon),
            title == "" ? SizedBox(width: 0, height: 0) : Text(title)
          ],
        ),
      ),
      onPressed: () => setState(() {
        _selectedPage = targetIdx;
      })
    );
  }

}