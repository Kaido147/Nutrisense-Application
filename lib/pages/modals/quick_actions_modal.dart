import 'package:flutter/material.dart';
import 'dart:ui';
import 'add_class_modal.dart';
import 'log_workout_modal.dart';
import 'add_task_modal.dart';
import 'journal_entry_modal.dart';
import 'nutrition/generate_meal_ideas_modal.dart';

class QuickActionsModal extends StatefulWidget {
  const QuickActionsModal({super.key});

  @override
  State<QuickActionsModal> createState() => _QuickActionsModalState();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => const QuickActionsModal(),
    );
  }
}

class _QuickActionsModalState extends State<QuickActionsModal> {
  static const Color _navyBlue = Color(0xFF1E2A4A);
  static const Color _goldTan = Color(0xFFD4B896);
  static const Color _brightBlue = Color(0xFF2563EB);
  static const Color _brightGreen = Color(0xFF22C55E);
  static const Color _brightPurple = Color(0xFFAF27F5);
  static const Color _lightGray = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.65;

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
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _navyBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'What would you like to add?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9CA3AF),
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
                    // Action buttons grid
                    // First row: Add Class and Log Workout
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'Add Class',
                            icon: Icons.backpack_outlined,
                            color: _brightBlue,
                            onTap: () {
                              AddClassModal.show(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            label: 'Log Workout',
                            icon: Icons.favorite_outline,
                            color: _goldTan,
                            onTap: () {
                              LogWorkoutModal.show(context);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Second row: Log Meal and Add Task
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'Log Meal',
                            icon: Icons.restaurant_menu_outlined,
                            color: _brightGreen,
                            onTap: () {
                              GenerateMealIdeasModal.show(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            label: 'Add Task',
                            icon: Icons.check_circle_outline,
                            color: _brightPurple,
                            onTap: () {
                              AddTaskModal.show(context);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Third row: Journal Entry (centered, same size as others)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 72) / 2,
                          child: _buildActionButton(
                            label: 'Journal Entry',
                            icon: Icons.menu_book_outlined,
                            color: _navyBlue,
                            onTap: () {
                              JournalEntryModal.show(context);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: _lightGray,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
