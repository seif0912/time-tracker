import 'package:flutter/material.dart';

class TimeTrackerApp extends StatelessWidget {
  const TimeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Time Tracker',

      home: const Scaffold(body: Center(child: Text('Time Tracker'))),
    );
  }
}
