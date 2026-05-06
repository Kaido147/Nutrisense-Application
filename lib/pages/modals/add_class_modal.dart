import 'package:flutter/material.dart';
import 'dart:ui';

class AddClassModal extends StatefulWidget {
  const AddClassModal({super.key});

  @override
  State<AddClassModal> createState() => _AddClassModalState();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => const AddClassModal(),
    );
  }
}

class _AddClassModalState extends State<AddClassModal> {
  static const Color _navyBlue = Color(0xFF1E2A4A);
  static const Color _lightGray = Color(0xFFF5F5F5);

  final TextEditingController _classTitle = TextEditingController();
  final TextEditingController _courseCode = TextEditingController();
  final TextEditingController _startTime = TextEditingController();
  final TextEditingController _endTime = TextEditingController();
  final TextEditingController _location = TextEditingController();

  String _selectedDay = 'Monday';
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void dispose() {
    _classTitle.dispose();
    _courseCode.dispose();
    _startTime.dispose();
    _endTime.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  void _addClass() {
    // Validate inputs
    if (_classTitle.text.isEmpty ||
        _startTime.text.isEmpty ||
        _endTime.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // TODO: Save class to database or state management

    // Go back to Quick Actions modal
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
                        Text(
                          'Add Class Schedule',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _navyBlue,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.close, color: _navyBlue, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Class Title
                    Text(
                      'Class Title *',
                      style: TextStyle(
                        color: _navyBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _classTitle,
                      decoration: InputDecoration(
                        hintText: 'e.g., Introduction to Psychology',
                        hintStyle: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.backpack_outlined,
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

                    // Course Code
                    Text(
                      'Course Code',
                      style: TextStyle(
                        color: _navyBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _courseCode,
                      decoration: InputDecoration(
                        hintText: 'e.g., PSYCH 101',
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

                    // Day of Week
                    Text(
                      'Day of Week *',
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
                              children: _days.map((day) {
                                return ListTile(
                                  title: Text(day),
                                  onTap: () {
                                    setState(() => _selectedDay = day);
                                    Navigator.pop(context);
                                  },
                                  trailing: _selectedDay == day
                                      ? Icon(Icons.check, color: _navyBlue)
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
                              Icons.calendar_today_outlined,
                              color: Color(0xFFCCCCCC),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDay,
                              style: const TextStyle(
                                color: _navyBlue,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Start Time and End Time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Time *',
                                style: TextStyle(
                                  color: _navyBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectTime(_startTime),
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
                                        Icons.schedule_outlined,
                                        color: Color(0xFFCCCCCC),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _startTime.text.isEmpty
                                              ? '--:-- --'
                                              : _startTime.text,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Time *',
                                style: TextStyle(
                                  color: _navyBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectTime(_endTime),
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
                                        Icons.schedule_outlined,
                                        color: Color(0xFFCCCCCC),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _endTime.text.isEmpty
                                              ? '--:-- --'
                                              : _endTime.text,
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

                    // Location
                    Text(
                      'Location',
                      style: TextStyle(
                        color: _navyBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _location,
                      decoration: InputDecoration(
                        hintText: 'e.g., Building A, Room 201',
                        hintStyle: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
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
                    const SizedBox(height: 24),

                    // Cancel and Add Class Buttons
                    Row(
                      children: [
                        Expanded(
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: _addClass,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: _navyBlue,
                            ),
                            child: const Text(
                              'Add Class',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
          ),
        ),
      ],
    );
  }
}
