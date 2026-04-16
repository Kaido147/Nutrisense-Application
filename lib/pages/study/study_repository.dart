import 'package:shared_preferences/shared_preferences.dart';

import 'study_mock_data.dart';
import 'study_models.dart';

class StudySeedData {
  const StudySeedData({
    required this.focusPresets,
    required this.tasks,
    required this.scheduleItems,
    required this.journalEntries,
    required this.sessionHistory,
    required this.completedTasksBeforeToday,
  });

  final List<FocusPreset> focusPresets;
  final List<StudyTask> tasks;
  final List<ScheduleItem> scheduleItems;
  final List<JournalEntry> journalEntries;
  final List<StudySessionRecord> sessionHistory;
  final int completedTasksBeforeToday;
}

class StudyPersistenceData {
  const StudyPersistenceData({
    required this.selectedPresetId,
    required this.remainingSeconds,
    required this.isRunning,
    required this.savedAt,
    required this.completedTaskIds,
    required this.sessionHistory,
  });

  final FocusPresetId selectedPresetId;
  final int remainingSeconds;
  final bool isRunning;
  final DateTime savedAt;
  final List<String> completedTaskIds;
  final List<StudySessionRecord> sessionHistory;
}

class StudyRepository {
  const StudyRepository();

  static const String _selectedPresetKey = 'study_selected_preset';
  static const String _remainingSecondsKey = 'study_remaining_seconds';
  static const String _isRunningKey = 'study_is_running';
  static const String _savedAtKey = 'study_saved_at';
  static const String _completedTaskIdsKey = 'study_completed_task_ids';
  static const String _sessionHistoryKey = 'study_session_history';

  StudySeedData loadSeedData() {
    return StudySeedData(
      focusPresets: buildFocusPresets(),
      tasks: buildStudyTasks(),
      scheduleItems: buildScheduleItems(),
      journalEntries: buildJournalEntries(),
      sessionHistory: buildStudySessionHistory(),
      completedTasksBeforeToday: weeklyCompletedTasksBeforeToday,
    );
  }

  Future<StudyPersistenceData?> loadPersistence() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final FocusPresetId? selectedPresetId = FocusPresetIdStorage.fromStorage(
      prefs.getString(_selectedPresetKey),
    );

    if (selectedPresetId == null) {
      return null;
    }

    final List<String> encodedHistory =
        prefs.getStringList(_sessionHistoryKey) ?? const [];

    return StudyPersistenceData(
      selectedPresetId: selectedPresetId,
      remainingSeconds: prefs.getInt(_remainingSecondsKey) ?? 0,
      isRunning: prefs.getBool(_isRunningKey) ?? false,
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(_savedAtKey) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      completedTaskIds: prefs.getStringList(_completedTaskIdsKey) ?? const [],
      sessionHistory: encodedHistory
          .map(StudySessionRecord.decode)
          .toList(growable: false),
    );
  }

  Future<void> savePersistence({
    required FocusTimerState timer,
    required List<StudyTask> tasks,
    required List<StudySessionRecord> sessionHistory,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _selectedPresetKey,
      timer.selectedPresetId.storageValue,
    );
    await prefs.setInt(_remainingSecondsKey, timer.remaining.inSeconds);
    await prefs.setBool(_isRunningKey, timer.isRunning);
    await prefs.setInt(_savedAtKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setStringList(
      _completedTaskIdsKey,
      tasks
          .where((task) => task.isCompleted)
          .map((task) => task.id)
          .toList(growable: false),
    );
    await prefs.setStringList(
      _sessionHistoryKey,
      sessionHistory.map((record) => record.encode()).toList(growable: false),
    );
  }
}
