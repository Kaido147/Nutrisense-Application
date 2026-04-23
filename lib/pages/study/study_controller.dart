import 'dart:async';

import 'package:flutter/material.dart';

import 'study_models.dart';
import 'study_repository.dart';

class StudyController extends ChangeNotifier {
  StudyController._(this._repository, this._seedData, this._state) {
    _scheduleItems = List<ScheduleItem>.unmodifiable(_seedData.scheduleItems);
    _journalEntries = List<JournalEntry>.unmodifiable(_seedData.journalEntries);
  }

  factory StudyController({required StudyRepository repository}) {
    final StudySeedData seedData = repository.loadSeedData();
    return StudyController._(
      repository,
      seedData,
      _buildInitialState(seedData),
    );
  }

  final StudyRepository _repository;
  final StudySeedData _seedData;
  late final List<ScheduleItem> _scheduleItems;
  late final List<JournalEntry> _journalEntries;

  static StudyState _buildInitialState(StudySeedData seedData) {
    final FocusPreset defaultPreset = seedData.focusPresets.first;
    return StudyState(
      focusTimer: FocusTimerState(
        presets: seedData.focusPresets,
        selectedPresetId: defaultPreset.id,
        remaining: defaultPreset.duration,
      ),
      tasks: seedData.tasks,
      sessionHistory: seedData.sessionHistory,
    );
  }

  StudyState _state;
  Timer? _ticker;
  bool _isDisposed = false;
  bool _isLoadingTasks = false;
  String? _taskErrorMessage;

  StudyState get state => _state;
  bool get isLoadingTasks => _isLoadingTasks;
  String? get taskErrorMessage => _taskErrorMessage;

  List<ScheduleItem> get scheduleItems => _scheduleItems;

  List<JournalEntry> get recentEntries {
    return _journalEntries.take(3).toList(growable: false);
  }

  List<MoodSummaryItem> get moodSummaryItems {
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = _startOfWeek(now);
    final Map<StudyMood, int> counts = {
      for (final StudyMood mood in StudyMood.values) mood: 0,
    };

    for (final JournalEntry entry in _journalEntries) {
      if (!entry.date.isBefore(startOfWeek)) {
        counts.update(entry.mood, (value) => value + 1);
      }
    }

    return StudyMood.values
        .map((mood) => MoodSummaryItem(mood: mood, count: counts[mood] ?? 0))
        .toList(growable: false);
  }

  List<WeeklyStat> get weeklyStats {
    final int totalMinutesThisWeek = _state.sessionHistory
        .where((record) => !_isBeforeCurrentWeek(record.date))
        .fold<int>(0, (sum, record) => sum + record.duration.inMinutes);
    final int tasksDone =
        _seedData.completedTasksBeforeToday +
        _state.tasks.where((task) => task.isCompleted).length;

    return [
      WeeklyStat(
        icon: Icons.menu_book_outlined,
        value: _formatHours(totalMinutesThisWeek),
        label: 'Hours',
      ),
      WeeklyStat(
        icon: Icons.task_alt_outlined,
        value: '$tasksDone',
        label: 'Tasks Done',
      ),
      WeeklyStat(
        icon: Icons.calendar_today_outlined,
        value: '${_calculateStreak(_state.sessionHistory)}',
        label: 'Days Streak',
      ),
    ];
  }

  InsightData get insights {
    final List<JournalEntry> weeklyEntries = _journalEntries
        .where((entry) => !_isBeforeCurrentWeek(entry.date))
        .toList(growable: false);

    if (weeklyEntries.isEmpty) {
      return const InsightData(
        title: 'Start your reflection habit',
        message:
            'No journal entries have been logged this week yet. A short note after a study session can make trends easier to spot.',
        tip:
            'Tip: Try logging one win and one challenge after each focus block.',
      );
    }

    final Map<StudyMood, int> moodCounts = {
      for (final StudyMood mood in StudyMood.values)
        mood: weeklyEntries.where((entry) => entry.mood == mood).length,
    };
    final StudyMood dominantMood = moodCounts.entries
        .reduce((left, right) => left.value >= right.value ? left : right)
        .key;
    final int streak = _calculateStreak(_state.sessionHistory);
    final String entryLabel = weeklyEntries.length == 1
        ? '1 journal entry'
        : '${weeklyEntries.length} journal entries';

    final bool positiveMood = dominantMood != StudyMood.stressed;
    final String title = positiveMood
        ? "You're doing great! 🎉"
        : 'A lighter load could help';
    final String message =
        'You’ve logged $entryLabel this week. Your most common mood is "${dominantMood.label}"${streak > 0 ? ' and your $streak-day focus streak is still active.' : '.'}';
    final String tip = switch (dominantMood) {
      StudyMood.happy =>
        'Tip: Keep repeating the study routines that make sessions feel enjoyable and sustainable.',
      StudyMood.motivated =>
        'Tip: Use that momentum on your highest-priority task before switching to easier work.',
      StudyMood.calm =>
        'Tip: Preserve the balance by pairing intense sessions with short breaks and quick reflections.',
      StudyMood.stressed =>
        'Tip: Break tomorrow’s workload into smaller blocks so progress feels clearer and less overwhelming.',
    };

    return InsightData(title: title, message: message, tip: tip);
  }

