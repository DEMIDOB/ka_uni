import 'package:flutter/material.dart';
import 'package:kit_mobile/module/models/module.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IliasPageView extends StatefulWidget {
  final KITModule module;
  final String PHPSESSID;

  const IliasPageView(this.module, {super.key, required this.PHPSESSID});

  @override
  State<StatefulWidget> createState() {
    return _IliasPageViewWState();
  }

}

class _IliasPageViewWState extends State<IliasPageView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController();

    _launchPage();
  }

  _launchPage() async {
    final cookieManager = WebViewCookieManager();
    await cookieManager.setCookie(
        WebViewCookie(
            name: "PHPSESSID",
            value: widget.PHPSESSID,
            domain: "ilias.studium.kit.edu"
        )
    );


    // final vm = Provider.of<KITProvider>(context);
    _controller.loadRequest(Uri.parse(widget.module.iliasLink!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ILIAS: ${widget.module.title}"),),
      body: WebViewWidget(controller: _controller),
    );
  }

}