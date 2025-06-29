import 'dart:convert';

import 'package:http/http.dart';
import 'package:kit_mobile/geo/models/kit_place.dart';

class KITTopographyManager {
  static const String dataSrcUrl = "https://www.kit.edu/campusplan/public/scripts/data_de.js";

  List<KITPlace> places = [];

  Future<void> fetchPlaces() async {
    List<KITPlace> newPlaces = [];

    final response = await get(Uri.parse(dataSrcUrl));
    String rawResponseBody = response.body;

    // rawResponseBody contains a JS code defining a variable with
    // its value being the array of dictionaries
    // each describing a place. This array is being extracted...
    final startIdx = rawResponseBody.indexOf("[");
    final endIdx = rawResponseBody.lastIndexOf(";");
    rawResponseBody = rawResponseBody.substring(startIdx, endIdx);

    //... and parsed...
    List<dynamic> placesData = jsonDecode(rawResponseBody);
    for (final placeData in placesData) {
      Map<String, dynamic> placeDataMap = placeData as Map<String, dynamic>;
      newPlaces.add(KITPlace.fromJSON(placeDataMap));
    }

    places = newPlaces;
  }
}