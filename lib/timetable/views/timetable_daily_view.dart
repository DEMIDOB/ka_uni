import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/timetable/models/timetable_appointment.dart';
import 'package:kit_mobile/timetable/pages/timetable_appointment_page.dart';

import '../models/timetable_daily.dart';

class TimetableDailyView extends StatelessWidget {
  final TimetableDaily tt;

  const TimetableDailyView({super.key, required this.tt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final deviceWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // Text("${tt.weekday}"),
        Column(
          children: tt.appointments.map((appointment) {
            return Container(
              decoration: BoxDecoration(
                border: appointment.begin.hour < 17 ? Border(bottom: BorderSide(color: theme.brightness == Brightness.light ? Colors.black12 : Colors.white.withValues(alpha: 0.15))) : null,
              ),
              // color: Colors.red,
              child: SizedBox(
                height: appointment.duration * 0.9,
                child: Stack(
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  alignment: Alignment.topLeft,
                  children: [

                    // Padding(
                    //   padding: EdgeInsets.only(left: 15, right: 5, top: 5, bottom: 5),
                    //   child: VerticalDivider(color: theme.primaryColor,),
                    // ),

                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => TimetableAppointmentPage(appointment: appointment)));
                      },
                      child: SizedBox(
                        width: appointment.type == TimetableAppointmentType.lunchBreak ? null : deviceWidth * 0.8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              appointment.id.isNotEmpty ? Hero(tag: "appointmentTitle_${appointment.title}_${appointment.id}", child: Text(appointment.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 2,))
                              : Text(appointment.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 2,),

                              appointment.place.title.isNotEmpty ? Hero(tag: "appointmentPlace_${appointment.title}_${appointment.id}", child: Text(appointment.place.title, maxLines: 2,)) : SizedBox(height: 0,),
                              appointment.type == TimetableAppointmentType.lunchBreak ? Row(
                                children: [
                                  // CupertinoButton(
                                  //   child: Text("Speiseplan", style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryColor),),
                                  //   onPressed: () {},
                                  //   padding: EdgeInsets.only(left: 0),
                                  // )
                                ],
                              ) : const SizedBox(height: 0,)
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 0,
                      right: 0,
                      child: ClipRRect(
                          borderRadius: const BorderRadius.only(topRight: Radius.circular(8)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              BlockContainer(
                                padding: const EdgeInsets.only(left: 3, bottom: 3),
                                  innerPadding: const EdgeInsets.only(left: 6, bottom: 3, top: 3, right: 6),
                                  child: Text("${appointment.begin.hour.toString().padLeft(2, "0")}:${appointment.begin.minute.toString().padLeft(2, "0")}", style: theme.textTheme.bodyLarge?.copyWith(color: theme.primaryColor),)
                              ),
                              // Text("${appointment.end.hour.toString().padLeft(2, "0")}:${appointment.end.minute.toString().padLeft(2, "0")}"),
                            ],
                          ),
                      ),
                    ),



                  ],
                ),
              ),
            );
          }).toList(),
        )
      ],
    );
  }


}