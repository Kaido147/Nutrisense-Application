import 'package:flutter/material.dart';

import '../study_models.dart';
import '../study_theme.dart';

class FocusSessionCard extends StatelessWidget {
  const FocusSessionCard({
    super.key,
    required this.timerState,
    required this.onToggleTimer,
    required this.onResetTimer,
    required this.onPresetSelected,
  });

  final FocusTimerState timerState;
  final VoidCallback onToggleTimer;
  final VoidCallback onResetTimer;
  final ValueChanged<FocusPresetId> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: StudyTheme.softShadow,
      ),
      child: Column(
        children: [
          Text(
            timerState.heading,
            style: const TextStyle(
              color: StudyTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final double timerSize =
                  constraints.maxWidth.clamp(180.0, 240.0).toDouble() * 0.7;

              return SizedBox(
                width: timerSize,
                height: timerSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: timerState.progress,
                        strokeWidth: 8,
                        backgroundColor: StudyTheme.navyBlue.withValues(
                          alpha: 0.12,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          StudyTheme.navyBlue,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timerState.durationLabel,
                          style: const TextStyle(
                            color: StudyTheme.navyBlue,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          timerState.subtitle,
                          style: const TextStyle(
                            color: StudyTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onToggleTimer,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: StudyTheme.navyBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    timerState.isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: onResetTimer,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: StudyTheme.chipBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.replay_rounded,
                    color: StudyTheme.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: timerState.presets
                .map(
                  (preset) => _PresetChip(
                    label: preset.label,
                    isSelected: timerState.selectedPresetId == preset.id,
                    onTap: () => onPresetSelected(preset.id),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? StudyTheme.chipBackground
              : StudyTheme.chipBackground.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? StudyTheme.navyBlue : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: StudyTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
