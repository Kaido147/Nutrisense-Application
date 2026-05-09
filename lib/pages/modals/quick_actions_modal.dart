import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/models/workout_catalog.dart';
import 'package:nutrisense/pages/study/study_repository.dart';
import 'package:nutrisense/providers/firebase_providers.dart';

import 'add_class_modal.dart';
import 'log_meal_modal.dart';
import 'add_task_modal.dart';
import 'journal_entry_modal.dart';

class QuickActionsModal extends ConsumerStatefulWidget {
  const QuickActionsModal({super.key});

  @override
  ConsumerState<QuickActionsModal> createState() => _QuickActionsModalState();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => const QuickActionsModal(),
    );
  }
}

class _QuickActionsModalState extends ConsumerState<QuickActionsModal> {
  static const Color _navyBlue = Color(0xFF1E2A4A);
  static const Color _goldTan = Color(0xFFD4B896);
  static const Color _brightBlue = Color(0xFF2563EB);
  static const Color _brightGreen = Color(0xFF22C55E);
  static const Color _brightPurple = Color(0xFFAF27F5);
  static const Color _lightGray = Color(0xFFF5F5F5);

  final TextEditingController _workoutName = TextEditingController();
  final TextEditingController _duration = TextEditingController();

  bool _showWorkoutLog = false;
  bool _isSavingWorkout = false;
  DateTime _workoutDate = DateTime.now();
  WorkoutCategory _workoutCategory = workoutCatalog.first;
  String _intensity = 'Moderate';
  final Set<String> _selectedExerciseIds = <String>{};