  Future<void> initialize() async {
    _isLoadingTasks = true;
    final StudyPersistenceData? persistence = await _repository
        .loadPersistence();
    if (_isDisposed) {
      return;
    }

    try {
      final List<StudyTask> firestoreTasks = await _repository.loadTasks();
      if (_isDisposed) {
        return;
      }

      FocusTimerState nextTimerState = _state.focusTimer;
      List<StudySessionRecord> restoredHistory = _seedData.sessionHistory;
      bool shouldRun = false;

      if (persistence != null) {
        final FocusPresetId selectedPresetId = persistence.selectedPresetId;
        final FocusPreset selectedPreset = _state.focusTimer.presets.firstWhere(
          (preset) => preset.id == selectedPresetId,
        );
        final int boundedSeconds = persistence.remainingSeconds
            .clamp(0, selectedPreset.duration.inSeconds)
            .toInt();
        restoredHistory = persistence.sessionHistory.isEmpty
            ? _seedData.sessionHistory
            : persistence.sessionHistory;
        Duration restoredRemaining = Duration(seconds: boundedSeconds);
        shouldRun = persistence.isRunning && restoredRemaining > Duration.zero;

        if (shouldRun) {
          final Duration elapsed = DateTime.now().difference(persistence.savedAt);
          final int nextSeconds = restoredRemaining.inSeconds - elapsed.inSeconds;

          if (nextSeconds <= 0) {
            restoredRemaining = Duration.zero;
            shouldRun = false;

            if (!selectedPreset.isBreak) {
              restoredHistory = [
                ...restoredHistory,
                StudySessionRecord(
                  date: persistence.savedAt.add(
                    Duration(seconds: persistence.remainingSeconds),
                  ),
                  duration: selectedPreset.duration,
                ),
              ];
            }
          } else {
            restoredRemaining = Duration(seconds: nextSeconds);
          }
        }

        nextTimerState = _state.focusTimer.copyWith(
          selectedPresetId: selectedPresetId,
          remaining: restoredRemaining,
          isRunning: shouldRun,
        );
      }

      _state = StudyState(
        focusTimer: nextTimerState,
        tasks: firestoreTasks,
        sessionHistory: restoredHistory,
      );
      _taskErrorMessage = null;
      _isLoadingTasks = false;

      if (shouldRun) {
        _startTicker();
      }

      notifyListeners();
      unawaited(_persistState());
    } on StudyTaskException catch (error) {
      if (_isDisposed) {
        return;
      }

      _state = _state.copyWith(tasks: const <StudyTask>[]);
      _taskErrorMessage = error.message;
      _isLoadingTasks = false;
      notifyListeners();
    } catch (_) {
      if (_isDisposed) {
        return;
      }

      _state = _state.copyWith(tasks: const <StudyTask>[]);
      _taskErrorMessage = 'We could not load your study tasks right now.';
      _isLoadingTasks = false;
      notifyListeners();
    }
  }

  void selectPreset(FocusPresetId presetId) {
    final FocusPreset preset = _state.focusTimer.presets.firstWhere(
      (item) => item.id == presetId,
    );

    _stopTicker();
    _state = _state.copyWith(
      focusTimer: _state.focusTimer.copyWith(
        selectedPresetId: presetId,
        remaining: preset.duration,
        isRunning: false,
      ),
    );
    notifyListeners();
    unawaited(_persistState());
  }

  void toggleTimer() {
    final FocusTimerState timerState = _state.focusTimer;

    if (timerState.isRunning) {
      _stopTicker();
      _state = _state.copyWith(
        focusTimer: timerState.copyWith(isRunning: false),
      );
      notifyListeners();
      unawaited(_persistState());
      return;
    }

    final FocusTimerState nextState = timerState.isComplete
        ? timerState.copyWith(
            remaining: timerState.selectedDuration,
            isRunning: true,
          )
        : timerState.copyWith(isRunning: true);
    _state = _state.copyWith(focusTimer: nextState);
    _startTicker();
    notifyListeners();
    unawaited(_persistState());
  }

