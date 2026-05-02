import 'package:flutter/material.dart';
import 'nutrition_modal.dart';
import 'cooking_steps_modal.dart';
import 'ingredient_matcher.dart';

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
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CookingStepsModal(meal: meal, onBack: () {}),
    ).then((completedMeal) {
      if (completedMeal != null && mounted) {
        // Meal was completed, pass it back to GenerateMealIdeasModal
        Navigator.pop(context, completedMeal);
      }
    });
  }

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
                            final caloriesLabel =
                                nutrition?['calories'] ??
                                meal['calories'] ??
                                '—';

                            final recipeIngredients = _toRecipeIngredients(
                              meal['ingredients'],
                            );

                            final result = matchIngredients(
                              userIngredients: widget.userIngredients,
                              recipeIngredients: recipeIngredients,
                            );

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

                                      // Match score badge
                                      _MatchScoreBadge(
                                        score: result.scorePercent,
                                        matchedCount:
                                            result.matchedIngredients.length,
                                        totalCount: recipeIngredients.length,
                                      ),
                                      const SizedBox(height: 14),

                                      // ── REQUIRED INGREDIENTS ────────────
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

                                          final hint = detail.quantityHint;
                                          final suffix =
                                              (hint != null &&
                                                  hint.mayNotBeEnough)
                                              ? ' ⚠ need ${hint.recipeAmount.toStringAsFixed(0)} ${hint.unit}'
                                              : '';

                                          return Chip(
                                            label: Text('$label$suffix'),
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
                                            avatar:
                                                detail.status !=
                                                    MatchStatus.missing
                                                ? Icon(
                                                    s.icon,
                                                    size: 14,
                                                    color: s.text,
                                                  )
                                                : null,
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
                                        children: result.userStatuses.map((us) {
                                          final s = _styleFor(us.status);

                                          // Quantity warning suffix (only if truly insufficient)
                                          final hint = us.quantityHint;
                                          final warnSuffix =
                                              (hint != null &&
                                                  hint.mayNotBeEnough)
                                              ? ' (need: ${hint.recipeAmount.toStringAsFixed(0)} ${hint.unit})'
                                              : '';

                                          // ── Show quantity from user's input ──
                                          // Look up the original entry to get
                                          // whatever quantity the user typed.
                                          final originalUser = widget
                                              .userIngredients
                                              .firstWhere(
                                                (u) =>
                                                    u['ingredient'] ==
                                                    us.userIngredient,
                                                orElse: () => {},
                                              );
                                          final qty =
                                              originalUser['quantity'] ?? '';

                                          // Format: "Chicken · 5 pcs (need: 450 g)"
                                          // or just "Chicken · 5 pcs"
                                          // or just "Chicken" if no quantity entered
                                          final displayLabel = qty.isNotEmpty
                                              ? '${us.userIngredient} · $qty$warnSuffix'
                                              : '${us.userIngredient}$warnSuffix';

                                          return Chip(
                                            label: Text(displayLabel),
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

                                      // View Nutritions
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

                                      // Select This Meal
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

// ─────────────────────────────────────────────────────────────────────────────
// Helper classes
// ─────────────────────────────────────────────────────────────────────────────

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

class _MatchLegend extends StatelessWidget {
  const _MatchLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(const Color(0xFF00A86B)),
        const SizedBox(width: 4),
        const Text(
          'Exact',
          style: TextStyle(fontSize: 10, color: Color(0xFF666666)),
        ),
        const SizedBox(width: 10),
        _dot(const Color(0xFFE65100)),
        const SizedBox(width: 4),
        const Text(
          'Similar',
          style: TextStyle(fontSize: 10, color: Color(0xFF666666)),
        ),
        const SizedBox(width: 10),
        _dot(const Color(0xFF666666)),
        const SizedBox(width: 4),
        const Text(
          'Missing',
          style: TextStyle(fontSize: 10, color: Color(0xFF666666)),
        ),
        const SizedBox(width: 10),
        _dot(const Color(0xFFE53935)),
        const SizedBox(width: 4),
        const Text(
          'Not needed',
          style: TextStyle(fontSize: 10, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _dot(Color color) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
