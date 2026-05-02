import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'nutrition_modal.dart';
import 'cooking_steps_modal.dart';

class MealResultsModal extends StatefulWidget {
  final List<Map<String, dynamic>> meals;
  final VoidCallback onBackPressed;
  final List<Map<String, String>> userIngredients;

  const MealResultsModal({
    super.key,
    required this.meals,
    required this.onBackPressed,
    this.userIngredients = const [],
  });

  @override
  State<MealResultsModal> createState() => _MealResultsModalState();
}

class _MealResultsModalState extends State<MealResultsModal> {
  static const Color _navyBlue = Color(0xFF273967);
  static const Color _green = Color(0xFF00D084);
  static const Color _lightGray = Color(0xFFF5F5F5);

  bool _ingredientMatches(String recipeName, String userInput) {
    final recipe = recipeName.toLowerCase().trim();
    final user = userInput.toLowerCase().trim();

    final recipeWords = recipe.split(RegExp(r'\s+'));
    final userWords = user.split(RegExp(r'\s+'));

    // Check if all user words appear in recipe words
    final allMatch = userWords.every((uw) => recipeWords.any((rw) => rw == uw));
    if (allMatch && recipeWords.length <= userWords.length + 1) return true;

    // Also check simplified — strip descriptors from both sides and compare
    final simplifiedRecipe = _simplifyForMatching(recipe);
    final simplifiedUser = _simplifyForMatching(user);

    if (simplifiedRecipe == simplifiedUser) return true;

    // Check if simplified user words all appear in simplified recipe words
    final sRecipeWords = simplifiedRecipe.split(RegExp(r'\s+'));
    final sUserWords = simplifiedUser.split(RegExp(r'\s+'));
    return sUserWords.every((uw) => sRecipeWords.any((rw) => rw == uw)) &&
        sRecipeWords.length <= sUserWords.length + 1;
  }

  // Same descriptor list as _simplifyIngredient in meal_services.dart
  String _simplifyForMatching(String text) {
    const descriptors = [
      'boneless',
      'skinless',
      'fresh',
      'frozen',
      'dried',
      'ground',
      'chopped',
      'sliced',
      'diced',
      'minced',
      'cooked',
      'raw',
      'whole',
      'half',
      'large',
      'small',
      'medium',
      'big',
      'lean',
      'thick',
      'thin',
      'baby',
      'organic',
      'ripe',
      'breast',
      'thigh',
      'fillet',
      'wing',
      'leg',
    ];
    final words = text
        .split(RegExp(r'\s+'))
        .where((w) => !descriptors.contains(w))
        .toList();
    return words.isEmpty ? text : words.join(' ');
  }

  // Extracts the first number from a string (e.g. "12" from "12 Bacon")
  double? _extractNumber(String text) {
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(text);
    return match != null ? double.tryParse(match.group(1)!) : null;
  }

  // Returns true only if the measure contains a unit word (not just a plain count)
  bool _hasSpecificMeasure(String measure) {
    if (measure.trim().isEmpty) return false;
    return RegExp(
      r'\b(g|kg|ml|l|cup|cups|tbsp|tsp|tablespoon|teaspoon|oz|lb|pound|pinch|clove|cloves|slice|slices)\b',
      caseSensitive: false,
    ).hasMatch(measure);
  }

