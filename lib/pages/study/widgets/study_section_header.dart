import 'package:flutter/material.dart';

import '../study_theme.dart';

class StudySectionHeader extends StatelessWidget {
  const StudySectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.actionIcon,
  });

  final String title;
  final String? actionLabel;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: StudyTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (actionLabel != null || actionIcon != null)
          Row(
            children: [
              if (actionLabel != null)
                Text(
                  actionLabel!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (actionIcon != null) ...[
                if (actionLabel != null) const SizedBox(width: 8),
                Icon(actionIcon, size: 18, color: StudyTheme.textSecondary),
              ],
            ],
          ),
      ],
    );
  }
}
