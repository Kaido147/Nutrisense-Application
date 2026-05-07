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
  WorkoutPlanDraft? _generatedDraft;
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
            const SizedBox(height: 58),
            if (_selectedTab == 0)
              _WorkoutContent(
                plans: plans,
                currentPlan: currentPlan,
                selectedCategory: _selectedCategory,
                generatedDraft: _generatedDraft,
                isGenerating: _isGenerating,
                isSavingGenerated: _isSavingGenerated,
                onCategorySelected: _selectCategory,
                onGenerate: () => _generateDraft(healthProfile, schedules),
                onSaveGenerated: () => _saveGeneratedDraft(schedules),
                onOpenManualBuilder: () =>
                    _openManualBuilder(healthProfile, schedules),
                onOpenPlan: _openPlanDetail,
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
      _generatedDraft = null;
    });
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

  Future<void> _openManualBuilder(
    HealthProfile? healthProfile,
    List<ClassSchedule> schedules,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualWorkoutBuilderSheet(
        initialCategory: _selectedCategory,
        healthProfile: healthProfile,
        schedules: schedules,
        onCategoryChanged: _selectCategory,
        onSave: (category, exercises) async {
          await ref
              .read(prototypeDataServiceProvider)
              .saveManualWorkoutPlan(
                category: category.name,
                exercises: exercises,
                healthProfile: healthProfile,
                schedules: schedules,
              );
          ref.invalidate(workoutPlansProvider);
          ref.invalidate(dashboardStatsProvider);
        },
      ),
    );
    if (saved == true) _showSnack('Custom workout saved.');
  }

  Future<void> _openPlanDetail(WorkoutPlan? plan) async {
    if (plan == null) {
      _showSnack('Create or generate a workout first.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WorkoutDetailSheet(
        plan: plan,
        onStartExercise: (exercise) {
          Navigator.pop(context);
          _startExercise(plan, exercise);
        },
      ),
    );
  }

  Future<void> _startExercise(
    WorkoutPlan plan,
    Map<String, dynamic> exercise,
  ) async {
    final completed = await showExerciseModal(context, exercise: exercise);
    if (completed != true) return;
    final exerciseId = exercise['id']?.toString();
    if (exerciseId == null || exerciseId.isEmpty) return;

    final allCompleted = plan.exercises.every((item) {
      if (item['id']?.toString() == exerciseId) return true;
      return item['completed'] == true;
    });

    try {
      await ref
          .read(prototypeDataServiceProvider)
          .setWorkoutExerciseCompleted(plan.id, exerciseId, true);
      ref.invalidate(workoutPlansProvider);
      ref.invalidate(dashboardStatsProvider);
      if (allCompleted && mounted) {
        await _showWorkoutSummary(plan, completedExerciseId: exerciseId);
      } else {
        _showSnack('${exercise['name'] ?? 'Exercise'} completed.');
      }
    } catch (_) {
      _showSnack('We could not update exercise progress.');
    }
  }

  Future<void> _showWorkoutSummary(
    WorkoutPlan plan, {
    required String completedExerciseId,
  }) {
    final exercises = plan.exercises
        .map((exercise) {
          if (exercise['id']?.toString() != completedExerciseId) {
            return exercise;
          }
          return <String, dynamic>{...exercise, 'completed': true};
        })
        .toList(growable: false);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _WorkoutSummarySheet(plan: plan, completedExercises: exercises),
    );
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
    required this.plans,
    required this.currentPlan,
    required this.selectedCategory,
    required this.generatedDraft,
    required this.isGenerating,
    required this.isSavingGenerated,
    required this.onCategorySelected,
    required this.onGenerate,
    required this.onSaveGenerated,
    required this.onOpenManualBuilder,
    required this.onOpenPlan,
    required this.onStartExercise,
  });

  final List<WorkoutPlan> plans;
  final WorkoutPlan? currentPlan;
  final WorkoutCategory selectedCategory;
  final WorkoutPlanDraft? generatedDraft;
  final bool isGenerating;
  final bool isSavingGenerated;
  final ValueChanged<WorkoutCategory> onCategorySelected;
  final VoidCallback onGenerate;
  final VoidCallback onSaveGenerated;
  final VoidCallback onOpenManualBuilder;
  final ValueChanged<WorkoutPlan?> onOpenPlan;
  final void Function(WorkoutPlan plan, Map<String, dynamic> exercise)
  onStartExercise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'This Week',
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.calendar_today_outlined),
              color: _WorkoutColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          _WeeklyProgressStrip(plans: plans),
          const SizedBox(height: 28),
          _DailyFocusCard(
            plan: currentPlan,
            onPressed: currentPlan == null
                ? onOpenManualBuilder
                : () => onOpenPlan(currentPlan),
          ),
          const SizedBox(height: 30),
          const _SectionHeader(title: 'Workout Library'),
          const SizedBox(height: 14),
          _CategoryGrid(
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
          const SizedBox(height: 24),
          _CategoryPreview(
            category: selectedCategory,
            onOpenManualBuilder: onOpenManualBuilder,
          ),
          const SizedBox(height: 24),
          _BuilderActions(
            isGenerating: isGenerating,
            onGenerate: onGenerate,
            onOpenManualBuilder: onOpenManualBuilder,
          ),
          if (generatedDraft != null) ...[
            const SizedBox(height: 16),
            _GeneratedDraftCard(
              draft: generatedDraft!,
              isSaving: isSavingGenerated,
              onSave: onSaveGenerated,
            ),
          ],
          const SizedBox(height: 30),
          _SectionHeader(
            title: 'Current Plan',
            trailing: currentPlan == null
                ? null
                : TextButton(
                    onPressed: () => onOpenPlan(currentPlan),
                    child: const Text('View'),
                  ),
          ),
          const SizedBox(height: 14),
          _SavedExercisesList(
            plan: currentPlan,
            onStartExercise: onStartExercise,
          ),
        ],
      ),
    );
  }
}

