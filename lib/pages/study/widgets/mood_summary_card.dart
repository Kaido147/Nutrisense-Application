import 'package:flutter/material.dart';

import '../study_models.dart';
import '../study_theme.dart';

class MoodSummaryCard extends StatelessWidget {
  const MoodSummaryCard({super.key, required this.items});

  final List<MoodSummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: StudyTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "This Week's Mood",
            style: TextStyle(
              color: StudyTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items
                .map(
                  (item) => Column(
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 10),
                      Text(
                        item.countLabel,
                        style: const TextStyle(
                          color: StudyTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
