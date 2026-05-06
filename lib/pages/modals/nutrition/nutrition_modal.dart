import 'package:flutter/material.dart';

class NutritionModal extends StatefulWidget {
  final Map<String, dynamic> meal;
  final VoidCallback onBack;
  final VoidCallback? onSelectMeal;

  const NutritionModal({
    super.key,
    required this.meal,
    required this.onBack,
    this.onSelectMeal,
  });

  @override
  State<NutritionModal> createState() => _NutritionModalState();
}

class _NutritionModalState extends State<NutritionModal> {
  static const Color _navyBlue = Color(0xFF273967);
  static const Color _green = Color(0xFF00D084);

  bool _showTotalNutrition = false;

  // Handles Map<dynamic, dynamic> returned by Firestore / JSON decoding.
  static Map<String, dynamic> _safeMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  // Returns a display string for calories regardless of whether the value
  // coming from the AI or Firestore is an int, double, or String.
  static String _parseCaloriesDisplay(
    Map<String, dynamic> meal,
    Map<String, dynamic> nutrition,
  ) {
    final raw = nutrition['calories'] ?? meal['calories'];
    if (raw == null) return 'N/A';
    if (raw is int) return '$raw kcal';
    if (raw is double) {
      final display = raw % 1 == 0
          ? raw.toInt().toString()
          : raw.toStringAsFixed(1);
      return '$display kcal';
    }
    if (raw is String) {
      final lower = raw.toLowerCase();
      // Already contains the unit, e.g. "450 kcal"
      if (lower.contains('kcal') || lower.contains('cal')) return raw;
      // Plain number string
      final n = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (n == null) return raw;
      final display = n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);
      return '$display kcal';
    }
    return 'N/A';
  }

  Widget _togglePill({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _navyBlue : const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _navyBlue.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.75;

    // Safe nutrition map -- fixes runtime cast error from Firestore/AI maps
    // Prefer nutritionTotal when showTotalNutrition is true, otherwise use per-serving
    final nutrition =
        _showTotalNutrition && widget.meal['nutritionTotal'] != null
        ? _safeMap(widget.meal['nutritionTotal'])
        : widget.meal['nutrition'] != null
        ? _safeMap(widget.meal['nutrition'])
        : <String, dynamic>{
            'calories': '420 kcal',
            'protein': '32g',
            'carbs': '48g',
            'fat': '12g',
            'saturatedFat': '4g',
            'transFat': '0g',
            'fiber': '6g',
            'sugar': '8g',
            'sodium': '540mg',
            'cholesterol': '85mg',
            'potassium': '235mg',
            'calcium': '260mg',
            'iron': '8mg',
            'vitaminD': '2mcg',
          };

    // Safe calories display -- fixes "String is not subtype of int?" crash
    // Use nutrition map directly to ensure it updates when toggling
    final caloriesDisplay = _parseCaloriesDisplay(widget.meal, nutrition);

    final macros = [
      _MacroItem(
        label: 'Calories',
        value: caloriesDisplay,
        icon: Icons.local_fire_department,
        color: const Color(0xFFFF6B35),
        fillRatio: 0.72,
      ),
      _MacroItem(
        label: 'Protein',
        value: nutrition['protein'] ?? '--',
        icon: Icons.fitness_center,
        color: _navyBlue,
        fillRatio: 0.64,
      ),
      _MacroItem(
        label: 'Carbs',
        value: nutrition['carbs'] ?? '--',
        icon: Icons.grain,
        color: const Color(0xFFFFB84D),
        fillRatio: 0.55,
      ),
      _MacroItem(
        label: 'Fat',
        value: nutrition['fat'] ?? '--',
        icon: Icons.water_drop,
        color: _green,
        fillRatio: 0.28,
      ),
    ];

    final nutrientGroups = [
      _NutrientGroup(
        label: 'FATS',
        color: _green,
        icon: Icons.water_drop_outlined,
        items: [
          _ExtraItem(
            label: 'Saturated Fat',
            value: nutrition['saturatedFat'] ?? '--',
          ),
          _ExtraItem(label: 'Trans Fat', value: nutrition['transFat'] ?? '--'),
        ],
      ),
      _NutrientGroup(
        label: 'CARBOHYDRATES',
        color: const Color(0xFFFFB84D),
        icon: Icons.grain_outlined,
        items: [
          _ExtraItem(label: 'Fiber', value: nutrition['fiber'] ?? '--'),
          _ExtraItem(label: 'Sugar', value: nutrition['sugar'] ?? '--'),
        ],
      ),
      _NutrientGroup(
        label: 'MINERALS & OTHER',
        color: const Color(0xFF8B5CF6),
        icon: Icons.science_outlined,
        items: [
          _ExtraItem(
            label: 'Cholesterol',
            value: nutrition['cholesterol'] ?? '--',
          ),
          _ExtraItem(label: 'Sodium', value: nutrition['sodium'] ?? '--'),
          _ExtraItem(label: 'Potassium', value: nutrition['potassium'] ?? '--'),
          _ExtraItem(label: 'Calcium', value: nutrition['calcium'] ?? '--'),
          _ExtraItem(label: 'Iron', value: nutrition['iron'] ?? '--'),
          _ExtraItem(label: 'Vitamin D', value: nutrition['vitaminD'] ?? '--'),
        ],
      ),
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

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _navyBlue.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    widget.meal['name'] ?? '',
                                    style: TextStyle(
                                      color: _navyBlue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.meal['nutritionTotal'] != null) ...[
                              const SizedBox(width: 12),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _togglePill(
                                      label: 'Per Serving',
                                      icon: Icons.restaurant_outlined,
                                      isActive: !_showTotalNutrition,
                                      onTap: () => setState(
                                        () => _showTotalNutrition = false,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _togglePill(
                                      label: 'Whole Meal',
                                      icon: Icons.dinner_dining_outlined,
                                      isActive: _showTotalNutrition,
                                      onTap: () => setState(
                                        () => _showTotalNutrition = true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Macro cards grid
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
                        const SizedBox(height: 24),

                        // Section label
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

                        // Grouped nutrient cards
                        ...nutrientGroups.map(
                          (group) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NutrientGroupCard(group: group),
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
                      if (widget.onSelectMeal != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onSelectMeal!();
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
                      if (widget.onSelectMeal != null)
                        const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onBack();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF5F5F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            '<- Back to Meal',
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

// Data models

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

class _NutrientGroup {
  final String label;
  final Color color;
  final IconData icon;
  final List<_ExtraItem> items;

  const _NutrientGroup({
    required this.label,
    required this.color,
    required this.icon,
    required this.items,
  });
}

// Widgets

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
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF273967),
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientGroupCard extends StatelessWidget {
  final _NutrientGroup group;
  const _NutrientGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: group.color.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Group header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: group.color.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                Icon(group.icon, size: 13, color: group.color),
                const SizedBox(width: 6),
                Text(
                  group.label,
                  style: TextStyle(
                    color: group.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
          // Nutrient rows
          ...group.items.asMap().entries.map((entry) {
            final isLast = entry.key == group.items.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        style: const TextStyle(
                          color: Color(0xFF273967),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: group.color.withValues(alpha: 0.12),
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
