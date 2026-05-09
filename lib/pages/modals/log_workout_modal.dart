import 'package:flutter/material.dart';
import 'dart:ui';

class LogWorkoutModal extends StatefulWidget {
  const LogWorkoutModal({super.key});

  @override
  State<LogWorkoutModal> createState() => _LogWorkoutModalState();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => const LogWorkoutModal(),
    );
  }
}

class _LogWorkoutModalState extends State<LogWorkoutModal> {
  static const Color _navyBlue = Color(0xFF1E2A4A);
  static const Color _lightGray = Color(0xFFF5F5F5);
  static const Color _goldTan = Color(0xFFD4B896);

  final TextEditingController _workoutName = TextEditingController();
  final TextEditingController _duration = TextEditingController();
  final TextEditingController _calories = TextEditingController();
  final TextEditingController _exercises = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  String _selectedType = 'Strength';
  String _selectedDate = '04/22/2026';
  String _selectedIntensity = 'Moderate';

  final List<String> _workoutTypes = [
    'Strength',
    'Cardio',
    'Flexibility',
    'Sports',
    'HIIT',
    'Yoga',
    'Other',
  ];

  final List<String> _intensityLevels = ['Light', 'Moderate', 'Intense'];

  @override
  void dispose() {
    _workoutName.dispose();
    _duration.dispose();
    _calories.dispose();
    _exercises.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _logWorkout() {
    if (_workoutName.text.isEmpty ||
        _duration.text.isEmpty ||
        _selectedType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // TODO: Save workout to database or state management

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.80;

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
            child: Column(
              children: [
                // ── Sticky Header ──
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Log Workout',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _navyBlue,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: _navyBlue,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable Body ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Workout Name
                        const Text(
                          'Workout Name *',
                          style: TextStyle(
                            color: _navyBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _workoutName,
                          decoration: InputDecoration(
                            hintText: 'e.g., Morning Run, Chest Day',
                            hintStyle: const TextStyle(
                              color: Color(0xFFCCCCCC),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.fitness_center_outlined,
                              color: Color(0xFFCCCCCC),
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
                        ),
                        const SizedBox(height: 16),

                        // Type and Date
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Type *',
                                    style: TextStyle(
                                      color: _navyBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) => Container(
                                          color: Colors.white,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: _workoutTypes.map((type) {
                                              return ListTile(
                                                title: Text(type),
                                                onTap: () {
                                                  setState(
                                                    () => _selectedType = type,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                trailing: _selectedType == type
                                                    ? Icon(
                                                        Icons.check,
                                                        color: _navyBlue,
                                                      )
                                                    : null,
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _lightGray,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.fitness_center_outlined,
                                            color: Color(0xFFCCCCCC),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _selectedType,
                                            style: const TextStyle(
                                              color: _navyBlue,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date *',
                                    style: TextStyle(
                                      color: _navyBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _selectDate,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _lightGray,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            color: Color(0xFFCCCCCC),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _selectedDate,
                                              style: const TextStyle(
                                                color: _navyBlue,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Duration and Calories
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Duration (min) *',
                                    style: TextStyle(
                                      color: _navyBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _duration,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '30',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFFCCCCCC),
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.schedule_outlined,
                                        color: Color(0xFFCCCCCC),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: _lightGray,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Calories Burned',
                                    style: TextStyle(
                                      color: _navyBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _calories,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '250',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFFCCCCCC),
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.bolt_outlined,
                                        color: Color(0xFFCCCCCC),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: _lightGray,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Intensity Level
                        const Text(
                          'Intensity Level *',
                          style: TextStyle(
                            color: _navyBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _intensityLevels.map((level) {
                            final bool isSelected = _selectedIntensity == level;

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _selectedIntensity = level,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _goldTan.withValues(alpha: 0.15)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isSelected
                                            ? _goldTan
                                            : const Color(0xFFE5E5E5),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      level,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSelected
                                            ? _goldTan
                                            : _navyBlue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Exercises / Sets
                        const Text(
                          'Exercises / Sets',
                          style: TextStyle(
                            color: _navyBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _exercises,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'e.g., Bench Press 3x10, Squats 4x8...',
                            hintStyle: const TextStyle(
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
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        const Text(
                          'Notes (Optional)',
                          style: TextStyle(
                            color: _navyBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notes,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'How did you feel? Any achievements?',
                            hintStyle: const TextStyle(
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
                        ),
                        const SizedBox(height: 24),

                        // Cancel and Log Workout Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextButton(
                                onPressed: _logWorkout,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  backgroundColor: _goldTan,
                                ),
                                child: const Text(
                                  'Log Workout',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _navyBlue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
}
