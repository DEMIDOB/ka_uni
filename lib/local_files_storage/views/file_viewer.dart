import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../state_management/kit_provider.dart';
import '../../toasts/models/toasts_provider.dart';
import '../models/pinned_file.dart';

class PDFScreen extends StatefulWidget {
  // final String? path;
  final PinnedFile iliasFile;
  final bool isIPadSafe;

  String get path => iliasFile.fileSystemPath;

  const PDFScreen(
      {super.key, required this.iliasFile, this.isIPadSafe = false});

  @override
  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> with WidgetsBindingObserver {
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Document"),
        actions: <Widget>[
          IconButton(
            icon: Icon(CupertinoIcons.pin_fill),
            onPressed: () => _handlePinPressed(
                Provider.of<ToastsProvider>(context, listen: false)),
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () async {
              final params = ShareParams(
                // text: widget.iliasFile.customName.isEmpty ? "Datei" : widget.iliasFile.customName,
                files: [XFile(widget.iliasFile.fileSystemPath)],
              );

              final result = await SharePlus.instance.share(params);

              if (result.status == ShareResultStatus.success) {
                if (kDebugMode) {
                  print("Successfully shared ${widget.iliasFile.customName}!");
                }
              }
            },
          ),
          IconButton(
              onPressed: () {
                Provider.of<KITProvider>(context, listen: false)
                    .iliasFileManager
                    .unpinFile(
                        semesterString: KITProvider.currentSemesterString,
                        urlString: widget.iliasFile.urlString);
                File(widget.path).deleteSync();
                Navigator.pop(context);
              },
              icon: Icon(CupertinoIcons.delete))
        ],
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.path,
            // iPad Safe Mode: Avoid conflicting scroll configurations
            enableSwipe: widget.isIPadSafe ? true : true,
            swipeHorizontal: widget.isIPadSafe
                ? false
                : true, // Vertical scrolling is safer on iPad
            autoSpacing:
                widget.isIPadSafe ? true : false, // Let PDFKit handle spacing
            pageFling: widget.isIPadSafe
                ? false
                : true, // Disable page fling to avoid conflicts
            pageSnap: widget.isIPadSafe
                ? false
                : true, // Disable page snap for smoother scrolling
            defaultPage: currentPage!,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation:
                false, // if set to true the link is handled in flutter
            // backgroundColor: Colors.white,
            nightMode: false,
            // nightModeBackgroundColor: Colors.amber,
            onRender: (_pages) {
              setState(() {
                pages = _pages;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
              if (kDebugMode) {
                print(error.toString());
              }
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
              if (kDebugMode) {
                print('$page: ${error.toString()}');
              }
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _controller.complete(pdfViewController);
            },
            onLinkHandler: (String? uri) {
              if (kDebugMode) {
                print('goto uri: $uri');
              }
            },
            onPageChanged: (int? page, int? total) {
              if (kDebugMode) {
                print('page change: ${page ?? 0 + 1}/$total');
              }
              setState(() {
                currentPage = page;
              });
            },
          ),
          errorMessage.isEmpty
              ? !isReady
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Container()
              : Center(
                  child: Text(errorMessage),
                )
        ],
      ),
      // floatingActionButton: FutureBuilder<PDFViewController>(
      //   future: _controller.future,
      //   builder: (context, AsyncSnapshot<PDFViewController> snapshot) {
      //     if (snapshot.hasData) {
      //       return FloatingActionButton.extended(
      //         label: Text("Go to ${pages! ~/ 2}"),
      //         onPressed: () async {
      //           await snapshot.data!.setPage(pages! ~/ 2);
      //         },
      //       );
      //     }
      //
      //     return Container();
      //   },
      // ),
    );
  }

  Future<void> _handlePinPressed(ToastsProvider toastsProvider) async {
    final kitProvider = Provider.of<KITProvider>(context, listen: false);
    final settingsProvider = Provider.of<KITProvider>(context, listen: false);

    final moduleTitles = [
          "Anderes",
        ] +
        _collectRelevantModuleTitles(kitProvider);
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
      await settingsProvider.saveIliasFile(PinnedFile(
          semesterString: KITProvider.currentSemesterString,
          urlString: widget.iliasFile.urlString,
          moduleTitle: selectedTitle,
          addedAt: DateTime.now().toUtc(),
          customName: resolvedCustomName,
          fileSystemPath: widget.path));
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
      final candidate = titleFromModule.isNotEmpty
          ? titleFromModule
          : titleFromRow.isNotEmpty
              ? titleFromRow
              : rowId;

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

extension _SettingsProviderIliasFiles on KITProvider {
  Future<void> saveIliasFile(PinnedFile file) async {
    await iliasFileManager.addPinnedFile(file);
    notifyListeners();
  }
}
