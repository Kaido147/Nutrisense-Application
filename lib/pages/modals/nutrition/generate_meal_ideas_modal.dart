import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'meal_results_modal.dart';
import '../../../services/meal_services.dart';

class GenerateMealIdeasModal extends StatefulWidget {
  const GenerateMealIdeasModal({super.key});

  @override
  State<GenerateMealIdeasModal> createState() => _GenerateMealIdeasModalState();

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => const GenerateMealIdeasModal(),
    );
  }
}

class _GenerateMealIdeasModalState extends State<GenerateMealIdeasModal> {
  static const Color _navyBlue = Color(0xFF273967);
  static const Color _green = Color(0xFF00D084);
  static const Color _lightGray = Color(0xFFF5F5F5);
  static const Color _lightBlue = Color(0xFFE3F2FD);

  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _ingredientFocus = FocusNode();

  // Each item stores both ingredient name and quantity
  final List<Map<String, String>> _fridgeItems = [];

  String _selectedMealType = 'Any';
  final Set<String> _selectedDietaryPrefs = {};
  bool _isLoading = false;

  // Selected unit for the quantity field
  String _selectedUnit = 'pcs';

  // Common quantity units
  static const List<String> _quickUnits = [
    'pcs',
    'whole',
    'cup',
    'tbsp',
    'tsp',
    'g',
    'kg',
    'ml',
    'l',
    'slice',
    'pinch',
  ];

  final List<String> _mealTypes = [
    'Any',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];
  final List<String> _dietaryPreferences = [
    'Vegetarian',
    'Vegan',
    'Gluten-free',
    'Dairy-free',
    'Low-Carb',
    'High-Protein',
  ];

  void _addFridgeItem() {
    final ingredient = _ingredientController.text.trim();
    if (ingredient.isEmpty) return;

    final number = _quantityController.text.trim();
    final quantity = number.isNotEmpty ? '$number $_selectedUnit' : '';

    setState(() {
      _fridgeItems.add({'ingredient': ingredient, 'quantity': quantity});
      _ingredientController.clear();
      _quantityController.clear();
    });
    _ingredientFocus.requestFocus();
  }

  void _removeFridgeItem(int index) {
    setState(() => _fridgeItems.removeAt(index));
  }

  /// Formats an ingredient entry into a readable label, e.g. "2 cups • Chicken"
  String _formatChipLabel(Map<String, String> item) {
    final qty = item['quantity'] ?? '';
    final name = item['ingredient'] ?? '';
    return qty.isNotEmpty ? '$qty  •  $name' : name;
  }

  Future<void> _showUnitPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Unit',
              style: TextStyle(
                color: _navyBlue,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ..._quickUnits.map(
              (unit) => ListTile(
                title: Text(
                  unit,
                  style: TextStyle(
                    color: _navyBlue,
                    fontWeight: _selectedUnit == unit
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                trailing: _selectedUnit == unit
                    ? Icon(Icons.check_rounded, color: _green)
                    : null,
                onTap: () => Navigator.pop(ctx, unit),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) {
      setState(() => _selectedUnit = selected);
    }
  }

  Future<void> _generateMealIdeas() async {
    if (_fridgeItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ingredients = _fridgeItems
          .map((item) => item['ingredient']!)
          .toList();

      final meals = await MealService.fetchMealsByIngredients(
        ingredients,
        mealType: _selectedMealType,
        dietaryPrefs: _selectedDietaryPrefs.toList(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (meals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE53935),
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.search_off, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'No Meals Found',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Try different ingredients',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }

      if (mounted) {
        final result = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.transparent,
          builder: (context) => MealResultsModal(
            meals: meals,
            onBackPressed: () => Navigator.pop(context),
            userIngredients: _fridgeItems,
          ),
        );

        if (result != null && mounted) {
          // A meal was completed, close this modal and return the meal
          Navigator.pop(context, result);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    }
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    _quantityController.dispose();
    _ingredientFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.7;

    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: _green, size: 24),
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
                    const SizedBox(height: 20),

                    // ── Ingredient section label ─────────────────────────────
                    Text(
                      "What's in your fridge? *",
                      style: TextStyle(
                        color: _navyBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Ingredient + Quantity row ────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Ingredient name field (flexible) — comes FIRST
                        Expanded(
                          child: TextField(
                            controller: _ingredientController,
                            focusNode: _ingredientFocus,
                            decoration: InputDecoration(
                              hintText: 'e.g., chicken, broccoli...',
                              hintStyle: const TextStyle(
                                color: Color(0xFFCCCCCC),
                                fontSize: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: _lightGray,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _addFridgeItem(),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Quantity field: number input + locked unit badge
                        Container(
                          width: 118,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _lightGray,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Number-only input
                              Expanded(
                                child: TextField(
                                  controller: _quantityController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      color: Color(0xFFCCCCCC),
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (_) => _addFridgeItem(),
                                ),
                              ),

                              // Thin divider
                              Container(
                                width: 1,
                                height: 24,
                                color: const Color(0xFFDDDDDD),
                              ),

                              // Tappable locked unit selector
                              GestureDetector(
                                onTap: _showUnitPicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  height: 46,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedUnit,
                                        style: TextStyle(
                                          color: _navyBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.arrow_drop_down_rounded,
                                        color: _navyBlue,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Add button
                        GestureDetector(
                          onTap: _addFridgeItem,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _navyBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Ingredient chips ─────────────────────────────────────
                    if (_fridgeItems.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Ingredients (${_fridgeItems.length})',
                            style: TextStyle(
                              color: _navyBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _fridgeItems
                                .asMap()
                                .entries
                                .map(
                                  (entry) => Chip(
                                    label: Text(_formatChipLabel(entry.value)),
                                    onDeleted: () =>
                                        _removeFridgeItem(entry.key),
                                    backgroundColor: _green.withValues(
                                      alpha: 0.12,
                                    ),
                                    labelStyle: TextStyle(
                                      color: _green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    side: BorderSide(
                                      color: _green.withValues(alpha: 0.3),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                    // ── Meal Type ────────────────────────────────────────────
                    Text(
                      'Meal Type',
                      style: TextStyle(
                        color: _navyBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _mealTypes.map((type) {
                          final isSelected = _selectedMealType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedMealType = type),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? _navyBlue : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? _navyBlue
                                        : const Color(0xFFDDDDDD),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : _navyBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Dietary Preferences ──────────────────────────────────
                    Text(
                      'Dietary Preferences (Optional)',
                      style: TextStyle(
                        color: _navyBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.5,
                          ),
                      itemCount: _dietaryPreferences.length,
                      itemBuilder: (context, index) {
                        final pref = _dietaryPreferences[index];
                        final isSelected = _selectedDietaryPrefs.contains(pref);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedDietaryPrefs.remove(pref);
                              } else {
                                _selectedDietaryPrefs.add(pref);
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? _lightBlue : _lightGray,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1976D2)
                                    : const Color(0xFFDDDDDD),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                pref,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _navyBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── AI info banner ───────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _lightBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBDEFB)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "We'll generate personalized meal ideas based on your available ingredients and preferences!",
                              style: TextStyle(
                                color: Color(0xFF1976D2),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Generate button ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generateMealIdeas,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          disabledBackgroundColor: const Color(0xFFCCCCCC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Generating...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Generate Meal Ideas',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
