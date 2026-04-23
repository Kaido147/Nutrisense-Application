import 'package:flutter/material.dart';

import 'modals/add_task_modal.dart';
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

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: StudyTheme.navyBlue,
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Study Focus',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Deep work mode activated',
                style: TextStyle(
                  color: StudyTheme.goldTan,
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
  const _FocusModeView({super.key, required this.controller});

  final StudyController controller;

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
            onSave: ({
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
        ScheduleSection(scheduleItems: controller.scheduleItems),
        const SizedBox(height: 24),
        WeeklyStatsCard(stats: controller.weeklyStats),
      ],
    );
  }
}

class _JournalMoodView extends StatelessWidget {
  const _JournalMoodView({super.key, required this.controller});

  final StudyController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MoodSummaryCard(items: controller.moodSummaryItems),
        const SizedBox(height: 20),
        const StudySectionHeader(
          title: 'Recent Entries',
          actionLabel: '+ New Entry',
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < controller.recentEntries.length; i++) ...[
          JournalEntryCard(entry: controller.recentEntries[i]),
          if (i != controller.recentEntries.length - 1)
            const SizedBox(height: 14),
        ],
        const SizedBox(height: 24),
        InsightsCard(data: controller.insights),
      ],
    );
  }
}
