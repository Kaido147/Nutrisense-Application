import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/providers/firebase_providers.dart';

import 'modals/add_task_modal.dart';
import 'modals/journal_entry_modal.dart';
import 'study/study_controller.dart';
import 'study/study_models.dart';
import 'study/study_repository.dart';
import 'study/study_theme.dart';
import 'study/widgets/focus_session_card.dart';
import 'study/widgets/insights_card.dart';
import 'study/widgets/journal_entry_card.dart';
import 'study/widgets/mood_summary_card.dart';
import 'study/widgets/schedule_section.dart';
import 'study/widgets/study_section_header.dart';
import 'study/widgets/study_tab_switcher.dart';
import 'study/widgets/task_section.dart';
import 'study/widgets/weekly_stats_card.dart';

class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key});

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  StudyTab _selectedTab = StudyTab.focusMode;
  late final StudyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StudyController(repository: StudyRepository());
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(schedulesProvider);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: StudyTheme.pageBackground,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StudyHeader(
                  selectedTab: _selectedTab,
                  onTabSelected: (tab) => setState(() => _selectedTab = tab),
                ),
                const SizedBox(height: 42),
                Padding(
                  padding: StudyTheme.pagePadding,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _selectedTab == StudyTab.focusMode
                        ? _FocusModeView(
                            key: const ValueKey('focus-mode'),
                            controller: _controller,
                            schedulesAsync: schedulesAsync,
                          )
                        : _JournalMoodView(
                            key: const ValueKey('journal-mood'),
                            controller: _controller,
                          ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StudyHeader extends StatelessWidget {
  const _StudyHeader({required this.selectedTab, required this.onTabSelected});

  final StudyTab selectedTab;
  final ValueChanged<StudyTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 26,
            left: StudyTheme.horizontalPadding,
            right: StudyTheme.horizontalPadding,
            bottom: 52,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Study Focus',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Deep work mode activated',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: StudyTheme.horizontalPadding,
          right: StudyTheme.horizontalPadding,
          bottom: -24,
          child: StudyTabSwitcher(
            selectedTab: selectedTab,
            onTabSelected: onTabSelected,
          ),
        ),
      ],
    );
  }
}

class _FocusModeView extends StatelessWidget {
  const _FocusModeView({
    super.key,
    required this.controller,
    required this.schedulesAsync,
  });

  final StudyController controller;
  final AsyncValue<List<ClassSchedule>> schedulesAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FocusSessionCard(
          timerState: controller.state.focusTimer,
          onToggleTimer: controller.toggleTimer,
          onResetTimer: controller.resetTimer,
          onPresetSelected: controller.selectPreset,
        ),
        const SizedBox(height: 24),
        TaskSection(
          tasks: controller.state.tasks,
          onTaskToggle: (taskId) {
            controller.toggleTask(taskId);
          },
          onAddTask: () => AddTaskModal.show(
            context,
            onSave:
                ({
                  required String title,
                  String? description,
                  DateTime? dueAt,
                }) {
                  return controller.addTask(
                    title: title,
                    description: description,
                    dueAt: dueAt,
                  );
                },
          ),
          isLoading: controller.isLoadingTasks,
          errorMessage: controller.taskErrorMessage,
        ),
        const SizedBox(height: 24),
        ScheduleSection(schedulesAsync: schedulesAsync),
        const SizedBox(height: 24),
        WeeklyStatsCard(stats: controller.weeklyStats),
      ],
    );
  }
}

class _JournalMoodView extends ConsumerWidget {
  const _JournalMoodView({super.key, required this.controller});

  final StudyController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        entriesAsync.maybeWhen(
          data: (entries) => MoodSummaryCard(items: _moodSummaryItems(entries)),
          orElse: () => MoodSummaryCard(items: _moodSummaryItems(const [])),
        ),
        const SizedBox(height: 20),
        StudySectionHeader(
          title: 'Recent Entries',
          actionLabel: '+ New Entry',
          onActionTap: () => JournalEntryModal.show(context),
        ),
        const SizedBox(height: 12),
        entriesAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return const _EmptyJournalState();
            }
            return Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  JournalEntryCard(
                    entry: entries[i],
                    onEdit: () =>
                        JournalEntryModal.show(context, entry: entries[i]),
                    onDelete: () => _confirmDelete(context, ref, entries[i]),
                  ),
                  if (i != entries.length - 1) const SizedBox(height: 14),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text(
            'We could not load your journal entries.',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
        const SizedBox(height: 24),
        InsightsCard(data: controller.insights),
      ],
    );
  }

  List<MoodSummaryItem> _moodSummaryItems(List<JournalRecord> entries) {
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday));
    final Map<StudyMood, int> counts = {
      for (final mood in StudyMood.values) mood: 0,
    };

    for (final entry in entries) {
      if (entry.entryDate.isBefore(startOfWeek)) continue;
      final mood = _toStudyMood(entry.mood);
      counts.update(mood, (value) => value + 1);
    }

    return StudyMood.values
        .map((mood) => MoodSummaryItem(mood: mood, count: counts[mood] ?? 0))
        .toList(growable: false);
  }

  StudyMood _toStudyMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return StudyMood.happy;
      case 'motivated':
        return StudyMood.motivated;
      case 'stressed':
      case 'sad':
      case 'tired':
        return StudyMood.stressed;
      default:
        return StudyMood.calm;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    JournalRecord entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete journal entry?'),
        content: Text('Delete "${entry.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(prototypeDataServiceProvider).deleteJournalEntry(entry.id);
    ref.invalidate(journalEntriesProvider);
  }
}

class _EmptyJournalState extends StatelessWidget {
  const _EmptyJournalState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: StudyTheme.softShadow,
      ),
      child: const Text(
        'No journal entries yet. Add one to start tracking your mood and reflections.',
        style: TextStyle(color: StudyTheme.textSecondary),
      ),
    );
  }
}
