import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/common_ui/kit_progress_indicator.dart';
import 'package:kit_mobile/module/models/module.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
      _phpsessid = value;
      _launchPage();
    });
  }

  _launchPage() async {
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
      link = "https://ilias.studium.kit.edu/ilias.php?baseClass=ilmembershipoverviewgui";
    }
    _controller.loadRequest(Uri.parse(link));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final appBarHeight = AppBar().preferredSize.height;

    return FutureBuilder(future: widget.PHPSESSID, builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Center(
          child: Scaffold(
            appBar: AppBar(title: Text("ILIAS"),),
            body: KITProgressIndicator(),
          ),
        );
      }

      return Scaffold(
          appBar: AppBar(title: Text(widget.module.title.isEmpty ? "ILIAS" : "ILIAS: ${widget.module.title}"),),
          bottomSheet: null,
          body: Column(
            children: [
              SizedBox(
                width: mq.size.width,
                height: mq.size.height - (Platform.isAndroid ? 100 : 150) - appBarHeight,
                child: WebViewWidget(controller: _controller),
              ),
              BlockContainer(
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
          )
      );
    });
  }

}