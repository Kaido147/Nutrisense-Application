import 'package:flutter/material.dart';

class NutritionModal extends StatelessWidget {
  final Map<String, dynamic> meal;
  final VoidCallback onBack;
  final VoidCallback onSelectMeal;

  static const Color _navyBlue = Color(0xFF273967);
  static const Color _green = Color(0xFF00D084);

  const NutritionModal({
    super.key,
    required this.meal,
    required this.onBack,
    required this.onSelectMeal,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.75;

    // Nutrition data — use meal['nutrition'] if provided, otherwise fallback
    final nutrition =
        (meal['nutrition'] as Map<String, dynamic>?) ??
        {
          'calories': '420 kcal',
          'protein': '32g',
          'carbs': '48g',
          'fat': '12g',
          'fiber': '6g',
          'sugar': '8g',
          'sodium': '540mg',
          'cholesterol': '85mg',
        };

    final macros = [
      _MacroItem(
        label: 'Calories',
        value: nutrition['calories'] ?? '—',
        icon: Icons.local_fire_department,
        color: const Color(0xFFFF6B35),
        fillRatio: 0.72,
      ),
      _MacroItem(
        label: 'Protein',
        value: nutrition['protein'] ?? '—',
        icon: Icons.fitness_center,
        color: _navyBlue,
        fillRatio: 0.64,
      ),
      _MacroItem(
        label: 'Carbs',
        value: nutrition['carbs'] ?? '—',
        icon: Icons.grain,
        color: const Color(0xFFFFB84D),
        fillRatio: 0.55,
      ),
      _MacroItem(
        label: 'Fat',
        value: nutrition['fat'] ?? '—',
        icon: Icons.water_drop,
        color: _green,
        fillRatio: 0.28,
      ),
    ];

    final extras = [
      _ExtraItem(label: 'Fiber', value: nutrition['fiber'] ?? '—'),
      _ExtraItem(label: 'Sugar', value: nutrition['sugar'] ?? '—'),
      _ExtraItem(label: 'Sodium', value: nutrition['sodium'] ?? '—'),
      _ExtraItem(label: 'Cholesterol', value: nutrition['cholesterol'] ?? '—'),
    ];

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
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            color: _navyBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nutrition Facts',
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
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meal name chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _navyBlue.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            meal['name'] ?? '',
                            style: TextStyle(
                              color: _navyBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Macro cards
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.55,
                          children: macros
                              .map((m) => _MacroCard(item: m))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        // Divider label
                        const Text(
                          'OTHER NUTRIENTS',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Extra nutrient rows
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFEEEEEE),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: extras.asMap().entries.map((entry) {
                              final isLast = entry.key == extras.length - 1;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.value.label,
                                          style: const TextStyle(
                                            color: Color(0xFF666666),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          entry.value.value,
                                          style: TextStyle(
                                            color: _navyBlue,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFEEEEEE),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onSelectMeal();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _navyBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onBack();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF5F5F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            '← Back to Meal',
                            style: TextStyle(
                              color: _navyBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ─── Private helpers ───────────────────────────────────────────────────────

class _MacroItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double fillRatio;

  const _MacroItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.fillRatio,
  });
}

class _ExtraItem {
  final String label;
  final String value;

  const _ExtraItem({required this.label, required this.value});
}

class _MacroCard extends StatelessWidget {
  final _MacroItem item;

  const _MacroCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(item.icon, color: item.color, size: 16),
              const SizedBox(width: 5),
              Text(
                item.label,
                style: TextStyle(
                  color: item.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            item.value,
            style: TextStyle(
              color: item.color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.fillRatio,
              backgroundColor: item.color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
