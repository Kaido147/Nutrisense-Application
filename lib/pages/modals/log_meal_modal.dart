import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/services/meal_services.dart';

class LogMealModal extends ConsumerStatefulWidget {
  const LogMealModal({super.key, this.initialMeal});

  final Map<String, dynamic>? initialMeal;

  @override
  ConsumerState<LogMealModal> createState() => _LogMealModalState();

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Map<String, dynamic>? initialMeal,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => LogMealModal(initialMeal: initialMeal),
    );
  }
}

class _LogMealModalState extends ConsumerState<LogMealModal> {
  static const Color _navyBlue = Color(0xFF1E2A4A);
  static const Color _lightGray = Color(0xFFF6F7F9);
  static const Color _brightGreen = Color(0xFF06C85F);
  static const Color _mutedText = Color(0xFF94A0B8);

  final TextEditingController _foodName = TextEditingController();
  final TextEditingController _servingAmount = TextEditingController();
  final TextEditingController _calories = TextEditingController();
  final TextEditingController _protein = TextEditingController();
  final TextEditingController _carbs = TextEditingController();
  final TextEditingController _fats = TextEditingController();
  final TextEditingController _saturatedFat = TextEditingController();
  final TextEditingController _transFat = TextEditingController();
  final TextEditingController _fiber = TextEditingController();
  final TextEditingController _sugar = TextEditingController();
  final TextEditingController _sodium = TextEditingController();
  final TextEditingController _cholesterol = TextEditingController();
  final TextEditingController _potassium = TextEditingController();
  final TextEditingController _calcium = TextEditingController();
  final TextEditingController _iron = TextEditingController();
  final TextEditingController _vitaminD = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  String _selectedMealType = 'Breakfast';
  String _selectedUnit = 'serving';
  bool _manualNutrition = false;
  bool _showMoreNutrients = false;
  bool _isSaving = false;

  /// The original per-serving nutrition from a recipe meal (TheMealDB).
  /// Never mutated — used to restore _baseNutritionPerServing when switching
  /// back from a weight unit to a serving-style unit.
  Map<String, dynamic>? _recipeNutritionPerServing;

  /// The active nutrition base used for scaling. Cleared when the user picks a
  /// weight unit on a recipe meal (because recipe data is per-serving, not
  /// per-100 g — applying weight-unit math to it gives nonsense values).
  Map<String, dynamic>? _baseNutritionPerServing;

  Map<String, dynamic>? _prefilledNutrition;
  bool _hasRecipeNutrition = false;

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  final List<String> _servingUnits = [
    'serving',
    'g',
    'kg',
    'ml',
    'l',
    'cup',
    'tbsp',
    'tsp',
    'oz',
    'lb',
    'slice',
    'piece',
    'bowl',
    'plate',
  ];

  // ── Unit-aware scaling ─────────────────────────────────────────────────────
  static const _weightUnits = {'g', 'kg', 'ml', 'l', 'oz', 'lb'};

  static const _unitBaseAmount = <String, double>{
    'g': 100,
    'kg': 0.1,
    'ml': 100,
    'l': 0.1,
    'oz': 3.527,
    'lb': 0.220,
  };

  double _effectiveScale() {
    final amount = double.tryParse(_servingAmount.text.trim()) ?? 1;
    if (amount <= 0) return 1.0;

    if (_weightUnits.contains(_selectedUnit)) {
      final base = _unitBaseAmount[_selectedUnit] ?? 1;
      return amount / base;
    }

    return amount;
  }

  @override
  void initState() {
    super.initState();
    _prefillFromInitialMeal();
    _servingAmount.addListener(_onServingAmountChanged);
  }