  void _openNutritionModal(BuildContext context, Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NutritionModal(
        meal: meal,
        onBack: () {},
        onSelectMeal: () => _openCookingStepsModal(context, meal),
      ),
    );
  }

  void _openCookingStepsModal(BuildContext context, Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CookingStepsModal(meal: meal, onBack: () {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.7;

    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
        ),
        // Bottom sheet content
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
                // ── Header ──────────────────────────────────────────────────
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

                // ── Meal list ────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Success header
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

                          // ── Meal cards ───────────────────────────────────
                          ...widget.meals.map((meal) {
                            final isLastItem = meal == widget.meals.last;

                            final nutrition =
                                meal['nutrition'] as Map<String, dynamic>?;
                            final caloriesLabel =
                                nutrition?['calories'] ??
                                meal['calories'] ??
                                '—';

                            final rawIngredients = meal['ingredients'];
                            final ingredients = rawIngredients == null
                                ? <Map<String, String>>[]
                                : (rawIngredients as List<dynamic>)
                                      .whereType<Map>()
                                      .map((e) => Map<String, String>.from(e))
                                      .toList();

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: isLastItem ? 20 : 12,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: isLastItem
                                        ? _navyBlue
                                        : const Color(0xFFEEEEEE),
                                    width: isLastItem ? 2 : 1,
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
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox.shrink(),
                                          ),
                                        ),
                                      if ((meal['thumbnail'] as String?)
                                              ?.isNotEmpty ==
                                          true)
                                        const SizedBox(height: 12),

                                      // Meal name
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

                                      // Stats row
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
                                          Text(
                                            caloriesLabel,
                                            style: TextStyle(
                                              color: _green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // ── REQUIRED INGREDIENTS ─────────────
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
                                        children: ingredients.map((ing) {
                                          final label =
                                              (ing['measure']?.isNotEmpty ==
                                                  true)
                                              ? '${ing['measure']} ${ing['name']}'
                                              : ing['name'] ?? '';

                                          final matchedUser = widget
                                              .userIngredients
                                              .firstWhereOrNull(
                                                (u) => _ingredientMatches(
                                                  ing['name'] ?? '',
                                                  u['ingredient'] ?? '',
                                                ),
                                              );
                                          final isMatched = matchedUser != null;

                                          final recipeNum = _extractNumber(
                                            ing['measure'] ?? '',
                                          );
                                          final userNum = _extractNumber(
                                            matchedUser?['quantity'] ?? '',
                                          );
                                          final isInsufficient =
                                              isMatched &&
                                              recipeNum != null &&
                                              userNum != null &&
                                              userNum < recipeNum;

                                          final needsWarning =
                                              isMatched && isInsufficient;

                                          return Chip(
                                            label: Text(label),
                                            backgroundColor: !isMatched
                                                ? const Color(0xFFF5F5F5)
                                                : needsWarning
                                                ? const Color(0xFFFFF3E0)
                                                : const Color(0xFFE8F8F3),
                                            labelStyle: TextStyle(
                                              color: !isMatched
                                                  ? const Color(0xFF666666)
                                                  : needsWarning
                                                  ? const Color(0xFFE65100)
                                                  : const Color(0xFF00A86B),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            side: BorderSide(
                                              color: !isMatched
                                                  ? const Color(0xFFDDDDDD)
                                                  : needsWarning
                                                  ? const Color(0xFFFFB74D)
                                                  : const Color(0xFF00D084),
                                              width: isMatched ? 1.5 : 1,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 14),

                                      // ── USING YOUR INGREDIENTS ───────────
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
                                        children: widget.userIngredients.map((
                                          userItem,
                                        ) {
                                          final userIng =
                                              userItem['ingredient'] ?? '';
                                          final userQty =
                                              userItem['quantity'] ?? '';

                                          final matchedIng = ingredients
                                              .firstWhereOrNull(
                                                (ing) => _ingredientMatches(
                                                  ing['name'] ?? '',
                                                  userIng,
                                                ),
                                              );

                                          final matchedInRecipe =
                                              matchedIng != null;
                                          final requiredMeasure =
                                              matchedIng?['measure']?.trim() ??
                                              '';

                                          final recipeNum = _extractNumber(
                                            requiredMeasure,
                                          );
                                          final userNum = _extractNumber(
                                            userQty,
                                          );
                                          final isInsufficient =
                                              matchedInRecipe &&
                                              recipeNum != null &&
                                              userNum != null &&
                                              userNum < recipeNum;

                                          final bgColor = !matchedInRecipe
                                              ? const Color(0xFFFFEDED)
                                              : isInsufficient
                                              ? const Color(0xFFFFF3E0)
                                              : const Color(0xFFE8F8F3);

                                          final borderColor = !matchedInRecipe
                                              ? const Color(0xFFFFCDD2)
                                              : isInsufficient
                                              ? const Color(0xFFFFB74D)
                                              : const Color(0xFF00D084);

                                          final textColor = !matchedInRecipe
                                              ? const Color(0xFFE53935)
                                              : isInsufficient
                                              ? const Color(0xFFE65100)
                                              : const Color(0xFF00A86B);

                                          final iconData = !matchedInRecipe
                                              ? Icons.cancel
                                              : isInsufficient
                                              ? Icons.warning_amber_rounded
                                              : Icons.check_circle;

                                          return Chip(
                                            label: Text(
                                              isInsufficient
                                                  ? '$userIng (need: $requiredMeasure)'
                                                  : userIng,
                                            ),
                                            backgroundColor: bgColor,
                                            labelStyle: TextStyle(
                                              color: textColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            side: BorderSide(
                                              color: borderColor,
                                              width: 1.5,
                                            ),
                                            avatar: Icon(
                                              iconData,
                                              size: 14,
                                              color: textColor,
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

                                      // Select This Meal button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _openCookingStepsModal(
                                                context,
                                                meal,
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _navyBlue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text(
                                            'Select This Meal',
                                            style: TextStyle(
                                              color: Colors.white,
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

                // ── Back button ──────────────────────────────────────────────
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
