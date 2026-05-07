import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nutrisense/pages/study/study_models.dart';

class AddTaskModal extends StatefulWidget {
  const AddTaskModal({super.key, this.task, this.onSave});

  final StudyTask? task;

  final Future<void> Function({
    required String title,
    String? description,
    DateTime? dueAt,
  })?
  onSave;

  static Future<void> show(
    BuildContext context, {
    StudyTask? task,
    Future<void> Function({
      required String title,
      String? description,
      DateTime? dueAt,
    })?
    onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => AddTaskModal(task: task, onSave: onSave),
    );
  }

  @override
  State<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<AddTaskModal> {
  static const Color _navyBlue = Color(0xFF1E2A4A);
  static const Color _lightGray = Color(0xFFF5F5F5);
  static const Color _goldTan = Color(0xFFD4B896);
  static const Color _mutedText = Color(0xFF6B7280);
  static const Color _hintText = Color(0xFF7A8190);

  final TextEditingController _taskTitle = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _dueDate = TextEditingController();
  final TextEditingController _dueTime = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedPriority = 'Medium';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  final List<String> _quickDates = ['Today', 'Tomorrow', 'Next Week'];

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task == null) {
      return;
    }

    _taskTitle.text = task.title;
    _description.text = task.description ?? '';
    final DateTime? dueAt = task.dueAt;
    if (dueAt != null) {
      _selectedDate = DateTime(dueAt.year, dueAt.month, dueAt.day);
      _selectedTime = TimeOfDay(hour: dueAt.hour, minute: dueAt.minute);
      _dueDate.text =
          '${dueAt.month.toString().padLeft(2, '0')}/${dueAt.day.toString().padLeft(2, '0')}/${dueAt.year}';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TimeOfDay? selectedTime = _selectedTime;
    if (selectedTime != null && _dueTime.text.isEmpty) {
      _dueTime.text = selectedTime.format(context);
    }
  }

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
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
      _dueDate.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _selectedTime = picked;
      _dueTime.text = picked.format(context);
    });
  }

  void _setQuickDate(String quickDate) {
    DateTime date = DateTime.now();
    if (quickDate == 'Tomorrow') {
      date = date.add(const Duration(days: 1));
    } else if (quickDate == 'Next Week') {
      date = date.add(const Duration(days: 7));
    }

    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _dueDate.text =
          '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    });
  }

  DateTime? _buildDueAt() {
    if (_selectedDate == null) {
      return null;
    }

    final TimeOfDay selectedTime =
        _selectedTime ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  Future<void> _addTask() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate() || _isSaving) {
      return;
    }

    final String trimmedTitle = _taskTitle.text.trim();
    if (trimmedTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final saveTask = widget.onSave;
      if (saveTask != null) {
        await saveTask(
          title: trimmedTitle,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          dueAt: _buildDueAt(),
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (error, stackTrace) {
      debugPrint('Failed to save study task: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not save this task.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.85;

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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
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
                            widget.task == null ? 'Add Task' : 'Edit Task',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _navyBlue,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.close,
                              color: _navyBlue,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Task Title *',
                              style: TextStyle(
                                color: _navyBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _taskTitle,
                              enabled: !_isSaving,
                              cursorColor: _navyBlue,
                              style: const TextStyle(
                                color: _navyBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'Please enter a task title';
                                }

                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'e.g., Complete Math Assignment',
                                hintStyle: const TextStyle(
                                  color: _hintText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: const Icon(
                                  Icons.check_circle_outline,
                                  color: _mutedText,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _goldTan),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                disabledBorder: OutlineInputBorder(
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
                              enabled: !_isSaving,
                              maxLines: 3,
                              cursorColor: _navyBlue,
                              style: const TextStyle(
                                color: _navyBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add details about this task...',
                                hintStyle: const TextStyle(
                                  color: _hintText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Icon(
                                    Icons.menu_outlined,
                                    color: _mutedText,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _goldTan),
                                ),
                                disabledBorder: OutlineInputBorder(
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
                            Text(
                              'Category',
                              style: TextStyle(
                                color: _navyBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _navyBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Study',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                final bool isSelected =
                                    _selectedPriority == priority;
                                final Color priorityColor = switch (priority) {
                                  'Low' => const Color(0xFF3B82F6),
                                  'Medium' => _goldTan,
                                  'High' => const Color(0xFFF97316),
                                  'Urgent' => const Color(0xFFEF4444),
                                  _ => _goldTan,
                                };

                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: GestureDetector(
                                      onTap: _isSaving
                                          ? null
                                          : () => setState(
                                              () =>
                                                  _selectedPriority = priority,
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.flag_outlined,
                                              color: isSelected
                                                  ? priorityColor
                                                  : _mutedText,
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
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        onTap: _isSaving ? null : _selectDate,
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
                                                color: _mutedText,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _dueDate.text.isEmpty
                                                      ? 'mm/dd/yy'
                                                      : _dueDate.text,
                                                  style: TextStyle(
                                                    color: _dueDate.text.isEmpty
                                                        ? _hintText
                                                        : _navyBlue,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        _dueDate.text.isEmpty
                                                        ? FontWeight.w500
                                                        : FontWeight.w700,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        onTap: _isSaving ? null : _selectTime,
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
                                                color: _mutedText,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _dueTime.text.isEmpty
                                                      ? '--:-- --'
                                                      : _dueTime.text,
                                                  style: TextStyle(
                                                    color: _dueTime.text.isEmpty
                                                        ? _hintText
                                                        : _navyBlue,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        _dueTime.text.isEmpty
                                                        ? FontWeight.w500
                                                        : FontWeight.w700,
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
                                      onTap: _isSaving
                                          ? null
                                          : () => _setQuickDate(date),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _lightGray,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: _isSaving
                                        ? null
                                        : () => Navigator.pop(context),
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
                                    onPressed: _isSaving ? null : _addTask,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      backgroundColor: _navyBlue,
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            widget.task == null
                                                ? 'Add Task'
                                                : 'Save Task',
                                            style: const TextStyle(
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
        ),
      ],
    );
  }
}