  @override
  void dispose() {
    _foodName.dispose();
    _servingAmount.removeListener(_onServingAmountChanged);
    _servingAmount.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fats.dispose();
    _saturatedFat.dispose();
    _transFat.dispose();
    _fiber.dispose();
    _sugar.dispose();
    _sodium.dispose();
    _cholesterol.dispose();
    _potassium.dispose();
    _calcium.dispose();
    _iron.dispose();
    _vitaminD.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _prefillFromInitialMeal() {
    final meal = widget.initialMeal;
    if (meal == null) {
      _servingAmount.text = '1';
      return;
    }

    _foodName.text = (meal['name'] ?? '').toString();
    _selectedMealType = _normalizeMealType(meal['category'] ?? meal['type']);
    _servingAmount.text = (meal['servingAmount'] ?? '1').toString();
    _selectedUnit = _normalizeUnit(meal['servingUnit'] ?? 'serving');

    _baseNutritionPerServing =
        _safeMap(meal['nutritionPerServing']) ??
        _safeMap(meal['recipeNutritionPerServing']) ??
        _safeMap(meal['nutrition']);

    // Keep an immutable copy so we can restore it after a unit switch.
    _recipeNutritionPerServing = _baseNutritionPerServing;
    _hasRecipeNutrition = _recipeNutritionPerServing != null;
    _prefilledNutrition = _scaledPrefilledNutrition();
    _applyNutritionToFields(_prefilledNutrition);
    _manualNutrition = false;
  }

  void _onServingAmountChanged() {
    if (_manualNutrition || _baseNutritionPerServing == null) return;
    setState(() {
      _prefilledNutrition = _scaledPrefilledNutrition();
      _applyNutritionToFields(_prefilledNutrition);
    });
  }

  void _clearNutritionFields() {
    for (final c in [
      _calories,
      _protein,
      _carbs,
      _fats,
      _saturatedFat,
      _transFat,
      _fiber,
      _sugar,
      _sodium,
      _cholesterol,
      _potassium,
      _calcium,
      _iron,
      _vitaminD,
    ]) {
      c.text = '';
    }
  }

  String _normalizeMealType(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return 'Breakfast';
    return _mealTypes.firstWhere(
      (type) => type.toLowerCase() == value.toLowerCase(),
      orElse: () => 'Lunch',
    );
  }

  String _normalizeUnit(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return 'serving';
    return _servingUnits.firstWhere(
      (unit) => unit.toLowerCase() == value.toLowerCase(),
      orElse: () => 'serving',
    );
  }

  String _caloriesWithUnit(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) return '0 kcal';
    final lower = value.toLowerCase();
    return lower.contains('kcal') || lower.contains('cal')
        ? value
        : '$value kcal';
  }

  Future<void> _logMeal() async {
    final validationMessage = _validateMeal();
    if (validationMessage != null) {
      _showValidationNotification(validationMessage);
      return;
    }

    final loggedAt = TimeOfDay.now().format(context);
    setState(() => _isSaving = true);

    // Use manual nutrition if toggled, otherwise use prefilled/scaled.
    Map<String, dynamic>? nutrition = _manualNutrition
        ? _nutritionFromFields()
        : _prefilledNutrition;

    // No prefilled nutrition and no recipe base — fetch from USDA.
    final shouldFetchUsda =
        !_hasRecipeNutrition || _weightUnits.contains(_selectedUnit);

    if (!_manualNutrition && nutrition == null && shouldFetchUsda) {
      final fetched = await MealService.fetchNutritionForFoodName(
        _foodName.text.trim(),
      );
      if (fetched != null) {
        final scale = _effectiveScale();
        nutrition = scale == 1.0
            ? fetched
            : _scaleNutritionByAmount(fetched, scale);
      }
    }

    nutrition ??= _emptyNutrition();
    _applyNutritionToFields(nutrition);

    final meal = {
      'name': _foodName.text.trim(),
      'category': _selectedMealType,
      'servingAmount': _servingAmount.text.trim(),
      'servingUnit': _selectedUnit,
      'time': loggedAt,
      'notes': _notes.text.trim(),
      'calories': nutrition['calories'],
      'nutrition': nutrition,
      'nutritionPerServing': _recipeNutritionPerServing,
      'recipeNutritionPerServing': _recipeNutritionPerServing,
      'ingredients': widget.initialMeal?['ingredients'] ?? const [],
      'nutritionBasis': _baseNutritionPerServing != null
          ? 'scaled from per 1 serving'
          : 'per serving (1 unit)',
    };

    try {
      await ref.read(nutritionServiceProvider).saveMeal(meal);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(mealLogsProvider);
      if (mounted) Navigator.pop(context, meal);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showValidationNotification('Could not log meal. Please try again.');
    }
  }

