import 'dart:convert';

import 'package:flutter/material.dart';

enum StudyTab { focusMode, journalMood }

enum FocusPresetId { focus25, break5, focus50 }

enum StudyMood { happy, motivated, calm, stressed }

class FocusPreset {
  const FocusPreset({
    required this.id,
    required this.label,
    required this.duration,
    this.isBreak = false,
  });

  final FocusPresetId id;
  final String label;
  final Duration duration;
  final bool isBreak;
}

class FocusTimerState {
  const FocusTimerState({
    required this.presets,
    required this.selectedPresetId,
    required this.remaining,
    this.isRunning = false,
  });

  final List<FocusPreset> presets;
  final FocusPresetId selectedPresetId;
  final Duration remaining;
  final bool isRunning;

  FocusPreset get selectedPreset =>
      presets.firstWhere((preset) => preset.id == selectedPresetId);

  Duration get selectedDuration => selectedPreset.duration;

  bool get isComplete => remaining.inSeconds <= 0;

  String get heading => 'FOCUS SESSION';

  String get durationLabel => StudyFormatters.formatDuration(remaining);

  String get subtitle {
    if (isComplete) {
      return selectedPreset.isBreak ? 'Break complete' : 'Session complete';
    }

    if (isRunning) {
      return selectedPreset.isBreak ? 'Take a breather' : 'Stay focused';
    }

    if (remaining.inSeconds < selectedDuration.inSeconds) {
      return selectedPreset.isBreak ? 'Break paused' : 'Focus paused';
    }

    return selectedPreset.isBreak ? 'Ready for a break' : 'Stay focused';
  }

  double get progress {
    if (selectedDuration.inSeconds == 0) {
      return 0;
    }

    return (remaining.inSeconds / selectedDuration.inSeconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  FocusTimerState copyWith({
    List<FocusPreset>? presets,
    FocusPresetId? selectedPresetId,
    Duration? remaining,
    bool? isRunning,
  }) {
    return FocusTimerState(
      presets: presets ?? this.presets,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
      remaining: remaining ?? this.remaining,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class StudyTask {
  const StudyTask({
    required this.id,
    required this.title,
    required this.subject,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String subject;
  final bool isCompleted;

  StudyTask copyWith({
    String? id,
    String? title,
    String? subject,
    bool? isCompleted,
  }) {
    return StudyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ScheduleItem {
  const ScheduleItem({
    required this.title,
    required this.room,
    required this.time,
    required this.accentColor,
  });

  final String title;
  final String room;
  final String time;
  final Color accentColor;
}

class WeeklyStat {
  const WeeklyStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;
}

class MoodSummaryItem {
  const MoodSummaryItem({required this.mood, required this.count});

  final StudyMood mood;
  final int count;

  String get emoji => mood.emoji;

  String get countLabel => '$count day${count == 1 ? '' : 's'}';
}

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.mood,
    required this.title,
    required this.date,
    required this.preview,
    required this.tags,
  });

  final String id;
  final StudyMood mood;
  final String title;
  final DateTime date;
  final String preview;
  final List<String> tags;

  String get emoji => mood.emoji;

  String get moodLabel => mood.label;

  String get dateLabel => StudyFormatters.formatMonthDay(date);
}

class InsightData {
  const InsightData({
    required this.title,
    required this.message,
    required this.tip,
  });

  final String title;
  final String message;
  final String tip;
}

class StudySessionRecord {
  const StudySessionRecord({required this.date, required this.duration});

  final DateTime date;
  final Duration duration;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'durationSeconds': duration.inSeconds,
    };
  }

  factory StudySessionRecord.fromJson(Map<String, dynamic> json) {
    return StudySessionRecord(
      date: DateTime.parse(json['date'] as String),
      duration: Duration(seconds: json['durationSeconds'] as int),
    );
  }

  String encode() => jsonEncode(toJson());

  factory StudySessionRecord.decode(String value) {
    return StudySessionRecord.fromJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
  }
}

class StudyState {
  const StudyState({
    required this.focusTimer,
    required this.tasks,
    required this.sessionHistory,
  });

  final FocusTimerState focusTimer;
  final List<StudyTask> tasks;
  final List<StudySessionRecord> sessionHistory;

  StudyState copyWith({
    FocusTimerState? focusTimer,
    List<StudyTask>? tasks,
    List<StudySessionRecord>? sessionHistory,
  }) {
    return StudyState(
      focusTimer: focusTimer ?? this.focusTimer,
      tasks: tasks ?? this.tasks,
      sessionHistory: sessionHistory ?? this.sessionHistory,
    );
  }
}

extension FocusPresetIdStorage on FocusPresetId {
  String get storageValue => name;

  static FocusPresetId? fromStorage(String? value) {
    for (final presetId in FocusPresetId.values) {
      if (presetId.storageValue == value) {
        return presetId;
      }
    }

    return null;
  }
}

extension StudyMoodDetails on StudyMood {
  String get emoji {
    switch (this) {
      case StudyMood.happy:
        return '😊';
      case StudyMood.motivated:
        return '💪';
      case StudyMood.calm:
        return '😌';
      case StudyMood.stressed:
        return '😰';
    }
  }

  String get label {
    switch (this) {
      case StudyMood.happy:
        return 'Happy';
      case StudyMood.motivated:
        return 'Motivated';
      case StudyMood.calm:
        return 'Calm';
      case StudyMood.stressed:
        return 'Stressed';
    }
  }
}

abstract final class StudyFormatters {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds.clamp(0, 359999).toInt();
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatMonthDay(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}';
  }
}
