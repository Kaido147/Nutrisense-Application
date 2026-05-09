import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/widgets/circular_macro_progress.dart';
import 'modals/nutrition/generate_meal_ideas_modal.dart';
import 'modals/nutrition/nutrition_modal.dart';

class NutritionTab extends ConsumerStatefulWidget {
  /// Optional callback invoked when the user taps "Go to Workout".
  /// The parent scaffold should switch to the workout tab when this fires.
  final VoidCallback? onGoToWorkout;

  const NutritionTab({super.key, this.onGoToWorkout});

  @override
  ConsumerState<NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends ConsumerState<NutritionTab> {
  static const Color _navyBlue = Color(0xFF273967);
  static const Color _green = Color(0xFF00D084);
  static const Color _lightGray = Color(0xFFF5F5F5);

  List<Map<String, dynamic>> _recentMeals = [];
  StreamSubscription<List<Map<String, dynamic>>>? _recentMealsSubscription;
  bool _isLoadingMeals = true;
  bool _sortNewestFirst = true;
  bool _showOtherNutrients = false;

  @override
  void initState() {
    super.initState();
    _watchRecentMeals();
  }

  void _watchRecentMeals() {
    _recentMealsSubscription?.cancel();
    _recentMealsSubscription = ref
        .read(nutritionServiceProvider)
        .watchRecentMeals()
        .listen(
          (meals) {
            if (!mounted) return;
            setState(() {
              _recentMeals = meals;
              _isLoadingMeals = false;
            });
          },
          onError: (_) {
            if (mounted) setState(() => _isLoadingMeals = false);
          },
        );
  }

  @override
  void dispose() {
    _recentMealsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _deleteMeal(int index) async {
    if (index < 0 || index >= _recentMeals.length) return;

    final meal = _recentMeals[index];
    final docId = meal['docId'] as String?;

    setState(() => _recentMeals.removeAt(index));

    if (docId != null) {
      await ref.read(nutritionServiceProvider).deleteMeal(docId);
    }
  }

  Future<bool> _confirmDeleteMeal(Map<String, dynamic> meal) async {
    final mealName = (meal['name'] as String?)?.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete meal?'),
        content: Text(
          mealName == null || mealName.isEmpty
              ? 'This meal will be removed from your recent meals.'
              : 'Remove "$mealName" from your recent meals?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );

    return confirmed ?? false;
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

  /// Detects allergens in a meal by checking ingredients against user allergies.
  List<String> _detectMealAllergens(
    Map<String, dynamic> meal,
    List<String> userAllergies,
  ) {
    if (userAllergies.isEmpty) return [];

    final ingredients = meal['ingredients'] as List<dynamic>? ?? [];
    final allergens = <String>[];

    for (final ing in ingredients) {
      if (ing is Map) {
        final ingName = (ing['name'] as String? ?? '').toLowerCase();
        for (final allergy in userAllergies) {
          if (ingName.contains(allergy.toLowerCase())) {
            final displayName = ing['name'] as String? ?? '';
            if (displayName.isNotEmpty && !allergens.contains(displayName)) {
              allergens.add(displayName);
            }
            break;
          }
        }
      }
    }

    return allergens;
  }

  static double _parseDecimal(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      return double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    }
    return 0;
  }

  static int _parseNumeric(dynamic raw) => _parseDecimal(raw).round();

  static String _formatDecimal(dynamic raw) {
    final value = _parseDecimal(raw);
    if (value == 0) return '0';
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  static String _mealCaloriesLabel(Map<String, dynamic> meal) {
    final nutrition = _safeMap(meal['nutrition']);
    return _formatDecimal(nutrition['calories'] ?? meal['calories']);
  }

  static Map<String, dynamic> _safeMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  Map<String, int> _calculateNutritionTotals() {
    int totalCalories = 0;
    int totalProtein = 0;
    int totalCarbs = 0;
    int totalFat = 0;
    int totalFiber = 0;
    int totalSugar = 0;
    int totalSodium = 0;
    int totalCholesterol = 0;
    int totalSaturatedFat = 0;
    int totalTransFat = 0;
    int totalPotassium = 0;
    int totalCalcium = 0;
    int totalIron = 0;
    int totalVitaminD = 0;

    for (final meal in _recentMeals) {
      final nutrition = _safeMap(meal['nutrition']);
      totalCalories += _parseNumeric(nutrition['calories'] ?? meal['calories']);
      totalProtein += _parseNumeric(nutrition['protein']);
      totalCarbs += _parseNumeric(nutrition['carbs']);
      totalFat += _parseNumeric(nutrition['fat']);
      totalFiber += _parseNumeric(nutrition['fiber']);
      totalSugar += _parseNumeric(nutrition['sugar']);
      totalSodium += _parseNumeric(nutrition['sodium']);
      totalCholesterol += _parseNumeric(nutrition['cholesterol']);
      totalSaturatedFat += _parseNumeric(nutrition['saturatedFat']);
      totalTransFat += _parseNumeric(nutrition['transFat']);
      totalPotassium += _parseNumeric(nutrition['potassium']);
      totalCalcium += _parseNumeric(nutrition['calcium']);
      totalIron += _parseNumeric(nutrition['iron']);
      totalVitaminD += _parseNumeric(nutrition['vitaminD']);
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'fiber': totalFiber,
      'sugar': totalSugar,
      'sodium': totalSodium,
      'cholesterol': totalCholesterol,
      'saturatedFat': totalSaturatedFat,
      'transFat': totalTransFat,
      'potassium': totalPotassium,
      'calcium': totalCalcium,
      'iron': totalIron,
      'vitaminD': totalVitaminD,
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
        child: Material(
          color: Colors.transparent,
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
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          mealName,
                          style: TextStyle(
                            color: _navyBlue.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
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
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry?.remove();
    });
  }

  // ── Insight / Reminder Banner ─────────────────────────────────────────────

  /// Evaluates calories, protein, fat, and carbs and surfaces the single most
  /// important insight using a strict priority order.
  ///
  /// Calorie tiers (highest priority, checked first):
  ///   1. Significantly exceeded  (≥ 125%)
  ///   2. Exceeded                (110–124%)
  ///   3. Target reached          (100–109%)
  ///   4. Near limit              (90–99%)
  ///   5. Approaching limit       (75–89%)
  ///   6. Safe zone               (< 75%) → no calorie banner
  ///
  /// Macro tiers (only shown when calories are in the safe zone):
  ///   7. Protein low  (< 60%)
  ///   8. Fat low      (< 60%)
  ///   9. Carbs low    (< 60%)
  ///
  /// Only one banner is shown at a time.
  Widget? _buildNutritionInsightBanner({
    required int totalCalories,
    required int dailyCalories,
    required int totalProtein,
    required int dailyProtein,
    required int totalFat,
    required int dailyFat,
    required int totalCarbs,
    required int dailyCarbs,
  }) {
    final calRatio = dailyCalories > 0 ? totalCalories / dailyCalories : 0.0;
    final calPercent = (calRatio * 100).round();

    // ── 1. Significantly exceeded (≥ 125%) ───────────────────────────────
    if (calRatio >= 1.25) {
      return _InsightBanner(
        icon: Icons.warning_rounded,
        iconColor: const Color(0xFFD32F2F),
        backgroundColor: const Color(0xFFFFF0F0),
        borderColor: const Color(0xFFD32F2F),
        title:
            "Today's intake is significantly above your target ($calPercent%)",
        message:
            'Consider balancing tomorrow\'s meals and activity levels. Every step counts.',
        action: _InsightAction(
          label: 'Go to Workout',
          icon: Icons.fitness_center_rounded,
          onTap: widget.onGoToWorkout ?? () {},
        ),
      );
    }

    // ── 2. Exceeded (110–124%) ────────────────────────────────────────────
    if (calRatio >= 1.10) {
      final overCal = totalCalories - dailyCalories;
      return _InsightBanner(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFE65100),
        backgroundColor: const Color(0xFFFFF3E0),
        borderColor: const Color(0xFFE65100),
        title: 'You exceeded your target by $overCal calories',
        message:
            'A short walk or a lighter dinner may help balance your intake today.',
        action: _InsightAction(
          label: 'Go to Workout',
          icon: Icons.fitness_center_rounded,
          onTap: widget.onGoToWorkout ?? () {},
        ),
      );
    }

    // ── 3. Target reached (100–109%) ─────────────────────────────────────
    if (calRatio >= 1.0) {
      return _InsightBanner(
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF2E7D32),
        backgroundColor: const Color(0xFFF1F8E9),
        borderColor: const Color(0xFF2E7D32),
        title: "You've reached today's calorie goal ($calPercent%)",
        message:
            'Additional meals may push you over your target intake. Listen to your body.',
      );
    }

    // ── 4. Near limit (90–99%) ────────────────────────────────────────────
    if (calRatio >= 0.9) {
      return _InsightBanner(
        icon: Icons.info_outline_rounded,
        iconColor: const Color(0xFFE8A200),
        backgroundColor: const Color(0xFFFFFBED),
        borderColor: const Color(0xFFE8A200),
        title: "You're close to your daily calorie target ($calPercent%)",
        message: 'Consider lighter meals or snacks for the rest of the day.',
      );
    }

    // ── 5. Approaching limit (75–89%) ─────────────────────────────────────
    if (calRatio >= 0.75) {
      return _InsightBanner(
        icon: Icons.info_outline_rounded,
        iconColor: const Color(0xFF1565C0),
        backgroundColor: const Color(0xFFE3F2FD),
        borderColor: const Color(0xFF1565C0),
        title: "You've consumed $calPercent% of your daily calories",
        message: 'Keep an eye on portion sizes for your next meals.',
      );
    }

    // ── 6. Safe zone (< 75%) — check macros instead ───────────────────────

    // ── 7. Protein low (< 60%) ────────────────────────────────────────────
    final proRatio = dailyProtein > 0 ? totalProtein / dailyProtein : 1.0;
    if (proRatio < 0.6 && totalCalories > 0) {
      final remaining = dailyProtein - totalProtein;
      return _InsightBanner(
        icon: Icons.fitness_center_outlined,
        iconColor: const Color(0xFF1976D2),
        backgroundColor: const Color(0xFFE3F2FD),
        borderColor: const Color(0xFF1976D2),
        title: 'Protein is at ${(proRatio * 100).round()}% of your daily goal',
        message:
            'You still need ${remaining}g. Try adding eggs, chicken, or legumes to your next meal.',
      );
    }

    // ── 8. Fat low (< 60%) ────────────────────────────────────────────────
    final fatRatio = dailyFat > 0 ? totalFat / dailyFat : 1.0;
    if (fatRatio < 0.6 && totalCalories > 0) {
      final remaining = dailyFat - totalFat;
      return _InsightBanner(
        icon: Icons.water_drop_outlined,
        iconColor: const Color(0xFF00897B),
        backgroundColor: const Color(0xFFE0F2F1),
        borderColor: const Color(0xFF00897B),
        title:
            'Healthy fats are at ${(fatRatio * 100).round()}% of your daily goal',
        message:
            'You still need ${remaining}g. Nuts, avocado, or olive oil can help.',
      );
    }

    // ── 9. Carbs low (< 60%) ─────────────────────────────────────────────
    final carbRatio = dailyCarbs > 0 ? totalCarbs / dailyCarbs : 1.0;
    if (carbRatio < 0.6 && totalCalories > 0) {
      final remaining = dailyCarbs - totalCarbs;
      return _InsightBanner(
        icon: Icons.bolt_outlined,
        iconColor: const Color(0xFF6A1B9A),
        backgroundColor: const Color(0xFFF3E5F5),
        borderColor: const Color(0xFF6A1B9A),
        title: 'Carbs are at ${(carbRatio * 100).round()}% of your daily goal',
        message:
            'You still need ${remaining}g. Whole grains or fruit can give you a quick energy boost.',
      );
    }

    // No notable issue
    return null;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
    final totalSugar = totals['sugar'] ?? 0;
    final totalSodium = totals['sodium'] ?? 0;
    final totalCholesterol = totals['cholesterol'] ?? 0;
    final totalSaturatedFat = totals['saturatedFat'] ?? 0;
    final totalTransFat = totals['transFat'] ?? 0;
    final totalPotassium = totals['potassium'] ?? 0;
    final totalCalcium = totals['calcium'] ?? 0;
    final totalIron = totals['iron'] ?? 0;
    final totalVitaminD = totals['vitaminD'] ?? 0;

    final dailyMacrosAsync = ref.watch(dailyMacrosProvider);

    return dailyMacrosAsync.when(
      data: (dailyMacros) {
        return _buildNutritionCardContent(
          totalCalories: totalCalories,
          totalProtein: totalProtein,
          totalCarbs: totalCarbs,
          totalFat: totalFat,
          totalFiber: totalFiber,
          totalSugar: totalSugar,
          totalSodium: totalSodium,
          totalCholesterol: totalCholesterol,
          totalSaturatedFat: totalSaturatedFat,
          totalTransFat: totalTransFat,
          totalPotassium: totalPotassium,
          totalCalcium: totalCalcium,
          totalIron: totalIron,
          totalVitaminD: totalVitaminD,
          dailyCalories: dailyMacros?.calories ?? 2000,
          dailyProtein: dailyMacros?.protein ?? 150,
          dailyCarbs: dailyMacros?.carbs ?? 225,
          dailyFat: dailyMacros?.fat ?? 65,
          dailyFiber: dailyMacros?.fiber ?? 25,
          dailySugar: dailyMacros?.sugar ?? 50,
          dailySodium: dailyMacros?.sodium ?? 2300,
          dailyCholesterol: dailyMacros?.cholesterol ?? 300,
          dailySaturatedFat: dailyMacros?.saturatedFat ?? 20,
          dailyTransFat: dailyMacros?.transFat ?? 2,
          dailyPotassium: dailyMacros?.potassium ?? 3500,
          dailyCalcium: dailyMacros?.calcium ?? 1000,
          dailyIron: dailyMacros?.iron ?? 18,
          dailyVitaminD: dailyMacros?.vitaminD ?? 20,
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
      error: (_, stackTrace) => _buildNutritionCardContent(
        totalCalories: totalCalories,
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
        totalFiber: totalFiber,
        totalSugar: totalSugar,
        totalSodium: totalSodium,
        totalCholesterol: totalCholesterol,
        totalSaturatedFat: totalSaturatedFat,
        totalTransFat: totalTransFat,
        totalPotassium: totalPotassium,
        totalCalcium: totalCalcium,
        totalIron: totalIron,
        totalVitaminD: totalVitaminD,
        dailyCalories: 2000,
        dailyProtein: 150,
        dailyCarbs: 225,
        dailyFat: 65,
        dailyFiber: 25,
        dailySugar: 50,
        dailySodium: 2300,
        dailyCholesterol: 300,
        dailySaturatedFat: 20,
        dailyTransFat: 2,
        dailyPotassium: 3500,
        dailyCalcium: 1000,
        dailyIron: 18,
        dailyVitaminD: 20,
      ),
    );
  }

  Widget _buildNutritionCardContent({
    required int totalCalories,
    required int totalProtein,
    required int totalCarbs,
    required int totalFat,
    required int totalFiber,
    required int totalSugar,
    required int totalSodium,
    required int totalCholesterol,
    required int totalSaturatedFat,
    required int totalTransFat,
    required int totalPotassium,
    required int totalCalcium,
    required int totalIron,
    required int totalVitaminD,
    required int dailyCalories,
    required int dailyProtein,
    required int dailyCarbs,
    required int dailyFat,
    required int dailyFiber,
    required int dailySugar,
    required int dailySodium,
    required int dailyCholesterol,
    required int dailySaturatedFat,
    required int dailyTransFat,
    required int dailyPotassium,
    required int dailyCalcium,
    required int dailyIron,
    required int dailyVitaminD,
  }) {
    final insightBanner = _buildNutritionInsightBanner(
      totalCalories: totalCalories,
      dailyCalories: dailyCalories,
      totalProtein: totalProtein,
      dailyProtein: dailyProtein,
      totalFat: totalFat,
      dailyFat: dailyFat,
      totalCarbs: totalCarbs,
      dailyCarbs: dailyCarbs,
    );

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
          // ── Header ──
          Text(
            "Today's Nutrition",
            style: TextStyle(
              color: _navyBlue,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // ── Three circular progress rings ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircularMacroProgress(
                current: totalCalories,
                target: dailyCalories,
                label: 'Calories',
                unit: '',
                color: _navyBlue,
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
                color: _navyBlue,
              ),
            ],
          ),

          // ── Insight / Reminder Banner ────────────────────────────────────
          if (insightBanner != null) ...[
            const SizedBox(height: 16),
            insightBanner,
          ],

          // ── "Show / Hide other nutrients" toggle button ──
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _showOtherNutrients = !_showOtherNutrients),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _showOtherNutrients
                      ? _green.withValues(alpha: 0.12)
                      : _lightGray,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showOtherNutrients
                        ? _green.withValues(alpha: 0.35)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showOtherNutrients
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16,
                      color: _showOtherNutrients
                          ? _green
                          : const Color(0xFF999999),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showOtherNutrients
                          ? 'Hide other nutrients'
                          : 'Show other nutrients',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _navyBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Animated collapsible section ──────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                _buildGroupTitle('Fats'),
                const SizedBox(height: 12),
                _buildHorizontalMacroBar(
                  label: 'Total fat',
                  current: totalFat,
                  target: dailyFat,
                  unit: 'g',
                  color: _green,
                ),
                const SizedBox(height: 14),
                _buildHorizontalMacroBar(
                  label: 'Saturated fat',
                  current: totalSaturatedFat,
                  target: dailySaturatedFat,
                  unit: 'g',
                  color: const Color(0xFFE24B4A),
                ),
                const SizedBox(height: 14),
                _buildHorizontalMacroBar(
                  label: 'Trans fat',
                  current: totalTransFat,
                  target: dailyTransFat,
                  unit: 'g',
                  color: Colors.grey[500]!,
                  isLimitOnly: true,
                  alwaysShowTrack: true,
                ),
                const SizedBox(height: 14),
                _buildHorizontalMacroBar(
                  label: 'Cholesterol',
                  current: totalCholesterol,
                  target: dailyCholesterol,
                  unit: 'mg',
                  color: const Color(0xFFD85A30),
                ),

                const SizedBox(height: 20),

                _buildGroupTitle('Carbohydrates'),
                const SizedBox(height: 12),
                _buildHorizontalMacroBar(
                  label: 'Fiber',
                  current: totalFiber,
                  target: dailyFiber,
                  unit: 'g',
                  color: Colors.grey[600]!,
                ),
                const SizedBox(height: 14),
                _buildHorizontalMacroBar(
                  label: 'Sugar',
                  current: totalSugar,
                  target: dailySugar,
                  unit: 'g',
                  color: const Color(0xFFFFB84D),
                ),

                const SizedBox(height: 20),

                _buildGroupTitle('Minerals & Others'),
                const SizedBox(height: 12),
                _buildHorizontalMacroBar(
                  label: 'Sodium',
                  current: totalSodium,
                  target: dailySodium,
                  unit: 'mg',
                  color: const Color(0xFF378ADD),
                ),
                const SizedBox(height: 14),
                _buildHorizontalMacroBar(
                  label: 'Potassium',
                  current: totalPotassium,
                  target: dailyPotassium,
                  unit: 'mg',
                  color: const Color(0xFF534AB7),
                ),
                const SizedBox(height: 14),
                _buildHorizontalMacroBar(
                  label: 'Calcium',
                  current: totalCalcium,
                  target: dailyCalcium,
                  unit: 'mg',
                  color: const Color(0xFF0F6E56),
                ),
                const SizedBox(height: 14),
                _buildHorizontalMacroBar(
                  label: 'Iron',
                  current: totalIron,
                  target: dailyIron,
                  unit: 'mg',
                  color: const Color(0xFF993C1D),
                ),
                const SizedBox(height: 14),
                _buildHorizontalMacroBar(
                  label: 'Vitamin D',
                  current: totalVitaminD,
                  target: dailyVitaminD,
                  unit: 'mcg',
                  color: const Color(0xFFBA7517),
                  alwaysShowTrack: true,
                ),
              ],
            ),
            crossFadeState: _showOtherNutrients
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF999999),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildHorizontalMacroBar({
    required String label,
    required int current,
    required int target,
    required String unit,
    required Color color,
    bool isLimitOnly = false,
    bool alwaysShowTrack = false,
  }) {
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.5) : 0.0;
    final isExceeded = current > target;

    final effectiveColor = isLimitOnly && current > 0
        ? const Color(0xFFFF6B35)
        : isExceeded
        ? const Color(0xFFFF6B35)
        : _navyBlue;

    final valueLabel = isLimitOnly
        ? '$current $unit'
        : '$current / $target $unit';

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
              valueLabel,
              style: TextStyle(
                color: _navyBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _lightGray,
            borderRadius: BorderRadius.circular(6),
          ),
          child: (percentage > 0 || alwaysShowTrack)
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: percentage.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: effectiveColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                )
              : null,
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
                          'Meal Ideas Generator',
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
      confirmDismiss: (_) async {
        final confirmed = await _confirmDeleteMeal(meal);
        if (confirmed && mounted) {
          await _deleteMeal(index);
        }
        return false;
      },
      child: Column(
        children: [
          Consumer(
            builder: (context, ref, child) {
              final healthProfileAsync = ref.watch(healthProfileProvider);
              final allergens = healthProfileAsync.when(
                data: (profile) => profile != null
                    ? _detectMealAllergens(meal, profile.allergies)
                    : <String>[],
                loading: () => <String>[],
                error: (_, stackTrace) => <String>[],
              );

              if (allergens.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF5A875).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFC65C1A),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contains allergen(s)',
                                style: TextStyle(
                                  color: Color(0xFFC65C1A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                allergens.join(', '),
                                style: const TextStyle(
                                  color: Color(0xFF8B4513),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Container(
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
                      if (meal['servingAmount'] != null &&
                          meal['servingAmount'].toString().trim().isNotEmpty &&
                          meal['servingUnit'] != null &&
                          meal['servingUnit'].toString().trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '${meal['servingAmount']} ${meal['servingUnit']}',
                            style: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _mealCaloriesLabel(meal),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable insight banner widget ────────────────────────────────────────────

class _InsightAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _InsightAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _InsightBanner extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String title;
  final String message;
  final _InsightAction? action;

  const _InsightBanner({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: TextStyle(
                        color: iconColor.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: action!.onTap,
                  icon: Icon(action!.icon, size: 15, color: Colors.white),
                  label: Text(
                    action!.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
