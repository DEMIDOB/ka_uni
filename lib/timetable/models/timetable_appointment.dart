import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:kit_mobile/geo/kit_place.dart';
import 'package:kit_mobile/parsing/util/remove_html_children.dart';
import 'package:requests_plus/requests_plus.dart';

enum TimetableAppointmentType {
  lecture,
  practice,
  lunchBreak,
  other,
  empty
}

class TimetableAppointment {
  String title = "—";
  String id = "";
  KITPlace place = KITPlace.empty;
  DateTime begin = DateTime.now();
  DateTime end = DateTime.now();
  TimetableAppointmentType type = TimetableAppointmentType.empty;

  TimetableAppointment({DateTime? begin, DateTime? end, this.type = TimetableAppointmentType.empty}) {
    if (begin != null) {
      this.begin = begin;
    }

    if (end != null) {
      this.end = end;
    }

    if (type == TimetableAppointmentType.lunchBreak && (title == "—" || title.isEmpty)) {
      title = "MITTAGSPAUSE";
    }
  }

  bool isAtTheSameBlockAs(TimetableAppointment other) {
    return begin.hour == other.begin.hour && begin.minute == other.begin.minute;
  }

  int get duration => end.difference(begin).inMinutes;

  Future<String> get placeData async {
    if (place.link.isEmpty) {
      return "Keine Infos";
    }

    return (await RequestsPlus.get("https://www.kit.edu/campusplan/?id=20.30")).body;

    final response = await RequestsPlus.get(place.link);
    var document = parse(response.body);
    final targetDiv = document.getElementById("rwro_map-field");
    if (targetDiv == null) {
      return "Keine Infos mehr :(";
    }
    
    final links = targetDiv.getElementsByTagName("a");
    if (links.length <2) {
      return "Keine Infos mehr :(";
    }

    String? href = links[1].attributes["href"];
    if (href == null) {
      return "Keine Infos mehr :(";
    }

    final openMapUri = Uri.parse(href);
    final lon = openMapUri.queryParameters["mlon"];
    final lat = openMapUri.queryParameters["mlat"];
    final zoom = openMapUri.queryParameters["zoom"];

    print(zoom);

    final url = "https://image.maps.ls.hereapi.com/mia/1.6/mapview";
    Map<String, String> queryParameters = {};

    queryParameters["apiKey"] = "ITm1qjHWvH1hAZERtqVnB_hF21VhsJieEn7DNSLXOf8";
    queryParameters["c"] = "$lat,$lon";
    queryParameters["t"] = "2";
    queryParameters["w"] = "300";
    queryParameters["h"] = "400";
    queryParameters["z"] = zoom ?? "7";

    final mapResponse = await RequestsPlus.get(url);

    return mapResponse.body;
  }

  static TimetableAppointment? parseFromHtmlTr(Element appointmentNode) {

    // –

    final links = appointmentNode.getElementsByTagName("a");
    if (links.length < 2) {
      print("failed :( 1");
      return null;
    }

    final titleNode = links[0];
    final placeNode = links[1];

    final appointment = TimetableAppointment();

    final place = nodeToPlace(placeNode);
    if (place == null) {
      if (kDebugMode) {
        print("Place is null: $placeNode");
      }
      return null;
    }

    appointment.place = place;
    appointment.title = nodeToTitleString(titleNode);
    final titleParts = appointment.title.split("–");
    if (titleParts.length == 2) {
      appointment.id = titleParts[0].trim();
      appointment.title = titleParts[1].trim();
    }

    final intervalStr = appointmentNode.attributes["app-interval"] ?? "00:00 00:00";
    final intervalStrSplit = intervalStr.split(" ");
    if (intervalStrSplit.length < 2) {
      if (kDebugMode) {
        print("Failed to parse the appointment! intervalStrSplit is $intervalStrSplit");
      }
      return null;
    }

    final beginStringSplit = intervalStrSplit[0].split(":");
    final endStringSplit = intervalStrSplit[1].split(":");

    if (beginStringSplit.length != 2 || endStringSplit.length != 2) {
      if (kDebugMode) {
        print("Failed to parse the appointment! $beginStringSplit or $endStringSplit");
      }
      return null;
    }

    appointment.begin = appointment.begin.copyWith(hour: int.tryParse(beginStringSplit[0]), minute: int.parse(beginStringSplit[1]));
    appointment.end = appointment.end.copyWith(hour: int.tryParse(endStringSplit[0]), minute: int.parse(endStringSplit[1]));



    return appointment;
  }

  static String nodeToTitleString(Element node) {
    removeHtmlChildren(node);
    return node.innerHtml;
  }

  static KITPlace? nodeToPlace(Element node) {
    removeHtmlChildren(node);
    String href = node.attributes["href"] ?? "";
    if (href.isEmpty) {
      return null;
    }

    while (href.startsWith("../")) {
      href = href.substring(3);
    }

    final place = KITPlace();
    place.title = node.innerHtml;
    place.link = "https://campus.kit.edu/sp/campus/$href";

    return place;
  }
}