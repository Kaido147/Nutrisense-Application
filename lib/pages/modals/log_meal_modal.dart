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
  Map<String, dynamic>? _prefilledNutrition;

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

  @override
  void initState() {
    super.initState();
    _prefillFromInitialMeal();
  }

  @override
  void dispose() {
    _foodName.dispose();
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
    _prefilledNutrition = _safeMap(meal['nutrition']);
    _applyNutritionToFields(_prefilledNutrition);

    // If nutrition was prefilled (e.g. from meal ideas), show it but keep
    // auto-fetch mode — user can still toggle to manual if they want.
    _manualNutrition = false;
  }

  String _normalizeMealType(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return 'Breakfast';
    return _mealTypes.firstWhere(
      (type) => type.toLowerCase() == value.toLowerCase(),
      orElse: () => 'Breakfast',
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

  Future<void> _logMeal() async {
    if (_foodName.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a food name')));
      return;
    }

    final loggedAt = TimeOfDay.now().format(context);
    setState(() => _isSaving = true);

    Map<String, dynamic>? nutrition = _manualNutrition
        ? _nutritionFromFields()
        : _prefilledNutrition;

    if (!_manualNutrition && nutrition == null) {
      nutrition = await MealService.fetchNutritionForFoodName(
        _foodName.text.trim(),
      );
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
      'nutritionBasis': _prefilledNutrition != null ? 'per 1 serving' : null,
    };

    try {
      await ref.read(nutritionServiceProvider).saveMeal(meal);
      if (mounted) Navigator.pop(context, meal);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log meal. Please try again.')),
      );
    }
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

  /// Inline dropdown for serving unit — no separate bottom sheet.
  Widget _buildUnitDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unit',
          style: TextStyle(
            color: _navyBlue,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedUnit,
          decoration: InputDecoration(
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            prefixIcon: const Icon(
              Icons.straighten_outlined,
              color: _mutedText,
              size: 22,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _mutedText,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(color: _navyBlue, fontSize: 14),
          isExpanded: true,
          items: _servingUnits
              .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedUnit = value);
          },
        ),
      ],
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
                      // Restore prefilled values when switching back to auto
                      _applyNutritionToFields(_prefilledNutrition);
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _manualNutrition
                ? 'Enter nutrition manually.'
                : _prefilledNutrition != null
                ? 'Nutrition is prefilled per 1 serving. Toggle to edit manually.'
                : 'Nutrition will be fetched automatically when you log this meal.',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Read-only preview when auto mode and nutrition is already prefilled
          if (!_manualNutrition && _prefilledNutrition != null) ...[
            const SizedBox(height: 16),
            _buildNutritionPreview(_prefilledNutrition!),
          ],

          // Manual entry fields
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

  /// Read-only nutrition preview shown when nutrition is prefilled but user is
  /// in auto mode.
  Widget _buildNutritionPreview(Map<String, dynamic> nutrition) {
    final items = [
      ('Calories', nutrition['calories']?.toString() ?? '—'),
      ('Protein', nutrition['protein']?.toString() ?? '—'),
      ('Carbs', nutrition['carbs']?.toString() ?? '—'),
      ('Fat', nutrition['fat']?.toString() ?? '—'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        const SizedBox(
          width: double.infinity,
          child: Text(
            'Per 1 serving',
            style: TextStyle(
              color: _brightGreen,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...items.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1F3DE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$1,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.$2,
                  style: const TextStyle(
                    color: _navyBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
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
