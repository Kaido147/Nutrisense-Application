import 'package:flutter/material.dart';
import 'nutrition_modal.dart';
import 'cooking_steps_modal.dart';
import 'ingredient_matcher.dart';
import '../log_meal_modal.dart';

class MealResultsModal extends StatefulWidget {
  final List<Map<String, dynamic>> meals;
  final VoidCallback onBackPressed;
  final List<Map<String, String>> userIngredients;
  final String selectedMealType;

  /// Allergies from the user's health profile (e.g. ['peanuts', 'shellfish']).
  final List<String> userAllergies;

  const MealResultsModal({
    super.key,
    required this.meals,
    required this.onBackPressed,
    this.userIngredients = const [],
    this.selectedMealType = 'Any',
    this.userAllergies = const [],
  });

  @override
  State<MealResultsModal> createState() => _MealResultsModalState();
}

class _MealResultsModalState extends State<MealResultsModal> {
  static const Color _navyBlue = Color(0xFF273967);
  static const Color _green = Color(0xFF00D084);
  static const Color _lightGray = Color(0xFFF5F5F5);
  static const Color _allergyOrange = Color(0xFFF5A875);
  static const Color _allergyOrangeDark = Color(0xFFC65C1A);
  static const Color _allergyOrangeBg = Color(0xFFFFF3ED);

  // ── Allergy detection ─────────────────────────────────────────────────────

  List<String> _detectAllergens(List<Map<String, String>> recipeIngredients) {
    if (widget.userAllergies.isEmpty) return [];
    return recipeIngredients
        .where((ing) {
          final name = (ing['name'] ?? '').toLowerCase();
          return widget.userAllergies.any(
            (a) => name.contains(a.toLowerCase()),
          );
        })
        .map((ing) => ing['name'] ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openNutritionModal(BuildContext context, Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NutritionModal(
        meal: meal,
        onBack: () {},
        onSelectMeal: () => _openCookingSteps(context, meal),
      ),
    );
  }

  /// Opens [CookingStepsModal]. When the user taps "Done" on the last step,
  /// [CookingStepsModal] pops with the meal map. We catch it here and open
  /// [LogMealModal] prefilled — no Firestore write happens until the user
  /// confirms in [LogMealModal].
  Future<void> _openCookingSteps(
    BuildContext context,
    Map<String, dynamic> meal,
  ) async {
    final completedMeal = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CookingStepsModal(meal: meal, onBack: () {}),
    );

    // User dismissed without finishing, or tapped "Back to Meal".
    if (completedMeal == null || !mounted || !context.mounted) return;

    await _openLogMealPrefilled(context, completedMeal);
  }

