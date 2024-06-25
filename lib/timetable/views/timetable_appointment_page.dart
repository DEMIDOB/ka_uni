import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:kit_mobile/common_ui/kit_logo.dart';
import 'package:kit_mobile/common_ui/kit_progress_indicator.dart';
import 'package:kit_mobile/timetable/models/timetable_appointment.dart';
import 'package:latlong2/latlong.dart';

class TimetableAppointmentPage extends StatelessWidget {
  final TimetableAppointment appointment;

  const TimetableAppointmentPage({super.key, required this.appointment});



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Termin"),
      ),
      body: Stack(
        children: [


          Center(
              child: SizedBox(
                width: mq.size.width,
                height: mq.size.height,
                child: FutureBuilder(
                  future: appointment.placeData,
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
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                          boxShadow: [BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 7
                                          )]
                                        ),
                                        width: 25,
                                        height: 25
                                    ),

                                    // BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(),)
                                  ],
                                )
                              ),
                            ),
                          ],
                        ),
                        RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              'OpenStreetMap contributors',
                              onTap: () => print(Uri.parse('https://openstreetmap.org/copyright')),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              )
          ),

          Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(),
              ClipRRect(
                child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.all(15),
                      color: theme.colorScheme.surface.withOpacity(0.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                              tag: "appointmentTitle_${appointment.title}_${appointment.id}",
                              child: Text(appointment.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), maxLines: 2,)
                          ),

                          SizedBox(height: 20),

                          Row(
                            children: [
                              Text("ID:", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),),
                              SizedBox(width: 5,),
                              Text(appointment.id, maxLines: 2,),
                            ],
                          ),

                          Row(
                            children: [
                              Text("Ort:", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),),
                              SizedBox(width: 5,),
                              Text(appointment.place.title, maxLines: 2,),
                            ],
                          ),

                          SizedBox(height: 20),
                        ],
                      ),
                    )
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

}