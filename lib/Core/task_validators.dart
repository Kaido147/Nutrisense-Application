import 'package:flutter/material.dart';

String? validateTaskDueDateTime(DateTime? date, TimeOfDay? time) {
  if (date == null) return null;
  if (isDateInPast(date)) return 'Due date cannot be in the past';
  if (time != null && isTimeInPastToday(date, time)) {
    return 'Due time has already passed';
  }
  return null;
}

bool isDateInPast(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.isBefore(today);
}

bool isTimeInPastToday(DateTime date, TimeOfDay time) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final normalized = DateTime(date.year, date.month, date.day);
  if (normalized != today) return false;

  final selected = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  return selected.isBefore(now);
}
