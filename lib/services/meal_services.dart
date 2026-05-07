import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Core/constants.dart';

class MealService {
  static const int _defaultRecipeServings = 4;

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
  static const _nidSaturatedFat = 1258;
  static const _nidTransFat = 1257;
  static const _nidPotassium = 1092;
  static const _nidCalcium = 1087;
  static const _nidIron = 1089;
  static const _nidVitaminD = 1114;

  static Future<List<Map<String, dynamic>>> fetchMealsByIngredients(
    List<String> ingredients, {
    String mealType = 'Any',
    List<String> dietaryPrefs = const [],
  }) async {
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

    final topIds =
        (idMatchCount.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(10)
            .map((e) => e.key)
            .toList();

    final results = await Future.wait(topIds.map(_lookupMealWithNutrition));

    var filtered = results.whereType<Map<String, dynamic>>().toList();

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
    final perServingNutrition = await _fetchNutritionForMeal(ingredients);
    final totalNutrition = _calculateTotalNutrition(
      perServingNutrition,
      _defaultRecipeServings,
    );

    meal['nutrition'] = perServingNutrition;
    meal['nutritionPerServing'] = perServingNutrition;
    meal['nutritionTotal'] = totalNutrition;
    meal['servings'] = _defaultRecipeServings;
    meal['nutritionBasis'] = 'per 1 serving';

    // FIX: update the top-level calories int from the nutrition result so
    // NutritionModal and NutritionTab can both read it without guessing the type.
    meal['calories'] = _parseCaloriesInt(perServingNutrition['calories']);

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

    final perServing = 1 / _defaultRecipeServings;

    return {
      'calories': '${(calories * perServing).round()} kcal',
      'protein': '${(protein * perServing).round()}g',
      'carbs': '${(carbs * perServing).round()}g',
      'fat': '${(fat * perServing).round()}g',
      'fiber': '${(fiber * perServing).round()}g',
      'sugar': '${(sugar * perServing).round()}g',
      'sodium': '${(sodium * perServing).round()}mg',
      'cholesterol': '${(cholesterol * perServing).round()}mg',
      'saturatedFat': '${(saturatedFat * perServing).round()}g',
      'transFat': '${(transFat * perServing).round()}g',
      'potassium': '${(potassium * perServing).round()}mg',
      'calcium': '${(calcium * perServing).round()}mg',
      'iron': '${(iron * perServing).round()}mg',
      'vitaminD': '${(vitaminD * perServing).round()}mcg',
    };
  }

  /// Converts per-serving nutrition to total nutrition by multiplying by servings
  static Map<String, dynamic> _calculateTotalNutrition(
    Map<String, dynamic> perServingNutrition,
    int servings,
  ) {
    String multiplyNutrient(dynamic raw, int times) {
      final value =
          double.tryParse(
            raw?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0',
          ) ??
          0;
      final total = value * times;
      final display = total == total.roundToDouble()
          ? total.round().toString()
          : total.toStringAsFixed(1);

      // Extract unit from original value
      final original = raw?.toString() ?? '';
      if (original.contains('kcal')) return '$display kcal';
      if (original.contains('g')) return '$display g';
      if (original.contains('mg')) return '$display mg';
      if (original.contains('mcg')) return '$display mcg';
      return display;
    }

    return {
      'calories': multiplyNutrient(perServingNutrition['calories'], servings),
      'protein': multiplyNutrient(perServingNutrition['protein'], servings),
      'carbs': multiplyNutrient(perServingNutrition['carbs'], servings),
      'fat': multiplyNutrient(perServingNutrition['fat'], servings),
      'saturatedFat': multiplyNutrient(
        perServingNutrition['saturatedFat'],
        servings,
      ),
      'transFat': multiplyNutrient(perServingNutrition['transFat'], servings),
      'fiber': multiplyNutrient(perServingNutrition['fiber'], servings),
      'sugar': multiplyNutrient(perServingNutrition['sugar'], servings),
      'sodium': multiplyNutrient(perServingNutrition['sodium'], servings),
      'cholesterol': multiplyNutrient(
        perServingNutrition['cholesterol'],
        servings,
      ),
      'potassium': multiplyNutrient(perServingNutrition['potassium'], servings),
      'calcium': multiplyNutrient(perServingNutrition['calcium'], servings),
      'iron': multiplyNutrient(perServingNutrition['iron'], servings),
      'vitaminD': multiplyNutrient(perServingNutrition['vitaminD'], servings),
    };
  }

  static Future<Map<String, dynamic>?> fetchNutritionForFoodName(
    String foodName,
  ) async {
    final recipeNutrition = await _fetchNutritionForRecipeName(foodName);
    if (recipeNutrition != null) return recipeNutrition;

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

  static Future<Map<String, dynamic>?> _fetchNutritionForRecipeName(
    String mealName,
  ) async {
    final query = mealName.trim();
    if (query.isEmpty) return null;

    try {
      final res = await http.get(
        Uri.parse('$_mealBase/search.php?s=${Uri.encodeComponent(query)}'),
      );
      if (res.statusCode != 200) return null;

      final meals = jsonDecode(res.body)['meals'] as List?;
      if (meals == null || meals.isEmpty) return null;

      final normalizedQuery = _normalizeName(query);
      Map<String, dynamic>? selectedMatch;

      for (final meal in meals) {
        final candidate = meal as Map<String, dynamic>;
        if (_normalizeName(candidate['strMeal']) == normalizedQuery) {
          selectedMatch = candidate;
          break;
        }
      }

      selectedMatch ??= _bestRecipeNameMatch(meals, normalizedQuery);
      if (selectedMatch == null) return null;

      final mealId = selectedMatch['idMeal']?.toString();
      if (mealId == null || mealId.isEmpty) return null;

      final meal = await _lookupMealWithNutrition(mealId);
      return meal == null ? null : meal['nutrition'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
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

      double? getNutrient(int nutrientId) {
        for (final n in nutrients) {
          if (n['nutrientId'] == nutrientId) {
            return (n['value'] as num?)?.toDouble();
          }
        }
        return null;
      }

      return {
        'calories': getNutrient(_nidCalories) ?? 0,
        'protein': getNutrient(_nidProtein) ?? 0,
        'carbs': getNutrient(_nidCarbs) ?? 0,
        'fat': getNutrient(_nidFat) ?? 0,
        'fiber': getNutrient(_nidFiber) ?? 0,
        'sugar': getNutrient(_nidSugar) ?? 0,
        'sodium': getNutrient(_nidSodium) ?? 0,
        'cholesterol': getNutrient(_nidCholesterol) ?? 0,
        'saturatedFat': getNutrient(_nidSaturatedFat) ?? 0,
        'transFat': getNutrient(_nidTransFat) ?? 0,
        'potassium': getNutrient(_nidPotassium) ?? 0,
        'calcium': getNutrient(_nidCalcium) ?? 0,
        'iron': getNutrient(_nidIron) ?? 0,
        'vitaminD': getNutrient(_nidVitaminD) ?? 0,
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

  static String _normalizeName(dynamic raw) {
    return raw.toString().trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      ' ',
    );
  }

  static Map<String, dynamic>? _bestRecipeNameMatch(
    List meals,
    String normalizedQuery,
  ) {
    final queryWords = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toSet();
    if (queryWords.isEmpty) return null;

    Map<String, dynamic>? best;
    var bestScore = 0.0;

    for (final meal in meals) {
      final candidate = meal as Map<String, dynamic>;
      final candidateWords = _normalizeName(
        candidate['strMeal'],
      ).split(RegExp(r'\s+')).where((word) => word.length > 2).toSet();
      if (candidateWords.isEmpty) continue;

      final score =
          queryWords.intersection(candidateWords).length / queryWords.length;
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return bestScore >= 0.6 ? best : null;
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
