import 'package:flutter/material.dart';
import 'dart:ui';

class AddTaskModal extends StatefulWidget {
  const AddTaskModal({super.key});

  @override
  State<AddTaskModal> createState() => _AddTaskModalState();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => const AddTaskModal(),
    );
  }
}

class _AddTaskModalState extends State<AddTaskModal> {
  static const Color _navyBlue = Color(0xFF1E2A4A);
  static const Color _lightGray = Color(0xFFF5F5F5);
  static const Color _goldTan = Color(0xFFD4B896);

  final TextEditingController _taskTitle = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _dueDate = TextEditingController();
  final TextEditingController _dueTime = TextEditingController();

  String _selectedCategory = 'Study';
  String _selectedPriority = 'Medium';

  final List<String> _categories = [
    'Study',
    'Workout',
    'Personal',
    'Work',
    'Health',
    'Other',
  ];
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  final List<String> _quickDates = ['Today', 'Tomorrow', 'Next Week'];

  @override
  void dispose() {
    _taskTitle.dispose();
    _description.dispose();
    _dueDate.dispose();
    _dueTime.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dueDate.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _dueTime.text = picked.format(context);
      });
    }
  }

  void _setQuickDate(String quickDate) {
    DateTime date = DateTime.now();
    if (quickDate == 'Tomorrow') {
      date = date.add(const Duration(days: 1));
    } else if (quickDate == 'Next Week') {
      date = date.add(const Duration(days: 7));
    }
    _dueDate.text =
        '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  void _addTask() {
    if (_taskTitle.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    // TODO: Save task to database or state management

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.85;

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
            child: Column(
              children: [
                // Sticky Header
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Task',
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
                  ),
                ),
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Task Title
                          Text(
                            'Task Title *',
                            style: TextStyle(
                              color: _navyBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _taskTitle,
                            decoration: InputDecoration(
                              hintText: 'e.g., Complete Math Assignment',
                              hintStyle: const TextStyle(
                                color: Color(0xFFCCCCCC),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.check_circle_outline,
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

                          // Description
                          Text(
                            'Description',
                            style: TextStyle(
                              color: _navyBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _description,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add details about this task...',
                              hintStyle: const TextStyle(
                                color: Color(0xFFCCCCCC),
                                fontSize: 14,
                              ),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Icon(
                                  Icons.menu_outlined,
                                  color: Color(0xFFCCCCCC),
                                ),
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

                          // Category
                          Text(
                            'Category *',
                            style: TextStyle(
                              color: _navyBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((category) {
                              bool isSelected = _selectedCategory == category;
                              return GestureDetector(
                                onTap: () => setState(
                                  () => _selectedCategory = category,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _navyBlue
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? _navyBlue
                                          : Color(0xFFDDDDDD),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : _navyBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Priority Level
                          // Priority Level
                          const Text(
                            'Priority Level *',
                            style: TextStyle(
                              color: _navyBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: _priorities.map((priority) {
                              bool isSelected = _selectedPriority == priority;

                              Color priorityColor;
                              switch (priority) {
                                case 'Low':
                                  priorityColor = const Color(0xFF3B82F6);
                                case 'Medium':
                                  priorityColor = _goldTan;
                                case 'High':
                                  priorityColor = const Color(0xFFF97316);
                                case 'Urgent':
                                  priorityColor = const Color(0xFFEF4444);
                                default:
                                  priorityColor = _goldTan;
                              }

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedPriority = priority,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? priorityColor.withValues(
                                                alpha: 0.08,
                                              )
                                            : Colors.white,
                                        border: Border.all(
                                          color: isSelected
                                              ? priorityColor
                                              : const Color(0xFFE5E7EB),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.flag_outlined,
                                            color: isSelected
                                                ? priorityColor
                                                : const Color(0xFFCCCCCC),
                                            size: 22,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            priority,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? priorityColor
                                                  : _navyBlue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Due Date and Time
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Due Date',
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                                _dueDate.text.isEmpty
                                                    ? 'mm/dd/yy'
                                                    : _dueDate.text,
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
                                      'Due Time',
                                      style: TextStyle(
                                        color: _navyBlue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _selectTime,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _lightGray,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                                _dueTime.text.isEmpty
                                                    ? '--:-- --'
                                                    : _dueTime.text,
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

                          // Quick Date Presets
                          Text(
                            'Quick Date Presets',
                            style: TextStyle(
                              color: _navyBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: _quickDates.map((date) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _setQuickDate(date),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _lightGray,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        date,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _navyBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Buttons
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
                                  onPressed: _addTask,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    backgroundColor: _navyBlue,
                                  ),
                                  child: const Text(
                                    'Add Task',
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
                          const SizedBox(height: 16),
                        ],
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
