import 'package:flutter/material.dart';

/// Circular progress indicator for displaying macro targets
class CircularMacroProgress extends StatelessWidget {
  const CircularMacroProgress({
    super.key,
    required this.current,
    required this.target,
    required this.label,
    required this.unit,
    required this.color,
    this.size = 90,
  });

  final int current;
  final int target;
  final String label;
  final String unit;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final percentage = (current / target).clamp(0.0, 1.0);
    final isExceeded = current > target;

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.08),
                  border: Border.all(
                    color: color.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              // Progress arc
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isExceeded ? const Color(0xFFFF6B35) : color,
                  ),
                  backgroundColor: color.withValues(alpha: 0.1),
                ),
              ),
              // Center content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$current$unit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isExceeded ? const Color(0xFFFF6B35) : color,
                    ),
                  ),
                  Text(
                    target.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF273967),
          ),
        ),
      ],
    );
  }
}
