import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';

class RestTimerDialog extends StatefulWidget {
  final VoidCallback onSkipRest;
  final VoidCallback onEndWorkout;

  const RestTimerDialog({
    super.key,
    required this.onSkipRest,
    required this.onEndWorkout,
  });

  @override
  State<RestTimerDialog> createState() => _RestTimerDialogState();
}

class _RestTimerDialogState extends State<RestTimerDialog> {
  Timer? _timer;
  int _seconds = 60;
  double _progress = 1.0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _progress = (_progress - (1 / 1200)).clamp(0.0, 1.0);
        _seconds = (_progress * 60).ceil();
      });
      
      // When timer reaches 0, automatically complete
      if (_seconds <= 0) {
        timer.cancel();
        _timer = null;
        widget.onSkipRest();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color _navyBlue = Color(0xFF273967);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              // Pause icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(
                  Icons.pause,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Rest Time',
                style: TextStyle(
                  color: _navyBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'Take a breather before your next set',
                style: TextStyle(
                  color: _navyBlue.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),
              // Circular timer
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _seconds.toString(),
                          style: TextStyle(
                            color: _navyBlue,
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'seconds',
                          style: TextStyle(
                            color: _navyBlue.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _timer?.cancel();
                        widget.onSkipRest();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navyBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Skip Rest',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () {
                        _timer?.cancel();
                        widget.onEndWorkout();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'End Workout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _navyBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}