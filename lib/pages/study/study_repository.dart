import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'study_task_document.dart';
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
  StudyRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String _selectedPresetKey = 'study_selected_preset';
  static const String _remainingSecondsKey = 'study_remaining_seconds';
  static const String _isRunningKey = 'study_is_running';
  static const String _savedAtKey = 'study_saved_at';
  static const String _completedTaskIdsKey = 'study_completed_task_ids';
  static const String _sessionHistoryKey = 'study_session_history';

  StudySeedData loadSeedData() {
    return StudySeedData(
      focusPresets: buildFocusPresets(),
      tasks: const <StudyTask>[],
      scheduleItems: buildScheduleItems(),
      journalEntries: buildJournalEntries(),
      sessionHistory: const <StudySessionRecord>[],
      completedTasksBeforeToday: 0,
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

  Future<List<StudySessionRecord>> loadSessionHistory() async {
    final User user = _requireUser();
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('studySessions')
        .orderBy('completedAt', descending: true)
        .limit(120)
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          final completedAt = _readTimestamp(data['completedAt']);
          final durationMinutes = _readInt(data['durationMinutes']) ?? 0;
          return StudySessionRecord(
            date: completedAt ?? DateTime.now(),
            duration: Duration(minutes: durationMinutes),
          );
        })
        .toList(growable: false);
  }

  Future<void> addSessionRecord(StudySessionRecord record) async {
    final User user = _requireUser();
    final DateTime date = record.date;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('studySessions')
        .add({
          'dateKey': _dateKey(date),
          'durationMinutes': record.duration.inMinutes,
          'completedAt': Timestamp.fromDate(date),
          'createdAt': FieldValue.serverTimestamp(),
          'source': 'focusTimer',
        });
  }

  Future<List<StudyTask>> loadTasks() async {
    final User user = _requireUser();
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('studyTasks')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(StudyTaskDocument.fromFirestore)
        .map((task) => task.toStudyTask())
        .toList(growable: false);
  }

  Stream<List<StudyTask>> watchTasks() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(const <StudyTask>[]);

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('studyTasks')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(StudyTaskDocument.fromFirestore)
                .map((task) => task.toStudyTask())
                .toList(growable: false),
          );
    });
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueAt,
  }) async {
    final User user = _requireUser();
    final String trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const StudyTaskException('Please enter a task title.');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('studyTasks')
        .add({
          'title': trimmedTitle,
          'description': _nullableString(description),
          'isCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'dueAt': dueAt == null ? null : Timestamp.fromDate(dueAt),
        });
  }

  Future<void> updateTask({
    required String taskId,
    required String title,
    String? description,
    DateTime? dueAt,
  }) async {
    final User user = _requireUser();
    final String trimmedTitle = title.trim();
    if (taskId.trim().isEmpty) {
      throw const StudyTaskException('Study task was not found.');
    }
    if (trimmedTitle.isEmpty) {
      throw const StudyTaskException('Please enter a task title.');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('studyTasks')
        .doc(taskId)
        .set({
          'title': trimmedTitle,
          'description': _nullableString(description),
          'dueAt': dueAt == null ? null : Timestamp.fromDate(dueAt),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> deleteTask(String taskId) async {
    final User user = _requireUser();
    if (taskId.trim().isEmpty) {
      throw const StudyTaskException('Study task was not found.');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('studyTasks')
        .doc(taskId)
        .delete();
  }

  Future<void> updateTaskCompletion(String taskId, bool isCompleted) async {
    final User user = _requireUser();
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('studyTasks')
        .doc(taskId)
        .set({
          'isCompleted': isCompleted,
          'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  User _requireUser() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw const StudyTaskException(
        'Please log in again before managing study tasks.',
      );
    }

    return user;
  }

  String? _nullableString(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

class StudyTaskException implements Exception {
  const StudyTaskException(this.message);

  final String message;

  @override
  String toString() => message;
}
