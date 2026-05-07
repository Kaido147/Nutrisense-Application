import 'dart:async';

import 'package:flutter/material.dart';

import 'exercise_complete_dialog.dart';

Future<bool?> showExerciseModal(
  BuildContext context, {
  required Map<String, dynamic> exercise,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ExerciseModal(exercise: exercise),
  );
}

class _ExerciseModal extends StatefulWidget {
  const _ExerciseModal({required this.exercise});

  final Map<String, dynamic> exercise;

  @override
  State<_ExerciseModal> createState() => _ExerciseModalState();
}

class _ExerciseModalState extends State<_ExerciseModal> {
  static const Color _navy = Color(0xFF1A2B4B);
  static const Color _gold = Color(0xFFFDDC96);
  static const Color _surface = Color(0xFFFBF9F9);
  static const Color _surfaceLow = Color(0xFFF5F3F3);
  static const Color _muted = Color(0xFF667085);

  late final String _name;
  late final String _target;
  late final String _instruction;
  late final int _setCount;
  late final int _initialSeconds;
  late final List<bool> _setCompleted;

  Timer? _timer;
  int _currentSet = 0;
  int _secondsLeft = 60;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _name = widget.exercise['name']?.toString() ?? 'Exercise';
    _target = widget.exercise['reps']?.toString() ?? 'Complete target reps';
    _instruction =
        widget.exercise['instruction']?.toString() ??
        'Move with control and keep a comfortable pace.';
    _setCount = _readPositiveInt(widget.exercise['sets']) ?? 1;
    _initialSeconds = _readPositiveInt(widget.exercise['timerSeconds']) ?? 60;
    _secondsLeft = _initialSeconds;
    _setCompleted = List<bool>.filled(_setCount, false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }

    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _isRunning = false;
        });
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _initialSeconds;
      _isRunning = false;
    });
  }

  Future<void> _completeCurrentSet() async {
    setState(() {
      _setCompleted[_currentSet] = true;
      _timer?.cancel();
      _isRunning = false;
      _secondsLeft = _initialSeconds;
      if (_currentSet < _setCount - 1) _currentSet += 1;
    });

    if (!_setCompleted.every((completed) => completed)) return;

    final shouldClose = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => ExerciseCompleteDialog(
        exerciseName: _name,
        setCompleted: _setCompleted,
        onContinue: () => Navigator.pop(context, true),
      ),
    );

    if (!mounted || shouldClose != true) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final completedSets = _setCompleted.where((completed) => completed).length;
    final progress = completedSets / _setCompleted.length;
    final nextSetLabel = _currentSet + 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.94,
      minChildSize: 0.62,
      maxChildSize: 0.98,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                height: 5,
                width: double.infinity,
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3E2E2),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: _navy,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        bottomRight: Radius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Row(
                  children: [
                    IconButton.filled(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: _surfaceLow,
                        foregroundColor: _navy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Set $nextSetLabel of $_setCount',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.more_vert),
                      style: IconButton.styleFrom(
                        backgroundColor: _surfaceLow,
                        foregroundColor: _navy,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  children: [
                    _ExerciseMediaCard(
                      name: _name,
                      icon: _iconForExercise(_name),
                      isRunning: _isRunning,
                      onToggle: _toggleTimer,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoMetricCard(
                            label: 'Current Set',
                            value: '$nextSetLabel',
                            suffix: '/ $_setCount',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _InfoMetricCard(
                            label: 'Target',
                            value: _target,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _TimerCard(
                      secondsLeft: _secondsLeft,
                      initialSeconds: _initialSeconds,
                      isRunning: _isRunning,
                      onToggle: _toggleTimer,
                      onReset: _resetTimer,
                    ),
                    const SizedBox(height: 20),
                    _InstructionCard(instruction: _instruction),
                    const SizedBox(height: 20),
                    const Text(
                      'Sets',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_setCount, (index) {
                      return _SetTile(
                        setNumber: index + 1,
                        target: _target,
                        active: index == _currentSet,
                        completed: _setCompleted[index],
                      );
                    }),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 26,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _setCompleted[_currentSet]
                          ? null
                          : _completeCurrentSet,
                      icon: const Icon(Icons.check_circle),
                      label: Text('Complete Set $nextSetLabel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: const Color(0xFF59440C),
                        minimumSize: const Size.fromHeight(54),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _navy,
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: _navy),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text('End Exercise'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExerciseMediaCard extends StatelessWidget {
  const _ExerciseMediaCard({
    required this.name,
    required this.icon,
    required this.isRunning,
    required this.onToggle,
  });

  final String name;
  final IconData icon;
  final bool isRunning;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: _ExerciseModalState._navy,
          borderRadius: BorderRadius.circular(30),
          boxShadow: _shadow,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              bottom: -34,
              child: Icon(
                icon,
                size: 190,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const Spacer(),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: IconButton.filled(
                onPressed: onToggle,
                icon: Icon(
                  isRunning ? Icons.pause : Icons.play_arrow,
                  size: 36,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.92),
                  foregroundColor: _ExerciseModalState._navy,
                  fixedSize: const Size(68, 68),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoMetricCard extends StatelessWidget {
  const _InfoMetricCard({
    required this.label,
    required this.value,
    this.suffix,
  });

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(radius: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ExerciseModalState._muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            text: TextSpan(
              text: value,
              style: const TextStyle(
                color: _ExerciseModalState._navy,
                fontSize: 26,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
              children: [
                if (suffix != null)
                  TextSpan(
                    text: ' $suffix',
                    style: const TextStyle(
                      color: Color(0xFF75777F),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({
    required this.secondsLeft,
    required this.initialSeconds,
    required this.isRunning,
    required this.onToggle,
    required this.onReset,
  });

  final int secondsLeft;
  final int initialSeconds;
  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final progress = initialSeconds == 0 ? 0.0 : secondsLeft / initialSeconds;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(radius: 24, color: Colors.white),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: const Color(0xFFE3E2E2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      _ExerciseModalState._gold,
                    ),
                  ),
                ),
                Text(
                  _formatSeconds(secondsLeft),
                  style: const TextStyle(
                    color: _ExerciseModalState._navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Set Timer',
                  style: TextStyle(
                    color: _ExerciseModalState._navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Use this as a pacing guide for timed sets.',
                  style: TextStyle(color: _ExerciseModalState._muted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onToggle,
                        icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(isRunning ? 'Pause' : 'Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ExerciseModalState._navy,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.outlined(
                      onPressed: onReset,
                      icon: const Icon(Icons.replay),
                      color: _ExerciseModalState._navy,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.instruction});

  final String instruction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(radius: 22, color: Colors.white),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFD8E2FF),
            foregroundColor: _ExerciseModalState._navy,
            child: Icon(Icons.info_outline),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Form Cue',
                  style: TextStyle(
                    color: _ExerciseModalState._navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  instruction,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  const _SetTile({
    required this.setNumber,
    required this.target,
    required this.active,
    required this.completed,
  });

  final int setNumber;
  final String target;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? Colors.green
        : active
        ? _ExerciseModalState._navy
        : const Color(0xFFC5C6CF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: completed
              ? const Color(0xFFE6F8EC)
              : active
              ? const Color(0xFFF5F3F3)
              : Colors.white,
          border: Border.all(
            color: color,
            width: active || completed ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: _shadow,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color,
              child: completed
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '$setNumber',
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : _ExerciseModalState._navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set $setNumber',
                    style: const TextStyle(
                      color: _ExerciseModalState._navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    target,
                    style: const TextStyle(color: _ExerciseModalState._muted),
                  ),
                ],
              ),
            ),
            if (active && !completed)
              const Text(
                'Now',
                style: TextStyle(
                  color: _ExerciseModalState._navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration({
  required double radius,
  Color color = _ExerciseModalState._surfaceLow,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white),
    boxShadow: _shadow,
  );
}

List<BoxShadow> get _shadow {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

String _formatSeconds(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}

int? _readPositiveInt(Object? value) {
  final parsed = switch (value) {
    int() => value,
    num() => value.toInt(),
    String() => int.tryParse(value),
    _ => null,
  };
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

IconData _iconForExercise(String name) {
  final value = name.toLowerCase();
  if (value.contains('plank') || value.contains('crunch')) {
    return Icons.accessibility_new;
  }
  if (value.contains('jump') ||
      value.contains('jog') ||
      value.contains('run')) {
    return Icons.directions_run;
  }
  if (value.contains('stretch') || value.contains('pose')) {
    return Icons.self_improvement;
  }
  if (value.contains('squat') || value.contains('lunge')) {
    return Icons.airline_seat_legroom_extra;
  }
  return Icons.fitness_center;
}
