import 'package:flutter/material.dart';

import '../study_models.dart';
import '../study_theme.dart';
import 'study_section_header.dart';

class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key, required this.data});

  final InsightData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudySectionHeader(title: 'Insights'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: StudyTheme.subtlePurple,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sentiment_very_satisfied_outlined,
                      size: 16,
                      color: StudyTheme.subtlePurpleText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.title,
                      style: const TextStyle(
                        color: StudyTheme.subtlePurpleText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.message,
                style: const TextStyle(
                  color: StudyTheme.subtlePurpleText,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                data.tip,
                style: const TextStyle(
                  color: StudyTheme.subtlePurpleText,
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
