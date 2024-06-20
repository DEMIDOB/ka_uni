import 'package:html/dom.dart';
import 'package:kit_mobile/parsing/util/remove_html_children.dart';

class ModuleInfoTableCell {
  String body = "";
  String link = "";
  final Element node;

  bool _doesToggleFavorite = false;
  bool _isFavorite = false;

  ModuleInfoTableCell({required this.node});

  static ModuleInfoTableCell parseFromHtml(Element node) {
    ModuleInfoTableCell cell = ModuleInfoTableCell(node: node.clone(true));
    
    final links = node.getElementsByTagName("a");

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
    final button = node.getElementsByTagName("button").firstOrNull;
    if (button == null) {
      return;
    }

    final starImage = button.getElementsByTagName("img").firstOrNull;
    if (starImage == null) {
      return;
    }

    final imgSrc = starImage.attributes["src"];
    if (imgSrc == null) {
      return;
    }

    _isFavorite = imgSrc.contains("star.png");
    _doesToggleFavorite = true;
  }
}