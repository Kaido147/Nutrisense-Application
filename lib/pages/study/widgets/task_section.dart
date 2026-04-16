import 'package:flutter/material.dart';

import '../study_models.dart';
import '../study_theme.dart';
import 'study_section_header.dart';

class TaskSection extends StatelessWidget {
  const TaskSection({
    super.key,
    required this.tasks,
    required this.onTaskToggle,
  });

  final List<StudyTask> tasks;
  final ValueChanged<String> onTaskToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudySectionHeader(
          title: "Today's Tasks",
          actionLabel: 'Add Task',
        ),
        const SizedBox(height: 12),
        Column(
          children: tasks
              .map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TaskCard(
                    task: task,
                    onTap: () => onTaskToggle(task.id),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onTap});

  final StudyTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color titleColor = task.isCompleted
        ? StudyTheme.textSecondary
        : StudyTheme.textPrimary;

    return Opacity(
      opacity: task.isCompleted ? 0.72 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: StudyTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: task.isCompleted
                      ? StudyTheme.chipBackground
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.isCompleted
                        ? StudyTheme.textSecondary
                        : StudyTheme.cardBorder,
                  ),
                ),
                child: task.isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: StudyTheme.textSecondary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.subject,
                      style: const TextStyle(
                        color: StudyTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
