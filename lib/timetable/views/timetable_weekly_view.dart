import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/timetable/models/timetable_daily.dart';
import 'package:kit_mobile/timetable/models/timetable_weekly.dart';
import 'package:kit_mobile/timetable/views/timetable_daily_view.dart';
import 'package:provider/provider.dart';

import '../../state_management/KITProvider.dart';

class TimetableWeeklyView extends StatefulWidget {
  const TimetableWeeklyView({super.key});

  @override
  State<StatefulWidget> createState() {
    return _TimetableWeeklyViewState();
  }

}

class _TimetableWeeklyViewState extends State<TimetableWeeklyView> {
  Weekday _initialWeekday = Weekday.monday;

  _TimetableWeeklyViewState({Weekday? initialWeekday}) {
    _initialWeekday = initialWeekday ?? _initialWeekday.fromInt(DateTime.now().weekday - 1);
  }

  final _weekdayHeight = 90 * 7 * 0.7 + 200;

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    // final emptyDay = TimetableDaily();

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(left: mq.size.width * 0),
          child: CarouselSlider.builder(
              itemCount: 3, itemBuilder: _weekdayCarouselBuilder, options: CarouselOptions(
            enableInfiniteScroll: true,
            initialPage: _initialWeekday.idx,
            height: _weekdayHeight,
          )),
        ),

        // Container(
        //   width: MediaQuery.of(context).size.width,
        //   padding: EdgeInsets.only(top: 52, left: 25),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.end,
        //     children: emptyDay.appointments.map((appointment) => Container(
        //       height: appointment.duration * 0.9,
        //       // padding: EdgeInsets.only(bottom: appointment.duration * 0.9 - 32),
        //       child: Container(
        //         // height: 10,
        //         //   color: Colors.blue,
        //         // innerPadding: EdgeInsets.symmetric(horizontal: 6),
        //         //   innerPadding: EdgeInsets.symmetric(vertical: 3, horizontal: 6),
        //           child: Column(
        //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //             children: [
        //               Text("${appointment.begin.hour.toString().padLeft(2, "0")}:${appointment.begin.minute.toString().padLeft(2, "0")}", style: theme.textTheme.bodyLarge?.copyWith(color: theme.primaryColor),),
        //               // Text("${appointment.end.hour.toString().padLeft(2, "0")}:${appointment.end.minute.toString().padLeft(2, "0")}", style: theme.textTheme.bodyLarge?.copyWith(color: theme.primaryColor),),
        //             ],
        //           )
        //       ),
        //     )).toList(),
        //   ),
        // ),
      ],
    );
  }

  Widget _weekdayCarouselBuilder(BuildContext context, int idx, int w) {
    final vm = Provider.of<KITProvider>(context);
    final theme = Theme.of(context);

    final now = DateTime.now();

    final weekdayIdx = (w - 10000);
    final todayWeekdayIdx = DateTime.now().weekday - 1;
    final date = now.add(Duration(days: weekdayIdx - todayWeekdayIdx));

    final TimetableDaily? tt = weekdayIdx % 7 < 5 ? vm.timetable.days[weekdayIdx % 7] : null;

    final monthStr = [
      "Januar",
      "Februar",
      "März",
      "April",
      "Mai",
      "Juni",
      "Juli",
      "August",
      "September",
      "Oktober",
      "November",
      "Dezember",
    ][date.month - 1];

    String dateTitle = "${date.day}. $monthStr";

    if (now.day == date.day && now.month == date.month) {
      dateTitle = "Heute, $dateTitle";
    } else if (now.day - date.day == 1 && now.month == date.month) {
      dateTitle = "Gestern, $dateTitle";
    } else if (now.day - date.day == -1 && now.month == date.month) {
      dateTitle = "Morgen, $dateTitle";
    }

    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: EdgeInsets.only(left: 10, right: 10, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(dateTitle, style: theme.textTheme.titleLarge,),

                  // Spacer(),

                  dateTitle.contains("Heute") ? GestureDetector(
                    onTap: () { },
                    child: Text("Bearbeiten", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),),
                    // child: Icon(CupertinoIcons.pencil_circle),
                  ) : SizedBox(width: 0, height: 0,)
                ],
              ),
            ),
            Padding(padding: EdgeInsets.all(5)),
            BlockContainer(
              innerPadding: EdgeInsets.zero,
              child: tt != null ? TimetableDailyView(tt: tt) : Padding(padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.15),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: _weekdayHeight * 0.47,
                      ),
                      Column(
                        children: [
                          Icon(CupertinoIcons.zzz, color: theme.colorScheme.primary, size: 64,),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Text("Wochenende :)", style: theme.textTheme.bodyLarge,),
                          )
                        ],
                      )
                    ],
                  )
              ),
            )
          ],
        )
      ],
    );
  }

}