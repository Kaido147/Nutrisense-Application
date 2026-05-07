import 'package:flutter/material.dart';
import 'dart:async';
import 'rest_timer_dialog.dart';
import 'exercise_complete_dialog.dart';

void showExerciseModal(
  BuildContext context, {
  String exerciseName = 'Shoulder Press',
}) {
  bool isCompletePressed = false;
  bool isEndPressed = false;
  int currentSet = 0;
  final List<bool> setCompleted = [false, false, false];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      final Color primary = Theme.of(context).colorScheme.primary;
      return DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {
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
                    // Fixed header with title and close button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            exerciseName,
                            style: TextStyle(
                              color: primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.close,
                                color: primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Fixed divider
                    Divider(
                      color: Colors.grey.withValues(alpha: 0.2),
                      height: 1,
                    ),
                    // Scrollable content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        children: [
                          // Current Set / Target Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Set',
                                          style: TextStyle(
                                            color: primary.withValues(
                                              alpha: 0.6,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${currentSet + 1} / ${setCompleted.length}',
                                            style: TextStyle(
                                            color: primary,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Target',
                                          style: TextStyle(
                                            color: primary.withValues(
                                              alpha: 0.6,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '12 reps',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value:
                                        (currentSet + 1) / setCompleted.length,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.withValues(
                                      alpha: 0.2,
                                    ),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                      primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sets Progress Title
                          Text(
                            'Sets Progress',
                            style: TextStyle(
                              color: primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Sets Progress List
                          ...[1, 2, 3].map((setNum) {
                            final isActive = setNum - 1 == currentSet;
                            final isDone = setCompleted[setNum - 1];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                  color: isDone
                                      ? const Color(0xFFE8F7EC)
                                      : isActive
                                      ? Colors.grey.withValues(alpha: 0.05)
                                      : Colors.white,
                                  border: Border.all(
                                    color: isDone
                                        ? Colors.green
                                        : isActive
                                        ? primary
                                        : Colors.grey.withValues(alpha: 0.2),
                                    width: isActive || isDone ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                            decoration: BoxDecoration(
                                            color: isDone
                                                ? Colors.green
                                                : isActive
                                                ? primary
                                                : Colors.grey.withValues(
                                                    alpha: 0.2,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                          child: Center(
                                            child: isDone
                                                ? const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 20,
                                                  )
                                                : Text(
                                                    setNum.toString(),
                                                    style: TextStyle(
                                                        color: isActive
                                                          ? Colors.white
                                                          : primary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Set $setNum',
                                              style: TextStyle(
                                                color: primary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              '12 reps',
                                              style: TextStyle(
                                                color: primary.withValues(
                                                  alpha: 0.6,
                                                ),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (isActive)
                                      Container(
                                        width: 28,
                                        height: 28,
                                        child: const Icon(
                                          Icons.local_fire_department,
                                          color: Colors.orange,
                                          size: 24,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 24),

                          // Description Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue.withValues(alpha: 0.05),
                              border: Border.all(
                                color: Colors.lightBlue.withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Build strong, defined shoulders with this fundamental pressing movement.',
                                  style: TextStyle(
                                    color: primary.withValues(alpha: 0.7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Tips
                                Text(
                                  'Tips',
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...[
                                  'Start with weights at shoulder height',
                                  'Press overhead until arms are fully extended',
                                  'Control the weight on the way down',
                                ].map((tip) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.chevron_right,
                                          color: Colors.lightBlue.withValues(
                                            alpha: 1,
                                          ),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                            child: Text(
                                            tip,
                                            style: TextStyle(
                                              color: primary.withValues(
                                                alpha: 0.7,
                                              ),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Action buttons
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Listener(
                                onPointerDown: (_) =>
                                    setState(() => isCompletePressed = true),
                                onPointerUp: (_) =>
                                    setState(() => isCompletePressed = false),
                                onPointerCancel: (_) =>
                                    setState(() => isCompletePressed = false),
                                child: AnimatedScale(
                                  scale: isCompletePressed ? 0.96 : 1.0,
                                  duration: const Duration(milliseconds: 100),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      setState(() {
                                        setCompleted[currentSet] = true;
                                        if (currentSet <
                                            setCompleted.length - 1)
                                          currentSet++;
                                      });

                                      // Show rest timer modal
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        barrierColor: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        builder: (dialogContext) => RestTimerDialog(
                                          onSkipRest: () {
                                            Navigator.pop(dialogContext);

                                            // Check if all sets are completed
                                            if (setCompleted.every(
                                              (completed) => completed,
                                            )) {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                barrierColor: Colors.black
                                                    .withValues(alpha: 0.3),
                                                builder: (completionContext) =>
                                                    ExerciseCompleteDialog(
                                                      setCompleted:
                                                          setCompleted,
                                                      onContinue: () {
                                                        Navigator.pop(
                                                          completionContext,
                                                        );
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                              );
                                            }
                                          },
                                          onEndWorkout: () {
                                            Navigator.pop(dialogContext);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Workout ended.'),
                                              ),
                                            );
                                            Navigator.pop(context);
                                          },
                                        ),
                                      );
                                    },
                                    style:
                                        ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ).copyWith(
                                          splashFactory: NoSplash.splashFactory,
                                          overlayColor:
                                              MaterialStateProperty.all(
                                                Colors.transparent,
                                              ),
                                        ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(right: 10.0),
                                          child: Icon(
                                            Icons.check,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          setCompleted[currentSet]
                                              ? 'Set ${currentSet + 1} Completed'
                                              : 'Complete Set ${currentSet + 1}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Listener(
                                onPointerDown: (_) =>
                                    setState(() => isEndPressed = true),
                                onPointerUp: (_) =>
                                    setState(() => isEndPressed = false),
                                onPointerCancel: (_) =>
                                    setState(() => isEndPressed = false),
                                child: AnimatedScale(
                                  scale: isEndPressed ? 0.96 : 1.0,
                                  duration: const Duration(milliseconds: 100),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      setState(() => isEndPressed = true);
                                      await Future.delayed(
                                        const Duration(milliseconds: 100),
                                      );
                                      setState(() => isEndPressed = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Workout ended.'),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade200,
                                      foregroundColor: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'End Workout',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
