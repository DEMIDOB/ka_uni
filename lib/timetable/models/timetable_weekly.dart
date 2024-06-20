import 'package:html/parser.dart';
import 'package:kit_mobile/timetable/models/timetable_daily.dart';

enum Weekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday
}

extension WeekdayExtension on Weekday {
  bool get isWorkingDay => idx < 5;

  int get idx => [
    Weekday.monday,
    Weekday.tuesday,
    Weekday.wednesday,
    Weekday.thursday,
    Weekday.friday,
    Weekday.saturday,
    Weekday.sunday
  ].indexOf(this);
  //
  // static Weekday workingFromInt(int src) {
  //   src = src % 7;
  //   if (src >= 5) {
  //     src = 0;
  //   }
  //
  //   return workingWeekdays[src];
  // }

  Weekday fromInt(int src) {
    return [
      Weekday.monday,
      Weekday.tuesday,
      Weekday.wednesday,
      Weekday.thursday,
      Weekday.friday,
      Weekday.saturday,
      Weekday.sunday
    ][src % 7];
  }
}

const List<Weekday> workingWeekdays = [
  Weekday.monday,
  Weekday.tuesday,
  Weekday.wednesday,
  Weekday.thursday,
  Weekday.friday,
];

class TimetableWeekly {
  List<TimetableDaily> days = [];

  TimetableWeekly({List<TimetableDaily>? days}) {
    this.days = days ?? [
      TimetableDaily(),
      TimetableDaily(),
      TimetableDaily(),
      TimetableDaily(),
      TimetableDaily(),
    ];
  }

  static TimetableWeekly? parseFromHtmlString(String src) {
    final document = parse(src);
    final daysContainer = document.getElementsByClassName("cal-row-lecture").firstOrNull;

    if (daysContainer == null) {
      return null;
    }

    final days = daysContainer.getElementsByTagName("td");
    if (days.length < 6) {
      return null;
    }

    TimetableWeekly timetableWeekly = TimetableWeekly();

    days.removeAt(0);
    int weekdayIdx = 0;
    for (var dayNode in days) {
      final timetableDaily = TimetableDaily.parseFromHtml(dayNode, workingWeekdays[weekdayIdx]);
      if (timetableDaily == null) {
        return null;
      }

      timetableWeekly.days[weekdayIdx] = timetableDaily;

      weekdayIdx++;
    }

    return timetableWeekly;
  }
}