  /// Opens [LogMealModal] with the meal's name and per-serving nutrition
  /// prefilled. [LogMealModal] owns the Firestore write on confirmation.
  Future<void> _openLogMealPrefilled(
    BuildContext context,
    Map<String, dynamic> meal,
  ) async {
    // Use the same nutrition map shown on the meal result card so the value
    // the user chooses is the value that gets logged.
    final perServingNutrition =
        meal['nutrition'] ?? meal['nutritionPerServing'];
    final nutrition = _safeNutritionMap(perServingNutrition);
    final displayedCalories = nutrition['calories'] ?? meal['calories'];
    final mealType = _resolvedMealType(meal);

    final prefill = <String, dynamic>{
      'name': meal['name'] ?? '',
      'category': mealType,
      'type': mealType,
      // Default to 1 serving; user adjusts amount and unit in LogMealModal.
      'servingAmount': '1',
      'servingUnit': 'serving',
      // Nutrition values are per serving (MealService baseline = 1 serving).
      'calories': displayedCalories,
      'nutrition': nutrition,
      'nutritionPerServing': nutrition,
      'recipeNutritionPerServing': nutrition,
      'lockRecipeNutrition': true,
      'ingredients': meal['ingredients'] ?? const [],
      'servings': meal['servings'] ?? 1,
      'nutritionBasis': 'per 1 serving',
    };

    if (!mounted || !context.mounted) return;

    final saved = await LogMealModal.show(context, initialMeal: prefill);

    if (saved != null && mounted && context.mounted) {
      // Bubble the confirmed & saved meal all the way up through
      // GenerateMealIdeasModal so it can close itself too.
      Navigator.pop(context, saved);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Map<String, dynamic> _safeNutritionMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  String _resolvedMealType(Map<String, dynamic> meal) {
    if (widget.selectedMealType != 'Any') return widget.selectedMealType;

    final category = (meal['category'] ?? meal['type'] ?? '')
        .toString()
        .toLowerCase();
    if (category == 'breakfast') return 'Breakfast';
    if (category == 'dessert' ||
        category == 'starter' ||
        category == 'side' ||
        category == 'miscellaneous') {
      return 'Snack';
    }
    return 'Lunch';
  }

  static _StatusStyle _styleFor(MatchStatus status) {
    switch (status) {
      case MatchStatus.green:
        return const _StatusStyle(
          bg: Color(0xFFE8F8F3),
          border: Color(0xFF00D084),
          text: Color(0xFF00A86B),
          icon: Icons.check_circle,
          label: 'exact',
        );
      case MatchStatus.orange:
        return const _StatusStyle(
          bg: Color(0xFFFFF3E0),
          border: Color(0xFFFFB74D),
          text: Color(0xFFE65100),
          icon: Icons.swap_horiz_rounded,
          label: 'similar',
        );
      case MatchStatus.red:
        return const _StatusStyle(
          bg: Color(0xFFFFEDED),
          border: Color(0xFFFFCDD2),
          text: Color(0xFFE53935),
          icon: Icons.cancel,
          label: 'not used',
        );
      case MatchStatus.missing:
        return const _StatusStyle(
          bg: Color(0xFFF5F5F5),
          border: Color(0xFFDDDDDD),
          text: Color(0xFF666666),
          icon: Icons.help_outline,
          label: 'missing',
        );
    }
  }

  List<Map<String, String>> _toRecipeIngredients(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>)
        .whereType<Map>()
        .map((e) => Map<String, String>.from(e))
        .toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.7;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: modalHeight,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_bag, color: _navyBlue, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Generate Meal Ideas',
                            style: TextStyle(
                              color: _navyBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: _navyBlue, size: 24),
                      ),
                    ],
                  ),
                ),

                // ── Meal list ─────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero heading
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: _green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: _green,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Meal Ideas Generated!',
                                  style: TextStyle(
                                    color: _navyBlue,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Here are some delicious options you can make',
                                  style: TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),

                          // ── Meal cards ──────────────────────────────────
                          ...widget.meals.map((meal) {
                            final isLastItem = meal == widget.meals.last;

                            final nutrition =
                                meal['nutrition'] as Map<String, dynamic>?;

                            // Display calories with a per-serving label.
                            final caloriesRaw =
                                nutrition?['calories'] ?? meal['calories'];
                            final caloriesLabel = caloriesRaw != null
                                ? '$caloriesRaw / serving'
                                : '—';

                            final recipeIngredients = _toRecipeIngredients(
                              meal['ingredients'],
                            );

                            final result = matchIngredients(
                              userIngredients: widget.userIngredients,
                              recipeIngredients: recipeIngredients,
                            );

                            final allergens = _detectAllergens(
                              recipeIngredients,
                            );
                            final hasAllergens = allergens.isNotEmpty;

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: isLastItem ? 20 : 12,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: hasAllergens
                                        ? _allergyOrange
                                        : isLastItem
                                        ? _navyBlue
                                        : const Color(0xFFEEEEEE),
                                    width: hasAllergens || isLastItem ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Thumbnail
                                      if ((meal['thumbnail'] as String?)
                                              ?.isNotEmpty ==
                                          true)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.network(
                                            meal['thumbnail'] as String,
                                            height: 140,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const SizedBox.shrink(),
                                          ),
                                        ),
                                      if ((meal['thumbnail'] as String?)
                                              ?.isNotEmpty ==
                                          true)
                                        const SizedBox(height: 12),

                                      // Name
                                      Text(
                                        meal['name'] ?? '',
                                        style: TextStyle(
                                          color: _navyBlue,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        meal['description'] ?? '',
                                        style: const TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Stats row — calories show per serving
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 16,
                                            color: _navyBlue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            meal['time'] ?? '',
                                            style: TextStyle(
                                              color: _navyBlue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.local_dining,
                                            size: 16,
                                            color: _navyBlue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            meal['difficulty'] ?? '',
                                            style: TextStyle(
                                              color: _navyBlue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.local_fire_department,
                                            size: 16,
                                            color: _green,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              caloriesLabel,
                                              style: TextStyle(
                                                color: _green,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // ── Allergy alert ─────────────────────
                                      if (hasAllergens)
                                        _AllergyAlertBanner(
                                          allergens: allergens,
                                        ),
                                      if (hasAllergens ||
                                          widget.userAllergies.isNotEmpty)
                                        const SizedBox(height: 12),

                                      // Match score badge
                                      _MatchScoreBadge(
                                        score: result.scorePercent,
                                        matchedCount:
                                            result.matchedIngredients.length,
                                        totalCount: recipeIngredients.length,
                                      ),
                                      const SizedBox(height: 14),

                                      // ── Required ingredients ──────────────
                                      const Text(
                                        'REQUIRED INGREDIENTS:',
                                        style: TextStyle(
                                          color: Color(0xFF999999),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: result.recipeDetails.map((
                                          detail,
                                        ) {
                                          final measure =
                                              recipeIngredients.firstWhere(
                                                (r) =>
                                                    r['name'] ==
                                                    detail.recipeIngredient,
                                                orElse: () => {},
                                              )['measure'] ??
                                              '';
                                          final label = measure.isNotEmpty
                                              ? '$measure ${detail.recipeIngredient}'
                                              : detail.recipeIngredient;
                                          final s = _styleFor(detail.status);
                                          final isAllergen = allergens.any(
                                            (a) =>
                                                a.toLowerCase() ==
                                                detail.recipeIngredient
                                                    .toLowerCase(),
                                          );
                                          return Chip(
                                            label: Text(label),
                                            backgroundColor: isAllergen
                                                ? _allergyOrangeBg
                                                : s.bg,
                                            labelStyle: TextStyle(
                                              color: isAllergen
                                                  ? _allergyOrangeDark
                                                  : s.text,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            side: BorderSide(
                                              color: isAllergen
                                                  ? _allergyOrange
                                                  : s.border,
                                              width: isAllergen ? 1.5 : 1,
                                            ),
                                            avatar: isAllergen
                                                ? Icon(
                                                    Icons.warning_amber_rounded,
                                                    size: 14,
                                                    color: _allergyOrangeDark,
                                                  )
                                                : (detail.status !=
                                                          MatchStatus.missing
                                                      ? Icon(
                                                          s.icon,
                                                          size: 14,
                                                          color: s.text,
                                                        )
                                                      : null),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 14),

                                      // ── Using your ingredients ────────────
                                      const Text(
                                        'USING YOUR INGREDIENTS:',
                                        style: TextStyle(
                                          color: Color(0xFF999999),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: result.userStatuses.map((us) {
                                          final s = _styleFor(us.status);
                                          return Chip(
                                            label: Text(us.userIngredient),
                                            backgroundColor: s.bg,
                                            labelStyle: TextStyle(
                                              color: s.text,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            side: BorderSide(
                                              color: s.border,
                                              width: 1.5,
                                            ),
                                            avatar: Icon(
                                              s.icon,
                                              size: 14,
                                              color: s.text,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 16),

                                      // View Nutritions button
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _openNutritionModal(
                                            context,
                                            meal,
                                          ),
                                          icon: Icon(
                                            Icons.bar_chart_rounded,
                                            size: 18,
                                            color: _navyBlue,
                                          ),
                                          label: Text(
                                            'View Nutritions',
                                            style: TextStyle(
                                              color: _navyBlue,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: _navyBlue,
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Select This Meal — opens cooking steps,
                                      // then LogMealModal for final confirmation.
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: hasAllergens
                                              ? null
                                              : () => _openCookingSteps(
                                                  context,
                                                  meal,
                                                ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: hasAllergens
                                                ? Colors.grey.shade300
                                                : _navyBlue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          child: Text(
                                            hasAllergens
                                                ? 'Not recommended (allergens)'
                                                : 'Select This Meal',
                                            style: TextStyle(
                                              color: hasAllergens
                                                  ? Colors.grey.shade600
                                                  : Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Back button ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: widget.onBackPressed,
                      style: TextButton.styleFrom(
                        backgroundColor: _lightGray,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        '← Back to Ingredients',
                        style: TextStyle(
                          color: _navyBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

class _AllergyAlertBanner extends StatelessWidget {
  final List<String> allergens;

  const _AllergyAlertBanner({required this.allergens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3ED),
        border: Border.all(color: const Color(0xFFF5A875)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFC65C1A),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Allergy warning',
                  style: TextStyle(
                    color: Color(0xFFC65C1A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'This meal contains ingredients matching your allergies:',
                  style: TextStyle(color: Color(0xFF9B4A16), fontSize: 11),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: allergens
                      .map(
                        (a) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5A875),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            a,
                            style: const TextStyle(
                              color: Color(0xFF5A2800),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  final Color bg;
  final Color border;
  final Color text;
  final IconData icon;
  final String label;

  const _StatusStyle({
    required this.bg,
    required this.border,
    required this.text,
    required this.icon,
    required this.label,
  });
}

class _MatchScoreBadge extends StatelessWidget {
  final int score;
  final int matchedCount;
  final int totalCount;

  const _MatchScoreBadge({
    required this.score,
    required this.matchedCount,
    required this.totalCount,
  });

  Color get _color {
    if (score >= 70) return const Color(0xFF00A86B);
    if (score >= 40) return const Color(0xFFE65100);
    return const Color(0xFFE53935);
  }

  Color get _bg {
    if (score >= 70) return const Color(0xFFE8F8F3);
    if (score >= 40) return const Color(0xFFFFF3E0);
    return const Color(0xFFFFEDED);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_rounded, size: 14, color: _color),
          const SizedBox(width: 6),
          Text(
            '$matchedCount / $totalCount matched  •  $score%',
            style: TextStyle(
              color: _color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
