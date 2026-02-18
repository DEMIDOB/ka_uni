import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/common_ui/kit_progress_indicator.dart';
import 'package:kit_mobile/constants/view_constants.dart';
import 'package:kit_mobile/module/models/module.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:kit_mobile/toasts/models/toasts_provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../local_files_storage/files_manager.dart';
import '../../local_files_storage/models/pinned_file.dart';
import '../../local_files_storage/views/file_viewer.dart';
import '../../settings/providers/settings_provider.dart';

class IliasPageView extends StatefulWidget {
  final KITModule module;
  final Future<String> PHPSESSID;
  final bool isFileView;

  const IliasPageView(this.module,
      {super.key, required this.PHPSESSID, this.isFileView = false});

  @override
  State<StatefulWidget> createState() {
    return _IliasPageViewWState();
  }
}

class _IliasPageViewWState extends State<IliasPageView> {
  late final WebViewController _controller;
  String _phpsessid = "";

  bool isBusy = false;

  int pagesStackSize = 0;
  Future<bool?> canGoBackFuture = Future.value(false),
      canGoForwardFuture = Future.value(false);

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    _controller.setNavigationDelegate(NavigationDelegate(
        onUrlChange: _navigationDelegateOnUrlChange,
        onNavigationRequest: (NavigationRequest req) {
          if (req.url.contains("sendfile")) {
            _saveAsFile(req.url);
            return NavigationDecision.prevent;
          }

          return NavigationDecision.navigate;
        }));

