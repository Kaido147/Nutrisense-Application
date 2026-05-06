import 'package:flutter/material.dart';

import '../study_models.dart';
import '../study_theme.dart';
import 'study_section_header.dart';

class ScheduleSection extends StatelessWidget {
  const ScheduleSection({super.key, required this.scheduleItems});

  final List<ScheduleItem> scheduleItems;

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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: StudyTheme.softShadow,
          ),
          child: Column(
            children: scheduleItems
                .map((item) => _ScheduleTile(item: item))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.item});

  final ScheduleItem item;

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
              color: item.accentColor,
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
                  item.room,
                  style: const TextStyle(
                    color: StudyTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.time,
            style: TextStyle(
              color: primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