  String? _validateMeal() {
    final foodName = _foodName.text.trim();
    if (foodName.isEmpty) return 'Please enter a food name.';
    if (RegExp(r'\d').hasMatch(foodName)) {
      return 'Food name cannot contain numbers.';
    }
    if (foodName.length < 2) return 'Food name is too short.';

    final amountText = _servingAmount.text.trim();
    final amount = double.tryParse(amountText);
    if (amountText.isEmpty || amount == null) {
      return 'Enter a valid serving amount.';
    }
    if (amount <= 0) return 'Serving amount must be greater than 0.';
    if (amount > 10000) return 'Serving amount is too large.';

    if (!_manualNutrition) return null;

    final requiredFields = {
      'calories': _calories,
      'protein': _protein,
      'carbs': _carbs,
      'fats': _fats,
    };

    for (final entry in requiredFields.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty) return 'Enter ${entry.key} for manual nutrition.';
      if (double.tryParse(value) == null) {
        return 'Enter a valid ${entry.key} value.';
      }
    }

    for (final entry in {
      'saturated fat': _saturatedFat,
      'trans fat': _transFat,
      'fiber': _fiber,
      'sugar': _sugar,
      'sodium': _sodium,
      'cholesterol': _cholesterol,
      'potassium': _potassium,
      'calcium': _calcium,
      'iron': _iron,
      'vitamin D': _vitaminD,
    }.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty && double.tryParse(value) == null) {
        return 'Enter a valid ${entry.key} value.';
      }
    }

    return null;
  }

  void _showValidationNotification(String message) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFB45309),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF78350F),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry?.remove();
    });
  }

  String _withUnit(TextEditingController controller, String unit) {
    final value = controller.text.trim();
    if (value.isEmpty) return '0$unit';
    return '$value$unit';
  }

  Map<String, dynamic> _nutritionFromFields() {
    return {
      'calories': _calories.text.trim(),
      'protein': _withUnit(_protein, 'g'),
      'carbs': _withUnit(_carbs, 'g'),
      'fat': _withUnit(_fats, 'g'),
      'saturatedFat': _withUnit(_saturatedFat, 'g'),
      'transFat': _withUnit(_transFat, 'g'),
      'fiber': _withUnit(_fiber, 'g'),
      'sugar': _withUnit(_sugar, 'g'),
      'sodium': _withUnit(_sodium, 'mg'),
      'cholesterol': _withUnit(_cholesterol, 'mg'),
      'potassium': _withUnit(_potassium, 'mg'),
      'calcium': _withUnit(_calcium, 'mg'),
      'iron': _withUnit(_iron, 'mg'),
      'vitaminD': _withUnit(_vitaminD, 'mcg'),
    };
  }

  Map<String, dynamic> _emptyNutrition() {
    return {
      'calories': '0 kcal',
      'protein': '0g',
      'carbs': '0g',
      'fat': '0g',
      'saturatedFat': '0g',
      'transFat': '0g',
      'fiber': '0g',
      'sugar': '0g',
      'sodium': '0mg',
      'cholesterol': '0mg',
      'potassium': '0mg',
      'calcium': '0mg',
      'iron': '0mg',
      'vitaminD': '0mcg',
    };
  }

  Map<String, dynamic>? _safeMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((key, value) => MapEntry('$key', value));
    return null;
  }

  Map<String, dynamic>? _scaledPrefilledNutrition() {
    final base = _baseNutritionPerServing;
    if (base == null) return null;

    final scale = _effectiveScale();

    return {
      'calories': _scaleNutrient(base['calories'], scale, 'kcal'),
      'protein': _scaleNutrient(base['protein'], scale, 'g'),
      'carbs': _scaleNutrient(base['carbs'], scale, 'g'),
      'fat': _scaleNutrient(base['fat'], scale, 'g'),
      'saturatedFat': _scaleNutrient(base['saturatedFat'], scale, 'g'),
      'transFat': _scaleNutrient(base['transFat'], scale, 'g'),
      'fiber': _scaleNutrient(base['fiber'], scale, 'g'),
      'sugar': _scaleNutrient(base['sugar'], scale, 'g'),
      'sodium': _scaleNutrient(base['sodium'], scale, 'mg'),
      'cholesterol': _scaleNutrient(base['cholesterol'], scale, 'mg'),
      'potassium': _scaleNutrient(base['potassium'], scale, 'mg'),
      'calcium': _scaleNutrient(base['calcium'], scale, 'mg'),
      'iron': _scaleNutrient(base['iron'], scale, 'mg'),
      'vitaminD': _scaleNutrient(base['vitaminD'], scale, 'mcg'),
    };
  }

  String _scaleNutrient(dynamic raw, double scale, String unit) {
    final value = double.tryParse(_stripNumber(raw)) ?? 0;
    final scaled = value * scale;
    final display = scaled == scaled.roundToDouble()
        ? scaled.round().toString()
        : scaled.toStringAsFixed(1);
    return unit == 'kcal' ? '$display kcal' : '$display$unit';
  }

  Map<String, dynamic> _scaleNutritionByAmount(
    Map<String, dynamic> nutrition,
    double scale,
  ) {
    if (scale <= 0) scale = 1.0;

    return {
      'calories': _scaleNutrient(nutrition['calories'], scale, 'kcal'),
      'protein': _scaleNutrient(nutrition['protein'], scale, 'g'),
      'carbs': _scaleNutrient(nutrition['carbs'], scale, 'g'),
      'fat': _scaleNutrient(nutrition['fat'], scale, 'g'),
      'saturatedFat': _scaleNutrient(nutrition['saturatedFat'], scale, 'g'),
      'transFat': _scaleNutrient(nutrition['transFat'], scale, 'g'),
      'fiber': _scaleNutrient(nutrition['fiber'], scale, 'g'),
      'sugar': _scaleNutrient(nutrition['sugar'], scale, 'g'),
      'sodium': _scaleNutrient(nutrition['sodium'], scale, 'mg'),
      'cholesterol': _scaleNutrient(nutrition['cholesterol'], scale, 'mg'),
      'potassium': _scaleNutrient(nutrition['potassium'], scale, 'mg'),
      'calcium': _scaleNutrient(nutrition['calcium'], scale, 'mg'),
      'iron': _scaleNutrient(nutrition['iron'], scale, 'mg'),
      'vitaminD': _scaleNutrient(nutrition['vitaminD'], scale, 'mcg'),
    };
  }

  void _applyNutritionToFields(Map<String, dynamic>? nutrition) {
    if (nutrition == null) return;
    _calories.text = _stripNumber(nutrition['calories']);
    _protein.text = _stripNumber(nutrition['protein']);
    _carbs.text = _stripNumber(nutrition['carbs']);
    _fats.text = _stripNumber(nutrition['fat']);
    _saturatedFat.text = _stripNumber(nutrition['saturatedFat']);
    _transFat.text = _stripNumber(nutrition['transFat']);
    _fiber.text = _stripNumber(nutrition['fiber']);
    _sugar.text = _stripNumber(nutrition['sugar']);
    _sodium.text = _stripNumber(nutrition['sodium']);
    _cholesterol.text = _stripNumber(nutrition['cholesterol']);
    _potassium.text = _stripNumber(nutrition['potassium']);
    _calcium.text = _stripNumber(nutrition['calcium']);
    _iron.text = _stripNumber(nutrition['iron']);
    _vitaminD.text = _stripNumber(nutrition['vitaminD']);
  }

  String _stripNumber(dynamic raw) {
    if (raw == null) return '';
    return raw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
  }

  void _showMealTypePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _mealTypes.map((type) {
            return ListTile(
              title: Text(type),
              onTap: () {
                setState(() => _selectedMealType = type);
                Navigator.pop(context);
              },
              trailing: _selectedMealType == type
                  ? const Icon(Icons.check, color: _navyBlue)
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.9;

    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _buildHeader(),
                const Divider(height: 1, color: Color(0xFFECEFF4)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabeledField(
                          label: 'Food Name *',
                          controller: _foodName,
                          hint: 'e.g. Grilled Chicken Salad',
                          icon: Icons.egg_alt_outlined,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildLabeledField(
                                label: 'Amount',
                                controller: _servingAmount,
                                hint: '1',
                                icon: Icons.scale_outlined,
                                numeric: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _buildUnitDropdown()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildMealTypeField(),
                        const SizedBox(height: 20),
                        _buildNutritionCard(),
                        const SizedBox(height: 20),
                        _buildLabeledField(
                          label: 'Notes (Optional)',
                          controller: _notes,
                          hint: 'Add any additional notes...',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 28),
                        _buildActions(),
                      ],
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Log Meal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _navyBlue,
            ),
          ),
          IconButton.filled(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F3F7),
              foregroundColor: const Color(0xFF6B7280),
            ),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  void _showUnitPicker() {
    const groups = <String, List<String>>{
      'Serving': [
        'serving',
        'slice',
        'piece',
        'bowl',
        'plate',
        'cup',
        'tbsp',
        'tsp',
      ],
      'Weight': ['g', 'kg', 'oz', 'lb'],
      'Volume': ['ml', 'l'],
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE1EA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 4, 24, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Unit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _navyBlue,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFECEFF4)),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 24),
                    children: groups.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _mutedText,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          ...entry.value.map((unit) {
                            final isSelected = _selectedUnit == unit;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 2,
                              ),
                              title: Text(
                                unit,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? _navyBlue
                                      : const Color(0xFF374151),
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: _brightGreen,
                                      size: 20,
                                    )
                                  : null,
                              tileColor: isSelected
                                  ? const Color(0xFFEAFBF1)
                                  : Colors.transparent,
                              onTap: () {
                                Navigator.pop(context);
                                if (_manualNutrition) {
                                  setState(() => _selectedUnit = unit);
                                  return;
                                }
                                setState(() {
                                  _selectedUnit = unit;
                                  final toWeight = _weightUnits.contains(unit);
                                  if (toWeight &&
                                      _recipeNutritionPerServing != null) {
                                    _baseNutritionPerServing = null;
                                    _prefilledNutrition = null;
                                    _clearNutritionFields();
                                  } else if (!toWeight &&
                                      _recipeNutritionPerServing != null) {
                                    _baseNutritionPerServing =
                                        _recipeNutritionPerServing;
                                    _prefilledNutrition =
                                        _scaledPrefilledNutrition();
                                    _applyNutritionToFields(
                                      _prefilledNutrition,
                                    );
                                  } else if (_baseNutritionPerServing != null) {
                                    _prefilledNutrition =
                                        _scaledPrefilledNutrition();
                                    _applyNutritionToFields(
                                      _prefilledNutrition,
                                    );
                                  }
                                });
                              },
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUnitDropdown() {
    return _buildTapField(
      label: 'Unit',
      value: _selectedUnit,
      icon: Icons.straighten_outlined,
      onTap: _showUnitPicker,
    );
  }

  Widget _buildMealTypeField() {
    return _buildTapField(
      label: 'Meal Type *',
      value: _selectedMealType,
      icon: Icons.restaurant_menu_outlined,
      onTap: _showMealTypePicker,
    );
  }

  Widget _buildNutritionCard() {
    final pendingUsda =
        !_manualNutrition &&
        _prefilledNutrition == null &&
        _weightUnits.contains(_selectedUnit) &&
        _recipeNutritionPerServing != null;

    final amount = _servingAmount.text.trim().isEmpty
        ? (_weightUnits.contains(_selectedUnit) ? '0' : '1')
        : _servingAmount.text.trim();

    final String subtitleText;
    if (_manualNutrition) {
      subtitleText = 'Enter nutrition manually.';
    } else if (pendingUsda) {
      subtitleText =
          'Nutrition will be fetched from USDA on save ($amount$_selectedUnit).';
    } else if (_weightUnits.contains(_selectedUnit)) {
      final baseline = _selectedUnit == 'kg'
          ? 'g'
          : _selectedUnit == 'l'
          ? 'ml'
          : _selectedUnit;
      subtitleText =
          'Nutrition scaled for $amount$_selectedUnit (per 100$baseline baseline).';
    } else {
      subtitleText = 'Nutrition scaled for $amount $_selectedUnit.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAFBF1),
        border: Border.all(color: const Color(0xFFD1F3DE)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                color: _brightGreen,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Nutritional Information',
                  style: TextStyle(
                    color: _navyBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch(
                value: _manualNutrition,
                activeThumbColor: _brightGreen,
                onChanged: (value) {
                  setState(() {
                    _manualNutrition = value;
                    if (!value) {
                      _applyNutritionToFields(_prefilledNutrition);
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitleText,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (_manualNutrition) ...[
            const SizedBox(height: 16),
            _buildNutrientGrid([
              _NutrientField('Calories (kcal)', _calories, ''),
              _NutrientField('Protein (g)', _protein, 'g'),
              _NutrientField('Carbs (g)', _carbs, 'g'),
              _NutrientField('Fats (g)', _fats, 'g'),
            ]),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _showMoreNutrients = !_showMoreNutrients),
              icon: Icon(
                _showMoreNutrients
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: _navyBlue,
              ),
              label: Text(
                _showMoreNutrients
                    ? 'Hide More nutrients'
                    : 'Add More nutrients',
                style: const TextStyle(
                  color: _navyBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_showMoreNutrients)
              _buildNutrientGrid([
                _NutrientField('Sat. Fat (g)', _saturatedFat, 'g'),
                _NutrientField('Trans Fat (g)', _transFat, 'g'),
                _NutrientField('Fiber (g)', _fiber, 'g'),
                _NutrientField('Sugar (g)', _sugar, 'g'),
                _NutrientField('Sodium (mg)', _sodium, 'mg'),
                _NutrientField('Cholesterol (mg)', _cholesterol, 'mg'),
                _NutrientField('Potassium (mg)', _potassium, 'mg'),
                _NutrientField('Calcium (mg)', _calcium, 'mg'),
                _NutrientField('Iron (mg)', _iron, 'mg'),
                _NutrientField('Vitamin D (mcg)', _vitaminD, 'mcg'),
              ]),
          ],
        ],
      ),
    );
  }

  Widget _buildNutrientGrid(List<_NutrientField> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: fields
              .map(
                (field) => SizedBox(
                  width: itemWidth,
                  child: _buildNutrientInput(field),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildNutrientInput(_NutrientField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: const TextStyle(
            color: Color(0xFF43516D),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: field.controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: _inputDecoration(hint: '0').copyWith(
            fillColor: Colors.white,
            suffixText: field.suffix.isEmpty ? null : field.suffix,
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool numeric = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _navyBlue,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : label.toLowerCase().contains('name')
              ? [FilteringTextInputFormatter.deny(RegExp(r'\d'))]
              : null,
          decoration: _inputDecoration(hint: hint, icon: icon),
        ),
      ],
    );
  }

  Widget _buildTapField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _navyBlue,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _lightGray,
                border: Border.all(color: const Color(0xFFE0E4EC)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(icon, color: _mutedText, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _navyBlue, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _mutedText, fontSize: 14),
      prefixIcon: icon == null ? null : Icon(icon, color: _mutedText, size: 22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE0E4EC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE0E4EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _brightGreen, width: 1.4),
      ),
      filled: true,
      fillColor: _lightGray,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: const Color(0xFFF1F3F7),
              foregroundColor: _navyBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton(
            onPressed: _isSaving ? null : _logMeal,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: _brightGreen,
              disabledBackgroundColor: _brightGreen.withValues(alpha: 0.45),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              _isSaving ? 'Logging...' : 'Log Meal',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _NutrientField {
  const _NutrientField(this.label, this.controller, this.suffix);

  final String label;
  final TextEditingController controller;
  final String suffix;
}
