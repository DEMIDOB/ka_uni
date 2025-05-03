import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/module/models/module.dart';
import 'package:kit_mobile/state_management/KITProvider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IliasPageView extends StatefulWidget {
  final KITModule module;

  const IliasPageView(this.module, {super.key});

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

    // final vm = Provider.of<KITProvider>(context);
    _controller = WebViewController()
      ..loadRequest(Uri.parse(widget.module.iliasLink!));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ILIAS: ${widget.module.title}"),),
      body: WebViewWidget(controller: _controller),
    );
  }

}