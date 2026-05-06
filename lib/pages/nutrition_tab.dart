import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/widgets/circular_macro_progress.dart';
import 'modals/nutrition/generate_meal_ideas_modal.dart';
import 'modals/nutrition/nutrition_modal.dart';

class NutritionTab extends ConsumerStatefulWidget {
  const NutritionTab({super.key});

  @override
  ConsumerState<NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends ConsumerState<NutritionTab> {
  static const Color _navyBlue = Color(0xFF273967);
  static const Color _green = Color(0xFF00D084);
  static const Color _lightGray = Color(0xFFF5F5F5);

  List<Map<String, dynamic>> _recentMeals = [];
  bool _isLoadingMeals = true;
  bool _sortNewestFirst = true;

  @override
  void initState() {
    super.initState();
    _loadRecentMeals();
  }

  Future<void> _loadRecentMeals() async {
    try {
      final meals = await ref.read(nutritionServiceProvider).getRecentMeals();
      if (mounted) {
        setState(() {
          _recentMeals = meals;
          _isLoadingMeals = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMeals = false);
    }
  }

  Future<void> _deleteMeal(int index) async {
    final meal = _recentMeals[index];
    final docId = meal['docId'] as String?;

    setState(() => _recentMeals.removeAt(index));

    if (docId != null) {
      await ref.read(nutritionServiceProvider).deleteMeal(docId);
    }
  }

  void _toggleSortOrder() {
    setState(() {
      _sortNewestFirst = !_sortNewestFirst;
      _recentMeals.sort((a, b) {
        final aTime = a['savedAt'] as Comparable?;
        final bTime = b['savedAt'] as Comparable?;
        if (_sortNewestFirst) {
          return bTime?.compareTo(aTime) ?? 0;
        } else {
          return aTime?.compareTo(bTime) ?? 0;
        }
      });
    });
  }

  Map<String, int> _calculateNutritionTotals() {
    int totalCalories = 0;
    int totalProtein = 0;
    int totalCarbs = 0;
    int totalFat = 0;
    int totalFiber = 0;

    for (final meal in _recentMeals) {
      final calories = meal['calories'] as int? ?? 0;
      totalCalories += calories;

      final nutrition = meal['nutrition'] as Map<String, dynamic>? ?? {};
      final protein = nutrition['protein'] as String? ?? '0g';
      totalProtein +=
          int.tryParse(protein.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      final carbs = nutrition['carbs'] as String? ?? '0g';
      totalCarbs += int.tryParse(carbs.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      final fat = nutrition['fat'] as String? ?? '0g';
      totalFat += int.tryParse(fat.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      final fiber = nutrition['fiber'] as String? ?? '0g';
      totalFiber += int.tryParse(fiber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'fiber': totalFiber,
    };
  }

  void _viewNutrition(Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => NutritionModal(meal: meal, onBack: () {}),
    );
  }

  Future<void> _onMealCompleted(Map<String, dynamic> completedMeal) async {
    await ref.read(nutritionServiceProvider).saveMeal(completedMeal);
    await _loadRecentMeals();

    if (mounted) {
      _showMealAddedNotification(completedMeal['name'] ?? 'Your meal');
    }
  }

  void _showMealAddedNotification(String mealName) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, -15 * (1 - value)),
              child: child,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _green.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check_circle, color: _green, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Added to Recent',
                        style: TextStyle(
                          color: _navyBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        mealName,
                        style: TextStyle(
                          color: _navyBlue.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry?.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildTodaysNutritionCard(ref),
            const SizedBox(height: 24),
            _buildMealPlannerSection(),
            const SizedBox(height: 24),
            _buildRecentMealsSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysNutritionCard(WidgetRef ref) {
    final totals = _calculateNutritionTotals();
    final totalCalories = totals['calories'] ?? 0;
    final totalProtein = totals['protein'] ?? 0;
    final totalCarbs = totals['carbs'] ?? 0;
    final totalFat = totals['fat'] ?? 0;
    final totalFiber = totals['fiber'] ?? 0;

    // Get daily macro targets from provider
    final dailyMacrosAsync = ref.watch(dailyMacrosProvider);

    return dailyMacrosAsync.when(
      data: (dailyMacros) {
        // Use daily macros if available, otherwise use defaults
        final dailyCalories = dailyMacros?.calories ?? 2000;
        final dailyProtein = dailyMacros?.protein ?? 150;
        final dailyCarbs = dailyMacros?.carbs ?? 225;
        final dailyFat = dailyMacros?.fat ?? 65;
        final dailyFiber = dailyMacros?.fiber ?? 25;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
            children: [
              Text(
                "Today's Nutrition",
                style: TextStyle(
                  color: _navyBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircularMacroProgress(
                    current: totalCalories,
                    target: dailyCalories,
                    label: 'Calories',
                    unit: '',
                    color: const Color(0xFFFF6B35),
                  ),
                  CircularMacroProgress(
                    current: totalProtein,
                    target: dailyProtein,
                    label: 'Protein',
                    unit: 'g',
                    color: _navyBlue,
                  ),
                  CircularMacroProgress(
                    current: totalCarbs,
                    target: dailyCarbs,
                    label: 'Carbs',
                    unit: 'g',
                    color: const Color(0xFFFFB84D),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildHorizontalMacroBar(
                label: 'Fat',
                current: totalFat,
                target: dailyFat,
                unit: 'g',
                color: _green,
              ),
              const SizedBox(height: 14),
              _buildHorizontalMacroBar(
                label: 'Fiber',
                current: totalFiber,
                target: dailyFiber,
                unit: 'g',
                color: Colors.grey[600]!,
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_navyBlue),
          ),
        ),
      ),
      error: (_, __) {
        final totals = _calculateNutritionTotals();
        return _buildNutritionCardWithDefaults(totals);
      },
    );
  }

  Widget _buildNutritionCardWithDefaults(Map<String, int> totals) {
    final totalCalories = totals['calories'] ?? 0;
    final totalProtein = totals['protein'] ?? 0;
    final totalCarbs = totals['carbs'] ?? 0;
    final totalFat = totals['fat'] ?? 0;
    final totalFiber = totals['fiber'] ?? 0;

    // Default targets
    const dailyCalories = 2000;
    const dailyProtein = 150;
    const dailyCarbs = 225;
    const dailyFat = 65;
    const dailyFiber = 25;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        children: [
          Text(
            "Today's Nutrition",
            style: TextStyle(
              color: _navyBlue,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircularMacroProgress(
                current: totalCalories,
                target: dailyCalories,
                label: 'Calories',
                unit: '',
                color: const Color(0xFFFF6B35),
              ),
              CircularMacroProgress(
                current: totalProtein,
                target: dailyProtein,
                label: 'Protein',
                unit: 'g',
                color: _navyBlue,
              ),
              CircularMacroProgress(
                current: totalCarbs,
                target: dailyCarbs,
                label: 'Carbs',
                unit: 'g',
                color: const Color(0xFFFFB84D),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildHorizontalMacroBar(
            label: 'Fat',
            current: totalFat,
            target: dailyFat,
            unit: 'g',
            color: _green,
          ),
          const SizedBox(height: 14),
          _buildHorizontalMacroBar(
            label: 'Fiber',
            current: totalFiber,
            target: dailyFiber,
            unit: 'g',
            color: Colors.grey[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: _navyBlue,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF999999),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalMacroBar({
    required String label,
    required int current,
    required int target,
    required String unit,
    required Color color,
  }) {
    final percentage = (current / target).clamp(0.0, 1.5);
    final isExceeded = current > target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: _navyBlue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$current / $target $unit',
              style: TextStyle(
                color: isExceeded ? const Color(0xFFFF6B35) : color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: _lightGray,
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              widthFactor: percentage,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: isExceeded ? const Color(0xFFFF6B35) : color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealPlannerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Planner',
          style: TextStyle(
            color: _navyBlue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8F3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _green.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: _green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Meal Generator',
                          style: TextStyle(
                            color: _navyBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Based on your fridge items',
                          style: TextStyle(
                            color: _green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final completedMeal = await GenerateMealIdeasModal.show(
                      context,
                    );
                    if (completedMeal != null) {
                      await _onMealCompleted(completedMeal);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Generate Meal Ideas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMealsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Meals',
              style: TextStyle(
                color: _navyBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: _toggleSortOrder,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _sortNewestFirst
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: _green,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _sortNewestFirst ? 'Newest' : 'Oldest',
                      style: TextStyle(
                        color: _green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingMeals)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_recentMeals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: _lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.no_meals, color: Color(0xFFCCCCCC), size: 32),
                SizedBox(height: 8),
                Text(
                  'No recent meals',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ..._recentMeals.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMealCard(entry.value, entry.key),
            ),
          ),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, int index) {
    return Dismissible(
      key: ValueKey(meal['docId'] ?? '${meal['name']}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDED),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFE53935),
          size: 24,
        ),
      ),
      onDismissed: (_) => _deleteMeal(index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['type'] ?? 'Meal',
                    style: const TextStyle(
                      color: Color(0xFFFFB84D),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal['name'] ?? '',
                    style: TextStyle(
                      color: _navyBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${meal['calories']}',
                  style: TextStyle(
                    color: _navyBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'cal',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _viewNutrition(meal),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF1976D2),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteMeal(index),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFE53935),
                      size: 18,
                    ),
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
