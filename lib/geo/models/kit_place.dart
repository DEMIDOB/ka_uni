import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class KITPlace {
  // MARK: - data provided by KIT in https://www.kit.edu/campusplan/public/scripts/data_de.js
  String id = "";
  String title = "";
  String category = "";
  List<String> aliasList = [];
  List<List<String>> positionList = [];
  String url = ""; // url to the website of the corresponding institution

  // MARK: - Data parsed in some special case
  String dataUrl = "";
  // dataUrl is the url to the page of the KITPlace
  // (if KITPlace was found parsing a module info table)


  LatLng? get latLngFromList {
    if (positionList.isEmpty || positionList[0].length != 2) {
      return null;
    }
    
    try {
      final lat = double.parse(positionList[0][0]);
      final lon = double.parse(positionList[0][1]);
      
      return LatLng(lat, lon);
    } catch (exc) {
      if (kDebugMode) {
        print("Failed to parse positionList: $exc");
      }
      return null;
    }
  }

  KITPlace({
    this.id = "",
    this.title = "",
    this.category = "",
    this.aliasList = const [],
    this.positionList = const [],
    this.url = "",
  });

  static KITPlace get empty => KITPlace();

  factory KITPlace.fromJSON(Map<String, dynamic> json) {
    return KITPlace(
      id: "${json["id"]}",
      title: json["title"] ?? "",
      category: json["category"] ?? "",
      aliasList: (json["aliasList"] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      positionList: (json["positionList"] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((coord) => coord.toString()).toList())
          .toList(),
      url: json["url"]?.toString() ?? "",
    );
  }
}