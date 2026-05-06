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
  static const Color _navy = Color(0xFF273967);
  static const Color _gold = Color(0xFFE2C783);

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
    final progress =
        _setCompleted.where((completed) => completed).length /
        _setCompleted.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close, color: _navy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Divider(color: Colors.grey.withValues(alpha: 0.18), height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _ProgressPanel(
                      currentSet: _currentSet,
                      setCount: _setCount,
                      target: _target,
                      progress: progress,
                    ),
                    const SizedBox(height: 20),
                    _TimerPanel(
                      secondsLeft: _secondsLeft,
                      initialSeconds: _initialSeconds,
                      isRunning: _isRunning,
                      onToggle: _toggleTimer,
                      onReset: _resetTimer,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sets Progress',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 18),
                    _InfoBox(instruction: _instruction),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: _setCompleted[_currentSet]
                          ? null
                          : _completeCurrentSet,
                      icon: const Icon(Icons.check),
                      label: Text('Complete Set ${_currentSet + 1}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _navy,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.currentSet,
    required this.setCount,
    required this.target,
    required this.progress,
  });

  final int currentSet;
  final int setCount;
  final String target;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Metric(
                label: 'Current Set',
                value: '${currentSet + 1} / $setCount',
              ),
              _Metric(label: 'Target', value: target, alignEnd: true),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _ExerciseModalState._navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({
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
      decoration: _panelDecoration(),
      child: Column(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.grey.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      _ExerciseModalState._gold,
                    ),
                  ),
                ),
                Text(
                  _formatSeconds(secondsLeft),
                  style: const TextStyle(
                    color: _ExerciseModalState._navy,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onToggle,
                  icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(isRunning ? 'Pause' : 'Play'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ExerciseModalState._navy,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.replay),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ExerciseModalState._navy,
                  ),
                ),
              ),
            ],
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
        : const Color(0xFFD7DCE6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: completed
              ? const Color(0xFFE8F7EC)
              : active
              ? const Color(0xFFF4F6FA)
              : Colors.white,
          border: Border.all(color: color, width: active || completed ? 2 : 1),
          borderRadius: BorderRadius.circular(18),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set $setNumber',
                  style: const TextStyle(
                    color: _ExerciseModalState._navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(target, style: const TextStyle(color: Color(0xFF667085))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.instruction});

  final String instruction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              color: _ExerciseModalState._navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            instruction,
            style: const TextStyle(color: Color(0xFF4B5563), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ExerciseModalState._navy,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: const Color(0xFFF7F7F7),
    border: Border.all(color: const Color(0xFFE5E7EB)),
    borderRadius: BorderRadius.circular(18),
  );
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
