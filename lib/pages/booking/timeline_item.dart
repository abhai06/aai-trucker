import 'package:flutter/material.dart';

class TimelineItem {
  final String title;
  final String address;
  final String date;
  final String status;
  final String time;
  final IconData icon;

  TimelineItem({
    required this.title,
    required this.address,
    required this.date,
    required this.status,
    required this.time,
    required this.icon,
  });
}
