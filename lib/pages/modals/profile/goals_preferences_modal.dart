import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/user_profile.dart';
import 'package:nutrisense/pages/modals/profile/profile_modal_shell.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/services/profile_service.dart';

class GoalsPreferencesModal extends ConsumerStatefulWidget {
  const GoalsPreferencesModal({super.key, required this.profile});

  final UserProfile profile;

  static Future<void> show(BuildContext context, UserProfile profile) {
    return ProfileModalShell.show<void>(
      context: context,
      builder: (context) => GoalsPreferencesModal(profile: profile),
    );
  }

  @override
  ConsumerState<GoalsPreferencesModal> createState() =>
      _GoalsPreferencesModalState();
}

class _GoalsPreferencesModalState extends ConsumerState<GoalsPreferencesModal> {
  late double _weeklyHours;
  late int _focusMinutes;
  late int _breakMinutes;
  late double _workoutDaysPerWeek;
  late double _dailyWaterGlasses;
  late double _targetSleepHours;
  late bool _studyReminders;
  late bool _workoutReminders;
  late bool _mealReminders;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _weeklyHours = widget.profile.editorStudyWeeklyHours.toDouble();
    _focusMinutes = widget.profile.editorFocusMinutes;
    _breakMinutes = widget.profile.editorBreakMinutes;
    _workoutDaysPerWeek = widget.profile.editorWorkoutDaysPerWeek.toDouble();
    _dailyWaterGlasses = widget.profile.editorDailyWaterGlasses.toDouble();
    _targetSleepHours = widget.profile.editorTargetSleepHours.toDouble();
    _studyReminders = widget.profile.editorStudyReminders;
    _workoutReminders = widget.profile.editorWorkoutReminders;
    _mealReminders = widget.profile.editorMealReminders;
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(profileServiceProvider)
          .updatePreferences(
            weeklyHours: _weeklyHours.round(),
            focusMinutes: _focusMinutes,
            breakMinutes: _breakMinutes,
            workoutDaysPerWeek: _workoutDaysPerWeek.round(),
            dailyWaterGlasses: _dailyWaterGlasses.round(),
            targetSleepHours: _targetSleepHours.round(),
            studyReminders: _studyReminders,
            workoutReminders: _workoutReminders,
            mealReminders: _mealReminders,
          );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } on ProfileFlowException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileModalShell(
      title: 'Goals & Preferences',
      child: Column(
        children: [
          _sectionCard(
            icon: Icons.menu_book_outlined,
            iconColor: const Color(0xFF2F477A),
            backgroundColor: const Color(0xFFF6F8FC),
            title: 'Study Goals',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sliderRow(
                  label: 'Weekly Study Hours',
                  valueLabel: '${_weeklyHours.round()}h',
                  min: 5,
                  max: 40,
                  activeColor: const Color(0xFF2F477A),
                  currentValue: _weeklyHours,
                  onChanged: (value) {
                    setState(() {
                      _weeklyHours = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _numberField(
                        label: 'Focus Time (min)',
                        value: _focusMinutes,
                        onChanged: (value) {
                          setState(() {
                            _focusMinutes = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _numberField(
                        label: 'Break Time (min)',
                        value: _breakMinutes,
                        onChanged: (value) {
                          setState(() {
                            _breakMinutes = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionCard(
            icon: Icons.fitness_center_outlined,
            iconColor: const Color(0xFFD1B16E),
            backgroundColor: const Color(0xFFFCF8EF),
            title: 'Workout Goals',
            child: _sliderRow(
              label: 'Workout Days Per Week',
              valueLabel: '${_workoutDaysPerWeek.round()}',
              min: 1,
              max: 7,
              activeColor: const Color(0xFFD1B16E),
              currentValue: _workoutDaysPerWeek,
              onChanged: (value) {
                setState(() {
                  _workoutDaysPerWeek = value;
                });
              },
            ),
          ),
          const SizedBox(height: 18),
          _sectionCard(
            icon: Icons.local_fire_department_outlined,
            iconColor: const Color(0xFF00A63E),
            backgroundColor: const Color(0xFFEFFCf4),
            title: 'Health Goals',
            child: Column(
              children: [
                _sliderRow(
                  label: 'Daily Water Intake (glasses)',
                  valueLabel: '${_dailyWaterGlasses.round()}',
                  min: 2,
                  max: 12,
                  activeColor: const Color(0xFF00A63E),
                  currentValue: _dailyWaterGlasses,
                  onChanged: (value) {
                    setState(() {
                      _dailyWaterGlasses = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _sliderRow(
                  label: 'Target Sleep Hours',
                  valueLabel: '${_targetSleepHours.round()}h',
                  min: 4,
                  max: 10,
                  activeColor: const Color(0xFF00A63E),
                  currentValue: _targetSleepHours,
                  onChanged: (value) {
                    setState(() {
                      _targetSleepHours = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionCard(
            icon: Icons.access_time_outlined,
            iconColor: const Color(0xFF8A2CFF),
            backgroundColor: const Color(0xFFF7EFFF),
            title: 'Reminder Preferences',
            child: Column(
              children: [
                _reminderTile(
                  label: 'Study Reminders',
                  value: _studyReminders,
                  onTap: () {
                    setState(() {
                      _studyReminders = !_studyReminders;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _reminderTile(
                  label: 'Workout Reminders',
                  value: _workoutReminders,
                  onTap: () {
                    setState(() {
                      _workoutReminders = !_workoutReminders;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _reminderTile(
                  label: 'Meal Reminders',
                  value: _mealReminders,
                  onTap: () {
                    setState(() {
                      _mealReminders = !_mealReminders;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: const Color(0xFFF1F3F7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF525D73),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25396F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Goals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF24376B),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required String valueLabel,
    required double min,
    required double max,
    required Color activeColor,
    required double currentValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF24376B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: activeColor,
                  inactiveTrackColor: const Color(0xFF4B4B4B),
                  thumbColor: activeColor,
                  overlayColor: activeColor.withValues(alpha: 0.12),
                  trackHeight: 7,
                ),
                child: Slider(
                  value: currentValue.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: (max - min).round(),
                  onChanged: _isSaving ? null : onChanged,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 82,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFE0E4EC)),
              ),
              child: Text(
                valueLabel,
                style: const TextStyle(
                  color: Color(0xFF24376B),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numberField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF24376B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE0E4EC)),
          ),
          child: Row(
            children: [
              _stepperButton(
                icon: Icons.remove,
                onTap: _isSaving || value <= 1 ? null : () => onChanged(value - 1),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      color: Color(0xFF24376B),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _stepperButton(
                icon: Icons.add,
                onTap: _isSaving ? null : () => onChanged(value + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color: onTap == null ? const Color(0xFFB9C0D0) : const Color(0xFF24376B),
          size: 18,
        ),
      ),
    );
  }

  Widget _reminderTile({
    required String label,
    required bool value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSaving ? null : onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF24376B),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF2F477A) : const Color(0xFF3F3F3F),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
