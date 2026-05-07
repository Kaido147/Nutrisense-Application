import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/models/workout_catalog.dart';
import 'package:nutrisense/providers/firebase_providers.dart';

import 'nutrition_tab.dart';

class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({super.key});

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> {
  int _selectedTab = 0;
  WorkoutCategory _selectedCategory = workoutCatalog.first;
  final Set<String> _selectedExerciseIds = <String>{};
  WorkoutPlanDraft? _generatedDraft;
  bool _isSavingManual = false;
  bool _isGenerating = false;
  bool _isSavingGenerated = false;

  static const Color _navyBlue = Color(0xFF273967);
  static const Color _lightBg = Color(0xFFF5F0EA);

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(workoutPlansProvider);
    final healthProfileAsync = ref.watch(healthProfileProvider);
    final schedulesAsync = ref.watch(schedulesProvider);

    final plans = plansAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <WorkoutPlan>[],
    );
    final healthProfile = healthProfileAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final schedules = schedulesAsync.maybeWhen(
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
              _WorkoutContent(
                selectedCategory: _selectedCategory,
                selectedExerciseIds: _selectedExerciseIds,
                generatedDraft: _generatedDraft,
                currentPlan: currentPlan,
                isSavingManual: _isSavingManual,
                isGenerating: _isGenerating,
                isSavingGenerated: _isSavingGenerated,
                onCategorySelected: _selectCategory,
                onExerciseToggled: _toggleExercise,
                onSaveManual: () =>
                    _saveManualWorkout(healthProfile, schedules),
                onGenerate: () => _generateDraft(healthProfile, schedules),
                onSaveGenerated: () => _saveGeneratedDraft(schedules),
                onToggleCompleted: currentPlan == null
                    ? null
                    : () => _toggleWorkoutCompleted(currentPlan),
              ),
            if (_selectedTab == 1) const NutritionTab(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _selectCategory(WorkoutCategory category) {
    setState(() {
      _selectedCategory = category;
      _selectedExerciseIds.clear();
      _generatedDraft = null;
    });
  }

  void _toggleExercise(WorkoutExercise exercise) {
    setState(() {
      if (_selectedExerciseIds.contains(exercise.id)) {
        _selectedExerciseIds.remove(exercise.id);
      } else {
        _selectedExerciseIds.add(exercise.id);
      }
    });
  }

  List<WorkoutExercise> get _selectedExercises {
    return _selectedCategory.exercises
        .where((exercise) => _selectedExerciseIds.contains(exercise.id))
        .toList(growable: false);
  }

  Future<void> _saveManualWorkout(
    HealthProfile? healthProfile,
    List<ClassSchedule> schedules,
  ) async {
    if (_selectedExercises.isEmpty) {
      _showSnack('Select at least one exercise.');
      return;
    }
    setState(() => _isSavingManual = true);
    try {
      await ref
          .read(prototypeDataServiceProvider)
          .saveManualWorkoutPlan(
            category: _selectedCategory.name,
            exercises: _selectedExercises,
            healthProfile: healthProfile,
            schedules: schedules,
          );
      ref.invalidate(workoutPlansProvider);
      ref.invalidate(dashboardStatsProvider);
      setState(() => _selectedExerciseIds.clear());
      _showSnack('Custom workout saved.');
    } catch (_) {
      _showSnack('We could not save this workout.');
    } finally {
      if (mounted) setState(() => _isSavingManual = false);
    }
  }

  Future<void> _generateDraft(
    HealthProfile? healthProfile,
    List<ClassSchedule> schedules,
  ) async {
    if (healthProfile == null) {
      _showSnack('Complete your health profile first.');
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final draft = ref
          .read(prototypeDataServiceProvider)
          .buildGeneratedWorkoutDraft(
            category: _selectedCategory.name,
            healthProfile: healthProfile,
            schedules: schedules,
          );
      setState(() => _generatedDraft = draft);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _saveGeneratedDraft(List<ClassSchedule> schedules) async {
    final draft = _generatedDraft;
    if (draft == null) return;
    setState(() => _isSavingGenerated = true);
    try {
      await ref
          .read(prototypeDataServiceProvider)
          .saveWorkoutDraft(draft, schedules: schedules);
      ref.invalidate(workoutPlansProvider);
      ref.invalidate(dashboardStatsProvider);
      setState(() => _generatedDraft = null);
      _showSnack('Generated workout saved.');
    } catch (_) {
      _showSnack('We could not save the generated workout.');
    } finally {
      if (mounted) setState(() => _isSavingGenerated = false);
    }
  }

  Future<void> _toggleWorkoutCompleted(WorkoutPlan plan) async {
    await ref
        .read(prototypeDataServiceProvider)
        .setWorkoutCompleted(plan.id, !plan.completed);
    ref.invalidate(workoutPlansProvider);
    ref.invalidate(dashboardStatsProvider);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
            'Choose exercises or generate a routine',
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

class _WorkoutContent extends StatelessWidget {
  const _WorkoutContent({
    required this.selectedCategory,
    required this.selectedExerciseIds,
    required this.generatedDraft,
    required this.currentPlan,
    required this.isSavingManual,
    required this.isGenerating,
    required this.isSavingGenerated,
    required this.onCategorySelected,
    required this.onExerciseToggled,
    required this.onSaveManual,
    required this.onGenerate,
    required this.onSaveGenerated,
    required this.onToggleCompleted,
  });

  final WorkoutCategory selectedCategory;
  final Set<String> selectedExerciseIds;
  final WorkoutPlanDraft? generatedDraft;
  final WorkoutPlan? currentPlan;
  final bool isSavingManual;
  final bool isGenerating;
  final bool isSavingGenerated;
  final ValueChanged<WorkoutCategory> onCategorySelected;
  final ValueChanged<WorkoutExercise> onExerciseToggled;
  final VoidCallback onSaveManual;
  final VoidCallback onGenerate;
  final VoidCallback onSaveGenerated;
  final VoidCallback? onToggleCompleted;

  static const Color _navyBlue = Color(0xFF273967);

  @override
  Widget build(BuildContext context) {
    final selectedExercises = selectedCategory.exercises
        .where((exercise) => selectedExerciseIds.contains(exercise.id))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Workout Categories'),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: workoutCatalog.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = workoutCatalog[index];
              return _CategoryCard(
                category: category,
                selected: selectedCategory.id == category.id,
                onTap: () => onCategorySelected(category),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('${selectedCategory.name} Exercises'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: selectedCategory.exercises
                .map(
                  (exercise) => _ExerciseTile(
                    exercise: exercise,
                    selected: selectedExerciseIds.contains(exercise.id),
                    onTap: () => onExerciseToggled(exercise),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        _SelectedSummary(
          exercises: selectedExercises,
          isSaving: isSavingManual,
          onSave: onSaveManual,
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlinedButton.icon(
            onPressed: isGenerating ? null : onGenerate,
            icon: isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: const Text('AI Generate Exercise'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _navyBlue,
              side: const BorderSide(color: _navyBlue),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
        if (generatedDraft != null) ...[
          const SizedBox(height: 18),
          _GeneratedDraftCard(
            draft: generatedDraft!,
            isSaving: isSavingGenerated,
            onSave: onSaveGenerated,
          ),
        ],
        const SizedBox(height: 24),
        _CurrentPlanCard(
          plan: currentPlan,
          onToggleCompleted: onToggleCompleted,
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: _navyBlue,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final WorkoutCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 138,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF273967) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF273967) : const Color(0xFFE2E6EF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF273967),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${category.exercises.length} exercises',
              style: TextStyle(
                color: selected ? Colors.white70 : const Color(0xFF667085),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.selected,
    required this.onTap,
  });

  final WorkoutExercise exercise;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(
        borderColor: selected
            ? const Color(0xFFD6B66E)
            : const Color(0xFFE2E6EF),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: (_) => onTap(),
        activeColor: const Color(0xFF273967),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Text(
          exercise.name,
          style: const TextStyle(
            color: Color(0xFF273967),
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${exercise.sets} sets - ${exercise.repsOrDuration} - ${exercise.difficulty}\n${exercise.instruction}',
            style: const TextStyle(color: Color(0xFF667085), height: 1.35),
          ),
        ),
      ),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({
    required this.exercises,
    required this.isSaving,
    required this.onSave,
  });

  final List<WorkoutExercise> exercises;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Exercises',
              style: TextStyle(
                color: Color(0xFF273967),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercises.isEmpty
                  ? 'Choose exercises above to build your own workout.'
                  : exercises.map((item) => item.name).join(', '),
              style: const TextStyle(color: Color(0xFF667085)),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: isSaving || exercises.isEmpty ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save Custom Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF273967),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneratedDraftCard extends StatelessWidget {
  const _GeneratedDraftCard({
    required this.draft,
    required this.isSaving,
    required this.onSave,
  });

  final WorkoutPlanDraft draft;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(borderColor: const Color(0xFFD6B66E)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              draft.title,
              style: const TextStyle(
                color: Color(0xFF273967),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${draft.category} - ${draft.durationMinutes} min - ${draft.intensity}',
              style: const TextStyle(color: Color(0xFF667085)),
            ),
            const SizedBox(height: 12),
            ...draft.exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '- ${exercise.name}: ${exercise.sets} sets, ${exercise.repsOrDuration}',
                  style: const TextStyle(color: Color(0xFF273967)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Save Generated Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6B66E),
                foregroundColor: const Color(0xFF273967),
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.plan, required this.onToggleCompleted});

  final WorkoutPlan? plan;
  final VoidCallback? onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: plan == null
            ? const Text(
                'No saved workout yet. Select exercises manually or generate a routine.',
                style: TextStyle(color: Color(0xFF667085)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan!.title,
                    style: const TextStyle(
                      color: Color(0xFF273967),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${plan!.category} - ${plan!.source} - ${plan!.durationMinutes} min',
                    style: const TextStyle(color: Color(0xFF667085)),
                  ),
                  const SizedBox(height: 12),
                  ...plan!.exercises
                      .take(5)
                      .map(
                        (exercise) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '- ${exercise['name'] ?? 'Exercise'}: ${exercise['sets'] ?? 1} sets, ${exercise['reps'] ?? ''}',
                            style: const TextStyle(color: Color(0xFF273967)),
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: onToggleCompleted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan!.completed
                          ? const Color(0xFFE6F8EC)
                          : const Color(0xFF273967),
                      foregroundColor: plan!.completed
                          ? Colors.green
                          : Colors.white,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: Text(
                      plan!.completed
                          ? 'Workout Completed'
                          : 'Mark Workout Complete',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color borderColor = const Color(0xFFE2E6EF)}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