  void resetTimer() {
    _stopTicker();
    _state = _state.copyWith(
      focusTimer: _state.focusTimer.copyWith(
        remaining: _state.focusTimer.selectedDuration,
        isRunning: false,
      ),
    );
    notifyListeners();
    unawaited(_persistState());
  }

  Future<void> toggleTask(String taskId) async {
    final StudyTask? currentTask = _state.tasks.cast<StudyTask?>().firstWhere(
      (task) => task?.id == taskId,
      orElse: () => null,
    );
    if (currentTask == null) {
      return;
    }

    final bool nextCompleted = !currentTask.isCompleted;
    final List<StudyTask> previousTasks = _state.tasks;
    final List<StudyTask> updatedTasks = previousTasks
        .map(
          (task) => task.id == taskId
              ? task.copyWith(isCompleted: nextCompleted)
              : task,
        )
        .toList(growable: false);

    _state = _state.copyWith(tasks: updatedTasks);
    _taskErrorMessage = null;
    notifyListeners();

    try {
      await _repository.updateTaskCompletion(taskId, nextCompleted);
    } on StudyTaskException catch (error) {
      if (_isDisposed) {
        return;
      }

      _state = _state.copyWith(tasks: previousTasks);
      _taskErrorMessage = error.message;
      notifyListeners();
    } catch (_) {
      if (_isDisposed) {
        return;
      }

      _state = _state.copyWith(tasks: previousTasks);
      _taskErrorMessage = 'We could not update this task right now.';
      notifyListeners();
    }
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueAt,
  }) async {
    await _repository.addTask(
      title: title,
      description: description,
      dueAt: dueAt,
    );
    await reloadTasks();
  }

  Future<void> reloadTasks() async {
    _isLoadingTasks = true;
    _taskErrorMessage = null;
    notifyListeners();

    try {
      final List<StudyTask> tasks = await _repository.loadTasks();
      if (_isDisposed) {
        return;
      }

      _state = _state.copyWith(tasks: tasks);
      _isLoadingTasks = false;
      notifyListeners();
    } on StudyTaskException catch (error) {
      if (_isDisposed) {
        return;
      }

      _taskErrorMessage = error.message;
      _isLoadingTasks = false;
      notifyListeners();
    } catch (_) {
      if (_isDisposed) {
        return;
      }

      _taskErrorMessage = 'We could not refresh your study tasks right now.';
      _isLoadingTasks = false;
      notifyListeners();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final int nextSeconds = _state.focusTimer.remaining.inSeconds - 1;

      if (nextSeconds <= 0) {
        _completeCurrentSession();
        return;
      }

      _state = _state.copyWith(
        focusTimer: _state.focusTimer.copyWith(
          remaining: Duration(seconds: nextSeconds),
        ),
      );
      notifyListeners();
      unawaited(_persistState());
    });
  }

  void _completeCurrentSession() {
    _stopTicker();

    final FocusTimerState timerState = _state.focusTimer;
    final List<StudySessionRecord> nextHistory =
        timerState.selectedPreset.isBreak
        ? _state.sessionHistory
        : [
            ..._state.sessionHistory,
            StudySessionRecord(
              date: DateTime.now(),
              duration: timerState.selectedDuration,
            ),
          ];

    _state = _state.copyWith(
      focusTimer: timerState.copyWith(
        remaining: Duration.zero,
        isRunning: false,
      ),
      sessionHistory: nextHistory,
    );
    notifyListeners();
    unawaited(_persistState());
  }

  int _calculateStreak(List<StudySessionRecord> records) {
    final Set<String> uniqueDays = records
        .map((record) => _dayKey(record.date))
        .toSet();
    DateTime currentDay = DateTime.now();
    int streak = 0;

    while (uniqueDays.contains(_dayKey(currentDay))) {
      streak += 1;
      currentDay = currentDay.subtract(const Duration(days: 1));
    }

    return streak;
  }

  bool _isBeforeCurrentWeek(DateTime date) {
    return date.isBefore(_startOfWeek(DateTime.now()));
  }

  DateTime _startOfWeek(DateTime date) {
    final DateTime day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  String _dayKey(DateTime date) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String();
  }

  String _formatHours(int totalMinutes) {
    final double hours = totalMinutes / 60;
    if (hours == hours.roundToDouble()) {
      return hours.toStringAsFixed(0);
    }

    return hours.toStringAsFixed(1);
  }

  Future<void> _persistState() {
    return _repository.savePersistence(
      timer: _state.focusTimer,
      tasks: _state.tasks,
      sessionHistory: _state.sessionHistory,
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopTicker();
    super.dispose();
  }
}