  @override
  void dispose() {
    _workoutName.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * (_showWorkoutLog ? 0.82 : 0.65);

    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
        ),
        // Bottom sheet content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: modalHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: _showWorkoutLog
                ? _buildWorkoutLogView()
                : _buildActionGridView(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionGridView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModalHeader(
              title: 'Quick Actions',
              subtitle: 'What would you like to add?',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Add Class',
                    icon: Icons.backpack_outlined,
                    color: _brightBlue,
                    onTap: () {
                      AddClassModal.show(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: 'Log Workout',
                    icon: Icons.favorite_outline,
                    color: _goldTan,
                    onTap: () => setState(() => _showWorkoutLog = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Log Meal',
                    icon: Icons.restaurant_menu_outlined,
                    color: _brightGreen,
                    onTap: () {
                      LogMealModal.show(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: 'Add Task',
                    icon: Icons.check_circle_outline,
                    color: _brightPurple,
                    onTap: () {
                      _showAddTaskModal();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 72) / 2,
                  child: _buildActionButton(
                    label: 'Journal Entry',
                    icon: Icons.menu_book_outlined,
                    color: _navyBlue,
                    onTap: () {
                      JournalEntryModal.show(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: _lightGray,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTaskModal() {
    return AddTaskModal.show(
      context,
      onSave:
          ({
            required String title,
            String? description,
            DateTime? dueAt,
          }) async {
            await StudyRepository().addTask(
              title: title,
              description: description,
              dueAt: dueAt,
            );
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(todayQuestsProvider);
          },
    );
  }

  Widget _buildWorkoutLogView() {
    final selectedExercises = _selectedExercises;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          child: _buildModalHeader(
            title: 'Log Workout',
            subtitle: 'Record your recent activity and track progress.',
            leading: IconButton(
              onPressed: () => setState(() => _showWorkoutLog = false),
              icon: const Icon(Icons.arrow_back),
              color: _navyBlue,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            onClose: () => Navigator.pop(context),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ModalTextField(
                  label: 'Workout Name',
                  controller: _workoutName,
                  hint: 'Morning Run',
                  icon: Icons.fitness_center_outlined,
                ),
                const SizedBox(height: 14),
                _CategoryDropdown(
                  category: _workoutCategory,
                  onChanged: (category) {
                    setState(() {
                      _workoutCategory = category;
                      _selectedExerciseIds.clear();
                    });
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        date: _workoutDate,
                        onTap: _selectWorkoutDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModalTextField(
                        label: 'Duration',
                        controller: _duration,
                        hint: '45',
                        icon: Icons.schedule_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _ModalLabel('Intensity Level'),
                const SizedBox(height: 10),
                _IntensitySelector(
                  value: _intensity,
                  onChanged: (value) => setState(() => _intensity = value),
                  gold: _goldTan,
                  navy: _navyBlue,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Exercises',
                        style: TextStyle(
                          color: _navyBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showExercisePicker,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(foregroundColor: _navyBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (selectedExercises.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _lightGray,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Add exercises from the selected workout type.',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  )
                else
                  ...selectedExercises.map(_buildSelectedExerciseTile),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isSavingWorkout
                      ? null
                      : () => setState(() => _showWorkoutLog = false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _lightGray,
                    foregroundColor: const Color(0xFF6B7280),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextButton(
                  onPressed: _isSavingWorkout ? null : _saveWorkoutLog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _goldTan,
                    foregroundColor: _navyBlue,
                  ),
                  child: _isSavingWorkout
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Log Workout',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModalHeader({
    required String title,
    required String subtitle,
    required VoidCallback onClose,
    Widget? leading,
  }) {
    return Row(
      children: [
        if (leading != null) ...[leading, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _navyBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onClose,
          child: const Icon(Icons.close, color: _navyBlue, size: 24),
        ),
      ],
    );
  }

  List<WorkoutExercise> get _selectedExercises {
    return _workoutCategory.exercises
        .where((exercise) => _selectedExerciseIds.contains(exercise.id))
        .toList(growable: false);
  }

  Future<void> _selectWorkoutDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _workoutDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _workoutDate = picked);
  }

  Future<void> _showExercisePicker() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Exercise',
                style: TextStyle(
                  color: _navyBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _workoutCategory.exercises.map((exercise) {
                    final selected = _selectedExerciseIds.contains(exercise.id);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: _lightGray,
                        child: Icon(
                          _iconForExercise(exercise.name),
                          color: _navyBlue,
                        ),
                      ),
                      title: Text(
                        exercise.name,
                        style: const TextStyle(
                          color: _navyBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${exercise.sets} sets • ${exercise.repsOrDuration}',
                      ),
                      trailing: Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.add_circle_outline,
                        color: selected ? Colors.green : _navyBlue,
                      ),
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedExerciseIds.remove(exercise.id);
                          } else {
                            _selectedExerciseIds.add(exercise.id);
                          }
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedExerciseTile(WorkoutExercise exercise) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _lightGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFD8E2FF),
              child: Icon(_iconForExercise(exercise.name), color: _navyBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: _navyBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${exercise.sets} sets • ${exercise.repsOrDuration}',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() => _selectedExerciseIds.remove(exercise.id));
              },
              icon: const Icon(Icons.delete_outline),
              color: const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWorkoutLog() async {
    final title = _workoutName.text.trim();
    final duration = int.tryParse(_duration.text.trim());
    if (title.isEmpty || duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a workout name and valid duration.')),
      );
      return;
    }

    final exerciseNames = _selectedExercises
        .map((exercise) => exercise.name)
        .join(', ');

    setState(() => _isSavingWorkout = true);
    try {
      await ref
          .read(prototypeDataServiceProvider)
          .logWorkoutActivity(
            title: title,
            type: _workoutCategory.name,
            dateKey: todayKey(_workoutDate),
            durationMinutes: duration,
            intensity: _intensity,
            notes: exerciseNames.isEmpty ? null : exerciseNames,
          );
      ref.invalidate(workoutActivitiesProvider);
      ref.invalidate(dashboardStatsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Workout logged.')));
    } catch (error, stackTrace) {
      debugPrint('Failed to log workout from Quick Actions: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not log this workout.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingWorkout = false);
    }
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalLabel extends StatelessWidget {
  const _ModalLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF1E2A4A),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ModalTextField extends StatelessWidget {
  const _ModalTextField({
    required this.label,
    required this.controller,
    required this.hint,
    this.icon,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModalLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          cursorColor: const Color(0xFF1E2A4A),
          style: const TextStyle(
            color: Color(0xFF1E2A4A),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF7A8190),
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: icon == null
                ? null
                : Icon(icon, color: const Color(0xFF6B7280)),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: Color(0xFFD4B896)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.category, required this.onChanged});

  final WorkoutCategory category;
  final ValueChanged<WorkoutCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ModalLabel('Workout Type'),
        const SizedBox(height: 8),
        DropdownButtonFormField<WorkoutCategory>(
          initialValue: category,
          isExpanded: true,
          dropdownColor: Colors.white,
          iconEnabledColor: const Color(0xFF1E2A4A),
          style: const TextStyle(
            color: Color(0xFF1E2A4A),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          items: workoutCatalog
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      color: Color(0xFF1E2A4A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: Color(0xFFD4B896)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ModalLabel('Date'),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF6B7280),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatShortDate(date),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1E2A4A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IntensitySelector extends StatelessWidget {
  const _IntensitySelector({
    required this.value,
    required this.onChanged,
    required this.gold,
    required this.navy,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final Color gold;
  final Color navy;

  @override
  Widget build(BuildContext context) {
    const levels = <String>['Light', 'Moderate', 'Intense'];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: levels.map((level) {
          final selected = value == level;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(level),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected ? gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  level,
                  style: TextStyle(
                    color: selected ? navy : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

String _formatShortDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

IconData _iconForExercise(String name) {
  final value = name.toLowerCase();
  if (value.contains('plank') || value.contains('crunch')) {
    return Icons.accessibility_new;
  }
  if (value.contains('jump') ||
      value.contains('jog') ||
      value.contains('run')) {
    return Icons.directions_run;
  }
  if (value.contains('stretch') || value.contains('pose')) {
    return Icons.self_improvement;
  }
  if (value.contains('squat') || value.contains('lunge')) {
    return Icons.airline_seat_legroom_extra;
  }
  return Icons.fitness_center;
}
