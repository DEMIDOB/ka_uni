import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/common_ui/kit_progress_indicator.dart';
import 'package:kit_mobile/constants/view_constants.dart';
import 'package:kit_mobile/local_files_storage/files_manager.dart';
import 'package:kit_mobile/local_files_storage/models/pinned_file.dart';
import 'package:kit_mobile/local_files_storage/views/file_viewer.dart';
import 'package:provider/provider.dart';

class CacheCleanerPage extends StatefulWidget {
  const CacheCleanerPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CacheCleanerPageState();
  }
}

class _CacheCleanerPageState extends State<CacheCleanerPage> {
  String expandedSemesterString = "";
  List<String> expandedSemesterStringFiles = [];

  @override
  Widget build(BuildContext context) {
    final filesVM = Provider.of<IliasFilesProvider>(context);
    final theme = Theme.of(context);

    final semestersListFuture =
        filesVM.localFileStorageManager.getSemestersWithCachedFiles();

    return Scaffold(
      appBar: AppBar(
        title: Text("Dateien Cache"),
      ),
      body: FutureBuilder(
          future: semestersListFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final currentSemesterString = snapshot.data![index];
                    final iAmSelected = expandedSemesterString
                            .compareTo(currentSemesterString) ==
                        0;

                    return Padding(
                      padding: EdgeInsets.all(defaultPagePadding),
                      child: BlockContainer(
                          child: Column(
                        children: [
                          GestureDetector(
                            child: Row(
                              children: [
                                Text(
                                  currentSemesterString,
                                  style: theme.textTheme.titleMedium,
                                ),
                                Spacer(),
                                AnimatedRotation(
                                  turns: iAmSelected ? 0 : -0.25,
                                  duration: Duration(milliseconds: 500),
                                  child: CupertinoButton(
                                    child: Icon(CupertinoIcons.chevron_down),
                                    onPressed: () => _expandSemester(
                                        currentSemesterString, filesVM),
                                    padding: EdgeInsets.zero,
                                  ),
                                )
                              ],
                            ),
                            onTap: () =>
                                _expandSemester(currentSemesterString, filesVM),
                          ),
                          !iAmSelected
                              ? SizedBox.shrink()
                              : Column(
                                  children: <Widget>[
                                        Padding(padding: EdgeInsets.all(5)),
                                        Divider(),
                                      ] +
                                      expandedSemesterStringFiles
                                          .map<Widget>((semFile) {
                                        final fileDisplayName =
                                            semFile.substring(semFile.indexOf(
                                                expandedSemesterString));
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _sanitizeFileDisplayName(
                                                    fileDisplayName),
                                                softWrap: true,
                                                maxLines: 3,
                                              ),
                                            ),
                                            Spacer(),
                                            FutureBuilder(
                                                future: File(semFile).stat(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData &&
                                                      snapshot.data != null) {
                                                    return Text(
                                                        "${(snapshot.data!.size / 1024 / 1024).toStringAsFixed(1)} MB");
                                                  }

                                                  return KITProgressIndicator();
                                                }),
                                            // Spacer(),
                                            CupertinoButton(
                                                child: Icon(
                                                    CupertinoIcons.eye_fill),
                                                onPressed: () {
                                                  Navigator.of(context).push(MaterialPageRoute(
                                                      builder: (BuildContext
                                                              context) =>
                                                          PDFScreen(
                                                              iliasFile: PinnedFile(
                                                                  semesterString:
                                                                      currentSemesterString,
                                                                  urlString: "",
                                                                  moduleTitle:
                                                                      "",
                                                                  addedAt:
                                                                      DateTime
                                                                          .now(),
                                                                  customName:
                                                                      fileDisplayName,
                                                                  fileSystemPath:
                                                                      semFile))));
                                                }),
                                            CupertinoButton(
                                              onPressed: () async {
                                                await filesVM
                                                    .localFileStorageManager
                                                    .removeFile(semFile);
                                                final newSemFiles = await filesVM
                                                    .localFileStorageManager
                                                    .getFilesForSemesterString(
                                                        currentSemesterString);

                                                setState(() {
                                                  expandedSemesterStringFiles =
                                                      newSemFiles;
                                                });
                                              },
                                              padding: EdgeInsets.zero,
                                              child: Icon(
                                                CupertinoIcons.delete,
                                                color: Colors.red,
                                              ),
                                            )
                                          ],
                                        );
                                      }).toList() +
                                      [
                                        CupertinoButton(
                                          onPressed: () async {
                                            for (final file
                                                in expandedSemesterStringFiles) {
                                              await filesVM
                                                  .localFileStorageManager
                                                  .removeFile(file);
                                            }
                                            setState(() {
                                              expandedSemesterStringFiles = [];
                                              expandedSemesterString = "";
                                            });
                                          },
                                          foregroundColor: Colors.red,
                                          child: Text("Alle Löschen"),
                                        )
                                      ],
                                )
                        ],
                      )),
                    );
                  });
            }

            return Center(
              child: KITProgressIndicator(),
            );
          }),
    );
  }

  String _sanitizeFileDisplayName(String fileDisplayName) {
    fileDisplayName =
        fileDisplayName.substring(fileDisplayName.indexOf("/") + 1);

    return fileDisplayName;
  }

  void _expandSemester(
      String currentSemesterString, IliasFilesProvider filesVM) {
    setState(() {
      if (expandedSemesterString == currentSemesterString) {
        // deselect
        expandedSemesterString = "";
        return;
      }
      expandedSemesterString = currentSemesterString;
    });

    filesVM.localFileStorageManager
        .getFilesForSemesterString(currentSemesterString)
        .then((filesList) {
      setState(() {
        expandedSemesterStringFiles = filesList;
      });
    });
  }
}
