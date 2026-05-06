import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/services/macro_calculator.dart';

/// Displays the user's daily macro targets
class DailyMacrosCard extends ConsumerWidget {
  const DailyMacrosCard({super.key, this.onTap, this.compact = false});

  final VoidCallback? onTap;
  final bool compact;

  static const Color _navyBlue = Color(0xFF273967);
  static const Color _green = Color(0xFF00D084);
  static const Color _orange = Color(0xFFFF6B35);
  static const Color _gold = Color(0xFFD6B66E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macrosAsync = ref.watch(dailyMacrosProvider);

    return macrosAsync.when(
      data: (macros) {
        if (macros == null) {
          return _buildEmptyState(context);
        }
        return _buildMacrosCard(context, macros);
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildMacrosCard(BuildContext context, DailyMacros macros) {
    if (compact) {
      return _buildCompactCard(macros);
    }
    return _buildFullCard(macros);
  }

  Widget _buildFullCard(DailyMacros macros) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _navyBlue.withValues(alpha: 0.05),
                _green.withValues(alpha: 0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: _orange, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Macro Targets',
                    style: TextStyle(
                      color: _navyBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMacroRow('Calories', '${macros.calories} kcal', _orange),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMacroRow(
                      'Protein',
                      '${macros.protein}g',
                      _navyBlue,
                      showIcon: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMacroRow(
                      'Carbs',
                      '${macros.carbs}g',
                      _gold,
                      showIcon: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMacroRow(
                      'Fat',
                      '${macros.fat}g',
                      _green,
                      showIcon: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMacroRow('Fiber', '${macros.fiber}g', Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(DailyMacros macros) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCompactMacroItem('Calories', macros.calories, _orange),
            _buildCompactMacroItem('Protein', macros.protein, _navyBlue),
            _buildCompactMacroItem('Carbs', macros.carbs, _gold),
            _buildCompactMacroItem('Fat', macros.fat, _green),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMacroItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroRow(
    String label,
    String value,
    Color color, {
    bool showIcon = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (showIcon)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(Icons.arrow_forward, color: color, size: 18),
          ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[50],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[400], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Daily Macro Targets',
                  style: TextStyle(
                    color: _navyBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Complete your health profile to see personalized macro recommendations based on your goals and measurements.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_navyBlue),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.red[50],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unable to load macro targets',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
