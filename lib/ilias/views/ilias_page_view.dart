import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/common_ui/kit_progress_indicator.dart';
import 'package:kit_mobile/constants.dart';
import 'package:kit_mobile/module/models/module.dart';
import 'package:kit_mobile/toasts/models/toasts_provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../settings/providers/settings_provider.dart';

class IliasPageView extends StatefulWidget {
  final KITModule module;
  final Future<String> PHPSESSID;

  const IliasPageView(this.module, {super.key, required this.PHPSESSID});

  @override
  State<StatefulWidget> createState() {
    return _IliasPageViewWState();
  }

}

class _IliasPageViewWState extends State<IliasPageView> {
  late final WebViewController _controller;
  String _phpsessid = "";

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    widget.PHPSESSID.then((value) {
      final settingsVM = Provider.of<SettingsProvider>(context, listen: false);
      _phpsessid = value;
      _launchPage(settingsVM.defaultIliasPage.value);
    });
  }

  _launchPage(String defaultPage) async {

    final cookieManager = WebViewCookieManager();
    await cookieManager.setCookie(
        WebViewCookie(
            name: "PHPSESSID",
            value: _phpsessid,
            domain: "ilias.studium.kit.edu"
        )
    );


    // final vm = Provider.of<KITProvider>(context);
    String link = widget.module.iliasLink ?? "";
    if (link.isEmpty) {
      link = defaultPage == "Dashboard" ?
        "https://ilias.studium.kit.edu/ilias.php?baseClass=ildashboardgui&cmd=show"
      : "https://ilias.studium.kit.edu/ilias.php?baseClass=ilmembershipoverviewgui";
    }
    _controller.loadRequest(Uri.parse(link));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final toastsProvider = Provider.of<ToastsProvider>(context);

    // final appBarHeight = AppBar().preferredSize.height * 1.5;
    final appBarHeight = AppBar().preferredSize.height * 1 - 25;

    return FutureBuilder(future: widget.PHPSESSID, builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Scaffold(
          appBar: AppBar(title: Text("ILIAS"),),
          body: Center(
            child: KITProgressIndicator(),
          )
        );
      }

      return Scaffold(
          // appBar: AppBar(
          //   title: Text(widget.module.title.isEmpty ? "ILIAS" : "ILIAS: ${widget.module.title}"),
          //   actions: [
          //     CupertinoButton(child: Icon(CupertinoIcons.floppy_disk), onPressed: () async {
          //       // toastsProvider.showTextToast("message");
          //       if (kDebugMode) {
          //         print(await _controller.currentUrl());
          //       }
          //     })
          //   ],
          // ),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  width: mq.size.width,
                  height: mq.size.height - (Platform.isAndroid ? 100 : 150) - appBarHeight,
                  child: BlockContainer(
                    // padding: EdgeInsets.all(15),
                    innerPadding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(appBorderRadius.x),
                      child: Stack(
                        children: [
                          WebViewWidget(controller: _controller),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              LiquidGlass(
                                shape: LiquidOval(side: BorderSide()),
                                child: CupertinoButton(
                                  child: Icon(CupertinoIcons.floppy_disk),
                                  onPressed: () {

                                  },
                                ),
                                settings: LiquidGlassSettings(blur: 5, glassColor: Color.fromARGB(50, 255, 255, 255)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(CupertinoIcons.back),
                        onPressed: () async {
                          if (await _controller.canGoBack()) {
                            _controller.goBack();
                          }
                        },
                      ),

                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(CupertinoIcons.forward),
                        onPressed: () async {
                          if (await _controller.canGoForward()) {
                            _controller.goForward();
                          }
                        },
                      )

                    ],
                  ),
                )
              ],
            ),
          )
      );
    });
  }

}