class _WeeklyProgressStrip extends StatelessWidget {
  const _WeeklyProgressStrip({required this.plans});

  final List<WorkoutPlan> plans;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surfaceDecoration(radius: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final date = start.add(Duration(days: index));
          final key = todayKey(date);
          final hasPlan = plans.any((plan) => plan.dateKey == key);
          final completed = plans.any(
            (plan) => plan.dateKey == key && plan.completed,
          );
          final isToday = index + 1 == now.weekday;
          return _WeekDayPill(
            date: date,
            active: isToday,
            planned: hasPlan,
            completed: completed,
          );
        }),
      ),
    );
  }
}

class _WeekDayPill extends StatelessWidget {
  const _WeekDayPill({
    required this.date,
    required this.active,
    required this.planned,
    required this.completed,
  });

  final DateTime date;
  final bool active;
  final bool planned;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    const labels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final fill = active
        ? _WorkoutColors.navy
        : completed
        ? const Color(0xFFFDDC96)
        : Colors.transparent;
    final textColor = active ? Colors.white : _WorkoutColors.text;
    return Column(
      children: [
        Text(
          labels[date.weekday - 1],
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: completed
                ? Colors.green
                : planned
                ? _WorkoutColors.gold
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _DailyFocusCard extends StatelessWidget {
  const _DailyFocusCard({required this.plan, required this.onPressed});

  final WorkoutPlan? plan;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final total = plan?.exercises.length ?? 0;
    final completed = plan?.completedExerciseCount ?? 0;
    final progress = total == 0 ? 0.0 : completed / total;
    final title = plan?.title ?? 'Create Today\'s Focus';
    final subtitle = plan == null
        ? 'Generate a balanced routine or build your own.'
        : '${plan!.durationMinutes} mins  •  ${plan!.intensity}  •  $completed/$total done';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFDDC96),
        borderRadius: BorderRadius.circular(32),
        boxShadow: _softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'TODAY\'S FOCUS',
                  style: TextStyle(
                    color: Color(0xFF775F26),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                plan?.completed == true
                    ? Icons.check_circle
                    : Icons.local_fire_department,
                color: _WorkoutColors.navy,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: _WorkoutColors.navy,
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF59440C),
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (plan != null) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.45),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  _WorkoutColors.navy,
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(
                plan == null
                    ? Icons.add
                    : plan!.completed
                    ? Icons.emoji_events
                    : Icons.play_arrow,
              ),
              label: Text(
                plan == null
                    ? 'Build a Workout'
                    : plan!.completed
                    ? 'Review Workout'
                    : 'Start Today\'s Workout',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _WorkoutColors.navy,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final WorkoutCategory selectedCategory;
  final ValueChanged<WorkoutCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final visible = workoutCatalog.take(6).toList(growable: false);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final category = visible[index];
        return _LibraryCategoryCard(
          category: category,
          selected: selectedCategory.id == category.id,
          icon: _iconForCategory(category),
          onTap: () => onCategorySelected(category),
        );
      },
    );
  }
}

