import 'package:flutter/material.dart';

class CookingStepsModal extends StatefulWidget {
  final Map<String, dynamic> meal;
  final VoidCallback onBack;

  const CookingStepsModal({
    super.key,
    required this.meal,
    required this.onBack,
  });

  @override
  State<CookingStepsModal> createState() => _CookingStepsModalState();
}

class _CookingStepsModalState extends State<CookingStepsModal> {
  static const Color _navyBlue = Color(0xFF273967);
  static const Color _green = Color(0xFF00D084);

  int _currentStep = 0;

  // ---------------------------------------------------------------------------
  // Instruction parser
  // ---------------------------------------------------------------------------

  /// Converts a raw TheMealDB instruction string into a list of step maps
  /// with 'title' and 'description' keys. Handles two common formats:
  ///   1. Inline-numbered  → "0. Do this1. Do that2. Finish"
  ///   2. Paragraph/prose  → "Do this. Then do that. Finally finish."
  static List<Map<String, String>> parseInstructions(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return [];

    // ── Format 1: inline-numbered steps ──────────────────────────────────────
    // Detects patterns like "softens1. Add beef" or a leading "0. Heat oil".
    // We look for a digit immediately preceded by a word char OR at string
    // start, followed by ". " and an uppercase letter.
    final markerRegex = RegExp(r'(?:(?<=[a-zA-Z])|^)(\d+)\.\s+(?=[A-Z])');
    final markerMatches = markerRegex.allMatches(text);

    if (markerMatches.length >= 2) {
      // Split on every occurrence of digit(s) + ". "
      // The lookbehind ensures we don't trip on decimal numbers like "30.5 g".
      final splitRegex = RegExp(r'(?:(?<=[a-zA-Z])|(?<=\s)|^)\d+\.\s+');
      final parts = text
          .split(splitRegex)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return _toStepMaps(parts);
    }

    // ── Format 2a: newline-separated paragraphs ───────────────────────────────
    final lines = text
        .split(RegExp(r'\n+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length > 1) return _toStepMaps(lines);

    // ── Format 2b: sentence-splitting (prose paragraph) ──────────────────────
    // Split at ". " / "! " / "? " where the NEXT char is uppercase.
    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+(?=[A-Z])'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (sentences.length <= 1) return _toStepMaps([text]);

    // Group every 2 sentences so steps aren't too granular.
    final grouped = <String>[];
    for (int i = 0; i < sentences.length; i += 2) {
      final end = (i + 2).clamp(0, sentences.length);
      grouped.add(sentences.sublist(i, end).join(' '));
    }
    return _toStepMaps(grouped);
  }

  static List<Map<String, String>> _toStepMaps(List<String> parts) {
    return parts.asMap().entries.map((e) {
      return {'title': _extractTitle(e.value), 'description': e.value};
    }).toList();
  }

  /// Derives a short title from the first 4 words of a step description.
  static String _extractTitle(String text) {
    final words = text.trim().split(RegExp(r'\s+')).take(4).join(' ');
    // Strip trailing punctuation so the title reads cleanly.
    return words.replaceAll(RegExp(r'[.!?,;:]+$'), '').trim();
  }

  // ---------------------------------------------------------------------------

  List<Map<String, String>> get _steps {
    // Prefer pre-structured steps if already parsed upstream.
    if (widget.meal['steps'] != null) {
      return List<Map<String, String>>.from(widget.meal['steps']);
    }

    // Parse raw instruction string from TheMealDB ('strInstructions' field).
    final raw = widget.meal['strInstructions'] as String?;
    if (raw != null && raw.trim().isNotEmpty) {
      final parsed = parseInstructions(raw);
      if (parsed.isNotEmpty) return parsed;
    }

    // Fallback demo steps
    return [
      {
        'title': 'Prepare Ingredients',
        'description':
            'Wash and chop all vegetables. Measure out spices and set aside. Pat proteins dry with a paper towel.',
      },
      {
        'title': 'Heat the Pan',
        'description':
            'Heat a large skillet or wok over medium-high heat. Add oil and let it shimmer before adding any ingredients.',
      },
      {
        'title': 'Cook the Protein',
        'description':
            'Add your protein to the hot pan. Cook undisturbed for 2–3 minutes per side until golden brown and cooked through.',
      },
      {
        'title': 'Add Vegetables',
        'description':
            'Toss in the harder vegetables first (carrots, broccoli), cook for 2 minutes, then add softer ones (peppers, zucchini).',
      },
      {
        'title': 'Season & Sauce',
        'description':
            'Add spices, sauces, and aromatics. Stir everything together and cook for another 2–3 minutes until fragrant.',
      },
      {
        'title': 'Plate & Serve',
        'description':
            'Transfer to a serving dish. Garnish with fresh herbs or a squeeze of lemon. Serve immediately while hot.',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.78;
    final steps = _steps;
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == steps.length - 1;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
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
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            color: _navyBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How to Cook',
                            style: TextStyle(
                              color: _navyBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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
                ),
                // Meal name chip
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _navyBlue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.meal['name'] ?? '',
                        style: TextStyle(
                          color: _navyBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                // Step progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Step ${_currentStep + 1} of ${steps.length}',
                            style: TextStyle(
                              color: _navyBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${((_currentStep + 1) / steps.length * 100).toInt()}% complete',
                            style: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (_currentStep + 1) / steps.length,
                          backgroundColor: _navyBlue.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(_green),
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Scrollable step content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Active step card
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: Container(
                            key: ValueKey(_currentStep),
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _navyBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _green,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${_currentStep + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        steps[_currentStep]['title'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  steps[_currentStep]['description'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // All steps overview (tappable)
                        ...steps.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final step = entry.value;
                          final isDone = idx < _currentStep;
                          final isCurrent = idx == _currentStep;
                          return GestureDetector(
                            onTap: () => setState(() => _currentStep = idx),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? _green
                                          : isCurrent
                                          ? _navyBlue
                                          : const Color(0xFFF0F0F0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: isDone
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          )
                                        : Text(
                                            '${idx + 1}',
                                            style: TextStyle(
                                              color: isCurrent
                                                  ? Colors.white
                                                  : const Color(0xFF999999),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      step['title'] ?? '',
                                      style: TextStyle(
                                        color: isCurrent
                                            ? _navyBlue
                                            : isDone
                                            ? _green
                                            : const Color(0xFF999999),
                                        fontSize: 13,
                                        fontWeight: isCurrent
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                // Bottom navigation buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (!isFirst)
                            Expanded(
                              child: TextButton(
                                onPressed: () => setState(() => _currentStep--),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFF5F5F5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  '← Previous',
                                  style: TextStyle(
                                    color: _navyBlue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          if (!isFirst) const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLast
                                  ? () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Enjoy your ${widget.meal['name']}! 🍽️',
                                          ),
                                        ),
                                      );
                                    }
                                  : () => setState(() => _currentStep++),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLast ? _green : _navyBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                isLast ? '🍽️ Done!' : 'Next Step →',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onBack();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF5F5F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            '← Back to Meal',
                            style: TextStyle(
                              color: _navyBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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
