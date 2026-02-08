import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/constants/view_constants.dart';
import 'package:kit_mobile/extensions/theme_data_extension.dart';
import 'package:kit_mobile/home/views/home_page.dart';
import 'package:kit_mobile/ilias/views/ilias_page_view.dart';
import 'package:kit_mobile/settings/views/settings_page.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../../constants/glass_settings.dart';
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
      bottomSheet: AdaptiveLiquidGlassLayer(
        settings: RecommendedGlassSettings.bottomBar,
        quality: GlassQuality.premium,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
            child: GlassContainer(
              useOwnLayer: true,
              // glassContainsChild: true,
              // shape: LiquidRoundedSuperellipse(
              //     borderRadius: appBorderRadiusDouble),
              settings: LiquidGlassSettings(
                blur: 3,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.isLightMode
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.black.withValues(alpha: 0.5),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.15),
                  ),
                  borderRadius: bottomNavigationBorderRadius,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    customBottomNavBarButton(0, CupertinoIcons.settings),
                    customBottomNavBarButton(1, CupertinoIcons.home,
                        title: "Dashboard"),
                    customBottomNavBarButton(
                        2, CupertinoIcons.rectangle_paperclip,
                        title: "ILIAS")
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      // bottomSheet: GlassTabBar(
      //   useOwnLayer: true,
      //   tabs: [
      //     GlassTab(icon: CupertinoIcons.settings),
      //     GlassTab(icon: CupertinoIcons.home),
      //     GlassTab(icon: CupertinoIcons.rectangle_paperclip)
      //   ],
      //   selectedIndex: _selectedPage,
      //   onTabSelected: (int value) {
      //     setState(() {
      //       _selectedPage = value;
      //     });
      //   },
      // ),
      body: Stack(
        children: [
          [
            SettingsPage(),
            KITHomePage(),
            IliasPageView(KITModule(),
                PHPSESSID: vm.iliasManager.getPHPSESSID()),
          ][_selectedPage],
        ],
      ),
    );
  }

  Widget customBottomNavBarButton(int targetIdx, IconData icon,
      {String title = ""}) {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Icon(
              icon,
              color: targetIdx == _selectedPage ? null : Colors.grey,
            ),
            // SizedBox(width: 5,),
            // Text(title)
          ],
        ),
        onPressed: () => setState(() {
              _selectedPage = targetIdx;
            }));
  }
}
