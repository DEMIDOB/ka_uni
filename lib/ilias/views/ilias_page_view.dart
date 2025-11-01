import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/common_ui/kit_progress_indicator.dart';
import 'package:kit_mobile/constants.dart';
import 'package:kit_mobile/module/models/module.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:kit_mobile/toasts/models/toasts_provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../settings/providers/settings_provider.dart';
import '../files/ilias_file_manager.dart';

class IliasPageView extends StatefulWidget {
  final KITModule module;
  final Future<String> PHPSESSID;
  final bool isFileView;

  const IliasPageView(this.module, {super.key, required this.PHPSESSID, this.isFileView=false});

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

    // if (widget.isFileView) {
    //   appBarHeight = AppBar().preferredSize.height * 1.5;
    // }

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
          appBar: widget.isFileView ? AppBar(
            title: Text(widget.module.title.isEmpty ? "Datei" : "${widget.isFileView ? 'Datei: ' : ''}${widget.module.title}"),
            actions: widget.isFileView ? [] : [
              CupertinoButton(child: Icon(CupertinoIcons.floppy_disk), onPressed: () async {
                // toastsProvider.showTextToast("message");
                if (kDebugMode) {
                  print(await _controller.currentUrl());
                }
              })
            ],
          ) : null,
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

                          widget.isFileView ? SizedBox.shrink() : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // LiquidGlass(
                              //   shape: LiquidRoundedRectangle(borderRadius: appBorderRadius),
                              //   settings: LiquidGlassSettings(blur: 5, glassColor: Color.fromARGB(10, 255, 255, 255)),
                              //   child: ClipRRect(
                              //       borderRadius: BorderRadius.circular(100),
                              //       child: CupertinoButton(
                              //         child: Icon(CupertinoIcons.floppy_disk, color: Colors.white,),
                              //         onPressed: () => _handleSavePressed(toastsProvider),
                              //       )
                              //   ),
                              // ),

                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                widget.isFileView ? SizedBox.shrink() :Container(
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
                        child: Icon(CupertinoIcons.floppy_disk,),
                        onPressed: () => _handleSavePressed(toastsProvider),
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

  Future<void> _handleSavePressed(ToastsProvider toastsProvider) async {
    final url = await _controller.currentUrl();

    if (url == null || !url.contains("sendfile")) {
      toastsProvider.showTextToast("Die App kann nur Dateien speichern");
      return;
    }

    final kitProvider = Provider.of<KITProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    final moduleTitles = _collectRelevantModuleTitles(kitProvider);
    if (moduleTitles.isEmpty) {
      toastsProvider.showTextToast("Keine Module verfügbar");
      return;
    }

    final selectedTitle = await _chooseModuleTitle(moduleTitles);
    if (!mounted || selectedTitle == null || selectedTitle.isEmpty) {
      return;
    }

    final customName = await _promptForCustomName(selectedTitle);
    if (!mounted || customName == null) {
      return;
    }

    final resolvedCustomName =
        customName.trim().isEmpty ? selectedTitle : customName.trim();

    try {
      await settingsProvider.saveIliasFile(IliasFile(
        semesterString: KITProvider.currentSemesterString,
        urlString: url,
        moduleTitle: selectedTitle,
        addedAt: DateTime.now().toUtc(),
        customName: resolvedCustomName,
      ));
      toastsProvider.showTextToast("Datei gespeichert");
    } catch (error) {
      if (!mounted) {
        return;
      }
      toastsProvider.showTextToast("Speichern fehlgeschlagen");
      if (kDebugMode) {
        print("Failed to save ILIAS file: $error");
      }
    }
  }

  List<String> _collectRelevantModuleTitles(KITProvider vm) {
    final titles = <String>[];
    final seen = <String>{};

    for (final rowId in vm.campusManager.relevantModuleRowIDs) {
      final module = vm.campusManager.rowModules[rowId];
      if (module == null) {
        continue;
      }

      final titleFromModule = module.title.trim();
      final titleFromRow = (module.row?.title ?? "").trim();
      final candidate = titleFromModule.isNotEmpty ? titleFromModule : titleFromRow.isNotEmpty ? titleFromRow : rowId;

      final normalized = candidate.trim();
      if (normalized.isEmpty || seen.contains(normalized)) {
        continue;
      }

      seen.add(normalized);
      titles.add(normalized);
    }

    return titles;
  }

  Future<String?> _chooseModuleTitle(List<String> moduleTitles) {
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (popupContext) {
        return CupertinoActionSheet(
          title: const Text("Modul auswählen"),
          message: const Text("Bitte wähle das Modul für die Datei aus."),
          actions: moduleTitles
              .map(
                (title) => CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(popupContext).pop(title),
                  child: Text(title),
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(popupContext).pop(),
            child: const Text("Abbrechen"),
          ),
        );
      },
    );
  }

  Future<String?> _promptForCustomName(String initialName) {
    final controller = TextEditingController(text: initialName);

    return showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text("Datei benennen"),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: controller,
              autofocus: true,
              placeholder: "Name der Datei",
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Abbrechen"),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text("Speichern"),
            ),
          ],
        );
      },
    );
  }

}

extension _SettingsProviderIliasFiles on SettingsProvider {
  static final IliasFileManager _iliasFileManager = IliasFileManager();

  Future<void> saveIliasFile(IliasFile file) async {
    await _iliasFileManager.addFile(file);
    notifyListeners();
  }
}
