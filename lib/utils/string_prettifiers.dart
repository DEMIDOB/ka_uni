import 'package:kit_mobile/utils/regexps.dart';

String sanitizeModuleTitle(String title) {
  // this method solves the problem when a hierarchic table's entry
  // like "Lineare Algebra - Prüfung" is used as module.title
  // so we split by "-" and filter out words like ["Prüfung", "Klausur"]
  // IMPORTANT: if you encounter some other

  const filterOutLower = ["prüfung", "klausur"]; // lowercased!

  // the initial split by "-"
  final split = title.split("-");

  split.removeWhere((entry) {
    final entryLower = entry.toLowerCase();
    for (final ignored in filterOutLower) {
      if (entryLower.contains(ignored)) {
        // ignore immediately
        return true;
      }
    }

    return false;
  });

  return split.join("-");
}

String prettifyTemporaryModuleTitle(String title) {
  // TODO: explain why we need this

  final split = title.split("_");
  if (split.isEmpty) {
    return "";
  }

  if (split.first.length <= 1) {
    split.removeWhere((element) => prettifyTemporaryModuleTitleNumberRegex.hasMatch(element));
  }

  return split.join(" ");
}