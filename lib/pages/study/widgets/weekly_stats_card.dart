import 'package:flutter/material.dart';

import '../study_models.dart';
import '../study_theme.dart';
import 'study_section_header.dart';

class WeeklyStatsCard extends StatelessWidget {
  const WeeklyStatsCard({super.key, required this.stats});

  final List<WeeklyStat> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudySectionHeader(title: 'This Week'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF6EFE5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: StudyTheme.cardBorder),
          ),
          child: Row(
            children: stats
                .map((stat) => Expanded(child: _StatTile(stat: stat)))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final WeeklyStat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: StudyTheme.softShadow,
          ),
          child: Icon(stat.icon, color: StudyTheme.navyBlue, size: 22),
        ),
        const SizedBox(height: 12),
        Text(
          stat.value,
          style: const TextStyle(
            color: StudyTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stat.label,
          style: const TextStyle(color: StudyTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
