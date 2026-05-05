import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'nutrition_tab.dart';

class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({super.key});

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> {
  int _selectedTab = 0;
  bool _isGenerating = false;

  static const Color _navyBlue = Color(0xFF273967);
  static const Color _lightBg = Color(0xFFF5F0EA);
  static const Color _cream = Color(0xFFF5F0E9);

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(workoutPlansProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <WorkoutPlan>[],
        );
    final healthProfile = ref.watch(healthProfileProvider).maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    final schedules = ref.watch(schedulesProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <ClassSchedule>[],
        );
    final currentPlan = plans.isEmpty ? null : plans.first;

    return Scaffold(
      backgroundColor: _lightBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderStack(context),
            const SizedBox(height: 40),
            if (_selectedTab == 0)
              ..._buildWorkoutContent(currentPlan, healthProfile, schedules),
            if (_selectedTab == 1) const NutritionTab(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWorkoutContent(
    WorkoutPlan? plan,
    HealthProfile? healthProfile,
    List<ClassSchedule> schedules,
  ) {
    return [
      _workoutCard(plan, healthProfile, schedules),
      const SizedBox(height: 24),
      _exerciseCard(plan),
      const SizedBox(height: 12),
      _weeklyPlan(plan),
    ];
  }

  Widget _workoutCard(
    WorkoutPlan? plan,
    HealthProfile? healthProfile,
    List<ClassSchedule> schedules,
  ) {
    final progress = plan == null
        ? 0.0
        : plan.completed
        ? 1.0
        : 0.35;
    final title = plan?.title ?? 'Generate Today\'s Plan';
    final subtitle = plan == null
        ? 'Based on your schedule and health profile'
        : '${plan.durationMinutes} minutes • ${plan.intensity}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            'Today\'s Routine',
            style: TextStyle(
              color: _navyBlue,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 21),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _cream.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: _navyBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _navyBlue,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Opacity(
                          opacity: 0.65,
                          child: Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _navyBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.4),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: _navyBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGenerating
                      ? null
                      : () => _handleWorkoutAction(
                            plan,
                            healthProfile,
                            schedules,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _navyBlue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          plan == null
                              ? 'Generate Workout Plan'
                              : plan.completed
                              ? 'Workout Completed'
                              : 'Mark Workout Complete',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleWorkoutAction(
    WorkoutPlan? plan,
    HealthProfile? healthProfile,
    List<ClassSchedule> schedules,
  ) async {
    if (plan != null) {
      await ref
          .read(prototypeDataServiceProvider)
          .setWorkoutCompleted(plan.id, !plan.completed);
      ref.invalidate(workoutPlansProvider);
      ref.invalidate(dashboardStatsProvider);
      return;
    }
    if (healthProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete your health profile first.')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    try {
      await ref.read(prototypeDataServiceProvider).generateWorkoutPlan(
            healthProfile: healthProfile,
            schedules: schedules,
          );
      ref.invalidate(workoutPlansProvider);
      ref.invalidate(dashboardStatsProvider);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Widget _exerciseCard(WorkoutPlan? plan) {
    final exercises = plan?.exercises ?? const <Map<String, dynamic>>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exercises',
            style: TextStyle(
              color: _navyBlue,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (exercises.isEmpty)
            _emptyCard('Generate a workout plan to see your exercise list.')
          else
            Column(
              children: exercises.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final exercise = entry.value;
                final isCompleted = plan?.completed ?? false;

                return Opacity(
                  opacity: isCompleted ? 0.65 : 1,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: _cardDecoration(),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: isCompleted
                              ? const Color(0xFFE6F8EC)
                              : const Color(0xFFEDEFF4),
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.green)
                              : Text(
                                  '$index',
                                  style: const TextStyle(
                                    color: _navyBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise['name']?.toString() ?? 'Exercise',
                                style: const TextStyle(
                                  color: _navyBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${exercise['sets']} sets • ${exercise['reps']}',
                                style: TextStyle(
                                  color: _navyBlue.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _weeklyPlan(WorkoutPlan? plan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan Basis',
            style: TextStyle(
              color: _navyBlue,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: _navyBlue, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Rule-Based Recommendation',
                      style: TextStyle(
                        color: _navyBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  plan == null
                      ? 'NutriSense will use your class schedule, activity level, and fitness goal to build a routine.'
                      : 'Goal: ${plan.fitnessGoal}\nActivity level: ${plan.activityLevel}\nIntensity: ${plan.intensity}',
                  style: TextStyle(
                    color: _navyBlue.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF718096)),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildHeaderStack(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [_buildNavyHeader(context), _buildTabToggle()],
    );
  }

  Widget _buildNavyHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _navyBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        left: 20,
        right: 20,
        bottom: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wellness Hub',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your fitness & nutrition tracker',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Positioned(
      bottom: -22,
      left: 40,
      right: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [_buildTab('Workout', 0), _buildTab('Nutrition', 1)],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _navyBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF718096),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
