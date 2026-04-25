import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/extensions/theme_data_extension.dart';
import 'package:kit_mobile/timetable/models/timetable_daily.dart';
import 'package:kit_mobile/timetable/models/timetable_weekly.dart';
import 'package:kit_mobile/timetable/views/timetable_daily_view.dart';
import 'package:provider/provider.dart';

import '../../state_management/kit_provider.dart';

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
    _initialWeekday =
        initialWeekday ?? _initialWeekday.fromInt(DateTime.now().weekday - 1);
  }

  final _weekdayHeight = 90 * 7 * 0.7 + 200;

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    // final emptyDay = TimetableDaily();

    return Column(
      children: [
        CarouselSlider.builder(
            itemCount: 3,
            itemBuilder: _weekdayCarouselBuilder,
            options: CarouselOptions(
              enableInfiniteScroll: true,
              initialPage: _initialWeekday.idx,
              height: _weekdayHeight - 40,
            )),
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

    final TimetableDaily? tt =
        weekdayIdx % 7 < 5 ? vm.timetable.days[weekdayIdx % 7] : null;

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

    final weekdayShortStr = [
      "Mo",
      "Di",
      "Mi",
      "Do",
      "Fr",
      "Sa",
      "So"
    ][weekdayIdx % 7];

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
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    weekdayShortStr,
                    style: theme.textTheme.titleLarge?.copyWith(color: theme.isLightMode ? Colors.black26 : Colors.white30),
                  ),

                  Padding(padding: EdgeInsets.all(5)),

                  Text(
                    dateTitle,
                    style: theme.textTheme.titleLarge,
                  ),

                  Padding(padding: EdgeInsets.all(5)),

                  Text(
                    weekdayShortStr,
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.transparent),
                  ),
                ],
              ),
            ),
            Padding(padding: EdgeInsets.all(5)),
            BlockContainer(
              innerPadding: EdgeInsets.zero,
              child: tt != null
                  ? TimetableDailyView(tt: tt)
                  : Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.15),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: _weekdayHeight * 0.4,
                          ),
                          Column(
                            children: [
                              Icon(
                                CupertinoIcons.zzz,
                                color: theme.colorScheme.primary,
                                size: 64,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  "Wochenende :)",
                                  style: theme.textTheme.bodyLarge,
                                ),
                              )
                            ],
                          )
                        ],
                      )),
            )
          ],
        )
      ],
    );
  }
}
