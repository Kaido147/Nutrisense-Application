import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/services/goals_service.dart';

class SetGoalsPage extends ConsumerStatefulWidget {
  const SetGoalsPage({super.key});

  @override
  ConsumerState<SetGoalsPage> createState() => _SetGoalsPageState();
}

class _SetGoalsPageState extends ConsumerState<SetGoalsPage> {
  static const List<String> _studyOptions = [
    '4+ hours/day',
    '2-3 hours/day',
    '1-2 hours/day',
    'Flexible',
  ];
  static const List<String> _workoutOptions = [
    'Daily workout',
    '3-4x per week',
    '1-2x per week',
    'Casual',
  ];
  static const List<String> _wellnessOptions = [
    'Better sleep',
    'Reduce stress',
    'Healthy eating',
    'Mindfulness',
  ];

  final Set<String> _studyGoals = <String>{};
  final Set<String> _workoutGoals = <String>{};
  final Set<String> _wellnessGoals = <String>{};
  bool _isSaving = false;

  Future<void> _continue() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(goalsServiceProvider)
          .saveGoals(
            studyGoals: _selectedGoalsInOptionOrder(_studyOptions, _studyGoals),
            workoutGoals: _selectedGoalsInOptionOrder(
              _workoutOptions,
              _workoutGoals,
            ),
            wellnessGoals: _selectedGoalsInOptionOrder(
              _wellnessOptions,
              _wellnessGoals,
            ),
          );

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } on GoalsFlowException catch (error) {
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

  void _skip() {
    if (_isSaving) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
  }

  void _toggleGoal(Set<String> selectedGoals, String option) {
    setState(() {
      if (selectedGoals.contains(option)) {
        selectedGoals.remove(option);
      } else {
        selectedGoals.add(option);
      }
    });
  }

  List<String> _selectedGoalsInOptionOrder(
    List<String> options,
    Set<String> selectedGoals,
  ) {
    return options.where(selectedGoals.contains).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[600],

      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Set Your Goals',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D3557),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {},
                      ),
                    ],
                  ),

                  const Text(
                    'Help us personalize your experience by selecting your goals',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),

                  const SizedBox(height: 24),

                  // STUDY GOALS
                  _buildSectionHeader(Icons.menu_book_outlined, 'Study Goals'),
                  _buildGoalChips(_studyOptions, _studyGoals),

                  const SizedBox(height: 20),

                  // WORKOUT GOALS
                  _buildSectionHeader(Icons.fitness_center, 'Workout Goals'),
                  _buildGoalChips(_workoutOptions, _workoutGoals),

                  const SizedBox(height: 20),

                  // WELLNESS
                  _buildSectionHeader(Icons.favorite_border, 'Wellness Focus'),
                  _buildGoalChips(_wellnessOptions, _wellnessGoals),

                  const SizedBox(height: 32),

                  // BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _skip,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF1D3557)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Color(0xFF1D3557),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF283B6B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1D3557)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D3557),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalChips(List<String> options, Set<String> selectedGoals) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedGoals.contains(option);

        return GestureDetector(
          onTap: _isSaving ? null : () => _toggleGoal(selectedGoals, option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF283B6B)
                  : const Color(0xFFF1F4F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4A5568),
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