class _LibraryCategoryCard extends StatelessWidget {
  const _LibraryCategoryCard({
    required this.category,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final WorkoutCategory category;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _WorkoutColors.navy : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected ? null : _softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.16)
                      : const Color(0xFFE3E2E2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : _WorkoutColors.navy,
                ),
              ),
              const Spacer(),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _WorkoutColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${category.exercises.length} workouts',
                style: TextStyle(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.72)
                      : const Color(0xFF667085),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview({
    required this.category,
    required this.onOpenManualBuilder,
  });

  final WorkoutCategory category;
  final VoidCallback onOpenManualBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: _WorkoutColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenManualBuilder,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Build'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            category.description,
            style: const TextStyle(color: Color(0xFF667085), height: 1.4),
          ),
          const SizedBox(height: 14),
          ...category.exercises
              .take(3)
              .map(
                (exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: _WorkoutColors.gold,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: const TextStyle(
                            color: _WorkoutColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${exercise.sets} x ${exercise.repsOrDuration}',
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _BuilderActions extends StatelessWidget {
  const _BuilderActions({
    required this.isGenerating,
    required this.onGenerate,
    required this.onOpenManualBuilder,
  });

  final bool isGenerating;
  final VoidCallback onGenerate;
  final VoidCallback onOpenManualBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Custom Routine',
            style: TextStyle(
              color: _WorkoutColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use your profile for a quick plan or select exercises manually.',
            style: TextStyle(color: Color(0xFF667085), height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isGenerating ? null : onGenerate,
                  icon: isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text('Quick Generate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDDC96),
                    foregroundColor: const Color(0xFF59440C),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenManualBuilder,
                  icon: const Icon(Icons.tune),
                  label: const Text('Manual Builder'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _WorkoutColors.navy,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: _WorkoutColors.navy),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      decoration: _surfaceDecoration(
        radius: 22,
        borderColor: const Color(0xFFFDDC96),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: _WorkoutColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  draft.title,
                  style: const TextStyle(
                    color: _WorkoutColors.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${draft.category}  •  ${draft.durationMinutes} min  •  ${draft.intensity}',
            style: const TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: draft.exercises
                .map(
                  (exercise) => Chip(
                    label: Text(exercise.name),
                    backgroundColor: const Color(0xFFF5F3F3),
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
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
              backgroundColor: _WorkoutColors.navy,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
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
      return const _EmptyCard(
        message:
            'No saved workout yet. Generate a routine or use the manual builder.',
      );
    }
    return Column(
      children: workoutPlan.exercises.asMap().entries.map((entry) {
        return _SavedExerciseTile(
          index: entry.key,
          exercise: entry.value,
          plan: workoutPlan,
          onStartExercise: onStartExercise,
        );
      }).toList(),
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
        padding: const EdgeInsets.all(16),
        decoration: _surfaceDecoration(radius: 18),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFFE6F8EC)
                    : const Color(0xFFE3E2E2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: completed
                  ? const Icon(Icons.check, color: Colors.green)
                  : Icon(_iconForExercise(name), color: _WorkoutColors.navy),
            ),
            const SizedBox(width: 14),
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
                          ? const Color(0xFF667085)
                          : _WorkoutColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$sets sets  •  $reps',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (!completed)
              IconButton.filled(
                onPressed: () => onStartExercise(plan, exercise),
                icon: const Icon(Icons.play_arrow),
                style: IconButton.styleFrom(
                  backgroundColor: _WorkoutColors.navy,
                  foregroundColor: Colors.white,
                ),
              )
            else
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _ManualWorkoutBuilderSheet extends StatefulWidget {
  const _ManualWorkoutBuilderSheet({
    required this.initialCategory,
    required this.healthProfile,
    required this.schedules,
    required this.onCategoryChanged,
    required this.onSave,
  });

  final WorkoutCategory initialCategory;
  final HealthProfile? healthProfile;
  final List<ClassSchedule> schedules;
  final ValueChanged<WorkoutCategory> onCategoryChanged;
  final Future<void> Function(
    WorkoutCategory category,
    List<WorkoutExercise> exercises,
  )
  onSave;

  @override
  State<_ManualWorkoutBuilderSheet> createState() =>
      _ManualWorkoutBuilderSheetState();
}

class _ManualWorkoutBuilderSheetState
    extends State<_ManualWorkoutBuilderSheet> {
  late WorkoutCategory _category;
  final Set<String> _selectedIds = <String>{};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  List<WorkoutExercise> get _selectedExercises {
    return _category.exercises
        .where((exercise) => _selectedIds.contains(exercise.id))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _WorkoutColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 18, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'New Routine',
                        style: TextStyle(
                          color: _WorkoutColors.navy,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                      color: _WorkoutColors.navy,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 120),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: _surfaceDecoration(radius: 999),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Color(0xFF75777F)),
                          SizedBox(width: 10),
                          Text(
                            'Search exercises...',
                            style: TextStyle(color: Color(0xFF75777F)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: workoutCatalog.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = workoutCatalog[index];
                          final selected = _category.id == category.id;
                          return ChoiceChip(
                            selected: selected,
                            label: Text(category.name),
                            onSelected: (_) {
                              setState(() {
                                _category = category;
                                _selectedIds.clear();
                              });
                              widget.onCategoryChanged(category);
                            },
                            selectedColor: _WorkoutColors.navy,
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : _WorkoutColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide.none,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 26),
                    _SectionHeader(
                      title: 'Selected Exercises',
                      trailing: Text(
                        '${_selectedExercises.length} items',
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedExercises.isEmpty)
                      const _EmptyCard(
                        message: 'Choose exercises from the suggestions below.',
                      )
                    else
                      ..._selectedExercises.map(
                        (exercise) => _SelectedBuilderCard(
                          exercise: exercise,
                          onRemove: () =>
                              setState(() => _selectedIds.remove(exercise.id)),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const _SectionHeader(title: 'Suggested Additions'),
                    const SizedBox(height: 12),
                    ..._category.exercises.map(
                      (exercise) => _BuilderExerciseTile(
                        exercise: exercise,
                        selected: _selectedIds.contains(exercise.id),
                        onTap: () {
                          setState(() {
                            if (_selectedIds.contains(exercise.id)) {
                              _selectedIds.remove(exercise.id);
                            } else {
                              _selectedIds.add(exercise.id);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(
                  color: _WorkoutColors.background,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isSaving || _selectedExercises.isEmpty
                      ? null
                      : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _selectedExercises.isEmpty
                        ? 'Select Exercises'
                        : 'Save Routine',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _WorkoutColors.navy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_category, _selectedExercises);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not save this workout.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _SelectedBuilderCard extends StatelessWidget {
  const _SelectedBuilderCard({required this.exercise, required this.onRemove});

  final WorkoutExercise exercise;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _surfaceDecoration(radius: 24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDDC96).withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _iconForExercise(exercise.name),
                    color: _WorkoutColors.navy,
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
                          color: _WorkoutColors.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise.difficulty,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                  color: const Color(0xFF75777F),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _BuilderMetric(
                    label: 'Sets',
                    value: '${exercise.sets}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BuilderMetric(
                    label: 'Target',
                    value: exercise.repsOrDuration,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BuilderMetric extends StatelessWidget {
  const _BuilderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _WorkoutColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuilderExerciseTile extends StatelessWidget {
  const _BuilderExerciseTile({
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
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? _WorkoutColors.gold : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: _softShadow,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: selected
                      ? const Color(0xFFE6F8EC)
                      : const Color(0xFFE3E2E2),
                  child: Icon(
                    selected ? Icons.check : Icons.add,
                    color: selected ? Colors.green : _WorkoutColors.navy,
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
                          color: _WorkoutColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exercise.sets} sets  •  ${exercise.repsOrDuration}',
                        style: const TextStyle(
                          color: Color(0xFF667085),
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
      ),
    );
  }
}

class _WorkoutDetailSheet extends StatelessWidget {
  const _WorkoutDetailSheet({
    required this.plan,
    required this.onStartExercise,
  });

  final WorkoutPlan plan;
  final ValueChanged<Map<String, dynamic>> onStartExercise;

  @override
  Widget build(BuildContext context) {
    final progress = plan.exerciseProgress;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _WorkoutColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
            children: [
              Row(
                children: [
                  IconButton.filled(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _WorkoutColors.navy,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Workout Overview',
                    style: TextStyle(
                      color: _WorkoutColors.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                height: 240,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _WorkoutColors.navy,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: _softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.local_fire_department, size: 16),
                      label: Text(plan.intensity),
                      backgroundColor: const Color(0xFFFDDC96),
                      side: BorderSide.none,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      plan.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${plan.durationMinutes} mins  •  ${plan.exercises.length} exercises',
                      style: const TextStyle(
                        color: Color(0xFFE1E7F3),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'A balanced ${plan.category.toLowerCase()} routine built for your ${plan.activityLevel.toLowerCase()} activity level and ${plan.fitnessGoal.toLowerCase()} goal.',
                style: const TextStyle(
                  color: Color(0xFF667085),
                  height: 1.45,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Workout Plan',
                      style: TextStyle(
                        color: _WorkoutColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: _WorkoutColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...plan.exercises.asMap().entries.map(
                (entry) => _DetailExerciseCard(
                  index: entry.key,
                  exercise: entry.value,
                  onStart: () => onStartExercise(entry.value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailExerciseCard extends StatelessWidget {
  const _DetailExerciseCard({
    required this.index,
    required this.exercise,
    required this.onStart,
  });

  final int index;
  final Map<String, dynamic> exercise;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final completed = exercise['completed'] == true;
    final name = exercise['name']?.toString() ?? 'Exercise';
    final sets = exercise['sets']?.toString() ?? '1';
    final reps = exercise['reps']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _surfaceDecoration(radius: 18),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E2E2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(_iconForExercise(name), color: _WorkoutColors.navy),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: _WorkoutColors.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _MiniChip(label: '$sets sets'),
                      _MiniChip(label: reps),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: completed ? null : onStart,
              icon: Icon(completed ? Icons.check_circle : Icons.play_arrow),
              color: completed ? Colors.green : _WorkoutColors.navy,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutSummarySheet extends StatelessWidget {
  const _WorkoutSummarySheet({
    required this.plan,
    required this.completedExercises,
  });

  final WorkoutPlan plan;
  final List<Map<String, dynamic>> completedExercises;

  @override
  Widget build(BuildContext context) {
    final completed = completedExercises
        .where((exercise) => exercise['completed'] == true)
        .length;
    final estimatedCalories = (plan.durationMinutes * 7).clamp(60, 650);
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _WorkoutColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 34, 24, 36),
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFFFDDC96),
                child: Icon(
                  Icons.emoji_events,
                  size: 44,
                  color: Color(0xFF59440C),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Great job!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _WorkoutColors.navy,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You completed ${plan.title}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF667085)),
              ),
              const SizedBox(height: 28),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  _SummaryStat(
                    icon: Icons.timer_outlined,
                    label: 'Total Time',
                    value: '${plan.durationMinutes}m',
                  ),
                  _SummaryStat(
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    value: '$estimatedCalories',
                  ),
                  _SummaryStat(
                    icon: Icons.fitness_center,
                    label: 'Exercises',
                    value: '$completed',
                  ),
                  _SummaryStat(
                    icon: Icons.trending_up,
                    label: 'Progress',
                    value: '100%',
                    accent: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: _surfaceDecoration(radius: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Workout Summary',
                      style: TextStyle(
                        color: _WorkoutColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...completedExercises.map((exercise) {
                      final name = exercise['name']?.toString() ?? 'Exercise';
                      final sets = exercise['sets']?.toString() ?? '1';
                      final reps = exercise['reps']?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFD8E2FF),
                              child: Icon(
                                Icons.check,
                                size: 18,
                                color: _WorkoutColors.navy,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: _WorkoutColors.text,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '$sets sets  •  $reps',
                                    style: const TextStyle(
                                      color: Color(0xFF667085),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _WorkoutColors.navy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Back to Workout'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFFDDC96) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _WorkoutColors.navy),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _WorkoutColors.navy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _WorkoutColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E2E2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF667085),
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
      decoration: _surfaceDecoration(radius: 18),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF667085), height: 1.4),
      ),
    );
  }
}

class _WorkoutColors {
  static const Color navy = Color(0xFF1A2B4B);
  static const Color gold = Color(0xFFDDBE7B);
  static const Color background = Color(0xFFFBF9F9);
  static const Color text = Color(0xFF1B1C1C);
}

BoxDecoration _surfaceDecoration({
  required double radius,
  Color borderColor = Colors.transparent,
}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
    boxShadow: _softShadow,
  );
}

List<BoxShadow> get _softShadow {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
}

IconData _iconForCategory(WorkoutCategory category) {
  final value = category.id.toLowerCase();
  if (value.contains('cardio') || value.contains('weight')) {
    return Icons.directions_run;
  }
  if (value.contains('core')) return Icons.accessibility_new;
  if (value.contains('stretch')) return Icons.self_improvement;
  if (value.contains('lower')) return Icons.airline_seat_legroom_extra;
  return Icons.fitness_center;
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
