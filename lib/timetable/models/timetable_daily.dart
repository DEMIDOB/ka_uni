import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';

import 'package:kit_mobile/timetable/models/timetable_appointment.dart';
import 'package:kit_mobile/timetable/models/timetable_weekly.dart';

class TimetableDaily {
  Weekday weekday = Weekday.monday;
  List<TimetableAppointment> appointments = genericAppointmentsSchedule;

  static List<TimetableAppointment> get genericAppointmentsSchedule {
   final d = DateTime.now();

   return [
     TimetableAppointment(begin: d.copyWith(hour: 8, minute: 0), end: d.copyWith(hour: 9, minute: 30)),
     TimetableAppointment(begin: d.copyWith(hour: 9, minute: 45), end: d.copyWith(hour: 11, minute: 15)),
     TimetableAppointment(begin: d.copyWith(hour: 11, minute: 30), end: d.copyWith(hour: 13, minute: 0)),
     TimetableAppointment(begin: d.copyWith(hour: 13, minute: 0), end: d.copyWith(hour: 14, minute: 0), type: TimetableAppointmentType.lunchBreak),
     TimetableAppointment(begin: d.copyWith(hour: 14, minute: 0), end: d.copyWith(hour: 15, minute: 30)),
     TimetableAppointment(begin: d.copyWith(hour: 15, minute: 45), end: d.copyWith(hour: 17, minute: 15)),
     TimetableAppointment(begin: d.copyWith(hour: 17, minute: 30), end: d.copyWith(hour: 19, minute: 0)),
   ];
  }

  static TimetableDaily? parseFromHtml(Element node, Weekday weekday) {
    TimetableDaily timetableDaily = TimetableDaily();
    timetableDaily.weekday = weekday;
    // print(node.innerHtml);

    node.getElementsByClassName("appointment").forEach((appointmentNode) {
      final appointment = TimetableAppointment.parseFromHtmlTr(appointmentNode);
      if (appointment == null) {
        return;
      }

      int idx = 0;
      for (var existingAppointment in timetableDaily.appointments) {
        if (existingAppointment.isAtTheSameBlockAs(appointment)) {
          break;
        }
        idx++;
      }

      if (idx >= 0 && idx < timetableDaily.appointments.length) {
        timetableDaily.appointments[idx] = appointment;
      }
    });

    // if (kDebugMode) {
    //   print("parsed timetableDaily ${timetableDaily.appointments.length}");
    // }

    return timetableDaily;
  }
}