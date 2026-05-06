import 'package:nutrisense/models/prototype_data.dart';

/// Daily macro intake recommendation
class DailyMacros {
  const DailyMacros({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.cholesterol,
    required this.saturatedFat,
    required this.transFat,
    required this.potassium,
    required this.calcium,
    required this.iron,
    required this.vitaminD,
  });

  // ── Core macros (user-personalised via MacroCalculator) ───────────────────
  final int calories; // kcal
  final int protein; // g
  final int carbs; // g
  final int fat; // g
  final int fiber; // g

  // ── Extended nutrients (FDA / WHO fixed daily reference values) ───────────
  final int sugar; // g   — WHO: <10 % of 2 000 kcal → 50 g
  final int sodium; // mg  — FDA upper limit: 2 300 mg
  final int cholesterol; // mg  — traditional reference: 300 mg
  final int saturatedFat; // g   — ~10 % of 2 000 kcal → 20 g
  final int transFat; // g   — keep as low as possible; 2 g used as visual max
  final int potassium; // mg  — FDA AI: 3 500 mg
  final int calcium; // mg  — FDA DV: 1 000 mg
  final int iron; // mg  — FDA DV (covers both sexes): 18 mg
  final int vitaminD; // mcg — FDA DV (= 800 IU): 20 mcg

  @override
  String toString() =>
      'DailyMacros(calories: $calories, protein: ${protein}g, '
      'carbs: ${carbs}g, fat: ${fat}g, fiber: ${fiber}g, '
      'sugar: ${sugar}g, sodium: ${sodium}mg, cholesterol: ${cholesterol}mg, '
      'saturatedFat: ${saturatedFat}g, transFat: ${transFat}g, '
      'potassium: ${potassium}mg, calcium: ${calcium}mg, '
      'iron: ${iron}mg, vitaminD: ${vitaminD}mcg)';
}

/// Calculates daily macro intake recommendations based on health profile.
class MacroCalculator {
  /// Activity level multipliers (TDEE = BMR × multiplier)
  static const Map<String, double> _activityMultipliers = {
    'Low': 1.2,
    'Moderate': 1.5,
    'High': 1.8,
  };

  /// Base caloric adjustments per fitness goal (applied before pace offset).
  /// These represent the general direction of the goal independent of pace.
  static const Map<String, double> _goalBaseAdjustments = {
    'General fitness': 0.0,
    'Build strength': 0.05, // Small base surplus for strength
    'Weight management': -0.05, // Small base deficit; pace drives the rest
    'Flexibility and mobility': 0.0,
  };

  // ── Fixed FDA / WHO daily reference values ────────────────────────────────
  static const int _dailySugar = 50;
  static const int _dailySodium = 2300;
  static const int _dailyCholesterol = 300;
  static const int _dailySaturatedFat = 20;
  static const int _dailyTransFat = 2;
  static const int _dailyPotassium = 3500;
  static const int _dailyCalcium = 1000;
  static const int _dailyIron = 18;
  static const int _dailyVitaminD = 20;

  /// Calculates daily macro recommendations based on a complete health profile.
  ///
  /// The [weightGainPaceKgPerWeek] from the profile is used to compute a
  /// daily caloric offset:
  ///   • Positive pace (gaining) → caloric surplus
  ///   • For weight management goal, pace is treated as a deficit
  ///
  /// Formula: 1 kg body fat ≈ 7,700 kcal, so pace × 7,700 / 7 = daily offset.
  static DailyMacros calculateMacros(HealthProfile profile) {
    if (!profile.isComplete) {
      throw ArgumentError('Health profile must be complete');
    }

    // BMR via Mifflin-St Jeor equation
    final bmr = _calculateBMR(
      age: profile.age!,
      gender: profile.gender!,
      heightCm: profile.heightCm!,
      weightKg: profile.weightKg!,
    );

    // TDEE = BMR × activity multiplier
    final activityMultiplier =
        _activityMultipliers[profile.activityLevel] ?? 1.5;
    double tdee = bmr * activityMultiplier;

    // Apply small goal-based directional adjustment
    final baseAdjustment = _goalBaseAdjustments[profile.fitnessGoal] ?? 0.0;
    tdee = tdee * (1 + baseAdjustment);

    // Apply pace-driven daily caloric offset
    // pace × 7,700 kcal/kg ÷ 7 days = daily kcal change
    final paceKgPerWeek = profile.weightGainPaceKgPerWeek ?? 0.5;
    final dailyPaceOffset = (paceKgPerWeek * 7700) / 7; // kcal/day

    // Direction: deficit for weight management, surplus for strength/gain
    final isDeficitGoal = profile.fitnessGoal == 'Weight management';
    final calorieTarget = isDeficitGoal
        ? tdee - dailyPaceOffset
        : tdee + dailyPaceOffset;

    // Clamp to a safe minimum (never below 1,200 kcal)
    final safeCalories = calorieTarget.clamp(1200.0, double.infinity).toInt();

    return _calculateMacroDistribution(
      calories: safeCalories,
      fitnessGoal: profile.fitnessGoal,
      dietaryPreference: profile.dietaryPreference,
    );
  }

  /// Mifflin-St Jeor BMR
  static double _calculateBMR({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
  }) {
    final sexConstant = gender.toLowerCase() == 'male' ? 5 : -161;
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + sexConstant;
  }

  /// Distributes [calories] into personalised macro targets.
  static DailyMacros _calculateMacroDistribution({
    required int calories,
    required String fitnessGoal,
    required String dietaryPreference,
  }) {
    int protein;
    int carbs;
    int fat;
    int fiber;

    switch (fitnessGoal) {
      case 'Build strength':
        protein = ((calories * 0.30) / 4).toInt();
        fat = ((calories * 0.25) / 9).toInt();
        carbs = ((calories * 0.45) / 4).toInt();
        break;
      case 'Weight management':
        protein = ((calories * 0.35) / 4).toInt();
        fat = ((calories * 0.28) / 9).toInt();
        carbs = ((calories * 0.37) / 4).toInt();
        break;
      default:
        protein = ((calories * 0.25) / 4).toInt();
        fat = ((calories * 0.30) / 9).toInt();
        carbs = ((calories * 0.45) / 4).toInt();
    }

    if (dietaryPreference.toLowerCase() == 'high-protein') {
      protein = ((calories * 0.35) / 4).toInt();
      carbs = ((calories * 0.40) / 4).toInt();
      fat = ((calories * 0.25) / 9).toInt();
    }

    if (dietaryPreference.toLowerCase() == 'vegetarian' ||
        dietaryPreference.toLowerCase() == 'vegan') {
      protein = ((calories * 0.28) / 4).toInt();
      carbs = ((calories * 0.50) / 4).toInt();
      fat = ((calories * 0.22) / 9).toInt();
    }

    fiber = ((calories / 1000) * 10).ceil().clamp(20, 40);

    return DailyMacros(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: _dailySugar,
      sodium: _dailySodium,
      cholesterol: _dailyCholesterol,
      saturatedFat: _dailySaturatedFat,
      transFat: _dailyTransFat,
      potassium: _dailyPotassium,
      calcium: _dailyCalcium,
      iron: _dailyIron,
      vitaminD: _dailyVitaminD,
    );
  }
}
