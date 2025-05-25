import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_mobile/timetable/views/timetable_weekly_view.dart';

class TimetableEditPage extends StatefulWidget {
  const TimetableEditPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _TimetableEditPageState();
  }

}

class _TimetableEditPageState extends State<TimetableEditPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stundenplan anpassen"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(""),
            TimetableWeeklyView()
          ],
        ),
      )
    );
  }

}