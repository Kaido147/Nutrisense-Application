import 'package:flutter/material.dart';

import '../study_models.dart';
import '../study_theme.dart';
import 'study_section_header.dart';

class TaskSection extends StatelessWidget {
  const TaskSection({
    super.key,
    required this.tasks,
    required this.onTaskToggle,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<StudyTask> tasks;
  final ValueChanged<String> onTaskToggle;
  final VoidCallback onAddTask;
  final ValueChanged<StudyTask> onEditTask;
  final ValueChanged<StudyTask> onDeleteTask;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudySectionHeader(
          title: "Today's Tasks",
          actionLabel: 'Add Task',
          onActionTap: onAddTask,
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (errorMessage != null)
          _TaskMessageCard(message: errorMessage!, icon: Icons.error_outline)
        else if (tasks.isEmpty)
          const _TaskMessageCard(
            message: 'No study tasks yet. Tap Add Task to create one.',
            icon: Icons.check_circle_outline,
          )
        else
          Column(
            children: tasks
                .map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TaskCard(
                      task: task,
                      onTap: () => onTaskToggle(task.id),
                      onEdit: () => onEditTask(task),
                      onDelete: () => onDeleteTask(task),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _TaskMessageCard extends StatelessWidget {
  const _TaskMessageCard({required this.message, required this.icon});

  final String message;
  final IconData icon;

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
      child: Row(
        children: [
          Icon(icon, color: StudyTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: StudyTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final StudyTask task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Color titleColor = task.isCompleted
        ? StudyTheme.textSecondary
        : StudyTheme.textPrimary;

    return Opacity(
      opacity: task.isCompleted ? 0.72 : 1,
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
            InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 24,
                height: 24,
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
            PopupMenuButton<_TaskAction>(
              icon: const Icon(
                Icons.more_horiz,
                color: StudyTheme.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (action) {
                switch (action) {
                  case _TaskAction.edit:
                    onEdit();
                  case _TaskAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: _TaskAction.edit, child: Text('Edit')),
                PopupMenuItem(value: _TaskAction.delete, child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _TaskAction { edit, delete }
