import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:kit_mobile/common_ui/kit_logo.dart';
import 'package:kit_mobile/common_ui/kit_progress_indicator.dart';
import 'package:kit_mobile/timetable/models/timetable_appointment.dart';

class TimetableAppointmentPage extends StatelessWidget {
  final TimetableAppointment appointment;

  const TimetableAppointmentPage({super.key, required this.appointment});



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Termin"),
      ),
      body: Column(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(),
          Container(
            padding: EdgeInsets.all(15),
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

                FutureBuilder(
                  future: appointment.placeData,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == null) {
                      return KITProgressIndicator();
                    }

                    final data = snapshot.data!;

                    return HtmlWidget(data);
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }

}