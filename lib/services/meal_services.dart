import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Core/constants.dart';

class MealService {
  static const _mealBase = 'https://www.themealdb.com/api/json/v1/1';
  static const _usdaBase = 'https://api.nal.usda.gov/fdc/v1';

  // ── USDA FoodData Central nutrient IDs ────────────────────────────────────
  static const _nidCalories = 1008;
  static const _nidProtein = 1003;
  static const _nidCarbs = 1005;
  static const _nidFat = 1004;
  static const _nidFiber = 1079;
  static const _nidSugar = 2000;
  static const _nidSodium = 1093;
  static const _nidCholesterol = 1253;
  static const _nidSaturatedFat = 1258; // NEW
  static const _nidTransFat = 1257; // NEW
  static const _nidPotassium = 1092; // NEW
  static const _nidCalcium = 1087; // NEW
  static const _nidIron = 1089; // NEW
  static const _nidVitaminD = 1114; // NEW

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchMealsByIngredients(
    List<String> ingredients, {
    String mealType = 'Any',
    List<String> dietaryPrefs = const [],
  }) async {
    // ── STEP 1: Query TheMealDB once per ingredient ──────────────────────────
    final Map<String, int> idMatchCount = {};

    for (int i = 0; i < ingredients.length; i++) {
      final ingredient = ingredients[i];
      final searchTerm = _simplifyIngredient(ingredient);
      if (searchTerm.isEmpty) continue;

      if (i > 0) await Future.delayed(const Duration(milliseconds: 300));

      final encoded = Uri.encodeComponent(searchTerm);
      final res = await http.get(Uri.parse('$_mealBase/filter.php?i=$encoded'));
      if (res.statusCode != 200) continue;

      final meals = jsonDecode(res.body)['meals'];
      if (meals == null) continue;

      for (final meal in meals as List) {
        final id = meal['idMeal'] as String;
        idMatchCount[id] = (idMatchCount[id] ?? 0) + 1;
      }
    }

    if (idMatchCount.isEmpty) return [];

    // ── STEP 2: Take top 10 meals by match count ─────────────────────────────
    final topIds =
        (idMatchCount.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(10)
            .map((e) => e.key)
            .toList();

    // ── STEP 3: Fetch full detail + nutrition for each ───────────────────────
    final results = await Future.wait(topIds.map(_lookupMealWithNutrition));

    // ── STEP 4: Remove nulls ─────────────────────────────────────────────────
    var filtered = results.whereType<Map<String, dynamic>>().toList();

    // ── STEP 5: Filter by meal type ──────────────────────────────────────────
    if (mealType != 'Any') {
      filtered = filtered.where((meal) {
        final category = (meal['category'] as String).toLowerCase();
        switch (mealType) {
          case 'Breakfast':
            return category == 'breakfast';
          case 'Lunch':
            return [
              'beef',
              'chicken',
              'lamb',
              'pork',
              'seafood',
              'pasta',
              'vegetarian',
              'vegan',
              'goat',
              'miscellaneous',
              'side',
            ].contains(category);
          case 'Dinner':
            return [
              'beef',
              'chicken',
              'lamb',
              'pork',
              'seafood',
              'pasta',
              'vegetarian',
              'vegan',
              'goat',
            ].contains(category);
          case 'Snack':
            return [
              'starter',
              'miscellaneous',
              'side',
              'dessert',
            ].contains(category);
          default:
            return true;
        }
      }).toList();
    }

    // ── STEP 6: Filter by dietary preferences ────────────────────────────────
    if (dietaryPrefs.isNotEmpty) {
      filtered = filtered.where((meal) {
        final category = (meal['category'] as String).toLowerCase();
        final ingredientNames =
            (meal['ingredients'] as List<Map<String, String>>)
                .map((i) => (i['name'] ?? '').toLowerCase())
                .toList();

        for (final pref in dietaryPrefs) {
          if (!_matchesDietaryPref(pref, category, ingredientNames)) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    // ── STEP 7: Sort by dietary preference nutrition ──────────────────────────
    if (dietaryPrefs.isNotEmpty) {
      filtered.sort((a, b) {
        final aNut = a['nutrition'] as Map<String, dynamic>? ?? {};
        final bNut = b['nutrition'] as Map<String, dynamic>? ?? {};

        double parse(dynamic val) =>
            double.tryParse(
              val?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0',
            ) ??
            0;

        if (dietaryPrefs.contains('High-Protein')) {
          return parse(bNut['protein']).compareTo(parse(aNut['protein']));
        }
        if (dietaryPrefs.contains('Low-Carb')) {
          return parse(aNut['carbs']).compareTo(parse(bNut['carbs']));
        }
        if (dietaryPrefs.contains('Vegan') ||
            dietaryPrefs.contains('Vegetarian')) {
          return parse(aNut['calories']).compareTo(parse(bNut['calories']));
        }
        if (dietaryPrefs.contains('Gluten-free') ||
            dietaryPrefs.contains('Dairy-free')) {
          return parse(bNut['fiber']).compareTo(parse(aNut['fiber']));
        }
        return 0;
      });
    }

    return filtered;
  }

  static bool _matchesDietaryPref(
    String pref,
    String category,
    List<String> ingredients,
  ) {
    bool hasAny(List<String> keywords) =>
        ingredients.any((i) => keywords.any((k) => i.contains(k)));

    switch (pref) {
      case 'Vegetarian':
        return category == 'vegetarian' || category == 'vegan';
      case 'Vegan':
        return category == 'vegan';
      case 'Gluten-free':
        return !hasAny([
          'flour',
          'wheat',
          'barley',
          'rye',
          'bread',
          'pasta',
          'noodle',
        ]);
      case 'Dairy-free':
        return !hasAny(['milk', 'cheese', 'butter', 'cream', 'yogurt', 'whey']);
      case 'Low-Carb':
        return !hasAny([
          'rice',
          'pasta',
          'bread',
          'potato',
          'flour',
          'sugar',
          'noodle',
        ]);
      case 'High-Protein':
        return [
          'beef',
          'chicken',
          'lamb',
          'pork',
          'seafood',
          'goat',
        ].contains(category);
      default:
        return true;
    }
  }

  static String _simplifyIngredient(String ingredient) {
    const descriptors = {
      'boneless',
      'skinless',
      'fresh',
      'frozen',
      'dried',
      'ground',
      'chopped',
      'sliced',
      'diced',
      'minced',
      'cooked',
      'raw',
      'whole',
      'half',
      'large',
      'small',
      'medium',
      'big',
      'lean',
      'thick',
      'thin',
      'baby',
      'organic',
      'ripe',
      'breast',
      'thigh',
      'fillet',
      'wing',
      'leg',
    };
    final words = ingredient.toLowerCase().trim().split(RegExp(r'\s+'));
    final filtered = words.where((w) => !descriptors.contains(w)).toList();
    return filtered.isEmpty
        ? ingredient.toLowerCase().trim()
        : filtered.join(' ');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE — MealDB
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> _lookupMealWithNutrition(
    String id,
  ) async {
    final res = await http.get(Uri.parse('$_mealBase/lookup.php?i=$id'));
    if (res.statusCode != 200) return null;

    final meals = jsonDecode(res.body)['meals'] as List?;
    if (meals == null || meals.isEmpty) return null;

    final raw = meals[0] as Map<String, dynamic>;
    final meal = _parseMeal(raw);

    final ingredients = meal['ingredients'] as List<Map<String, String>>;
    final nutrition = await _fetchNutritionForMeal(ingredients);
    meal['nutrition'] = nutrition;

    // FIX: update the top-level calories int from the nutrition result so
    // NutritionModal and NutritionTab can both read it without guessing the type.
    meal['calories'] = _parseCaloriesInt(nutrition['calories']);

    return meal;
  }

  static Map<String, dynamic> _parseMeal(Map<String, dynamic> raw) {
    final List<Map<String, String>> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final name = (raw['strIngredient$i'] ?? '').toString().trim();
      final measure = (raw['strMeasure$i'] ?? '').toString().trim();
      if (name.isNotEmpty) ingredients.add({'name': name, 'measure': measure});
    }

    return {
      'id': raw['idMeal'] ?? '',
      'name': raw['strMeal'] ?? '',
      'category': raw['strCategory'] ?? '',
      'area': raw['strArea'] ?? '',
      'instructions': raw['strInstructions'] ?? '',
      'thumbnail': raw['strMealThumb'] ?? '',
      'youtubeUrl': raw['strYoutube'] ?? '',
      'tags': raw['strTags'] ?? '',
      'ingredients': ingredients,
      'description': '${raw['strCategory'] ?? ''} · ${raw['strArea'] ?? ''}',
      'time': _estimateTime(ingredients.length),
      'difficulty': _estimateDifficulty(ingredients.length),
      // Placeholder — overwritten with a real int after nutrition is fetched.
      'calories': 0,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE — USDA FoodData Central
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _fetchNutritionForMeal(
    List<Map<String, String>> ingredients,
  ) async {
    final results = await Future.wait(
      ingredients.map((ing) => _fetchNutrientsForIngredient(ing['name']!)),
    );

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double fiber = 0;
    double sugar = 0;
    double sodium = 0;
    double cholesterol = 0;
    double saturatedFat = 0; // NEW
    double transFat = 0; // NEW
    double potassium = 0; // NEW
    double calcium = 0; // NEW
    double iron = 0; // NEW
    double vitaminD = 0; // NEW

    for (final n in results) {
      if (n == null) continue;
      calories += n['calories'] ?? 0;
      protein += n['protein'] ?? 0;
      carbs += n['carbs'] ?? 0;
      fat += n['fat'] ?? 0;
      fiber += n['fiber'] ?? 0;
      sugar += n['sugar'] ?? 0;
      sodium += n['sodium'] ?? 0;
      cholesterol += n['cholesterol'] ?? 0;
      saturatedFat += n['saturatedFat'] ?? 0; // NEW
      transFat += n['transFat'] ?? 0; // NEW
      potassium += n['potassium'] ?? 0; // NEW
      calcium += n['calcium'] ?? 0; // NEW
      iron += n['iron'] ?? 0; // NEW
      vitaminD += n['vitaminD'] ?? 0; // NEW
    }

    return {
      'calories': '${calories.round()} kcal',
      'protein': '${protein.round()}g',
      'carbs': '${carbs.round()}g',
      'fat': '${fat.round()}g',
      'fiber': '${fiber.round()}g',
      'sugar': '${sugar.round()}g',
      'sodium': '${sodium.round()}mg',
      'cholesterol': '${cholesterol.round()}mg',
      'saturatedFat': '${saturatedFat.round()}g', // NEW
      'transFat': '${transFat.round()}g', // NEW
      'potassium': '${potassium.round()}mg', // NEW
      'calcium': '${calcium.round()}mg', // NEW
      'iron': '${iron.round()}mg', // NEW
      'vitaminD': '${vitaminD.round()}mcg', // NEW
    };
  }

  static Future<Map<String, dynamic>?> fetchNutritionForFoodName(
    String foodName,
  ) async {
    final nutrients = await _fetchNutrientsForIngredient(foodName);
    if (nutrients == null) return null;

    return {
      'calories': '${(nutrients['calories'] ?? 0).round()} kcal',
      'protein': '${(nutrients['protein'] ?? 0).round()}g',
      'carbs': '${(nutrients['carbs'] ?? 0).round()}g',
      'fat': '${(nutrients['fat'] ?? 0).round()}g',
      'fiber': '${(nutrients['fiber'] ?? 0).round()}g',
      'sugar': '${(nutrients['sugar'] ?? 0).round()}g',
      'sodium': '${(nutrients['sodium'] ?? 0).round()}mg',
      'cholesterol': '${(nutrients['cholesterol'] ?? 0).round()}mg',
      'saturatedFat': '${(nutrients['saturatedFat'] ?? 0).round()}g',
      'transFat': '${(nutrients['transFat'] ?? 0).round()}g',
      'potassium': '${(nutrients['potassium'] ?? 0).round()}mg',
      'calcium': '${(nutrients['calcium'] ?? 0).round()}mg',
      'iron': '${(nutrients['iron'] ?? 0).round()}mg',
      'vitaminD': '${(nutrients['vitaminD'] ?? 0).round()}mcg',
    };
  }

  static Future<Map<String, double>?> _fetchNutrientsForIngredient(
    String ingredientName,
  ) async {
    try {
      final uri = Uri.parse(
        '$_usdaBase/foods/search'
        '?query=${Uri.encodeComponent(ingredientName)}'
        '&dataType=Foundation,SR%20Legacy'
        '&pageSize=1'
        '&api_key=${AppConstants.usdaApiKey}',
      );

      final res = await http.get(uri);
      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final foods = body['foods'] as List?;
      if (foods == null || foods.isEmpty) return null;

      final food = foods[0] as Map<String, dynamic>;
      final nutrients = food['foodNutrients'] as List? ?? [];

      double? _get(int nutrientId) {
        for (final n in nutrients) {
          if (n['nutrientId'] == nutrientId) {
            return (n['value'] as num?)?.toDouble();
          }
        }
        return null;
      }

      return {
        'calories': _get(_nidCalories) ?? 0,
        'protein': _get(_nidProtein) ?? 0,
        'carbs': _get(_nidCarbs) ?? 0,
        'fat': _get(_nidFat) ?? 0,
        'fiber': _get(_nidFiber) ?? 0,
        'sugar': _get(_nidSugar) ?? 0,
        'sodium': _get(_nidSodium) ?? 0,
        'cholesterol': _get(_nidCholesterol) ?? 0,
        'saturatedFat': _get(_nidSaturatedFat) ?? 0, // NEW
        'transFat': _get(_nidTransFat) ?? 0, // NEW
        'potassium': _get(_nidPotassium) ?? 0, // NEW
        'calcium': _get(_nidCalcium) ?? 0, // NEW
        'iron': _get(_nidIron) ?? 0, // NEW
        'vitaminD': _get(_nidVitaminD) ?? 0, // NEW
      };
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE — Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Converts a nutrition calories string like "450 kcal" into a plain int.
  static int _parseCaloriesInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    if (raw is String) {
      return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return 0;
  }

  static String _estimateTime(int n) => n <= 5
      ? '~15 min'
      : n <= 10
      ? '~30 min'
      : '~45 min';

  static String _estimateDifficulty(int n) => n <= 5
      ? 'Easy'
      : n <= 10
      ? 'Medium'
      : 'Advanced';
}
