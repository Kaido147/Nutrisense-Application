import 'package:nutrisense/models/prototype_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../study_theme.dart';
import 'study_section_header.dart';

class ScheduleSection extends StatelessWidget {
  const ScheduleSection({super.key, required this.schedulesAsync});

  final AsyncValue<List<ClassSchedule>> schedulesAsync;

  @override
  Widget build(BuildContext context) {
    return schedulesAsync.when(
      data: (schedules) => _ScheduleContent(schedules: schedules),
      loading: () => const _ScheduleShell(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const _ScheduleShell(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'We could not load your class schedule.',
              style: TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleContent extends StatelessWidget {
  const _ScheduleContent({required this.schedules});

  final List<ClassSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    final today = weekdayName();
    final todaySchedules =
        schedules.where((item) => item.dayOfWeek == today).toList()
          ..sort((a, b) => a.startTimeMinutes.compareTo(b.startTimeMinutes));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScheduleShell(
          child: todaySchedules.isEmpty
              ? _ScheduleEmptyMessage(
                  message: schedules.isEmpty
                      ? 'No classes have been added yet.'
                      : 'No classes scheduled for today.',
                )
              : Column(
                  children: todaySchedules
                      .map((item) => _ScheduleTile(item: item))
                      .toList(),
                ),
        ),
        const SizedBox(height: 18),
        const StudySectionHeader(
          title: 'All Classes',
          actionIcon: Icons.calendar_view_week_outlined,
        ),
        const SizedBox(height: 12),
        _ScheduleCard(
          child: schedules.isEmpty
              ? const _ScheduleEmptyMessage(
                  message: 'Added classes will appear here.',
                )
              : Column(
                  children: schedules
                      .map((item) => _ScheduleTile(item: item, showDay: true))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _ScheduleShell extends StatelessWidget {
  const _ScheduleShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudySectionHeader(
          title: "Today's Schedule",
          actionIcon: Icons.calendar_today_outlined,
        ),
        const SizedBox(height: 12),
        _ScheduleCard(child: child),
      ],
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.item, this.showDay = false});

  final ClassSchedule item;
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (showDay) item.dayOfWeek,
                    item.location.isEmpty ? 'No location set' : item.location,
                  ].join(' - '),
                  style: const TextStyle(
                    color: StudyTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.timeLabel,
            style: const TextStyle(
              color: StudyTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color get accentColor {
    switch (item.color) {
      case 'purple':
        return const Color(0xFFA72EFF);
      case 'green':
        return const Color(0xFF17C45B);
      case 'gold':
        return const Color(0xFFD6B66E);
      default:
        return const Color(0xFF2F65FF);
    }
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: StudyTheme.softShadow,
      ),
      child: child,
    );
  }
}

class _ScheduleEmptyMessage extends StatelessWidget {
  const _ScheduleEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: StudyTheme.textSecondary, fontSize: 13),
        ),
      ),
    );
  }
}