    widget.PHPSESSID.then((value) {
      final settingsVM = Provider.of<SettingsProvider>(context, listen: false);
      _phpsessid = value;

      if (widget.isFileView && widget.module.iliasLink != null) {
        _saveAsFile(widget.module.iliasLink!);
      } else {
        _launchPage(settingsVM.defaultIliasPage.value);
      }
    });
  }

  _navigationDelegateOnUrlChange(UrlChange urlChange) {
    pagesStackSize++;
    setState(() {
      canGoBackFuture = _controller.canGoBack();
      canGoForwardFuture = _controller.canGoForward();
    });

    if (kDebugMode) {
      print("Changed: ${urlChange.url}");
    }
  }

  Future<String?> _saveAsFile(String url) async {
    final vm = Provider.of<KITProvider>(context, listen: false);
    final iliasFileManager =
        Provider.of<IliasFilesProvider>(context, listen: false);
    final toastsProvider = Provider.of<ToastsProvider>(context, listen: false);

    final refId = Uri.parse(url).queryParameters["ref_id"];

    if (refId != null) {
      final directory = await iliasFileManager.localFileStorageManager
          .ensureAndGetCurrentSemesterDirectory();

      final filepath = "$directory/${widget.module.title}$refId.pdf";

      File file = File(filepath);

      if (!await file.exists()) {
        setState(() {
          isBusy = true;
        });

        toastsProvider.showTextToast("Wird heruntergeladen...");

        final iliasFile = await vm.iliasManager.downloadFile(url, file);

        setState(() {
          isBusy = false;
        });

        _launchFileView(iliasFile);
      } else {
        PinnedFile? iliasFile;

        var existingFiles =
            await vm.iliasFileManager.getFilesForCurrentSemester();
        for (var element in existingFiles) {
          if (element.urlString == url) {
            iliasFile = element;
            break;
          }
        }

        _launchFileView(iliasFile ??
            PinnedFile(
                semesterString: KITProvider.currentSemesterString,
                urlString: url,
                moduleTitle: "",
                addedAt: DateTime.now().toUtc(),
                customName: "",
                fileSystemPath: filepath));
      }

      return filepath;
    }

    // TODO: callback!

    return null;
  }

  _launchFileView(PinnedFile iliasFile) {
    if (iliasFile.fileSystemPath.isEmpty) {
      if (kDebugMode) {
        print("Failed to download file!");
      }
    }

    final filepath = iliasFile.fileSystemPath;

    if (kDebugMode) {
      print("Launching file view for $filepath");
    }

    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PDFScreen(
              iliasFile: iliasFile,
            )));
  }

  _launchPage(String defaultPage) async {
    final cookieManager = WebViewCookieManager();
    await cookieManager.setCookie(WebViewCookie(
        name: "PHPSESSID", value: _phpsessid, domain: "ilias.studium.kit.edu"));

    // final vm = Provider.of<KITProvider>(context);
    String link = widget.module.iliasLink ?? "";
    if (link.isEmpty) {
      link = defaultPage == "Dashboard"
          ? "https://ilias.studium.kit.edu/ilias.php?baseClass=ildashboardgui&cmd=show"
          : "https://ilias.studium.kit.edu/ilias.php?baseClass=ilmembershipoverviewgui";
    }
    _controller.loadRequest(Uri.parse(link));
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<KITProvider>(context);
    final mq = MediaQuery.of(context);
    final toastsProvider = Provider.of<ToastsProvider>(context);

    // final appBarHeight = AppBar().preferredSize.height * 1.5;
    final appBarHeight = AppBar().preferredSize.height * 1 + 2;

    // if (widget.isFileView) {
    //   appBarHeight = AppBar().preferredSize.height * 1.5;
    // }

    return FutureBuilder(
        future: widget.PHPSESSID,
        builder: (context, snapshot) {
          if (!snapshot.hasData || _phpsessid.isEmpty) {
            return Scaffold(
                appBar: AppBar(
                  title: Text("ILIAS"),
                ),
                body: Center(
                  child: KITProgressIndicator(),
                ));
          }

          return Scaffold(
              appBar: Navigator.of(context).canPop()
                  ? AppBar(
                      title: Text("ILIAS"),
                      actions: [
                        MaterialButton(
                            child: Icon(CupertinoIcons.refresh),
                            onPressed: () async {
                              setState(() {
                                _phpsessid = "";
                              });

                              await vm.iliasManager
                                  .authorize(refreshSession: true);
                              final newPHPSESSIONID =
                                  await vm.iliasManager.getPHPSESSID();

                              if (newPHPSESSIONID.isEmpty) {
                                toastsProvider.showTextToast(
                                    "Fehler beim Aktualisieren!");
                              }

                              setState(() {
                                _phpsessid = newPHPSESSIONID;
                              });
                            })
                      ],
                    )
                  : null,
              body: SafeArea(
                child: Column(
                  children: [
                    SizedBox(
                      width: mq.size.width,
                      height: mq.size.height -
                          (Platform.isAndroid ? 100 : 150) -
                          appBarHeight,
                      child: BlockContainer(
                        // padding: EdgeInsets.all(15),
                        innerPadding: EdgeInsets.zero,
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(appBorderRadius.x),
                          child: Stack(
                            children: [
                              WebViewWidget(controller: _controller),
                              isBusy
                                  ? Center(
                                      child: GlassContainer(
                                      useOwnLayer: true,
                                      child: Padding(
                                        padding: EdgeInsets.all(10),
                                        child: KITProgressIndicator(),
                                      ),
                                    ))
                                  : SizedBox.shrink()
                            ],
                          ),
                        ),
                      ),
                    ),
                    widget.isFileView
                        ? SizedBox.shrink()
                        : Container(
                            padding: EdgeInsets.all(5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                FutureBuilder(
                                    future: canGoBackFuture,
                                    builder: (context, snapshot) {
                                      return CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed:
                                            (snapshot.hasData && snapshot.data!)
                                                ? () async {
                                                    // if (await _controller.canGoBack()) { the condition is always true
                                                    _controller.goBack();
                                                    // }
                                                  }
                                                : null,
                                        child: Icon(CupertinoIcons.back),
                                      );
                                    }),
                                FutureBuilder(
                                    future: canGoForwardFuture,
                                    builder: (context, snapshot) {
                                      return CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed:
                                            (snapshot.hasData && snapshot.data!)
                                                ? () async {
                                                    // if (await _controller.canGoForward()) { the condition is always true
                                                    _controller.goForward();
                                                    // }
                                                  }
                                                : null,
                                        child: Icon(CupertinoIcons.forward),
                                      );
                                    }),
                              ],
                            ),
                          )
                  ],
                ),
              ));
        });
  }
}
