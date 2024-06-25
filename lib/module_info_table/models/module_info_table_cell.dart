import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:kit_mobile/parsing/util/remove_html_children.dart';
import 'package:requests_plus/requests_plus.dart';

class ModuleInfoTableCell {
  String body = "";
  String link = "";
  final Element? node;

  String dateStr = "";
  String timeStr = "";

  bool doesToggleFavorite = false;
  bool isFavorite = false;
  String objectValue = "";

  ModuleInfoTableCell({this.node});

  static ModuleInfoTableCell parseFromHtml(Element node) {
    ModuleInfoTableCell cell = ModuleInfoTableCell(node: node.clone(true));
    
    final spans = node.getElementsByTagName("span");
    final links = node.getElementsByTagName("a");
    final buttons = node.getElementsByTagName("button");
    
    for (final spanElement in spans) {
      if (spanElement.classes.contains("date")) {
        removeHtmlChildren(spanElement);
        cell.dateStr = spanElement.innerHtml.trim();
      } else if (spanElement.classes.contains("time")) {
        removeHtmlChildren(spanElement);
        cell.timeStr = spanElement.innerHtml.trim();
      }
    }

    for (final buttonNode in buttons) {
      if (buttonNode.attributes.containsKey("name") && buttonNode.attributes["name"]!.toLowerCase().contains("eventfavorite")) {
        cell.markMeAsAddToFavorites();
      }
    }

    // if (cell.dateStr.isNotEmpty) {
    //   if (kDebugMode) {
    //     print(cell.dateStr);
    //     print(cell.timeStr);
    //   }
    // }

    if (links.isEmpty) {
      removeHtmlChildren(node);
      cell.body = node.innerHtml;
      return cell;
    } else {
      final link = links.first;
      cell.link = link.attributes["href"] ?? "";
      removeHtmlChildren(link);
      cell.body = link.innerHtml;
    }

    removeHtmlChildren(node);
    cell.body += " ${node.innerHtml}";
    return cell;
  }

  markMeAsAddToFavorites() {
    if (node == null) {
      return;
    }

    final button = node!.getElementsByTagName("button").firstOrNull;
    if (button == null) {
      return;
    }

    final buttonName = button.attributes["name"];
    if (buttonName == null) {
      return;
    }

    final buttonValue = button.attributes["value"];
    if (buttonValue == null) {
      return;
    }

    isFavorite = buttonName.contains("remove");
    doesToggleFavorite = true;
    objectValue = buttonValue;
  }

  bool get isAppointment {
    return dateStr.isNotEmpty && timeStr.isNotEmpty;
  }

  static ModuleInfoTableCell get empty {
    return ModuleInfoTableCell();
  }

}