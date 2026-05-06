import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/pages/modals/profile/profile_modal_shell.dart';
import 'package:nutrisense/providers/firebase_providers.dart';

class ReminderSettingsModal extends ConsumerStatefulWidget {
  const ReminderSettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return ProfileModalShell.show<void>(
      context: context,
      builder: (context) => const ReminderSettingsModal(),
    );
  }

  @override
  ConsumerState<ReminderSettingsModal> createState() =>
      _ReminderSettingsModalState();
}

class _ReminderSettingsModalState extends ConsumerState<ReminderSettingsModal> {
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_ensureReminders);
  }

  Future<void> _ensureReminders() async {
    try {
      await ref.read(prototypeDataServiceProvider).ensureDefaultReminders();
      ref.invalidate(remindersProvider);
    } catch (_) {
      _errorMessage = 'We could not prepare reminder settings.';
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _toggleReminder(AppReminder reminder, bool enabled) async {
    try {
      await ref
          .read(prototypeDataServiceProvider)
          .setReminderEnabled(reminder.id, enabled);
      ref.invalidate(remindersProvider);
      ref.invalidate(enabledRemindersProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not update this reminder.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(remindersProvider);

    return ProfileModalShell(
      title: 'Reminder Settings',
      footer: const SizedBox.shrink(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage your hydration, sleep, workout, mental break, and notification preferences.',
            style: TextStyle(color: Color(0xFF667085), height: 1.4),
          ),
          const SizedBox(height: 18),
          if (_isInitializing)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
            )
          else
            remindersAsync.when(
              data: (reminders) {
                if (reminders.isEmpty) {
                  return const _EmptyReminderState();
                }
                return Column(
                  children: reminders
                      .map(
                        (reminder) => _ReminderTile(
                          reminder: reminder,
                          onChanged: (value) =>
                              _toggleReminder(reminder, value),
                        ),
                      )
                      .toList(growable: false),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text(
                'We could not load reminder settings.',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder, required this.onChanged});

  final AppReminder reminder;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E6EF)),
      ),
      child: SwitchListTile(
        value: reminder.enabled,
        activeThumbColor: const Color(0xFF24376B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          reminder.title,
          style: const TextStyle(
            color: Color(0xFF24376B),
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(reminder.timeLabel),
        secondary: CircleAvatar(
          backgroundColor: const Color(0xFFF8F3E8),
          child: Icon(_iconFor(reminder.type), color: const Color(0xFFD6B66E)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'hydration':
        return Icons.water_drop_outlined;
      case 'sleep':
        return Icons.bedtime_outlined;
      case 'workout':
        return Icons.fitness_center_outlined;
      case 'mentalBreak':
        return Icons.self_improvement_outlined;
      case 'notifications':
        return Icons.notifications_none;
      case 'study':
        return Icons.menu_book_outlined;
      default:
        return Icons.restaurant_menu_outlined;
    }
  }
}

class _EmptyReminderState extends StatelessWidget {
  const _EmptyReminderState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Text(
        'No reminder preferences have been created yet.',
        style: TextStyle(color: Color(0xFF667085)),
      ),
    );
  }
}
