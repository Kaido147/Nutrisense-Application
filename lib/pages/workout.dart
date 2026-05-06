import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/models/workout_catalog.dart';
import 'package:nutrisense/pages/modals/workout/exercise_modal.dart';
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

  static const Color _navy = Color(0xFF273967);
  static const Color _cream = Color(0xFFF5F0EA);

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
      backgroundColor: _cream,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderStack(context),
            const SizedBox(height: 54),
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
                onStartExercise: _startExercise,
              ),
            if (_selectedTab == 1) const NutritionTab(),
            const SizedBox(height: 28),
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

  Future<void> _startExercise(
    WorkoutPlan plan,
    Map<String, dynamic> exercise,
  ) async {
    final completed = await showExerciseModal(context, exercise: exercise);
    if (completed != true) return;
    final exerciseId = exercise['id']?.toString();
    if (exerciseId == null || exerciseId.isEmpty) return;
    try {
      await ref
          .read(prototypeDataServiceProvider)
          .setWorkoutExerciseCompleted(plan.id, exerciseId, true);
      ref.invalidate(workoutPlansProvider);
      ref.invalidate(dashboardStatsProvider);
      _showSnack('${exercise['name'] ?? 'Exercise'} completed.');
    } catch (_) {
      _showSnack('We could not update exercise progress.');
    }
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
        color: _navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 56,
        left: 24,
        right: 24,
        bottom: 36,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wellness Hub',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your fitness & nutrition tracker',
            style: TextStyle(color: Color(0xFFE1E7F3), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Positioned(
      bottom: -32,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? _navy : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : _navy,
              fontWeight: FontWeight.w700,
              fontSize: 15,
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
    required this.onStartExercise,
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
  final void Function(WorkoutPlan plan, Map<String, dynamic> exercise)
  onStartExercise;

  static const Color _navy = Color(0xFF273967);
  static const Color _gold = Color(0xFFE2C783);

  @override
  Widget build(BuildContext context) {
    final selectedExercises = selectedCategory.exercises
        .where((exercise) => selectedExerciseIds.contains(exercise.id))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Today's Routine"),
        const SizedBox(height: 16),
        _RoutineCard(plan: currentPlan),
        const SizedBox(height: 30),
        _sectionTitle('Workout Categories'),
        const SizedBox(height: 14),
        SizedBox(
          height: 112,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
        const SizedBox(height: 26),
        _sectionTitle('${selectedCategory.name} Picker'),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: selectedCategory.exercises.map((exercise) {
              return _PickerExerciseTile(
                exercise: exercise,
                selected: selectedExerciseIds.contains(exercise.id),
                onTap: () => onExerciseToggled(exercise),
              );
            }).toList(),
          ),
        ),
        _PlanActions(
          selectedExercises: selectedExercises,
          generatedDraft: generatedDraft,
          isSavingManual: isSavingManual,
          isGenerating: isGenerating,
          isSavingGenerated: isSavingGenerated,
          onSaveManual: onSaveManual,
          onGenerate: onGenerate,
          onSaveGenerated: onSaveGenerated,
        ),
        const SizedBox(height: 30),
        _sectionTitle('Exercises'),
        const SizedBox(height: 16),
        _SavedExercisesList(
          plan: currentPlan,
          onStartExercise: onStartExercise,
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Weekly Plan',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(color: _gold, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _WeeklyPlanCard(plan: currentPlan),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: const TextStyle(
          color: _navy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.plan});

  final WorkoutPlan? plan;

  static const Color _navy = Color(0xFF273967);
  static const Color _gold = Color(0xFFE2C783);

  @override
  Widget build(BuildContext context) {
    final total = plan?.exercises.length ?? 0;
    final completed = plan?.completedExerciseCount ?? 0;
    final progress = total == 0 ? 0.0 : completed / total;
    final title = plan?.title ?? 'Choose Your Workout';
    final subtitle = plan == null
        ? 'Pick exercises or generate a routine'
        : '${plan!.durationMinutes} minutes - ${plan!.intensity}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _gold,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.36),
                  child: const Icon(Icons.fitness_center, color: _navy),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF586173),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.45),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                plan == null
                    ? 'Create Workout'
                    : plan!.completed
                    ? 'Workout Completed'
                    : 'Continue Workout',
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
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
        width: 146,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF273967) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
            const SizedBox(height: 8),
            Text(
              '${category.exercises.length} exercises',
              style: TextStyle(
                color: selected ? Colors.white70 : const Color(0xFF7D8596),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerExerciseTile extends StatelessWidget {
  const _PickerExerciseTile({
    required this.exercise,
    required this.selected,
    required this.onTap,
  });

  final WorkoutExercise exercise;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(
            borderColor: selected
                ? const Color(0xFFE2C783)
                : Colors.white.withValues(alpha: 0),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: selected
                    ? const Color(0xFFE6F8EC)
                    : const Color(0xFFE9ECF2),
                child: Icon(
                  selected ? Icons.check : Icons.add,
                  color: selected ? Colors.green : const Color(0xFF273967),
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        color: Color(0xFF273967),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.sets} x ${exercise.repsOrDuration}',
                      style: const TextStyle(color: Color(0xFF7D8596)),
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

class _PlanActions extends StatelessWidget {
  const _PlanActions({
    required this.selectedExercises,
    required this.generatedDraft,
    required this.isSavingManual,
    required this.isGenerating,
    required this.isSavingGenerated,
    required this.onSaveManual,
    required this.onGenerate,
    required this.onSaveGenerated,
  });

  final List<WorkoutExercise> selectedExercises;
  final WorkoutPlanDraft? generatedDraft;
  final bool isSavingManual;
  final bool isGenerating;
  final bool isSavingGenerated;
  final VoidCallback onSaveManual;
  final VoidCallback onGenerate;
  final VoidCallback onSaveGenerated;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: isSavingManual || selectedExercises.isEmpty
                ? null
                : onSaveManual,
            icon: isSavingManual
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              selectedExercises.isEmpty
                  ? 'Select Exercises'
                  : 'Save ${selectedExercises.length} Exercises',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF273967),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isGenerating ? null : onGenerate,
            icon: isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: const Text('Generate Workout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF273967),
              side: const BorderSide(color: Color(0xFF273967)),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (generatedDraft != null) ...[
            const SizedBox(height: 14),
            _GeneratedDraftCard(
              draft: generatedDraft!,
              isSaving: isSavingGenerated,
              onSave: onSaveGenerated,
            ),
          ],
        ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(borderColor: const Color(0xFFE2C783)),
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
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${exercise.name}: ${exercise.sets} x ${exercise.repsOrDuration}',
                style: const TextStyle(color: Color(0xFF273967)),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
              backgroundColor: const Color(0xFFE2C783),
              foregroundColor: const Color(0xFF273967),
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedExercisesList extends StatelessWidget {
  const _SavedExercisesList({
    required this.plan,
    required this.onStartExercise,
  });

  final WorkoutPlan? plan;
  final void Function(WorkoutPlan plan, Map<String, dynamic> exercise)
  onStartExercise;

  @override
  Widget build(BuildContext context) {
    final workoutPlan = plan;
    if (workoutPlan == null || workoutPlan.exercises.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: _EmptyCard(
          message:
              'No saved workout yet. Select exercises manually or generate a routine.',
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: workoutPlan.exercises.asMap().entries.map((entry) {
          return _SavedExerciseTile(
            index: entry.key,
            exercise: entry.value,
            plan: workoutPlan,
            onStartExercise: onStartExercise,
          );
        }).toList(),
      ),
    );
  }
}

class _SavedExerciseTile extends StatelessWidget {
  const _SavedExerciseTile({
    required this.index,
    required this.exercise,
    required this.plan,
    required this.onStartExercise,
  });

  final int index;
  final Map<String, dynamic> exercise;
  final WorkoutPlan plan;
  final void Function(WorkoutPlan plan, Map<String, dynamic> exercise)
  onStartExercise;

  @override
  Widget build(BuildContext context) {
    final completed = exercise['completed'] == true;
    final name = exercise['name']?.toString() ?? 'Exercise';
    final sets = exercise['sets']?.toString() ?? '1';
    final reps = exercise['reps']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: completed
                  ? const Color(0xFFE6F8EC)
                  : const Color(0xFFE9ECF2),
              child: completed
                  ? const Icon(Icons.check, color: Colors.green, size: 18)
                  : Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF273967),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: completed
                          ? const Color(0xFF7D8596)
                          : const Color(0xFF273967),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$sets x $reps',
                    style: const TextStyle(color: Color(0xFF7D8596)),
                  ),
                ],
              ),
            ),
            if (!completed)
              ElevatedButton(
                onPressed: () => onStartExercise(plan, exercise),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF273967),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Start'),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyPlanCard extends StatelessWidget {
  const _WeeklyPlanCard({required this.plan});

  final WorkoutPlan? plan;

  @override
  Widget build(BuildContext context) {
    final category = plan?.category ?? 'Cardio';
    final items = <String>[
      'Mon: $category',
      'Tue: Upper Body',
      'Wed: Rest',
      'Thu: Lower Body',
      'Fri: Core',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF273967),
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  "This Week's Focus",
                  style: TextStyle(
                    color: Color(0xFF273967),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...items.asMap().entries.map((entry) {
              final active = entry.key < 2;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: active
                          ? Colors.green
                          : const Color(0xFFD1D5DB),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      entry.value,
                      style: const TextStyle(
                        color: Color(0xFF273967),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF667085), height: 1.4),
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color borderColor = Colors.white}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
