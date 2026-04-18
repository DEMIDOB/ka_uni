import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kit_mobile/common_ui/kit_progress_indicator.dart';
import 'package:kit_mobile/timetable/models/timetable_appointment.dart';

class TimetableAppointmentPage extends StatefulWidget {
  final TimetableAppointment appointment;

  const TimetableAppointmentPage({super.key, required this.appointment});

  @override
  State<StatefulWidget> createState() {
    return _TimetableAppointmentPageState();
  }
}

class _TimetableAppointmentPageState extends State<TimetableAppointmentPage> {
  double _draggableSheetOffset = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Center(
              child: SizedBox(
            width: mq.size.width,
            height: mq.size.height,
            child: FutureBuilder(
              future: widget.appointment.placeData,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return KITProgressIndicator();
                }

                final data = snapshot.data!;

                return FlutterMap(
                  options: MapOptions(
                    initialCenter: data,
                    initialZoom: 17,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.demidov.kaUni',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: data,
                          width: 50,
                          height: 50,
                          child: ClipRRect(
                              child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            spreadRadius: 2,
                                            blurRadius: 7)
                                      ]),
                                  width: 25,
                                  height: 25),

                              // BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(),)
                            ],
                          )),
                        ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () => print(
                              Uri.parse('https://openstreetmap.org/copyright')),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          )),
          DraggableScrollableSheet(
              minChildSize: 0.15,
              initialChildSize: 0.2,
              maxChildSize: 0.4,
              builder: (context, controller) {
                controller.addListener(() {
                  setState(() {
                    _draggableSheetOffset = controller.offset;
                  });
                });

                return Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 15 * max(0, 1 - _draggableSheetOffset / 100)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20) *
                            max(0, 1 - _draggableSheetOffset / 100),
                        topRight: Radius.circular(20) *
                            max(0, 1 - _draggableSheetOffset / 100)),
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          // padding: EdgeInsets.all(15),
                          color:
                              theme.colorScheme.surface.withValues(alpha: 0.5),
                          child: ListView(
                            controller: controller,
                            children: [
                              // Text("data"),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Hero(
                                        tag:
                                            "appointmentTitle_${widget.appointment.title}_${widget.appointment.id}",
                                        child: Text(
                                          widget.appointment.title,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                        )),
                                    SizedBox(height: 20),
                                    placeDetail(
                                        "ID:", widget.appointment.id, theme),
                                    placeDetail("Ort:",
                                        widget.appointment.place.title, theme),
                                    SizedBox(height: 20),
                                    SizedBox(height: 500),
                                  ],
                                ),
                              )
                            ],
                          ),
                        )),
                  ),
                );
              }),
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ),
              child: Container(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                child: SafeArea(
                  bottom: false,
                  child:
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      // color: Colors.amber,
                      child: Icon(Icons.arrow_back_ios_rounded),
                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },
                    )
                  ]),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget placeDetail(String description, String detail, ThemeData theme) {
    return Row(
      children: [
        Text(
          description,
          style:
              theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(
          width: 5,
        ),
        Text(
          detail,
          maxLines: 2,
        ),
      ],
    );
  }
}
