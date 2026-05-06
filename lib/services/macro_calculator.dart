import 'package:nutrisense/models/prototype_data.dart';

/// Daily macro intake recommendation
class DailyMacros {
  const DailyMacros({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  /// Daily calorie target in kcal
  final int calories;

  /// Daily protein target in grams
  final int protein;

  /// Daily carbs target in grams
  final int carbs;

  /// Daily fat target in grams
  final int fat;

  /// Daily fiber target in grams
  final int fiber;

  @override
  String toString() =>
      'DailyMacros(calories: $calories, protein: ${protein}g, '
      'carbs: ${carbs}g, fat: ${fat}g, fiber: ${fiber}g)';
}

/// Calculates daily macro intake recommendations based on health profile
class MacroCalculator {
  /// Activity level multipliers (TDEE = BMR × multiplier)
  static const Map<String, double> _activityMultipliers = {
    'Low': 1.2, // Sedentary: little or no exercise
    'Moderate': 1.5, // Light exercise 1-3 days/week
    'High': 1.8, // Moderate exercise 3-5 days/week
  };

  /// Default caloric adjustments per fitness goal (% of TDEE)
  static const Map<String, double> _calorieAdjustments = {
    'General fitness': 0.0, // Maintenance
    'Build strength': 0.1, // +10% surplus
    'Weight management': -0.15, // -15% deficit
    'Flexibility and mobility': 0.0, // Maintenance
  };

  /// Calculates daily macro recommendations based on health profile
  static DailyMacros calculateMacros(HealthProfile profile) {
    if (!profile.isComplete) {
      throw ArgumentError('Health profile must be complete');
    }

    // Calculate BMR using Mifflin-St Jeor equation
    final bmr = _calculateBMR(
      age: profile.age!,
      gender: profile.gender!,
      heightCm: profile.heightCm!,
      weightKg: profile.weightKg!,
    );

    // Apply activity multiplier to get TDEE
    final activityMultiplier =
        _activityMultipliers[profile.activityLevel] ?? 1.5;
    var tdee = bmr * activityMultiplier;

    // Apply caloric adjustment based on fitness goal
    final adjustment = _calorieAdjustments[profile.fitnessGoal] ?? 0.0;
    tdee = tdee * (1 + adjustment);

    final dailyCalories = tdee.toInt();

    // Calculate macros based on fitness goal and dietary preference
    final macros = _calculateMacroDistribution(
      calories: dailyCalories,
      fitnessGoal: profile.fitnessGoal,
      dietaryPreference: profile.dietaryPreference,
    );

    return macros;
  }

  /// Calculates BMR (Basal Metabolic Rate) using Mifflin-St Jeor equation
  /// BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + (sex_constant)
  static double _calculateBMR({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
  }) {
    final sexConstant = gender.toLowerCase() == 'male' ? 5 : -161;
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + sexConstant;
  }

  /// Calculates macro distribution based on fitness goal and dietary preference
  static DailyMacros _calculateMacroDistribution({
    required int calories,
    required String fitnessGoal,
    required String dietaryPreference,
  }) {
    int protein;
    int carbs;
    int fat;
    int fiber;

    // Determine protein intake based on fitness goal
    // High-protein diets aim for 1.6-2.2g per kg bodyweight
    // We'll use general recommendations:
    // - Building muscle: 30% of calories
    // - Weight loss: 35% of calories (preserves muscle)
    // - General fitness: 25% of calories
    switch (fitnessGoal) {
      case 'Build strength':
        protein = ((calories * 0.30) / 4).toInt(); // 4 kcal per gram protein
        fat = ((calories * 0.25) / 9).toInt(); // 9 kcal per gram fat
        carbs = ((calories * 0.45) / 4).toInt(); // 4 kcal per gram carbs
        break;
      case 'Weight management':
        protein = ((calories * 0.35) / 4).toInt();
        fat = ((calories * 0.28) / 9).toInt();
        carbs = ((calories * 0.37) / 4).toInt();
        break;
      default: // General fitness & Flexibility
        protein = ((calories * 0.25) / 4).toInt();
        fat = ((calories * 0.30) / 9).toInt();
        carbs = ((calories * 0.45) / 4).toInt();
    }

    // Adjust for dietary preferences
    if (dietaryPreference.toLowerCase() == 'high-protein') {
      protein = ((calories * 0.35) / 4).toInt();
      carbs = ((calories * 0.40) / 4).toInt();
      fat = ((calories * 0.25) / 9).toInt();
    }

    // Vegetarian/Vegan adjustments (increase carbs, may adjust protein sources)
    if (dietaryPreference.toLowerCase() == 'vegetarian' ||
        dietaryPreference.toLowerCase() == 'vegan') {
      protein = ((calories * 0.28) / 4).toInt();
      carbs = ((calories * 0.50) / 4).toInt();
      fat = ((calories * 0.22) / 9).toInt();
    }

    // Fiber recommendation: 25-35g per day for adults
    // Scale based on calorie intake (rough estimate: ~10g per 1000 cal)
    fiber = ((calories / 1000) * 10).ceil().clamp(20, 40);

    return DailyMacros(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
    );
  }
}
