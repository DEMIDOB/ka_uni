import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/constants.dart';
import 'package:kit_mobile/home/views/home_page.dart';
import 'package:kit_mobile/ilias/views/ilias_page_view.dart';
import 'package:kit_mobile/settings/views/settings_page.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';

import '../../extensions/theme_data_extension.dart';
import '../../module/models/module.dart';

class KITNavContainer extends StatefulWidget {
  const KITNavContainer({super.key});

  @override
  State<StatefulWidget> createState() {
    return _KITNavContainerState();
  }

}

const bottomNavigationBorderRadius = BorderRadius.all(appBorderRadius);

class _KITNavContainerState extends State<KITNavContainer> {
  int _selectedPage = 1;

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<KITProvider>(context);
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    return Scaffold(
      bottomSheet: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
          child: LiquidGlass(
            // glassContainsChild: true,
            shape: LiquidRoundedSuperellipse(borderRadius: bottomNavigationBorderRadius.bottomLeft),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(

                  decoration: BoxDecoration(
                    // color: theme.isLightMode ? navigationLightBackground : Colors.black.withValues(alpha: 0.5),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                    borderRadius: bottomNavigationBorderRadius,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      customBottomNavBarButton(0, CupertinoIcons.settings),
                      customBottomNavBarButton(1, CupertinoIcons.home, title: "Dashboard"),
                      customBottomNavBarButton(2, CupertinoIcons.rectangle_paperclip, title: "ILIAS")
                    ],
                  ),
                ),
              )
          ),
        ),
      ),
      body: Stack(
        children: [
          [
            SettingsPage(),
            KITHomePage(),
            IliasPageView(KITModule(), PHPSESSID: vm.iliasManager.getPHPSESSID()),
          ][_selectedPage],

        ],
      ),
    );
  }

  Widget customBottomNavBarButton(int targetIdx, IconData icon, {String title = ""}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Icon(icon, color: targetIdx == _selectedPage ? null : Colors.grey,),
          // SizedBox(width: 5,),
          // Text(title)
        ],
      ),
      onPressed: () => setState(() {
        _selectedPage = targetIdx;
      })
    );
  }

}