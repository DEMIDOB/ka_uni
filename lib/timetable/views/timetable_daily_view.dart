import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/block_container.dart';
import 'package:kit_mobile/constants/view_constants.dart';
import 'package:kit_mobile/module/models/module.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:kit_mobile/timetable/models/timetable_appointment.dart';
import 'package:kit_mobile/timetable/pages/timetable_appointment_page.dart';
import 'package:kit_mobile/tutorials/data/tutorial_manager.dart';
import 'package:kit_mobile/tutorials/models/tutorial.dart';
import 'package:provider/provider.dart';

import '../models/timetable_daily.dart';

class TimetableDailyView extends StatelessWidget {
  final TimetableDaily tt;

  const TimetableDailyView({super.key, required this.tt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceWidth = MediaQuery.of(context).size.width;
    final tutorialManager = Provider.of<TutorialManager>(context);
    final kitProvider = Provider.of<KITProvider>(context);

    final modulesById = <String, KITModule>{};
    for (final module in kitProvider.campusManager.rowModules.values) {
      if (module.id.isNotEmpty) {
        modulesById[module.id] = module;
      }
    }

    final semesterString = KITProvider.currentSemesterString;
    final tutorialsList = tutorialManager
        .tutorialsForWeekday(semesterString, tt.weekday)
        .map((tutorial) {
      final module = modulesById[tutorial.moduleId];
      if (module != null && module.title.trim().isNotEmpty) {
        return tutorial.copyWith(moduleTitle: module.title.trim());
      }
      return tutorial;
    }).toList(growable: false);

    final tutorialsByBlock = <int, List<Tutorial>>{};
    for (final tutorial in tutorialsList) {
      tutorialsByBlock.putIfAbsent(tutorial.blockIndex, () => []).add(tutorial);
    }

    final appointmentsByBlock = tt.appointmentsWithTutorials(tutorialsByBlock);

    return Column(
      children: [
        Column(
          children: appointmentsByBlock.map((appointments) {
            final appointment = appointments
                .where((appointment) =>
                    !appointment.isEmpty || appointments.length <= 1)
                .first;
            bool isTut = appointment.type == TimetableAppointmentType.tutorial;

            // try {
            //   appointment as Tutorial;
            //   // isTut = true;
            // } catch (exc) {
            //   isTut = false;
            // }

            return Container(
              decoration: BoxDecoration(
                border: appointment.begin.hour < 17
                    ? Border(
                        bottom: BorderSide(
                            color: theme.brightness == Brightness.light
                                ? Colors.black12
                                : Colors.white.withValues(alpha: 0.15)))
                    : null,
              ),
              child: SizedBox(
                height: appointment.duration * 0.9,
                child: Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    // Padding(
                    //   padding: EdgeInsets.only(left: 15, right: 5, top: 5, bottom: 5),
                    //   child: VerticalDivider(color: theme.colorScheme.primary,),
                    // ),

                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => TimetableAppointmentPage(
                                appointment: appointment)));
                      },
                      child: SizedBox(
                        width: appointment.type ==
                                TimetableAppointmentType.lunchBreak
                            ? null
                            : deviceWidth * 0.8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // !isTut ? SizedBox.shrink() : Text("Tutorium:"),

                              appointment.id.isNotEmpty
                                  ? Hero(
                                      tag:
                                          "appointmentTitle_${appointment.title}_${appointment.id}",
                                      child: Text(
                                        isTut
                                            ? "Tutorium: " +
                                                appointment
                                                    .abbreviatedTitleIfLongerThan(
                                                        30)
                                            : appointment
                                                .abbreviatedTitleIfLongerThan(
                                                    50),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                      ))
                                  : Text(
                                      appointment.title,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                    ),

                              appointment.place.title.isNotEmpty
                                  ? Hero(
                                      tag:
                                          "appointmentPlace_${appointment.title}_${appointment.id}",
                                      child: Text(
                                        appointment.place.title,
                                        maxLines: 2,
                                      ))
                                  : SizedBox(
                                      height: 0,
                                    ),

                              isTut && (appointment.notes ?? "").isNotEmpty
                                  ? Text(
                                      appointment.notes,
                                      maxLines: 2,
                                    )
                                  : SizedBox.shrink(),

                              appointment.type ==
                                      TimetableAppointmentType.lunchBreak
                                  ? Row(
                                      children: [
                                        // CupertinoButton(
                                        //   child: Text("Speiseplan", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),),
                                        //   onPressed: () {},
                                        //   padding: EdgeInsets.only(left: 0),
                                        // )
                                      ],
                                    )
                                  : const SizedBox(
                                      height: 0,
                                    )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.only(topRight: appBorderRadius),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            BlockContainer(
                                padding:
                                    const EdgeInsets.only(left: 3, bottom: 3),
                                innerPadding: const EdgeInsets.only(
                                    left: 6, bottom: 3, top: 3, right: 6),
                                child: Text(
                                  "${appointment.begin.hour.toString().padLeft(2, "0")}:${appointment.begin.minute.toString().padLeft(2, "0")}",
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.primary),
                                )),
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

class _BlockContent extends StatelessWidget {
  final TimetableAppointment appointment;
  final List<Tutorial> tutorials;
  final double deviceWidth;

  const _BlockContent({
    required this.appointment,
    required this.tutorials,
    required this.deviceWidth,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final isLunchBreak =
        appointment.type == TimetableAppointmentType.lunchBreak;

    if (isLunchBreak) {
      children.add(_LunchBreakTile(appointment: appointment));
    } else if (!appointment.isEmpty) {
      children.add(
        _AppointmentTile(
          appointment: appointment,
          deviceWidth: deviceWidth,
        ),
      );
    }

    if (tutorials.isNotEmpty) {
      children.addAll(
        tutorials.map(
          (tutorial) => _TutorialTile(
            tutorial: tutorial,
            deviceWidth: deviceWidth,
          ),
        ),
      );
    }

    if (children.isEmpty) {
      children.add(const SizedBox(height: 12));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final TimetableAppointment appointment;
  final double deviceWidth;

  const _AppointmentTile({
    required this.appointment,
    required this.deviceWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                TimetableAppointmentPage(appointment: appointment),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: deviceWidth * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            appointment.id.isNotEmpty
                ? Hero(
                    tag:
                        "appointmentTitle_${appointment.title}_${appointment.id}",
                    child: Text(
                      appointment.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                    ),
                  )
                : Text(
                    appointment.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                  ),
            if (appointment.place.title.isNotEmpty)
              Hero(
                tag: "appointmentPlace_${appointment.title}_${appointment.id}",
                child: Text(
                  appointment.place.title,
                  maxLines: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TutorialTile extends StatelessWidget {
  final Tutorial tutorial;
  final double deviceWidth;

  const _TutorialTile({
    required this.tutorial,
    required this.deviceWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.secondaryContainer
        .withValues(alpha: theme.brightness == Brightness.dark ? 0.45 : 0.7);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                TimetableAppointmentPage(appointment: tutorial),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: deviceWidth * 0.8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.all(appBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tutorium",
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
            ),
            const SizedBox(height: 4),
            Text(
              tutorial.title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
            ),
            if (tutorial.notes != null && tutorial.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  tutorial.notes!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LunchBreakTile extends StatelessWidget {
  final TimetableAppointment appointment;

  const _LunchBreakTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        appointment.title,
        style: theme.textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }
}
