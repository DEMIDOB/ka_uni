import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../state_management/kit_provider.dart';

class LocalFileStorageManager {
  static Future<String> get baseDirPath async {
    final dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/ilias_cache";
  }

  static String sanitizeSemesterString(String semesterString) {
    return semesterString.replaceAll(" ", "_").replaceAll("/", "_");
  }

  Future<String> getDirectoryForSemesterString(String semesterString,
      {ensureExists = false}) async {
    final base = await baseDirPath;
    final path = "$base/$semesterString";

    if (ensureExists) {
      await Directory(path).create(recursive: true);
    }

    return path;
  }

  Future<String> ensureAndGetCurrentSemesterDirectory() async {
    final currentSemester =
        sanitizeSemesterString(KITProvider.currentSemesterString);

    return await getDirectoryForSemesterString(currentSemester,
        ensureExists: true);
  }

  Future<int> getCacheSize() async {
    /// In bytes

    await ensureAndGetCurrentSemesterDirectory();

    final dir = Directory(await baseDirPath);

    int res = 0;

    for (final file in dir.listSync(recursive: true)) {
      if (file is File) {
        res += file.statSync().size;
      }
    }

    return res;
  }

  Future<List<String>> getSemestersWithCachedFiles() async {
    await ensureAndGetCurrentSemesterDirectory();

    final dir = Directory(await baseDirPath);

    final List<String> res = [];
    String? currentRelative;

    await for (final entry in dir.list(recursive: false)) {
      if (await Directory(entry.path).exists()) {
        currentRelative = entry.path.split("/").lastOrNull;
        if (currentRelative != null &&
            (currentRelative.startsWith("WS") ||
                currentRelative.startsWith("SS"))) {
          res.add(currentRelative);
        }
      }
    }

    return res;
  }

  Future<List<String>> getFilesForSemesterString(String semesterString) async {
    final dir = Directory(await getDirectoryForSemesterString(semesterString,
        ensureExists: true));

    final List<String> res = [];

    await for (final entry in dir.list()) {
      if (await File(entry.path).exists()) {
        res.add(entry.path);
      }
    }

    return res;
  }

  Future<FileSystemEntity> removeFile(String filePath) async {
    return await File(filePath).delete();
  }
}
