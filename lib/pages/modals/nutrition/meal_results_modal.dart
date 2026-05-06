import 'package:flutter/material.dart';

class MealResultsModal extends StatefulWidget {
  final List<Map<String, dynamic>> meals;
  final VoidCallback onBackPressed;

  const MealResultsModal({
    super.key,
    required this.meals,
    required this.onBackPressed,
  });

  @override
  State<MealResultsModal> createState() => _MealResultsModalState();
}

class _MealResultsModalState extends State<MealResultsModal> {
  static const Color _green = Color(0xFF00D084);
  static const Color _lightGray = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_bag, color: primaryColor, size: 24),
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
                        child: Icon(Icons.close, color: primaryColor, size: 24),
                      ),
                    ],
                  ),
                ),
                // Meals list
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
                                    color: primaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
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
                          // Meal cards
                          ...widget.meals.map((meal) {
                            final isLastItem = meal == widget.meals.last;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: isLastItem ? 20 : 12,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: isLastItem
                                        ? primaryColor
                                        : Color(0xFFEEEEEE),
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
                                      Text(
                                        meal['name'],
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        meal['description'],
                                        style: TextStyle(
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
                                            color: primaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            meal['time'],
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.local_dining,
                                            size: 16,
                                            color: primaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            meal['difficulty'],
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            meal['calories'],
                                            style: TextStyle(
                                              color: _green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Using your ingredients
                                      Text(
                                        'USING YOUR INGREDIENTS:',
                                        style: TextStyle(
                                          color: Color(0xFF999999),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children:
                                            (meal['ingredients']
                                                    as List<String>)
                                                .map(
                                                  (ingredient) => Chip(
                                                    label: Text(ingredient),
                                                    backgroundColor: _green
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    labelStyle: TextStyle(
                                                      color: _green,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    side: BorderSide(
                                                      color: _green.withValues(
                                                        alpha: 0.3,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // TODO: Handle meal selection
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Selected: ${meal['name']}',
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          child: Text(
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
                // Back button
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
                          color: primaryColor,
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
