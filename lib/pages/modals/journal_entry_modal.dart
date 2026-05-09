import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/models/prototype_data.dart';
import 'package:nutrisense/providers/firebase_providers.dart';

class JournalEntryModal extends ConsumerStatefulWidget {
  const JournalEntryModal({super.key, this.entry});

  final JournalRecord? entry;

  static Future<void> show(BuildContext context, {JournalRecord? entry}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => JournalEntryModal(entry: entry),
    );
  }

  @override
  ConsumerState<JournalEntryModal> createState() => _JournalEntryModalState();
}

class _JournalEntryModalState extends ConsumerState<JournalEntryModal> {
  static const Color _navyBlue = Color(0xFF1E2A4A);
  static const Color _lightGray = Color(0xFFF5F5F5);

  late final TextEditingController _title;
  late final TextEditingController _content;
  late DateTime _selectedDate;
  late String _selectedMood;
  late final Set<String> _selectedTags;
  bool _isSaving = false;

  static const List<String> _moods = <String>[
    'Happy',
    'Calm',
    'Sad',
    'Stressed',
    'Tired',
    'Motivated',
  ];

  static const List<String> _availableTags = <String>[
    'Grateful',
    'Reflection',
    'Goals',
    'Health',
    'Study',
    'Personal',
  ];

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _title = TextEditingController(text: entry?.title ?? '');
    _content = TextEditingController(text: entry?.content ?? '');
    _selectedDate = entry?.entryDate ?? DateTime.now();
    _selectedMood = entry?.mood ?? 'Calm';
    _selectedTags = (entry?.tags ?? const <String>[]).toSet();
    _content.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    if (_content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something in your journal.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final service = ref.read(prototypeDataServiceProvider);
      final entry = widget.entry;
      final title = _resolvedTitle();
      final content = _content.text.trim();
      if (entry == null) {
        await service.addJournalEntry(
          title: title,
          content: content,
          mood: _selectedMood,
          entryDate: _selectedDate,
          tags: _selectedTags.toList(growable: false),
        );
      } else {
        await service.updateJournalEntry(
          entryId: entry.id,
          title: title,
          content: content,
          mood: _selectedMood,
          entryDate: _selectedDate,
          tags: _selectedTags.toList(growable: false),
        );
      }
      ref.invalidate(journalEntriesProvider);
      ref.invalidate(dashboardStatsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            entry == null ? 'Journal entry saved.' : 'Journal entry updated.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not save this journal entry.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _resolvedTitle() {
    final trimmedTitle = _title.text.trim();
    if (trimmedTitle.isNotEmpty) return trimmedTitle;

    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = months[_selectedDate.month - 1];
    return '$month ${_selectedDate.day}, ${_selectedDate.year}';
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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.entry == null ? 'Journal Entry' : 'Edit Entry',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _navyBlue,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: _navyBlue),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Date'),
                        const SizedBox(height: 8),
                        _dateTile(),
                        const SizedBox(height: 20),
                        _label('How are you feeling?'),
                        const SizedBox(height: 12),
                        _moodGrid(),
                        const SizedBox(height: 20),
                        _label('Title'),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _title,
                          hintText: 'Give your entry a title...',
                          icon: Icons.menu_book_outlined,
                        ),
                        const SizedBox(height: 16),
                        _label('Your Thoughts *'),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _content,
                          hintText:
                              'Write about your day, thoughts, feelings, goals...',
                          maxLines: 6,
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${_content.text.length} characters',
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label('Tags'),
                        const SizedBox(height: 12),
                        _tagWrap(),
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
                                    vertical: 14,
                                  ),
                                  backgroundColor: _lightGray,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
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
                                onPressed: _isSaving ? null : _saveEntry,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  backgroundColor: _navyBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Save Entry',
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateTile() {
    return InkWell(
      onTap: _isSaving ? null : _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatDate(_selectedDate),
                style: const TextStyle(color: _navyBlue, fontSize: 14),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _moodGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: _moods.map((mood) {
        final isSelected = _selectedMood == mood;
        return InkWell(
          onTap: _isSaving ? null : () => setState(() => _selectedMood = mood),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? _navyBlue : Colors.white,
              border: Border.all(
                color: isSelected ? _navyBlue : const Color(0xFFE5E7EB),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              mood,
              style: TextStyle(
                color: isSelected ? Colors.white : _navyBlue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _tagWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableTags.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        return FilterChip(
          label: Text(tag),
          selected: isSelected,
          selectedColor: _navyBlue.withValues(alpha: 0.12),
          checkmarkColor: _navyBlue,
          onSelected: _isSaving
              ? null
              : (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
        );
      }).toList(),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: !_isSaving,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: const Color(0xFF9CA3AF)),
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
    );
  }

  Widget _label(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _navyBlue,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/${date.year}';
  }
}
