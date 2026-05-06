import 'package:flutter/material.dart';
import 'dart:ui';
import 'meal_results_modal.dart';

class GenerateMealIdeasModal extends StatefulWidget {
  const GenerateMealIdeasModal({super.key});

  @override
  State<GenerateMealIdeasModal> createState() => _GenerateMealIdeasModalState();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => const GenerateMealIdeasModal(),
    );
  }
}

class _GenerateMealIdeasModalState extends State<GenerateMealIdeasModal> {
  static const Color _green = Color(0xFF00D084);
  static const Color _lightGray = Color(0xFFF5F5F5);
  static const Color _lightBlue = Color(0xFFE3F2FD);

  final TextEditingController _fridgeController = TextEditingController();
  final List<String> _fridgeItems = [];
  String _selectedMealType = 'Any';
  final Set<String> _selectedDietaryPrefs = {};
  bool _isLoading = false;

  // Mock meal data
  final List<Map<String, dynamic>> _mockMeals = [
    {
      'name': 'Veggie Stir-Fry Bowl',
      'description': 'A colorful mix of fresh vegetables with a savory sauce',
      'time': '15 min',
      'difficulty': 'Easy',
      'calories': '320 cal',
      'ingredients': ['Chicken'],
    },
    {
      'name': 'Healthy Buddha Bowl',
      'description': 'Nutritious bowl with balanced proteins and greens',
      'time': '20 min',
      'difficulty': 'Easy',
      'calories': '450 cal',
      'ingredients': ['Chicken'],
    },
    {
      'name': 'Quick Garden Salad',
      'description': 'Fresh and crisp salad with homemade dressing',
      'time': '10 min',
      'difficulty': 'Very Easy',
      'calories': '180 cal',
      'ingredients': ['Chicken'],
    },
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
    if (_fridgeController.text.isNotEmpty) {
      setState(() {
        _fridgeItems.add(_fridgeController.text);
        _fridgeController.clear();
      });
    }
  }

  void _removeFridgeItem(int index) {
    setState(() {
      _fridgeItems.removeAt(index);
    });
  }

  Future<void> _generateMealIdeas() async {
    if (_fridgeItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call with delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Show meal results modal
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.transparent,
        builder: (context) => MealResultsModal(
          meals: _mockMeals,
          onBackPressed: () {
            Navigator.pop(context); // Close results modal
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _fridgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.7;

    return Stack(
      children: [
        // Blurred background (top 30%)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
        ),
        // Bottom sheet content (70% from bottom)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: modalHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
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
                    // Header
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
                                color: primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // What's in your fridge section
                    Text(
                      "What's in your fridge? *",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fridgeController,
                            decoration: InputDecoration(
                              hintText: 'e.g., chicken, broccoli, rice...',
                              hintStyle: TextStyle(
                                color: Color(0xFFCCCCCC),
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: _lightGray,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _addFridgeItem(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _addFridgeItem,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Display fridge items as chips
                    if (_fridgeItems.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Ingredients (${_fridgeItems.length})',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _fridgeItems.asMap().entries.map((entry) {
                              int index = entry.key;
                              String item = entry.value;
                              return Chip(
                                label: Text(item),
                                onDeleted: () => _removeFridgeItem(index),
                                backgroundColor: _green.withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: _green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                side: BorderSide(
                                  color: _green.withValues(alpha: 0.3),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                    // Meal Type
                    Text(
                      'Meal Type',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _mealTypes.map((type) {
                          bool isSelected = _selectedMealType == type;
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
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryColor
                                        : Color(0xFFDDDDDD),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : primaryColor,
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

                    // Dietary Preferences
                    Text(
                      'Dietary Preferences (Optional)',
                      style: TextStyle(
                        color: primaryColor,
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
                        String pref = _dietaryPreferences[index];
                        bool isSelected = _selectedDietaryPrefs.contains(pref);
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
                                    ? Color(0xFF1976D2)
                                    : Color(0xFFDDDDDD),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                pref,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: primaryColor,
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

                    // AI-Powered Suggestions
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _lightBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFBBDEFB)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
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

                    // Generate button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generateMealIdeas,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          disabledBackgroundColor: Color(0xFFCCCCCC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? Row(
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
                                  const SizedBox(width: 8),
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
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
