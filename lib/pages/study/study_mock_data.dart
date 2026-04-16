import 'package:flutter/material.dart';

import 'study_models.dart';

const int weeklyCompletedTasksBeforeToday = 41;

List<FocusPreset> buildFocusPresets() {
  return const [
    FocusPreset(
      id: FocusPresetId.focus25,
      label: '25 min',
      duration: Duration(minutes: 25),
    ),
    FocusPreset(
      id: FocusPresetId.break5,
      label: '5 min break',
      duration: Duration(minutes: 5),
      isBreak: true,
    ),
    FocusPreset(
      id: FocusPresetId.focus50,
      label: '50 min',
      duration: Duration(minutes: 50),
    ),
  ];
}

List<StudyTask> buildStudyTasks() {
  return const [
    StudyTask(
      id: 'biology-readings',
      title: 'MATULOG DAW SABI NI MAMA',
      subject: 'Biology',
      isCompleted: true,
    ),
    StudyTask(
      id: 'math-problem-set',
      title: 'MAG HULOG NG LIMA SA ALANSIYA',
      subject: 'Mathematics',
    ),
    StudyTask(
      id: 'essay-outline',
      title: 'PITCH PRACTICE',
      subject: 'English',
    ),
    StudyTask(
      id: 'history-notes',
      title: 'KUNG IBON AKO, BAT AKO',
      subject: 'History',
    ),
  ];
}

List<ScheduleItem> buildScheduleItems() {
  return const [
    ScheduleItem(
      title: 'MARVEL ACADEMY',
      room: 'Room 204',
      time: '9:00 AM',
      accentColor: Color(0xFF2F65FF),
    ),
    ScheduleItem(
      title: 'WHAT IF ?',
      room: 'Room 156',
      time: '11:00 AM',
      accentColor: Color(0xFFA72EFF),
    ),
    ScheduleItem(
      title: 'Mahal kong Maynila',
      room: 'Room 301',
      time: '2:00 PM',
      accentColor: Color(0xFF17C45B),
    ),
  ];
}

List<StudySessionRecord> buildStudySessionHistory() {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);

  return [
    StudySessionRecord(
      date: today
          .subtract(const Duration(days: 4))
          .add(const Duration(hours: 8, minutes: 30)),
      duration: const Duration(minutes: 375),
    ),
    StudySessionRecord(
      date: today
          .subtract(const Duration(days: 3))
          .add(const Duration(hours: 10)),
      duration: const Duration(minutes: 360),
    ),
    StudySessionRecord(
      date: today
          .subtract(const Duration(days: 2))
          .add(const Duration(hours: 9, minutes: 15)),
      duration: const Duration(minutes: 315),
    ),
    StudySessionRecord(
      date: today
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 11)),
      duration: const Duration(minutes: 360),
    ),
    StudySessionRecord(
      date: today.add(const Duration(hours: 8)),
      duration: const Duration(minutes: 300),
    ),
  ];
}

List<JournalEntry> buildJournalEntries() {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);

  return [
    JournalEntry(
      id: 'entry-1',
      mood: StudyMood.happy,
      title: 'Great Study Session',
      date: today
          .subtract(const Duration(days: 0))
          .add(const Duration(hours: 18, minutes: 30)),
      preview:
          'Had a productive day studying for my biology exam. Feeling confident about the upcoming topics and review session.',
      tags: const ['Study', 'Goals'],
    ),
    JournalEntry(
      id: 'entry-2',
      mood: StudyMood.motivated,
      title: 'New Semester Goals',
      date: today
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 19, minutes: 10)),
      preview:
          'Set new goals for this semester. Want to maintain a consistent study schedule and stay ahead on assignments.',
      tags: const ['Goals', 'Reflection'],
    ),
    JournalEntry(
      id: 'entry-3',
      mood: StudyMood.stressed,
      title: 'Midterm Week',
      date: today
          .subtract(const Duration(days: 2))
          .add(const Duration(hours: 21)),
      preview:
          'Feeling a bit overwhelmed with all the upcoming exams, but I have a good study plan in place.',
      tags: const ['Reflection'],
    ),
    JournalEntry(
      id: 'entry-4',
      mood: StudyMood.happy,
      title: 'Library Flow State',
      date: today
          .subtract(const Duration(days: 3))
          .add(const Duration(hours: 20, minutes: 5)),
      preview:
          'Spent the afternoon in the library and finished more than expected. Quiet spaces really help me lock in.',
      tags: const ['Study'],
    ),
    JournalEntry(
      id: 'entry-5',
      mood: StudyMood.calm,
      title: 'Slow but Steady',
      date: today
          .subtract(const Duration(days: 4))
          .add(const Duration(hours: 17, minutes: 50)),
      preview:
          'Today felt balanced. I kept a lighter workload and stayed consistent without burning out.',
      tags: const ['Wellness'],
    ),
    JournalEntry(
      id: 'entry-6',
      mood: StudyMood.motivated,
      title: 'Morning Momentum',
      date: today
          .subtract(const Duration(days: 5))
          .add(const Duration(hours: 8, minutes: 45)),
      preview:
          'An early start gave me a lot of momentum. Crossing off small tasks first made the rest of the day easier.',
      tags: const ['Goals', 'Routine'],
    ),
    JournalEntry(
      id: 'entry-7',
      mood: StudyMood.happy,
      title: 'Wrapped Up Strong',
      date: today
          .subtract(const Duration(days: 6))
          .add(const Duration(hours: 20, minutes: 20)),
      preview:
          'Finished the week on a strong note and felt proud of staying consistent with my study blocks.',
      tags: const ['Study', 'Reflection'],
    ),
  ]..sort((a, b) => b.date.compareTo(a.date));
}
